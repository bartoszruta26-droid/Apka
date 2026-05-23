#!/usr/bin/env bash
#===============================================================================
# Qwen TAM - Security Library
# Secure credential storage and cryptographic operations
# Version: 1.0.0
#===============================================================================

set -euo pipefail

# Security library version
readonly SECURITY_LIB_VERSION="1.0.0"

# Encryption settings
readonly ENCRYPTION_ALGORITHM="aes-256-cbc"
readonly PBKDF2_ITERATIONS=100000
readonly KEY_LENGTH=32

#-------------------------------------------------------------------------------
# Initialize security infrastructure
#-------------------------------------------------------------------------------
init_security() {
    local config_dir="${QWEN_TAM_CONFIG_DIR:-$HOME/.qwen_tam}"
    local keyring_file="${config_dir}/.keyring"
    
    # Create config directory if not exists
    if [[ ! -d "$config_dir" ]]; then
        mkdir -p "$config_dir"
        chmod 700 "$config_dir"
    fi
    
    # Generate master encryption key if not exists
    if [[ ! -f "$keyring_file" ]]; then
        generate_master_key "$keyring_file"
    fi
    
    # Ensure proper permissions
    chmod 600 "$keyring_file" 2>/dev/null || true
    
    export QWEN_TAM_KEYRING_FILE="$keyring_file"
}

#-------------------------------------------------------------------------------
# Generate cryptographically secure master key
#-------------------------------------------------------------------------------
generate_master_key() {
    local keyring_file="$1"
    
    # Try multiple methods for secure random generation
    if command -v openssl &>/dev/null; then
        openssl rand -base64 "$KEY_LENGTH" > "$keyring_file"
    elif [[ -r /dev/urandom ]]; then
        head -c "$KEY_LENGTH" /dev/urandom | base64 > "$keyring_file"
    else
        echo "ERROR: No secure random source available" >&2
        return 1
    fi
    
    chmod 600 "$keyring_file"
    return 0
}

#-------------------------------------------------------------------------------
# Encrypt data using AES-256-CBC with PBKDF2
#-------------------------------------------------------------------------------
encrypt_data() {
    local data="$1"
    local keyring_file="${2:-$QWEN_TAM_KEYRING_FILE}"
    
    if [[ ! -f "$keyring_file" ]]; then
        echo "ERROR: Keyring file not found: $keyring_file" >&2
        return 1
    fi
    
    if ! command -v openssl &>/dev/null; then
        echo "ERROR: OpenSSL is required for encryption" >&2
        return 1
    fi
    
    # Encrypt with strong parameters
    echo "$data" | openssl enc "-${ENCRYPTION_ALGORITHM}" \
        -salt \
        -pbkdf2 \
        -iter "$PBKDF2_ITERATIONS" \
        -pass "file:${keyring_file}" \
        -base64 \
        2>/dev/null
}

#-------------------------------------------------------------------------------
# Decrypt data using AES-256-CBC with PBKDF2
#-------------------------------------------------------------------------------
decrypt_data() {
    local encrypted_data="$1"
    local keyring_file="${2:-$QWEN_TAM_KEYRING_FILE}"
    
    if [[ ! -f "$keyring_file" ]]; then
        echo "ERROR: Keyring file not found: $keyring_file" >&2
        return 1
    fi
    
    if ! command -v openssl &>/dev/null; then
        echo "ERROR: OpenSSL is required for decryption" >&2
        return 1
    fi
    
    # Decrypt with matching parameters
    echo "$encrypted_data" | openssl enc "-${ENCRYPTION_ALGORITHM}" \
        -d \
        -pbkdf2 \
        -iter "$PBKDF2_ITERATIONS" \
        -pass "file:${keyring_file}" \
        -base64 \
        2>/dev/null
}

#-------------------------------------------------------------------------------
# Store GitHub token securely (encrypted)
#-------------------------------------------------------------------------------
store_github_token_secure() {
    local token="$1"
    local username="${2:-}"
    local config_dir="${QWEN_TAM_CONFIG_DIR:-$HOME/.qwen_tam}"
    local github_conf="${config_dir}/github.conf.enc"
    
    # Validate token format (basic check)
    if [[ -z "$token" ]]; then
        echo "ERROR: Token cannot be empty" >&2
        return 1
    fi
    
    # Initialize security if needed
    if [[ -z "${QWEN_TAM_KEYRING_FILE:-}" ]]; then
        init_security || return 1
    fi
    
    # Encrypt the token
    local encrypted_token
    encrypted_token=$(encrypt_data "$token")
    
    if [[ -z "$encrypted_token" ]]; then
        echo "ERROR: Failed to encrypt token" >&2
        return 1
    fi
    
    # Create encrypted config file
    cat > "$github_conf" << EOF
# GitHub Configuration (Encrypted)
# Created: $(date '+%Y-%m-%d %H:%M:%S')
# Security Version: ${SECURITY_LIB_VERSION}

TOKEN_ENCRYPTED=${encrypted_token}
USERNAME=${username}
CREATED_AT=$(date -Iseconds)
EOF
    
    # Set restrictive permissions
    chmod 600 "$github_conf"
    
    return 0
}

#-------------------------------------------------------------------------------
# Retrieve and decrypt GitHub token
#-------------------------------------------------------------------------------
retrieve_github_token_secure() {
    local config_dir="${QWEN_TAM_CONFIG_DIR:-$HOME/.qwen_tam}"
    local github_conf="${config_dir}/github.conf.enc"
    
    if [[ ! -f "$github_conf" ]]; then
        return 1
    fi
    
    # Source to get encrypted token
    local encrypted_token=""
    local username=""
    
    while IFS='=' read -r key value; do
        case "$key" in
            TOKEN_ENCRYPTED) encrypted_token="$value" ;;
            USERNAME) username="$value" ;;
        esac
    done < <(grep -E '^(TOKEN_ENCRYPTED|USERNAME)=' "$github_conf")
    
    if [[ -z "$encrypted_token" ]]; then
        return 1
    fi
    
    # Decrypt the token
    local decrypted_token
    decrypted_token=$(decrypt_data "$encrypted_token")
    
    if [[ -z "$decrypted_token" ]]; then
        echo "ERROR: Failed to decrypt token. Key may be corrupted." >&2
        return 1
    fi
    
    # Output token (caller should capture it)
    echo "$decrypted_token"
    return 0
}

#-------------------------------------------------------------------------------
# Get GitHub username from encrypted config
#-------------------------------------------------------------------------------
get_github_username_secure() {
    local config_dir="${QWEN_TAM_CONFIG_DIR:-$HOME/.qwen_tam}"
    local github_conf="${config_dir}/github.conf.enc"
    
    if [[ ! -f "$github_conf" ]]; then
        return 1
    fi
    
    grep "^USERNAME=" "$github_conf" | cut -d'=' -f2
}

#-------------------------------------------------------------------------------
# Securely delete credentials
#-------------------------------------------------------------------------------
delete_credentials_secure() {
    local config_dir="${QWEN_TAM_CONFIG_DIR:-$HOME/.qwen_tam}"
    local github_conf="${config_dir}/github.conf.enc"
    local keyring_file="${config_dir}/.keyring"
    
    # Securely delete encrypted config
    if [[ -f "$github_conf" ]]; then
        # Overwrite with zeros before deletion (basic secure delete)
        dd if=/dev/zero of="$github_conf" bs=1 count=$(stat -c%s "$github_conf" 2>/dev/null || echo 1024) 2>/dev/null
        rm -f "$github_conf"
    fi
    
    # Optionally delete keyring (warning: this will make other encrypted data unrecoverable)
    if [[ "${1:-}" == "--full-wipe" && -f "$keyring_file" ]]; then
        dd if=/dev/zero of="$keyring_file" bs=1 count=$(stat -c%s "$keyring_file" 2>/dev/null || echo 1024) 2>/dev/null
        rm -f "$keyring_file"
    fi
    
    return 0
}

#-------------------------------------------------------------------------------
# Verify encryption integrity
#-------------------------------------------------------------------------------
verify_encryption_integrity() {
    local config_dir="${QWEN_TAM_CONFIG_DIR:-$HOME/.qwen_tam}"
    local github_conf="${config_dir}/github.conf.enc"
    local keyring_file="${config_dir}/.keyring"
    
    local status=0
    
    # Check keyring
    if [[ ! -f "$keyring_file" ]]; then
        echo "❌ Keyring file missing"
        status=1
    elif [[ ! -r "$keyring_file" ]]; then
        echo "❌ Keyring file not readable"
        status=1
    else
        echo "✅ Keyring file OK"
    fi
    
    # Check encrypted config
    if [[ ! -f "$github_conf" ]]; then
        echo "⚠️  No encrypted GitHub config (not configured yet)"
    elif [[ ! -r "$github_conf" ]]; then
        echo "❌ GitHub config not readable"
        status=1
    else
        # Try to decrypt a test value
        local test_data="integrity_test_$(date +%s)"
        local encrypted
        encrypted=$(encrypt_data "$test_data")
        local decrypted
        decrypted=$(decrypt_data "$encrypted")
        
        if [[ "$decrypted" == "$test_data" ]]; then
            echo "✅ Encryption/Decryption test PASSED"
        else
            echo "❌ Encryption/Decryption test FAILED"
            status=1
        fi
    fi
    
    return $status
}

#-------------------------------------------------------------------------------
# Generate secure random string
#-------------------------------------------------------------------------------
generate_secure_random() {
    local length="${1:-32}"
    
    if command -v openssl &>/dev/null; then
        openssl rand -base64 "$length" | tr -dc 'a-zA-Z0-9' | head -c "$length"
    elif [[ -r /dev/urandom ]]; then
        tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "$length"
    else
        echo "ERROR: No secure random source" >&2
        return 1
    fi
}

#-------------------------------------------------------------------------------
# Hash data with SHA-256
#-------------------------------------------------------------------------------
hash_sha256() {
    local data="$1"
    echo -n "$data" | sha256sum | cut -d' ' -f1
}

#-------------------------------------------------------------------------------
# Verify file integrity with checksum
#-------------------------------------------------------------------------------
verify_file_checksum() {
    local file="$1"
    local expected_checksum="$2"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    local actual_checksum
    actual_checksum=$(sha256sum "$file" | cut -d' ' -f1)
    
    [[ "$actual_checksum" == "$expected_checksum" ]]
}

# Auto-initialize when sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    init_security 2>/dev/null || true
fi
