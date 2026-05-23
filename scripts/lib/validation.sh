#!/usr/bin/env bash
#===============================================================================
# Qwen TAM - Validation Library
# Input validation and sanitization functions
# Version: 1.0.0
#===============================================================================

set -euo pipefail

# Validation library version
readonly VALIDATION_LIB_VERSION="1.0.0"

#-------------------------------------------------------------------------------
# Validate GitHub username format
# GitHub usernames: 1-39 chars, alphanumeric and hyphens, cannot start with hyphen
#-------------------------------------------------------------------------------
validate_github_username() {
    local username="$1"
    
    # Empty check
    if [[ -z "$username" ]]; then
        return 1
    fi
    
    # Length check (1-39 characters)
    if [[ ${#username} -lt 1 || ${#username} -gt 39 ]]; then
        return 1
    fi
    
    # Format check: starts with alphanumeric, followed by alphanumeric or hyphens
    if [[ ! "$username" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,38}$ ]]; then
        return 1
    fi
    
    return 0
}

#-------------------------------------------------------------------------------
# Validate GitHub repository name format
#-------------------------------------------------------------------------------
validate_repo_name() {
    local name="$1"
    
    # Empty check
    if [[ -z "$name" ]]; then
        return 1
    fi
    
    # Length check (1-100 characters)
    if [[ ${#name} -lt 1 || ${#name} -gt 100 ]]; then
        return 1
    fi
    
    # Format check: alphanumeric, dots, hyphens, underscores
    if [[ ! "$name" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        return 1
    fi
    
    return 0
}

#-------------------------------------------------------------------------------
# Validate GitHub token format (basic structure check)
# GitHub tokens are typically 40 characters (classic) or longer (fine-grained)
#-------------------------------------------------------------------------------
validate_github_token_format() {
    local token="$1"
    
    # Empty check
    if [[ -z "$token" ]]; then
        return 1
    fi
    
    # Classic PAT: ghp_ followed by 36 alphanumeric chars
    if [[ "$token" =~ ^ghp_[a-zA-Z0-9]{36}$ ]]; then
        return 0
    fi
    
    # Fine-grained PAT: github_pat_ followed by alphanumeric and underscores
    if [[ "$token" =~ ^github_pat_[a-zA-Z0-9_]+$ ]]; then
        return 0
    fi
    
    # Classic 40-char token (old format)
    if [[ ${#token} -eq 40 && "$token" =~ ^[a-zA-Z0-9]+$ ]]; then
        return 0
    fi
    
    # Generic long token (allow for future formats)
    if [[ ${#token} -ge 32 && "$token" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        return 0
    fi
    
    return 1
}

#-------------------------------------------------------------------------------
# Validate email address format
#-------------------------------------------------------------------------------
validate_email() {
    local email="$1"
    
    # Basic email regex
    if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    fi
    
    return 1
}

#-------------------------------------------------------------------------------
# Validate file path is safe (no path traversal)
#-------------------------------------------------------------------------------
validate_file_path_safe() {
    local path="$1"
    local base_dir="${2:-}"
    
    # Empty check
    if [[ -z "$path" ]]; then
        return 1
    fi
    
    # Check for null bytes
    if [[ "$path" == *$'\0'* ]]; then
        return 1
    fi
    
    # Check for dangerous shell characters
    if [[ "$path" =~ [\;\|\&\$\`\(\)] ]]; then
        return 1
    fi
    
    # Resolve to absolute path without following symlinks
    local resolved_path
    resolved_path=$(realpath -m "$path" 2>/dev/null) || return 1
    
    # If base_dir provided, ensure path is within it
    if [[ -n "$base_dir" ]]; then
        local resolved_base
        resolved_base=$(realpath -m "$base_dir" 2>/dev/null) || return 1
        
        # Check containment
        if [[ ! "$resolved_path" =~ ^"$resolved_base" ]]; then
            return 1
        fi
    fi
    
    return 0
}

#-------------------------------------------------------------------------------
# Sanitize filename (remove dangerous characters)
#-------------------------------------------------------------------------------
sanitize_filename() {
    local filename="$1"
    
    # Remove path components
    filename=$(basename "$filename")
    
    # Replace dangerous characters with underscores
    filename=$(echo "$filename" | tr -c 'a-zA-Z0-9._-' '_')
    
    # Remove leading dots (hidden files)
    filename="${filename#.}"
    
    # Ensure not empty
    if [[ -z "$filename" ]]; then
        filename="unnamed_file"
    fi
    
    echo "$filename"
}

#-------------------------------------------------------------------------------
# Validate cron expression format (5 fields)
#-------------------------------------------------------------------------------
validate_cron_expression() {
    local expr="$1"
    
    # Split into fields
    read -ra fields <<< "$expr"
    
    # Must have exactly 5 fields
    if [[ ${#fields[@]} -ne 5 ]]; then
        return 1
    fi
    
    # Validate each field (basic check)
    local field_patterns=(
        '^[\*,0-9/-]+$'  # minute
        '^[\*,0-9/-]+$'  # hour
        '^[\*,0-9/-]+$'  # day of month
        '^[\*,0-9/-]+$'  # month
        '^[\*,0-9/-]+$'  # day of week
    )
    
    for i in "${!fields[@]}"; do
        if [[ ! "${fields[$i]}" =~ ${field_patterns[$i]} ]]; then
            return 1
        fi
    done
    
    return 0
}

#-------------------------------------------------------------------------------
# Validate URL format (basic)
#-------------------------------------------------------------------------------
validate_url() {
    local url="$1"
    
    # Basic URL pattern
    if [[ "$url" =~ ^https?://[a-zA-Z0-9][-a-zA-Z0-9]*(\.[a-zA-Z0-9][-a-zA-Z0-9]*)*(:[0-9]+)?(/.*)?$ ]]; then
        return 0
    fi
    
    return 1
}

#-------------------------------------------------------------------------------
# Validate API endpoint URL
#-------------------------------------------------------------------------------
validate_api_endpoint() {
    local url="$1"
    
    # Must be http or https
    if ! validate_url "$url"; then
        return 1
    fi
    
    # Should not contain query parameters or fragments
    if [[ "$url" =~ [\?\#] ]]; then
        return 1
    fi
    
    return 0
}

#-------------------------------------------------------------------------------
# Validate port number
#-------------------------------------------------------------------------------
validate_port() {
    local port="$1"
    
    # Must be numeric
    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        return 1
    fi
    
    # Must be in valid range
    if [[ "$port" -lt 1 || "$port" -gt 65535 ]]; then
        return 1
    fi
    
    return 0
}

#-------------------------------------------------------------------------------
# Validate integer within range
#-------------------------------------------------------------------------------
validate_integer_range() {
    local value="$1"
    local min="${2:--9223372036854775808}"
    local max="${3:-9223372036854775807}"
    
    # Must be numeric (integer)
    if ! [[ "$value" =~ ^-?[0-9]+$ ]]; then
        return 1
    fi
    
    # Check range
    if [[ "$value" -lt "$min" || "$value" -gt "$max" ]]; then
        return 1
    fi
    
    return 0
}

#-------------------------------------------------------------------------------
# Validate non-empty string
#-------------------------------------------------------------------------------
validate_non_empty_string() {
    local value="$1"
    local max_length="${2:-}"
    
    if [[ -z "$value" ]]; then
        return 1
    fi
    
    if [[ -n "$max_length" && ${#value} -gt "$max_length" ]]; then
        return 1
    fi
    
    return 0
}

#-------------------------------------------------------------------------------
# Validate alphanumeric string
#-------------------------------------------------------------------------------
validate_alphanumeric() {
    local value="$1"
    local allow_special="${2:-}"
    
    if [[ -z "$value" ]]; then
        return 1
    fi
    
    if [[ -n "$allow_special" ]]; then
        # Allow specified special characters
        local pattern="^[a-zA-Z0-9${allow_special}]+$"
        if [[ ! "$value" =~ $pattern ]]; then
            return 1
        fi
    else
        if [[ ! "$value" =~ ^[a-zA-Z0-9]+$ ]]; then
            return 1
        fi
    fi
    
    return 0
}

#-------------------------------------------------------------------------------
# Sanitize command input (prevent injection)
#-------------------------------------------------------------------------------
sanitize_command_input() {
    local input="$1"
    
    # Remove dangerous characters
    local sanitized
    sanitized=$(echo "$input" | sed 's/[;&|`$(){}]/_/g')
    
    # Trim whitespace
    sanitized=$(echo "$sanitized" | xargs)
    
    echo "$sanitized"
}

#-------------------------------------------------------------------------------
# Validate workflow name
#-------------------------------------------------------------------------------
validate_workflow_name() {
    local name="$1"
    
    # Empty check
    if [[ -z "$name" ]]; then
        return 1
    fi
    
    # Length check
    if [[ ${#name} -gt 100 ]]; then
        return 1
    fi
    
    # Allow alphanumeric, hyphens, underscores, spaces
    if [[ ! "$name" =~ ^[a-zA-Z0-9_-][a-zA-Z0-9_\ -]*$ ]]; then
        return 1
    fi
    
    return 0
}

#-------------------------------------------------------------------------------
# Validate programming language
#-------------------------------------------------------------------------------
validate_language() {
    local lang="$1"
    
    local supported_languages=(
        "markdown" "md" "bash" "shell" "sh" "python" "py"
        "javascript" "js" "typescript" "ts" "html" "css"
        "c" "cpp" "java" "go" "golang" "rust" "php" "ruby"
        "json" "yaml" "yml" "xml" "sql"
    )
    
    local lang_lower
    lang_lower=$(echo "$lang" | tr '[:upper:]' '[:lower:]')
    
    for supported in "${supported_languages[@]}"; do
        if [[ "$lang_lower" == "$supported" ]]; then
            return 0
        fi
    done
    
    return 1
}

#-------------------------------------------------------------------------------
# Comprehensive input validation with error messages
#-------------------------------------------------------------------------------
validate_input_comprehensive() {
    local input="$1"
    local type="$2"
    local field_name="${3:-field}"
    local extra="${4:-}"
    
    case "$type" in
        github_username)
            if ! validate_github_username "$input"; then
                echo "ERROR: Invalid GitHub username format for ${field_name}" >&2
                return 1
            fi
            ;;
        github_token)
            if ! validate_github_token_format "$input"; then
                echo "ERROR: Invalid GitHub token format for ${field_name}" >&2
                return 1
            fi
            ;;
        repo_name)
            if ! validate_repo_name "$input"; then
                echo "ERROR: Invalid repository name format for ${field_name}" >&2
                return 1
            fi
            ;;
        email)
            if ! validate_email "$input"; then
                echo "ERROR: Invalid email format for ${field_name}" >&2
                return 1
            fi
            ;;
        file_path)
            if ! validate_file_path_safe "$input" "$extra"; then
                echo "ERROR: Unsafe file path for ${field_name}" >&2
                return 1
            fi
            ;;
        cron)
            if ! validate_cron_expression "$input"; then
                echo "ERROR: Invalid cron expression format for ${field_name}" >&2
                return 1
            fi
            ;;
        url)
            if ! validate_url "$input"; then
                echo "ERROR: Invalid URL format for ${field_name}" >&2
                return 1
            fi
            ;;
        port)
            if ! validate_port "$input"; then
                echo "ERROR: Invalid port number for ${field_name}" >&2
                return 1
            fi
            ;;
        *)
            echo "WARNING: Unknown validation type: $type" >&2
            ;;
    esac
    
    return 0
}

# Export functions for use in other scripts
export -f validate_github_username
export -f validate_repo_name
export -f validate_github_token_format
export -f validate_email
export -f validate_file_path_safe
export -f sanitize_filename
export -f validate_cron_expression
export -f validate_url
export -f validate_api_endpoint
export -f validate_port
export -f validate_integer_range
export -f validate_non_empty_string
export -f validate_alphanumeric
export -f sanitize_command_input
export -f validate_workflow_name
export -f validate_language
export -f validate_input_comprehensive
