#!/bin/bash

#===============================================================================
# QWEN TIME & AUTOMATION MANAGER - Configuration & Settings Module
# Podskrypt do zarządzania konfiguracją aplikacji (Menu 5)
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# Konfiguracja i zmienne globalne
#-------------------------------------------------------------------------------
readonly CONFIG_VERSION="1.0"
readonly CONFIG_MODULE_NAME="config"
readonly CONFIG_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly MAIN_SCRIPT_DIR="$(dirname "$CONFIG_SCRIPT_DIR")"
CONFIG_FILE="${HOME}/.qwen_tam_config"
CONFIG_BACKUP_DIR="${HOME}/.qwen_tam_backups"
LOG_DIR="${MAIN_SCRIPT_DIR}/logs"

# Domyślne wartości konfiguracji
DEFAULT_QWEN_API_ENDPOINT="http://localhost:11434"
DEFAULT_WORKING_DIRECTORY="${HOME}/qwen-tam-workspace"
DEFAULT_THEME="dark"
DEFAULT_DISPLAY_MODE="full"
DEFAULT_NOTIFICATION_METHOD="terminal"
DEFAULT_NOTIFICATION_EMAIL=""
DEFAULT_NOTIFICATION_WEBHOOK=""
DEFAULT_AUTO_UPDATE="false"
DEFAULT_UPDATE_CHANNEL="stable"
DEFAULT_MAINTENANCE_WINDOW="02:00-04:00"

# Kolory ANSI
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m' # No Color

#-------------------------------------------------------------------------------
# Funkcje pomocnicze
#-------------------------------------------------------------------------------

log_config_info() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[CONFIG INFO]${NC} $timestamp - $*"
    [[ -d "$LOG_DIR" ]] && echo "[CONFIG INFO] $timestamp - $*" >> "${LOG_DIR}/app.log"
}

log_config_debug() {
    if [[ "${DEBUG_MODE:-false}" == "true" ]]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo -e "${CYAN}[CONFIG DEBUG]${NC} $timestamp - $*" >&2
        [[ -d "$LOG_DIR" ]] && echo "[CONFIG DEBUG] $timestamp - $*" >> "${LOG_DIR}/debug.log"
    fi
}

log_config_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[CONFIG ERROR]${NC} $timestamp - $*" >&2
    [[ -d "$LOG_DIR" ]] && echo "[CONFIG ERROR] $timestamp - $*" >> "${LOG_DIR}/app.log"
}

log_config_event() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    [[ -d "$LOG_DIR" ]] && echo "[CONFIG EVENT] $timestamp - $*" >> "${LOG_DIR}/events.log"
}

# Inicjalizacja środowiska konfiguracyjnego
init_config_environment() {
    log_config_debug "Initializing configuration environment..."
    
    # Tworzenie katalogów
    mkdir -p "$(dirname "$CONFIG_FILE")"
    mkdir -p "$CONFIG_BACKUP_DIR"
    mkdir -p "$LOG_DIR"
    
    # Tworzenie domyślnej konfiguracji jeśli nie istnieje
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_config_info "Creating default configuration file..."
        create_default_config
    fi
    
    log_config_event "Configuration environment initialized"
}

# Tworzenie domyślnej konfiguracji
create_default_config() {
    cat > "$CONFIG_FILE" << EOF
# Qwen Time & Automation Manager Configuration
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# Version: ${CONFIG_VERSION}

#-------------------------------------------------------------------------------
# GitHub Configuration
#-------------------------------------------------------------------------------
GITHUB_TOKEN=""
GITHUB_USERNAME=""
GITHUB_EMAIL=""

#-------------------------------------------------------------------------------
# Qwen API Configuration
#-------------------------------------------------------------------------------
QWEN_API_ENDPOINT="${DEFAULT_QWEN_API_ENDPOINT}"
QWEN_MODEL_CODER="qwen-coder"
QWEN_MODEL_AGENT="qwen-agent"
QWEN_API_TIMEOUT="120"
QWEN_API_MAX_TOKENS="4096"

#-------------------------------------------------------------------------------
# Working Directory
#-------------------------------------------------------------------------------
WORKING_DIRECTORY="${DEFAULT_WORKING_DIRECTORY}"
PROJECTS_DIRECTORY="\${WORKING_DIRECTORY}/projects"
BACKUPS_DIRECTORY="\${WORKING_DIRECTORY}/backups"
TEMP_DIRECTORY="\${WORKING_DIRECTORY}/tmp"

#-------------------------------------------------------------------------------
# Display & Theme
#-------------------------------------------------------------------------------
THEME="${DEFAULT_THEME}"
DISPLAY_MODE="${DEFAULT_DISPLAY_MODE}"
COLOR_ENABLED="true"
ASCII_ART_ENABLED="true"

#-------------------------------------------------------------------------------
# Notification Settings
#-------------------------------------------------------------------------------
NOTIFICATION_METHOD="${DEFAULT_NOTIFICATION_METHOD}"
NOTIFICATION_EMAIL="${DEFAULT_NOTIFICATION_EMAIL}"
NOTIFICATION_WEBHOOK="${DEFAULT_NOTIFICATION_WEBHOOK}"
NOTIFY_ON_SUCCESS="true"
NOTIFY_ON_ERROR="true"
NOTIFY_ON_WARNING="false"

#-------------------------------------------------------------------------------
# Auto-Update Settings
#-------------------------------------------------------------------------------
AUTO_UPDATE_ENABLED="${DEFAULT_AUTO_UPDATE}"
UPDATE_CHANNEL="${DEFAULT_UPDATE_CHANNEL}"
MAINTENANCE_WINDOW="${DEFAULT_MAINTENANCE_WINDOW}"
LAST_UPDATE_CHECK=""

#-------------------------------------------------------------------------------
# Advanced Settings
#-------------------------------------------------------------------------------
DEBUG_MODE="false"
VERBOSE_MODE="false"
LOG_RETENTION_DAYS="30"
MAX_LOG_SIZE_MB="10"
EOF
    
    chmod 600 "$CONFIG_FILE"
    log_config_info "Default configuration created at $CONFIG_FILE"
}

# Ładowanie konfiguracji
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log_config_debug "Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE"
        return 0
    else
        log_config_error "Configuration file not found: $CONFIG_FILE"
        return 1
    fi
}

# Zapisywanie pojedynczej wartości konfiguracyjnej
save_config_value() {
    local key="$1"
    local value="$2"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_config_error "Configuration file does not exist"
        return 1
    fi
    
    # Backup przed modyfikacją
    create_config_backup "pre_edit"
    
    # Aktualizacja wartości w pliku
    if grep -q "^${key}=" "$CONFIG_FILE" 2>/dev/null; then
        # Wartość istnieje - aktualizuj
        sed -i "s|^${key}=.*|${key}=\"${value}\"|" "$CONFIG_FILE"
        log_config_debug "Updated $key = $value"
    else
        # Dodaj nową wartość na końcu sekcji
        echo "${key}=\"${value}\"" >> "$CONFIG_FILE"
        log_config_debug "Added $key = $value"
    fi
    
    # Przeładuj konfigurację
    load_config
    
    log_config_event "Configuration updated: $key"
    return 0
}

# Walidacja tokena GitHub
validate_github_token() {
    local token="$1"
    
    if [[ -z "$token" ]]; then
        echo "Token is empty"
        return 1
    fi
    
    if [[ ${#token} -lt 10 ]]; then
        echo "Token is too short"
        return 1
    fi
    
    # Testowe połączenie z GitHub API
    log_config_debug "Validating GitHub token..."
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/user" 2>/dev/null) || true
    
    case "$response" in
        200)
            echo "Token is valid"
            return 0
            ;;
        401)
            echo "Invalid token"
            return 1
            ;;
        403)
            echo "Token lacks required permissions"
            return 1
            ;;
        *)
            echo "Network error or GitHub API unavailable (HTTP $response)"
            return 2
            ;;
    esac
}

# Tworzenie backupu konfiguracji
create_config_backup() {
    local suffix="${1:-manual}"
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="${CONFIG_BACKUP_DIR}/config_${timestamp}_${suffix}.bak"
    
    if [[ -f "$CONFIG_FILE" ]]; then
        cp "$CONFIG_FILE" "$backup_file"
        chmod 600 "$backup_file"
        log_config_info "Configuration backed up to: $backup_file"
        
        # Usuń stare backupy (zachowaj ostatnie 10)
        cd "$CONFIG_BACKUP_DIR"
        ls -t config_*.bak 2>/dev/null | tail -n +11 | xargs -r rm -f
        cd - > /dev/null
        
        return 0
    else
        log_config_error "No configuration file to backup"
        return 1
    fi
}

# Przywracanie konfiguracji z backupu
restore_config_backup() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        log_config_error "Backup file not found: $backup_file"
        return 1
    fi
    
    # Backup obecnej konfiguracji przed przywróceniem
    create_config_backup "pre_restore"
    
    cp "$backup_file" "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    
    log_config_info "Configuration restored from: $backup_file"
    log_config_event "Configuration restored from backup"
    
    # Przeładuj konfigurację
    load_config
    
    return 0
}

#-------------------------------------------------------------------------------
# Funkcje interfejsu użytkownika (TUI)
#-------------------------------------------------------------------------------

# Wyświetlanie menu konfiguracji
show_config_menu() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           QWEN TIME & AUTOMATION MANAGER v${CONFIG_VERSION}         ║"
    echo "║              CONFIGURATION & SETTINGS MODULE                 ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo -e "${NC}"
    echo -e "${GREEN}║  [1] 🔑 Manage GitHub Token                                ║${NC}"
    echo -e "${GREEN}║  [2] 🌐 Configure Qwen API Endpoint                        ║${NC}"
    echo -e "${GREEN}║  [3] 📂 Set Working Directory                              ║${NC}"
    echo -e "${GREEN}║  [4] 🎨 Theme & Display Options                            ║${NC}"
    echo -e "${GREEN}║  [5] 🔔 Notification Settings                              ║${NC}"
    echo -e "${GREEN}║  [6] 🗄️  Backup Configuration                              ║${NC}"
    echo -e "${GREEN}║  [7] ♻️  Restore Configuration                             ║${NC}"
    echo -e "${GREEN}║  [8] 🔄 Reset to Defaults                                  ║${NC}"
    echo -e "${YELLOW}║  [9] ⬅️  Back to Main Menu                                 ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Menu zarządzania tokenem GitHub
menu_manage_github_token() {
    while true; do
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║              MANAGE GITHUB TOKEN                             ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        
        # Pobierz obecny status
        load_config 2>/dev/null || true
        if [[ -n "${GITHUB_TOKEN:-}" ]]; then
            local masked_token="${GITHUB_TOKEN:0:4}****${GITHUB_TOKEN: -4}"
            echo -e "${GREEN}║  Current Token: ${masked_token}                              ║${NC}"
            echo -e "${GREEN}║  Status: ● Configured                                      ║${NC}"
        else
            echo -e "${YELLOW}║  Current Token: Not configured                             ║${NC}"
            echo -e "${YELLOW}║  Status: ○ Missing                                         ║${NC}"
        fi
        
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║  [1] Set/Update GitHub Token                                 ║${NC}"
        echo -e "${GREEN}║  [2] Validate Current Token                                  ║${NC}"
        echo -e "${GREEN}║  [3] Remove Token                                            ║${NC}"
        echo -e "${GREEN}║  [4] Show User Info                                          ║${NC}"
        echo -e "${YELLOW}║  [5] Back                                                    ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        read -rp "  Enter choice [1-5]: " choice
        case $choice in
            1)
                echo ""
                echo -e "${CYAN}Enter your GitHub Personal Access Token:${NC}"
                echo "(Generate at: https://github.com/settings/tokens)"
                echo "Required scopes: repo, workflow, user"
                echo ""
                read -sp "  Token: " new_token
                echo ""
                
                if [[ -n "$new_token" ]]; then
                    # Walidacja tokena
                    echo -e "${YELLOW}Validating token...${NC}"
                    local validation_result
                    validation_result=$(validate_github_token "$new_token")
                    local validation_status=$?
                    
                    if [[ $validation_status -eq 0 ]]; then
                        save_config_value "GITHUB_TOKEN" "$new_token"
                        echo -e "${GREEN}✓ Token saved successfully!${NC}"
                        log_config_event "GitHub token updated"
                        
                        # Pobierz informacje o użytkowniku
                        local user_info
                        user_info=$(curl -s -H "Authorization: token $new_token" \
                            -H "Accept: application/vnd.github.v3+json" \
                            "https://api.github.com/user" 2>/dev/null) || true
                        
                        if [[ -n "$user_info" ]]; then
                            local username=$(echo "$user_info" | jq -r '.login // empty' 2>/dev/null)
                            local email=$(echo "$user_info" | jq -r '.email // empty' 2>/dev/null)
                            
                            if [[ -n "$username" ]]; then
                                save_config_value "GITHUB_USERNAME" "$username"
                                echo -e "${GREEN}✓ Username detected: $username${NC}"
                            fi
                            if [[ -n "$email" ]]; then
                                save_config_value "GITHUB_EMAIL" "$email"
                                echo -e "${GREEN}✓ Email detected: $email${NC}"
                            fi
                        fi
                        
                        read -rp "Press Enter to continue..."
                    else
                        echo -e "${RED}✗ Validation failed: $validation_result${NC}"
                        echo ""
                        echo "Options:"
                        echo "  1) Try again with different token"
                        echo "  2) Skip validation and save anyway"
                        echo "  3) Cancel"
                        read -rp "  Choice [1-3]: " sub_choice
                        case $sub_choice in
                            1) continue ;;
                            2)
                                save_config_value "GITHUB_TOKEN" "$new_token"
                                echo -e "${YELLOW}⚠ Token saved without validation${NC}"
                                read -rp "Press Enter to continue..."
                                ;;
                            3) echo "Cancelled." ;;
                        esac
                    fi
                else
                    echo -e "${RED}Token cannot be empty${NC}"
                    sleep 1
                fi
                ;;
            2)
                if [[ -n "${GITHUB_TOKEN:-}" ]]; then
                    echo -e "${YELLOW}Validating current token...${NC}"
                    local result
                    result=$(validate_github_token "$GITHUB_TOKEN")
                    if [[ $? -eq 0 ]]; then
                        echo -e "${GREEN}✓ $result${NC}"
                    else
                        echo -e "${RED}✗ $result${NC}"
                    fi
                else
                    echo -e "${YELLOW}No token configured${NC}"
                fi
                read -rp "Press Enter to continue..."
                ;;
            3)
                echo -e "${YELLOW}Are you sure you want to remove the GitHub token?${NC}"
                read -rp "  Confirm [y/N]: " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    save_config_value "GITHUB_TOKEN" ""
                    echo -e "${GREEN}✓ Token removed${NC}"
                    log_config_event "GitHub token removed"
                fi
                read -rp "Press Enter to continue..."
                ;;
            4)
                if [[ -n "${GITHUB_TOKEN:-}" ]]; then
                    echo -e "${CYAN}Fetching user information...${NC}"
                    local user_info
                    user_info=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                        -H "Accept: application/vnd.github.v3+json" \
                        "https://api.github.com/user" 2>/dev/null) || true
                    
                    if [[ -n "$user_info" ]]; then
                        echo ""
                        echo -e "${GREEN}GitHub User Information:${NC}"
                        echo "  Login: $(echo "$user_info" | jq -r '.login' 2>/dev/null)"
                        echo "  Name: $(echo "$user_info" | jq -r '.name // "N/A"' 2>/dev/null)"
                        echo "  Email: $(echo "$user_info" | jq -r '.email // "N/A"' 2>/dev/null)"
                        echo "  Company: $(echo "$user_info" | jq -r '.company // "N/A"' 2>/dev/null)"
                        echo "  Location: $(echo "$user_info" | jq -r '.location // "N/A"' 2>/dev/null)"
                        echo "  Public Repos: $(echo "$user_info" | jq -r '.public_repos // 0' 2>/dev/null)"
                        echo "  Followers: $(echo "$user_info" | jq -r '.followers // 0' 2>/dev/null)"
                        echo "  Following: $(echo "$user_info" | jq -r '.following // 0' 2>/dev/null)"
                        echo "  Created At: $(echo "$user_info" | jq -r '.created_at // "N/A"' 2>/dev/null)"
                    else
                        echo -e "${RED}Failed to fetch user information${NC}"
                    fi
                else
                    echo -e "${YELLOW}No token configured${NC}"
                fi
                read -rp "Press Enter to continue..."
                ;;
            5|*) break ;;
        esac
    done
}

# Menu konfiguracji endpointu Qwen API
menu_configure_qwen_api() {
    load_config 2>/dev/null || true
    
    while true; do
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║           CONFIGURE QWEN API ENDPOINT                        ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║  Current Settings:                                           ║${NC}"
        echo -e "${GREEN}║    API Endpoint: ${QWEN_API_ENDPOINT:-$DEFAULT_QWEN_API_ENDPOINT}                      ║${NC}"
        echo -e "${GREEN}║    Coder Model: ${QWEN_MODEL_CODER:-$DEFAULT_QWEN_MODEL_CODER}                          ║${NC}"
        echo -e "${GREEN}║    Agent Model: ${QWEN_MODEL_AGENT:-$DEFAULT_QWEN_MODEL_AGENT}                          ║${NC}"
        echo -e "${GREEN}║    Timeout: ${QWEN_API_TIMEOUT:-$DEFAULT_QWEN_API_TIMEOUT}s                                   ║${NC}"
        echo -e "${GREEN}║    Max Tokens: ${QWEN_API_MAX_TOKENS:-$DEFAULT_QWEN_API_MAX_TOKENS}                            ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║  [1] Change API Endpoint                                     ║${NC}"
        echo -e "${GREEN}║  [2] Change Coder Model                                      ║${NC}"
        echo -e "${GREEN}║  [3] Change Agent Model                                      ║${NC}"
        echo -e "${GREEN}║  [4] Set Timeout                                             ║${NC}"
        echo -e "${GREEN}║  [5] Set Max Tokens                                          ║${NC}"
        echo -e "${GREEN}║  [6] Test Connection                                         ║${NC}"
        echo -e "${YELLOW}║  [7] Back                                                    ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        read -rp "  Enter choice [1-7]: " choice
        case $choice in
            1)
                echo ""
                echo -e "${CYAN}Current endpoint: ${QWEN_API_ENDPOINT:-$DEFAULT_QWEN_API_ENDPOINT}${NC}"
                read -rp "  New API endpoint: " new_endpoint
                if [[ -n "$new_endpoint" ]]; then
                    save_config_value "QWEN_API_ENDPOINT" "$new_endpoint"
                    echo -e "${GREEN}✓ API endpoint updated${NC}"
                fi
                read -rp "Press Enter to continue..."
                ;;
            2)
                echo ""
                echo -e "${CYAN}Current model: ${QWEN_MODEL_CODER:-$DEFAULT_QWEN_MODEL_CODER}${NC}"
                echo "Available models (Ollama): qwen-coder, qwen2.5-coder, codellama"
                read -rp "  New Coder model: " new_model
                if [[ -n "$new_model" ]]; then
                    save_config_value "QWEN_MODEL_CODER" "$new_model"
                    echo -e "${GREEN}✓ Coder model updated${NC}"
                fi
                read -rp "Press Enter to continue..."
                ;;
            3)
                echo ""
                echo -e "${CYAN}Current model: ${QWEN_MODEL_AGENT:-$DEFAULT_QWEN_MODEL_AGENT}${NC}"
                echo "Available models (Ollama): qwen-agent, qwen2.5, llama3"
                read -rp "  New Agent model: " new_model
                if [[ -n "$new_model" ]]; then
                    save_config_value "QWEN_MODEL_AGENT" "$new_model"
                    echo -e "${GREEN}✓ Agent model updated${NC}"
                fi
                read -rp "Press Enter to continue..."
                ;;
            4)
                echo ""
                echo -e "${CYAN}Current timeout: ${QWEN_API_TIMEOUT:-$DEFAULT_QWEN_API_TIMEOUT}s${NC}"
                read -rp "  New timeout (seconds): " new_timeout
                if [[ "$new_timeout" =~ ^[0-9]+$ ]] && [[ $new_timeout -gt 0 ]]; then
                    save_config_value "QWEN_API_TIMEOUT" "$new_timeout"
                    echo -e "${GREEN}✓ Timeout updated${NC}"
                else
                    echo -e "${RED}Invalid timeout value${NC}"
                fi
                read -rp "Press Enter to continue..."
                ;;
            5)
                echo ""
                echo -e "${CYAN}Current max tokens: ${QWEN_API_MAX_TOKENS:-$DEFAULT_QWEN_API_MAX_TOKENS}${NC}"
                read -rp "  New max tokens: " new_max
                if [[ "$new_max" =~ ^[0-9]+$ ]] && [[ $new_max -gt 0 ]]; then
                    save_config_value "QWEN_API_MAX_TOKENS" "$new_max"
                    echo -e "${GREEN}✓ Max tokens updated${NC}"
                else
                    echo -e "${RED}Invalid value${NC}"
                fi
                read -rp "Press Enter to continue..."
                ;;
            6)
                echo -e "${YELLOW}Testing connection to Qwen API...${NC}"
                local endpoint="${QWEN_API_ENDPOINT:-$DEFAULT_QWEN_API_ENDPOINT}"
                
                # Test podstawowego połączenia
                if curl -s --connect-timeout 5 "${endpoint}/api/tags" > /dev/null 2>&1; then
                    echo -e "${GREEN}✓ Connection successful!${NC}"
                    
                    # Pobierz listę modeli
                    echo ""
                    echo -e "${CYAN}Available models:${NC}"
                    curl -s "${endpoint}/api/tags" 2>/dev/null | jq -r '.models[].name' 2>/dev/null | while read -r model; do
                        echo "  - $model"
                    done || echo "  (Could not retrieve model list)"
                else
                    echo -e "${RED}✗ Connection failed${NC}"
                    echo "Make sure Ollama/Qwen service is running at: $endpoint"
                    echo ""
                    echo "Troubleshooting:"
                    echo "  1. Check if Ollama is running: systemctl status ollama"
                    echo "  2. Start Ollama: ollama serve"
                    echo "  3. Verify endpoint URL is correct"
                fi
                read -rp "Press Enter to continue..."
                ;;
            7|*) break ;;
        esac
    done
}

# Menu ustawienia katalogu roboczego
menu_set_working_directory() {
    load_config 2>/dev/null || true
    
    while true; do
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║              SET WORKING DIRECTORY                           ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║  Current Directories:                                        ║${NC}"
        echo -e "${GREEN}║    Working: ${WORKING_DIRECTORY:-$DEFAULT_WORKING_DIRECTORY}                     ║${NC}"
        echo -e "${GREEN}║    Projects: ${PROJECTS_DIRECTORY:-${WORKING_DIRECTORY:-$DEFAULT_WORKING_DIRECTORY}/projects}                   ║${NC}"
        echo -e "${GREEN}║    Backups: ${BACKUPS_DIRECTORY:-${WORKING_DIRECTORY:-$DEFAULT_WORKING_DIRECTORY}/backups}                    ║${NC}"
        echo -e "${GREEN}║    Temp: ${TEMP_DIRECTORY:-${WORKING_DIRECTORY:-$DEFAULT_WORKING_DIRECTORY}/tmp}                            ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║  [1] Change Working Directory                                ║${NC}"
        echo -e "${GREEN}║  [2] Create Directory Structure                              ║${NC}"
        echo -e "${GREEN}║  [3] Verify Directories                                      ║${NC}"
        echo -e "${GREEN}║  [4] Open Working Directory                                  ║${NC}"
        echo -e "${YELLOW}║  [5] Back                                                    ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        read -rp "  Enter choice [1-5]: " choice
        case $choice in
            1)
                echo ""
                echo -e "${CYAN}Current working directory: ${WORKING_DIRECTORY:-$DEFAULT_WORKING_DIRECTORY}${NC}"
                echo "Enter new path (absolute or relative):"
                read -rp "  Path: " new_path
                
                if [[ -n "$new_path" ]]; then
                    # Rozwiń ścieżkę
                    new_path=$(eval echo "$new_path")
                    
                    # Sprawdź czy katalog istnieje lub można go utworzyć
                    if [[ ! -d "$new_path" ]]; then
                        echo -e "${YELLOW}Directory does not exist. Create it?${NC}"
                        read -rp "  Create [Y/n]: " create_confirm
                        if [[ ! "$create_confirm" =~ ^[Nn]$ ]]; then
                            mkdir -p "$new_path" 2>/dev/null
                            if [[ $? -eq 0 ]]; then
                                echo -e "${GREEN}✓ Directory created${NC}"
                            else
                                echo -e "${RED}✗ Failed to create directory${NC}"
                                read -rp "Press Enter to continue..."
                                continue
                            fi
                        else
                            echo "Cancelled."
                            read -rp "Press Enter to continue..."
                            continue
                        fi
                    fi
                    
                    # Zapisz konfigurację
                    save_config_value "WORKING_DIRECTORY" "$new_path"
                    
                    # Aktualizuj powiązane katalogi
                    save_config_value "PROJECTS_DIRECTORY" "${new_path}/projects"
                    save_config_value "BACKUPS_DIRECTORY" "${new_path}/backups"
                    save_config_value "TEMP_DIRECTORY" "${new_path}/tmp"
                    
                    echo -e "${GREEN}✓ Working directory updated${NC}"
                    log_config_event "Working directory changed to: $new_path"
                fi
                read -rp "Press Enter to continue..."
                ;;
            2)
                echo -e "${CYAN}Creating directory structure...${NC}"
                local base_dir="${WORKING_DIRECTORY:-$DEFAULT_WORKING_DIRECTORY}"
                
                local dirs=(
                    "$base_dir"
                    "${base_dir}/projects"
                    "${base_dir}/backups"
                    "${base_dir}/tmp"
                    "${base_dir}/scripts"
                    "${base_dir}/docs"
                    "${base_dir}/tests"
                )
                
                for dir in "${dirs[@]}"; do
                    if [[ ! -d "$dir" ]]; then
                        mkdir -p "$dir"
                        echo -e "${GREEN}  ✓ Created: $dir${NC}"
                    else
                        echo -e "${BLUE}  • Exists: $dir${NC}"
                    fi
                done
                
                echo -e "${GREEN}✓ Directory structure ready${NC}"
                read -rp "Press Enter to continue..."
                ;;
            3)
                echo -e "${CYAN}Verifying directories...${NC}"
                echo ""
                
                local all_ok=true
                local dirs_to_check=(
                    "WORKING_DIRECTORY:${WORKING_DIRECTORY:-$DEFAULT_WORKING_DIRECTORY}"
                    "PROJECTS_DIRECTORY:${PROJECTS_DIRECTORY:-${WORKING_DIRECTORY:-$DEFAULT_WORKING_DIRECTORY}/projects}"
                    "BACKUPS_DIRECTORY:${BACKUPS_DIRECTORY:-${WORKING_DIRECTORY:-$DEFAULT_WORKING_DIRECTORY}/backups}"
                    "TEMP_DIRECTORY:${TEMP_DIRECTORY:-${WORKING_DIRECTORY:-$DEFAULT_WORKING_DIRECTORY}/tmp}"
                )
                
                for entry in "${dirs_to_check[@]}"; do
                    local name="${entry%%:*}"
                    local path="${entry#*:}"
                    
                    if [[ -d "$path" ]]; then
                        if [[ -w "$path" ]]; then
                            echo -e "${GREEN}  ✓ $name: $path (read/write)${NC}"
                        else
                            echo -e "${YELLOW}  ⚠ $name: $path (read-only)${NC}"
                        fi
                    else
                        echo -e "${RED}  ✗ $name: $path (not found)${NC}"
                        all_ok=false
                    fi
                done
                
                echo ""
                if $all_ok; then
                    echo -e "${GREEN}All directories verified successfully${NC}"
                else
                    echo -e "${YELLOW}Some directories are missing. Use option 2 to create them.${NC}"
                fi
                read -rp "Press Enter to continue..."
                ;;
            4)
                local target_dir="${WORKING_DIRECTORY:-$DEFAULT_WORKING_DIRECTORY}"
                if [[ -d "$target_dir" ]]; then
                    echo -e "${CYAN}Opening working directory: $target_dir${NC}"
                    cd "$target_dir" && pwd && ls -la
                    cd - > /dev/null
                else
                    echo -e "${RED}Directory does not exist: $target_dir${NC}"
                fi
                read -rp "Press Enter to continue..."
                ;;
            5|*) break ;;
        esac
    done
}

# Menu opcji motywu i wyświetlania
menu_theme_display() {
    load_config 2>/dev/null || true
    
    while true; do
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║              THEME & DISPLAY OPTIONS                         ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║  Current Settings:                                           ║${NC}"
        echo -e "${GREEN}║    Theme: ${THEME:-$DEFAULT_THEME}                                       ║${NC}"
        echo -e "${GREEN}║    Display Mode: ${DISPLAY_MODE:-$DEFAULT_DISPLAY_MODE}                               ║${NC}"
        echo -e "${GREEN}║    Colors: ${COLOR_ENABLED:-true}                                         ║${NC}"
        echo -e "${GREEN}║    ASCII Art: ${ASCII_ART_ENABLED:-true}                                    ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║  [1] Select Theme (dark/light/colorful)                      ║${NC}"
        echo -e "${GREEN}║  [2] Set Display Mode (full/compact/minimal)                 ║${NC}"
        echo -e "${GREEN}║  [3] Toggle Colors                                           ║${NC}"
        echo -e "${GREEN}║  [4] Toggle ASCII Art                                        ║${NC}"
        echo -e "${GREEN}║  [5] Preview Theme                                           ║${NC}"
        echo -e "${YELLOW}║  [6] Back                                                    ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        read -rp "  Enter choice [1-6]: " choice
        case $choice in
            1)
                echo ""
                echo -e "${CYAN}Select theme:${NC}"
                echo "  1) dark (default)"
                echo "  2) light"
                echo "  3) colorful"
                read -rp "  Choice [1-3]: " theme_choice
                case $theme_choice in
                    1) save_config_value "THEME" "dark" ;;
                    2) save_config_value "THEME" "light" ;;
                    3) save_config_value "THEME" "colorful" ;;
                    *) echo "Invalid choice" ;;
                esac
                read -rp "Press Enter to continue..."
                ;;
            2)
                echo ""
                echo -e "${CYAN}Select display mode:${NC}"
                echo "  1) full (all details)"
                echo "  2) compact (reduced spacing)"
                echo "  3) minimal (text only)"
                read -rp "  Choice [1-3]: " mode_choice
                case $mode_choice in
                    1) save_config_value "DISPLAY_MODE" "full" ;;
                    2) save_config_value "DISPLAY_MODE" "compact" ;;
                    3) save_config_value "DISPLAY_MODE" "minimal" ;;
                    *) echo "Invalid choice" ;;
                esac
                read -rp "Press Enter to continue..."
                ;;
            3)
                local current="${COLOR_ENABLED:-true}"
                local new_val="false"
                if [[ "$current" == "true" ]]; then
                    new_val="false"
                else
                    new_val="true"
                fi
                save_config_value "COLOR_ENABLED" "$new_val"
                echo -e "${GREEN}✓ Colors ${new_val}${NC}"
                read -rp "Press Enter to continue..."
                ;;
            4)
                local current="${ASCII_ART_ENABLED:-true}"
                local new_val="false"
                if [[ "$current" == "true" ]]; then
                    new_val="false"
                else
                    new_val="true"
                fi
                save_config_value "ASCII_ART_ENABLED" "$new_val"
                echo -e "${GREEN}✓ ASCII Art ${new_val}${NC}"
                read -rp "Press Enter to continue..."
                ;;
            5)
                echo ""
                echo -e "${CYAN}Theme Preview:${NC}"
                echo ""
                echo -e "${GREEN}This is green text (success/info)${NC}"
                echo -e "${RED}This is red text (errors)${NC}"
                echo -e "${YELLOW}This is yellow text (warnings)${NC}"
                echo -e "${BLUE}This is blue text (info)${NC}"
                echo -e "${MAGENTA}This is magenta text (highlights)${NC}"
                echo -e "${CYAN}This is cyan text (headers)${NC}"
                echo ""
                read -rp "Press Enter to continue..."
                ;;
            6|*) break ;;
        esac
    done
}

# Menu ustawień powiadomień
menu_notification_settings() {
    load_config 2>/dev/null || true
    
    while true; do
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║              NOTIFICATION SETTINGS                           ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║  Current Settings:                                           ║${NC}"
        echo -e "${GREEN}║    Method: ${NOTIFICATION_METHOD:-$DEFAULT_NOTIFICATION_METHOD}                                   ║${NC}"
        echo -e "${GREEN}║    Email: ${NOTIFICATION_EMAIL:-Not set}                               ║${NC}"
        echo -e "${GREEN}║    Webhook: ${NOTIFICATION_WEBHOOK:-Not set}                             ║${NC}"
        echo -e "${GREEN}║    Notify on Success: ${NOTIFY_ON_SUCCESS:-true}                          ║${NC}"
        echo -e "${GREEN}║    Notify on Error: ${NOTIFY_ON_ERROR:-true}                            ║${NC}"
        echo -e "${GREEN}║    Notify on Warning: ${NOTIFY_ON_WARNING:-false}                         ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║  [1] Change Notification Method                              ║${NC}"
        echo -e "${GREEN}║  [2] Set Email Address                                       ║${NC}"
        echo -e "${GREEN}║  [3] Set Webhook URL                                         ║${NC}"
        echo -e "${GREEN}║  [4] Configure Event Types                                   ║${NC}"
        echo -e "${GREEN}║  [5] Test Notification                                       ║${NC}"
        echo -e "${YELLOW}║  [6] Back                                                    ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        read -rp "  Enter choice [1-6]: " choice
        case $choice in
            1)
                echo ""
                echo -e "${CYAN}Select notification method:${NC}"
                echo "  1) terminal (default) - show in TUI"
                echo "  2) email - send via mail command"
                echo "  3) webhook - HTTP POST to URL"
                echo "  4) all - use all configured methods"
                read -rp "  Choice [1-4]: " method_choice
                case $method_choice in
                    1) save_config_value "NOTIFICATION_METHOD" "terminal" ;;
                    2) save_config_value "NOTIFICATION_METHOD" "email" ;;
                    3) save_config_value "NOTIFICATION_METHOD" "webhook" ;;
                    4) save_config_value "NOTIFICATION_METHOD" "all" ;;
                    *) echo "Invalid choice" ;;
                esac
                read -rp "Press Enter to continue..."
                ;;
            2)
                echo ""
                echo -e "${CYAN}Current email: ${NOTIFICATION_EMAIL:-Not set}${NC}"
                read -rp "  New email address: " new_email
                if [[ -n "$new_email" ]]; then
                    if [[ "$new_email" =~ ^[^@]+@[^@]+\.[^@]+$ ]]; then
                        save_config_value "NOTIFICATION_EMAIL" "$new_email"
                        echo -e "${GREEN}✓ Email saved${NC}"
                    else
                        echo -e "${RED}Invalid email format${NC}"
                    fi
                fi
                read -rp "Press Enter to continue..."
                ;;
            3)
                echo ""
                echo -e "${CYAN}Current webhook: ${NOTIFICATION_WEBHOOK:-Not set}${NC}"
                read -rp "  New webhook URL: " new_webhook
                if [[ -n "$new_webhook" ]]; then
                    if [[ "$new_webhook" =~ ^https?:// ]]; then
                        save_config_value "NOTIFICATION_WEBHOOK" "$new_webhook"
                        echo -e "${GREEN}✓ Webhook saved${NC}"
                    else
                        echo -e "${RED}URL must start with http:// or https://${NC}"
                    fi
                fi
                read -rp "Press Enter to continue..."
                ;;
            4)
                echo ""
                echo -e "${CYAN}Configure event types to notify:${NC}"
                
                # Notify on Success
                local current="${NOTIFY_ON_SUCCESS:-true}"
                echo -n "  Notify on success [Y/n]: "
                read -r resp
                if [[ "$resp" =~ ^[Nn]$ ]]; then
                    save_config_value "NOTIFY_ON_SUCCESS" "false"
                else
                    save_config_value "NOTIFY_ON_SUCCESS" "true"
                fi
                
                # Notify on Error
                current="${NOTIFY_ON_ERROR:-true}"
                echo -n "  Notify on error [Y/n]: "
                read -r resp
                if [[ "$resp" =~ ^[Nn]$ ]]; then
                    save_config_value "NOTIFY_ON_ERROR" "false"
                else
                    save_config_value "NOTIFY_ON_ERROR" "true"
                fi
                
                # Notify on Warning
                current="${NOTIFY_ON_WARNING:-false}"
                echo -n "  Notify on warning [y/N]: "
                read -r resp
                if [[ "$resp" =~ ^[Yy]$ ]]; then
                    save_config_value "NOTIFY_ON_WARNING" "true"
                else
                    save_config_value "NOTIFY_ON_WARNING" "false"
                fi
                
                echo -e "${GREEN}✓ Event types updated${NC}"
                read -rp "Press Enter to continue..."
                ;;
            5)
                echo -e "${CYAN}Sending test notification...${NC}"
                local method="${NOTIFICATION_METHOD:-terminal}"
                
                case "$method" in
                    terminal)
                        echo -e "${GREEN}✓ Test notification (terminal)${NC}"
                        ;;
                    email)
                        local email="${NOTIFICATION_EMAIL:-}"
                        if [[ -n "$email" ]] && command -v mail &> /dev/null; then
                            echo "Test notification from Qwen TAM" | mail -s "Qwen TAM Test" "$email" 2>/dev/null && \
                                echo -e "${GREEN}✓ Test email sent to $email${NC}" || \
                                echo -e "${RED}✗ Failed to send email${NC}"
                        else
                            echo -e "${RED}Email not configured or mail command not available${NC}"
                        fi
                        ;;
                    webhook)
                        local webhook="${NOTIFICATION_WEBHOOK:-}"
                        if [[ -n "$webhook" ]]; then
                            local payload='{"text":"Test notification from Qwen TAM","type":"test"}'
                            curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$webhook" > /dev/null && \
                                echo -e "${GREEN}✓ Test webhook sent${NC}" || \
                                echo -e "${RED}✗ Failed to send webhook${NC}"
                        else
                            echo -e "${RED}Webhook not configured${NC}"
                        fi
                        ;;
                    all)
                        echo "Testing all methods..."
                        echo -e "${GREEN}✓ Terminal: OK${NC}"
                        ;;
                esac
                read -rp "Press Enter to continue..."
                ;;
            6|*) break ;;
        esac
    done
}

# Menu backupu konfiguracji
menu_backup_configuration() {
    load_config 2>/dev/null || true
    
    while true; do
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║              BACKUP CONFIGURATION                            ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║  Configuration File: ${CONFIG_FILE}          ║${NC}"
        echo -e "${GREEN}║  Backup Directory: ${CONFIG_BACKUP_DIR}             ║${NC}"
        echo ""
        
        # Lista backupów
        echo -e "${CYAN}  Available Backups:${NC}"
        if [[ -d "$CONFIG_BACKUP_DIR" ]]; then
            local count=0
            for backup in $(ls -t "$CONFIG_BACKUP_DIR"/config_*.bak 2>/dev/null | head -10); do
                local filename=$(basename "$backup")
                local size=$(stat -c%s "$backup" 2>/dev/null || echo "?")
                local date=$(stat -c%y "$backup" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
                echo -e "${GREEN}    • $filename ($size bytes, $date)${NC}"
                ((count++))
            done
            if [[ $count -eq 0 ]]; then
                echo -e "${YELLOW}    No backups found${NC}"
            fi
        else
            echo -e "${YELLOW}    Backup directory does not exist${NC}"
        fi
        
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║  [1] Create Manual Backup                                    ║${NC}"
        echo -e "${GREEN}║  [2] View Backup Content                                     ║${NC}"
        echo -e "${GREEN}║  [3] Compare with Current                                    ║${NC}"
        echo -e "${GREEN}║  [4] Export to Archive                                       ║${NC}"
        echo -e "${YELLOW}║  [5] Back                                                    ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        read -rp "  Enter choice [1-5]: " choice
        case $choice in
            1)
                echo -e "${CYAN}Creating backup...${NC}"
                local suffix="manual_$(date '+%Y%m%d_%H%M%S')"
                if create_config_backup "$suffix"; then
                    echo -e "${GREEN}✓ Backup created successfully${NC}"
                else
                    echo -e "${RED}✗ Failed to create backup${NC}"
                fi
                read -rp "Press Enter to continue..."
                ;;
            2)
                echo ""
                echo -e "${CYAN}Select backup to view:${NC}"
                local backups=($(ls -t "$CONFIG_BACKUP_DIR"/config_*.bak 2>/dev/null))
                if [[ ${#backups[@]} -gt 0 ]]; then
                    for i in "${!backups[@]}"; do
                        echo "  $((i+1))) $(basename "${backups[$i]}")"
                    done
                    read -rp "  Choice [1-${#backups[@]}]: " idx
                    if [[ $idx -ge 1 && $idx -le ${#backups[@]} ]]; then
                        local selected="${backups[$((idx-1))]}"
                        echo ""
                        echo -e "${CYAN}Content of $(basename "$selected"):${NC}"
                        echo "────────────────────────────────────────"
                        cat "$selected"
                        echo "────────────────────────────────────────"
                    fi
                else
                    echo -e "${YELLOW}No backups available${NC}"
                fi
                read -rp "Press Enter to continue..."
                ;;
            3)
                echo ""
                echo -e "${CYAN}Select backup to compare:${NC}"
                local backups=($(ls -t "$CONFIG_BACKUP_DIR"/config_*.bak 2>/dev/null))
                if [[ ${#backups[@]} -gt 0 && -f "$CONFIG_FILE" ]]; then
                    for i in "${!backups[@]}"; do
                        echo "  $((i+1))) $(basename "${backups[$i]}")"
                    done
                    read -rp "  Choice [1-${#backups[@]}]: " idx
                    if [[ $idx -ge 1 && $idx -le ${#backups[@]} ]]; then
                        local selected="${backups[$((idx-1))]}"
                        echo ""
                        echo -e "${CYAN}Differences:${NC}"
                        if command -v diff &> /dev/null; then
                            diff -u "$selected" "$CONFIG_FILE" || true
                        else
                            echo "diff command not available"
                        fi
                    fi
                else
                    echo -e "${YELLOW}Cannot compare - no backups or config file${NC}"
                fi
                read -rp "Press Enter to continue..."
                ;;
            4)
                echo -e "${CYAN}Exporting configuration to archive...${NC}"
                local timestamp=$(date '+%Y%m%d_%H%M%S')
                local archive_name="qwen_tam_config_${timestamp}.tar.gz"
                local archive_path="${CONFIG_BACKUP_DIR}/${archive_name}"
                
                if tar -czf "$archive_path" -C "$(dirname "$CONFIG_FILE")" "$(basename "$CONFIG_FILE")" 2>/dev/null; then
                    echo -e "${GREEN}✓ Archive created: $archive_path${NC}"
                    echo "  Size: $(stat -c%s "$archive_path" 2>/dev/null) bytes"
                else
                    echo -e "${RED}✗ Failed to create archive${NC}"
                fi
                read -rp "Press Enter to continue..."
                ;;
            5|*) break ;;
        esac
    done
}

# Menu przywracania konfiguracji
menu_restore_configuration() {
    load_config 2>/dev/null || true
    
    while true; do
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║              RESTORE CONFIGURATION                           ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║  Current Config: ${CONFIG_FILE}                  ║${NC}"
        echo -e "${GREEN}║  Backup Directory: ${CONFIG_BACKUP_DIR}             ║${NC}"
        echo ""
        
        # Lista backupów
        echo -e "${CYAN}  Available Backups:${NC}"
        if [[ -d "$CONFIG_BACKUP_DIR" ]]; then
            local count=0
            for backup in $(ls -t "$CONFIG_BACKUP_DIR"/config_*.bak 2>/dev/null | head -10); do
                local filename=$(basename "$backup")
                local date=$(stat -c%y "$backup" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
                echo -e "${GREEN}    $((count+1)). $filename ($date)${NC}"
                ((count++))
            done
            if [[ $count -eq 0 ]]; then
                echo -e "${YELLOW}    No backups found${NC}"
            fi
        fi
        
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║  [1] Restore from Backup                                     ║${NC}"
        echo -e "${GREEN}║  [2] Restore from Archive                                    ║${NC}"
        echo -e "${GREEN}║  [3] View Current Config                                     ║${NC}"
        echo -e "${YELLOW}║  [4] Back                                                    ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        read -rp "  Enter choice [1-4]: " choice
        case $choice in
            1)
                echo ""
                local backups=($(ls -t "$CONFIG_BACKUP_DIR"/config_*.bak 2>/dev/null))
                if [[ ${#backups[@]} -gt 0 ]]; then
                    echo -e "${CYAN}Select backup to restore:${NC}"
                    for i in "${!backups[@]}"; do
                        echo "  $((i+1))) $(basename "${backups[$i]}")"
                    done
                    read -rp "  Choice [1-${#backups[@]}]: " idx
                    
                    if [[ $idx -ge 1 && $idx -le ${#backups[@]} ]]; then
                        local selected="${backups[$((idx-1))]}"
                        echo ""
                        echo -e "${YELLOW}⚠ WARNING: This will overwrite current configuration!${NC}"
                        echo -e "${YELLOW}   Current config will be backed up automatically.${NC}"
                        echo ""
                        read -rp "   Are you sure? [y/N]: " confirm
                        
                        if [[ "$confirm" =~ ^[Yy]$ ]]; then
                            if restore_config_backup "$selected"; then
                                echo -e "${GREEN}✓ Configuration restored successfully${NC}"
                                log_config_event "Configuration restored from: $selected"
                            else
                                echo -e "${RED}✗ Failed to restore configuration${NC}"
                            fi
                        else
                            echo "Cancelled."
                        fi
                    fi
                else
                    echo -e "${YELLOW}No backups available${NC}"
                fi
                read -rp "Press Enter to continue..."
                ;;
            2)
                echo ""
                echo -e "${CYAN}Enter path to archive (.tar.gz):${NC}"
                read -rp "  Archive path: " archive_path
                
                if [[ -f "$archive_path" ]]; then
                    echo -e "${YELLOW}Extracting archive...${NC}"
                    local temp_dir=$(mktemp -d)
                    
                    if tar -xzf "$archive_path" -C "$temp_dir" 2>/dev/null; then
                        local extracted_config=$(find "$temp_dir" -name "*.config" -o -name "*qwen*config*" 2>/dev/null | head -1)
                        
                        if [[ -n "$extracted_config" && -f "$extracted_config" ]]; then
                            echo -e "${YELLOW}Found config file: $(basename "$extracted_config")${NC}"
                            echo ""
                            read -rp "Restore this configuration? [y/N]: " confirm
                            
                            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                                if restore_config_backup "$extracted_config"; then
                                    echo -e "${GREEN}✓ Configuration restored from archive${NC}"
                                fi
                            fi
                        else
                            echo -e "${RED}No valid configuration file found in archive${NC}"
                        fi
                    else
                        echo -e "${RED}Failed to extract archive${NC}"
                    fi
                    
                    rm -rf "$temp_dir"
                else
                    echo -e "${RED}Archive not found: $archive_path${NC}"
                fi
                read -rp "Press Enter to continue..."
                ;;
            3)
                echo ""
                echo -e "${CYAN}Current Configuration:${NC}"
                echo "────────────────────────────────────────"
                if [[ -f "$CONFIG_FILE" ]]; then
                    cat "$CONFIG_FILE"
                else
                    echo -e "${YELLOW}No configuration file found${NC}"
                fi
                echo "────────────────────────────────────────"
                read -rp "Press Enter to continue..."
                ;;
            4|*) break ;;
        esac
    done
}

# Menu resetowania do ustawień domyślnych
menu_reset_defaults() {
    load_config 2>/dev/null || true
    
    while true; do
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║              RESET TO DEFAULTS                               ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${RED}║  ⚠ WARNING: This will reset all settings to defaults!          ║${NC}"
        echo -e "${RED}║  Your current configuration will be lost (backup created).     ║${NC}"
        echo ""
        echo -e "${GREEN}║  Current Config File: ${CONFIG_FILE}            ║${NC}"
        echo -e "${GREEN}║  Config Size: $(stat -c%s "$CONFIG_FILE" 2>/dev/null || echo "N/A") bytes                    ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║  [1] Full Reset (All Settings)                               ║${NC}"
        echo -e "${GREEN}║  [2] Reset GitHub Settings Only                              ║${NC}"
        echo -e "${GREEN}║  [3] Reset API Settings Only                                 ║${NC}"
        echo -e "${GREEN}║  [4] Reset UI Settings Only                                  ║${NC}"
        echo -e "${YELLOW}║  [5] Back                                                    ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        read -rp "  Enter choice [1-5]: " choice
        case $choice in
            1)
                echo ""
                echo -e "${RED}⚠ FULL RESET WARNING:${NC}"
                echo "  This will delete ALL your settings including:"
                echo "  - GitHub token and credentials"
                echo "  - API endpoints and model settings"
                echo "  - Working directory paths"
                echo "  - Theme and display preferences"
                echo "  - Notification settings"
                echo ""
                read -rp "  Type 'RESET' to confirm: " confirm
                
                if [[ "$confirm" == "RESET" ]]; then
                    # Backup obecnej konfiguracji
                    create_config_backup "pre_full_reset"
                    
                    # Usuń obecną konfigurację
                    rm -f "$CONFIG_FILE"
                    
                    # Utwórz nową domyślną
                    create_default_config
                    
                    echo -e "${GREEN}✓ Full reset completed${NC}"
                    echo -e "${YELLOW}  Please restart the application${NC}"
                    log_config_event "Full configuration reset performed"
                else
                    echo "Reset cancelled."
                fi
                read -rp "Press Enter to continue..."
                ;;
            2)
                echo ""
                echo -e "${CYAN}Resetting GitHub settings...${NC}"
                create_config_backup "pre_github_reset"
                save_config_value "GITHUB_TOKEN" ""
                save_config_value "GITHUB_USERNAME" ""
                save_config_value "GITHUB_EMAIL" ""
                echo -e "${GREEN}✓ GitHub settings reset${NC}"
                read -rp "Press Enter to continue..."
                ;;
            3)
                echo ""
                echo -e "${CYAN}Resetting API settings...${NC}"
                create_config_backup "pre_api_reset"
                save_config_value "QWEN_API_ENDPOINT" "$DEFAULT_QWEN_API_ENDPOINT"
                save_config_value "QWEN_MODEL_CODER" "qwen-coder"
                save_config_value "QWEN_MODEL_AGENT" "qwen-agent"
                save_config_value "QWEN_API_TIMEOUT" "120"
                save_config_value "QWEN_API_MAX_TOKENS" "4096"
                echo -e "${GREEN}✓ API settings reset${NC}"
                read -rp "Press Enter to continue..."
                ;;
            4)
                echo ""
                echo -e "${CYAN}Resetting UI settings...${NC}"
                create_config_backup "pre_ui_reset"
                save_config_value "THEME" "$DEFAULT_THEME"
                save_config_value "DISPLAY_MODE" "$DEFAULT_DISPLAY_MODE"
                save_config_value "COLOR_ENABLED" "true"
                save_config_value "ASCII_ART_ENABLED" "true"
                echo -e "${GREEN}✓ UI settings reset${NC}"
                read -rp "Press Enter to continue..."
                ;;
            5|*) break ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# Główna funkcja menu
#-------------------------------------------------------------------------------

config_menu() {
    # Inicjalizacja
    init_config_environment
    load_config 2>/dev/null || true
    
    log_config_event "Configuration menu started"
    
    while true; do
        show_config_menu
        read -rp "  Enter choice [5.1-5.9 or 1-9]: " choice
        
        # Obsługa formatów 5.x oraz x
        case $choice in
            5.1|1) menu_manage_github_token ;;
            5.2|2) menu_configure_qwen_api ;;
            5.3|3) menu_set_working_directory ;;
            5.4|4) menu_theme_display ;;
            5.5|5) menu_notification_settings ;;
            5.6|6) menu_backup_configuration ;;
            5.7|7) menu_restore_configuration ;;
            5.8|8) menu_reset_defaults ;;
            5.9|9|99) 
                log_config_event "Configuration menu exited"
                break
                ;;
            *) 
                echo -e "${RED}Invalid option!${NC}"
                sleep 1
                ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# Obsługa wywołania jako skrypt standalone
#-------------------------------------------------------------------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Skrypt uruchomiony bezpośrednio
    case "${1:-menu}" in
        menu)
            config_menu
            ;;
        backup)
            init_config_environment
            create_config_backup "cli"
            ;;
        restore)
            init_config_environment
            if [[ -n "${2:-}" ]]; then
                restore_config_backup "$2"
            else
                echo "Usage: $0 restore <backup_file>"
                exit 1
            fi
            ;;
        reset)
            init_config_environment
            create_default_config
            echo "Configuration reset to defaults"
            ;;
        show)
            load_config || exit 1
            echo "Current Configuration:"
            echo "======================"
            env | grep -E "^(GITHUB_|QWEN_|WORKING_|PROJECTS_|BACKUPS_|TEMP_|THEME_|DISPLAY_|COLOR_|ASCII_|NOTIFICATION|NOTIFY_|AUTO_UPDATE|UPDATE_|MAINTENANCE)" | sort
            ;;
        *)
            echo "Qwen TAM Configuration Module"
            echo ""
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  menu      Show interactive configuration menu (default)"
            echo "  backup    Create configuration backup"
            echo "  restore   Restore from backup file"
            echo "  reset     Reset to default configuration"
            echo "  show      Display current configuration"
            echo ""
            ;;
    esac
fi
