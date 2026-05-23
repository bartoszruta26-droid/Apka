#!/usr/bin/env bash
#===============================================================================
# Qwen TAM - File Locking Library
# Safe file operations with locking mechanisms
# Version: 1.0.0
#===============================================================================

set -euo pipefail

# Lock library version
readonly LOCK_LIB_VERSION="1.0.0"

# Default lock timeout (seconds)
readonly DEFAULT_LOCK_TIMEOUT=30

# Lock directory
LOCK_DIR="${QWEN_TAM_LOCK_DIR:-/tmp/qwen-tam-locks}"

#-------------------------------------------------------------------------------
# Initialize lock directory
#-------------------------------------------------------------------------------
init_lock_system() {
    if [[ ! -d "$LOCK_DIR" ]]; then
        mkdir -p "$LOCK_DIR"
        chmod 1777 "$LOCK_DIR"  # Sticky bit for shared temp directory
    fi
}

#-------------------------------------------------------------------------------
# Acquire exclusive lock on a file
#-------------------------------------------------------------------------------
acquire_lock() {
    local resource="$1"
    local timeout="${2:-$DEFAULT_LOCK_TIMEOUT}"
    local lock_file="${LOCK_DIR}/$(echo "$resource" | sha256sum | cut -c1-32).lock"
    
    # Initialize if needed
    init_lock_system
    
    # Create lock file descriptor
    local fd_num=200
    eval "exec ${fd_num}>\"${lock_file}\""
    
    # Try to acquire lock with timeout
    if ! flock -x -w "$timeout" $fd_num; then
        echo "ERROR: Failed to acquire lock for: $resource (timeout: ${timeout}s)" >&2
        return 1
    fi
    
    # Export lock info for release
    export CURRENT_LOCK_FD=$fd_num
    export CURRENT_LOCK_FILE="$lock_file"
    export CURRENT_LOCK_RESOURCE="$resource"
    
    return 0
}

#-------------------------------------------------------------------------------
# Release current lock
#-------------------------------------------------------------------------------
release_lock() {
    local fd_num="${CURRENT_LOCK_FD:-200}"
    
    # Release the lock
    flock -u $fd_num 2>/dev/null || true
    
    # Close file descriptor
    eval "exec ${fd_num}>&-" 2>/dev/null || true
    
    # Clear exports
    unset CURRENT_LOCK_FD
    unset CURRENT_LOCK_FILE
    unset CURRENT_LOCK_RESOURCE
    
    return 0
}

#-------------------------------------------------------------------------------
# Execute function with lock (wrapper)
#-------------------------------------------------------------------------------
with_lock() {
    local resource="$1"
    local func="$2"
    local timeout="${3:-$DEFAULT_LOCK_TIMEOUT}"
    shift 3 || true
    local args=("$@")
    
    # Acquire lock
    if ! acquire_lock "$resource" "$timeout"; then
        return 1
    fi
    
    # Execute function with arguments
    local result=0
    "$func" "${args[@]}" || result=$?
    
    # Release lock
    release_lock
    
    return $result
}

#-------------------------------------------------------------------------------
# Safe file write with locking
#-------------------------------------------------------------------------------
safe_file_write() {
    local file="$1"
    local content="$2"
    local mode="${3:-644}"
    
    local file_dir
    file_dir=$(dirname "$file")
    
    # Create directory if needed
    if [[ ! -d "$file_dir" ]]; then
        mkdir -p "$file_dir"
    fi
    
    # Acquire lock on file
    if ! acquire_lock "$file"; then
        return 1
    fi
    
    # Write atomically using temp file
    local temp_file
    temp_file=$(mktemp "${file}.tmp.XXXXXX")
    
    if ! echo "$content" > "$temp_file"; then
        rm -f "$temp_file"
        release_lock
        return 1
    fi
    
    # Set permissions before moving
    chmod "$mode" "$temp_file"
    
    # Atomic move
    if ! mv "$temp_file" "$file"; then
        rm -f "$temp_file"
        release_lock
        return 1
    fi
    
    # Release lock
    release_lock
    
    return 0
}

#-------------------------------------------------------------------------------
# Safe file read with locking (shared lock)
#-------------------------------------------------------------------------------
safe_file_read() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    # Acquire shared lock
    if ! acquire_lock "$file"; then
        return 1
    fi
    
    # Read content
    local content
    content=$(cat "$file")
    
    # Release lock
    release_lock
    
    echo "$content"
    return 0
}

#-------------------------------------------------------------------------------
# Safe file append with locking
#-------------------------------------------------------------------------------
safe_file_append() {
    local file="$1"
    local content="$2"
    local mode="${3:-644}"
    
    local file_dir
    file_dir=$(dirname "$file")
    
    # Create directory if needed
    if [[ ! -d "$file_dir" ]]; then
        mkdir -p "$file_dir"
    fi
    
    # Acquire lock
    if ! acquire_lock "$file"; then
        return 1
    fi
    
    # Append content
    if ! echo "$content" >> "$file"; then
        release_lock
        return 1
    fi
    
    # Ensure permissions
    chmod "$mode" "$file" 2>/dev/null || true
    
    # Release lock
    release_lock
    
    return 0
}

#-------------------------------------------------------------------------------
# Safe config update with backup and lock
#-------------------------------------------------------------------------------
safe_config_update() {
    local config_file="$1"
    local key="$2"
    local value="$3"
    local create_backup="${4:-true}"
    
    if [[ ! -f "$config_file" ]]; then
        echo "ERROR: Config file not found: $config_file" >&2
        return 1
    fi
    
    # Acquire lock
    if ! acquire_lock "$config_file"; then
        return 1
    fi
    
    # Create backup if requested
    if [[ "$create_backup" == "true" ]]; then
        local timestamp
        timestamp=$(date +%Y%m%d_%H%M%S)
        local backup_file="${config_file}.backup_${timestamp}"
        
        if ! cp "$config_file" "$backup_file"; then
            release_lock
            return 1
        fi
        
        chmod 600 "$backup_file"
    fi
    
    # Update or add key-value pair
    local temp_file
    temp_file=$(mktemp "${config_file}.tmp.XXXXXX")
    
    local key_found=false
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^${key}= ]]; then
            echo "${key}=${value}"
            key_found=true
        else
            echo "$line"
        fi
    done < "$config_file" > "$temp_file"
    
    # If key not found, append it
    if [[ "$key_found" == "false" ]]; then
        echo "${key}=${value}" >> "$temp_file"
    fi
    
    # Atomic replace
    if ! mv "$temp_file" "$config_file"; then
        rm -f "$temp_file"
        release_lock
        return 1
    fi
    
    # Release lock
    release_lock
    
    return 0
}

#-------------------------------------------------------------------------------
# Cleanup stale locks
#-------------------------------------------------------------------------------
cleanup_stale_locks() {
    local max_age="${1:-3600}"  # Default 1 hour
    
    init_lock_system
    
    local current_time
    current_time=$(date +%s)
    
    for lock_file in "$LOCK_DIR"/*.lock; do
        [[ -f "$lock_file" ]] || continue
        
        local file_age
        file_age=$((current_time - $(stat -c %Y "$lock_file" 2>/dev/null || echo 0)))
        
        if [[ $file_age -gt $max_age ]]; then
            rm -f "$lock_file"
        fi
    done
}

#-------------------------------------------------------------------------------
# List active locks
#-------------------------------------------------------------------------------
list_active_locks() {
    init_lock_system
    
    echo "Active locks in $LOCK_DIR:"
    echo "=========================="
    
    local count=0
    for lock_file in "$LOCK_DIR"/*.lock; do
        [[ -f "$lock_file" ]] || continue
        
        local resource_name
        resource_name=$(basename "$lock_file" .lock)
        local file_age
        file_age=$(($(date +%s) - $(stat -c %Y "$lock_file" 2>/dev/null || echo 0)))
        
        echo "  - ${resource_name} (${file_age}s old)"
        ((count++))
    done
    
    echo "=========================="
    echo "Total: $count active locks"
}

#-------------------------------------------------------------------------------
# Check if resource is locked
#-------------------------------------------------------------------------------
is_resource_locked() {
    local resource="$1"
    local lock_file="${LOCK_DIR}/$(echo "$resource" | sha256sum | cut -c1-32).lock"
    
    if [[ ! -f "$lock_file" ]]; then
        return 1  # Not locked (no lock file)
    fi
    
    # Try to acquire lock without waiting
    local fd_num=201
    eval "exec ${fd_num}>\"${lock_file}\""
    
    if flock -n $fd_num 2>/dev/null; then
        # Got the lock, so it wasn't held
        flock -u $fd_num
        eval "exec ${fd_num}>&-"
        return 1  # Not locked
    else
        return 0  # Locked
    fi
}

#-------------------------------------------------------------------------------
# Wait for lock to be released
#-------------------------------------------------------------------------------
wait_for_lock() {
    local resource="$1"
    local max_wait="${2:-60}"
    local check_interval="${3:-1}"
    
    local waited=0
    
    while is_resource_locked "$resource"; do
        if [[ $waited -ge $max_wait ]]; then
            echo "ERROR: Timeout waiting for lock: $resource" >&2
            return 1
        fi
        
        sleep "$check_interval"
        ((waited += check_interval))
    done
    
    return 0
}

# Auto-initialize when sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    init_lock_system 2>/dev/null || true
fi

# Export important functions
export -f acquire_lock
export -f release_lock
export -f with_lock
export -f safe_file_write
export -f safe_file_read
export -f safe_file_append
export -f safe_config_update
