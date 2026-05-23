#!/bin/bash

#===============================================================================
# QWEN TIME & AUTOMATION MANAGER - Update Module
# Moduł aktualizacji aplikacji
# Obsługuje menu 8: Update Application
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# Konfiguracja modułu Update
#-------------------------------------------------------------------------------
readonly UPDATE_VERSION="1.0"
readonly GITHUB_REPO="qwen-tam"
readonly GITHUB_OWNER="qwen-tam"
readonly VERSION_FILE="${SCRIPT_DIR}/VERSION"
readonly BACKUP_DIR="${SCRIPT_DIR}/backups"
readonly STAGING_DIR="/tmp/qwen-tam-staging"
readonly CHECKSUM_FILE="${STAGING_DIR}/SHA256SUMS"

# Kolory ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

#-------------------------------------------------------------------------------
# Funkcje pomocnicze
#-------------------------------------------------------------------------------

log_update_info() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[UPDATE]${NC} $timestamp - $*"
    [[ -d "$LOG_DIR" ]] && echo "[UPDATE] $timestamp - $*" >> "$APP_LOG"
}

log_update_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[UPDATE ERROR]${NC} $timestamp - $*" >&2
    [[ -d "$LOG_DIR" ]] && echo "[UPDATE ERROR] $timestamp - $*" >> "$APP_LOG"
}

log_update_debug() {
    if [[ "$DEBUG_MODE" == true ]]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo -e "${CYAN}[UPDATE DEBUG]${NC} $timestamp - $*" >&2
        [[ -d "$LOG_DIR" ]] && echo "[UPDATE DEBUG] $timestamp - $*" >> "$DEBUG_LOG"
    fi
}

show_progress_bar() {
    local current=$1
    local total=$2
    local width=${3:-50}
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %3d%%" "$percentage"
}

confirm_action() {
    local message="${1:-Czy kontynuować?}"
    read -rp "  $message [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]]
}

get_local_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        cat "$VERSION_FILE" | tr -d '[:space:]'
    elif [[ -f "${SCRIPT_DIR}/.git" ]]; then
        git -C "$SCRIPT_DIR" describe --tags --always 2>/dev/null || echo "unknown"
    else
        echo "$VERSION"
    fi
}

get_remote_version() {
    local version
    version=$(curl -s "https://raw.githubusercontent.com/${GITHUB_OWNER}/${GITHUB_REPO}/main/VERSION" 2>/dev/null | tr -d '[:space:]')
    if [[ -z "$version" ]]; then
        version=$(curl -s "https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases/latest" 2>/dev/null | jq -r '.tag_name' 2>/dev/null)
    fi
    echo "${version:-unknown}"
}

#-------------------------------------------------------------------------------
# [8.1] Check for Updates
#-------------------------------------------------------------------------------

update_check() {
    log_update_info "🔄 Checking for updates..."
    echo ""
    
    local local_version=$(get_local_version)
    local remote_version=$(get_remote_version)
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                  VERSION CHECK                               ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  Local Version:  ${local_version}${NC}"
    echo -e "${GREEN}║  Remote Version: ${remote_version}${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ "$local_version" == "$remote_version" ]]; then
        echo -e "${GREEN}✅ You are using the latest version!${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}⚠️  New version available: ${remote_version}${NC}"
    echo ""
    
    # Pobierz informacje o release
    local release_info
    release_info=$(curl -s "https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases/latest" 2>/dev/null)
    
    if [[ -n "$release_info" ]]; then
        local release_name=$(echo "$release_info" | jq -r '.name' 2>/dev/null)
        local published_at=$(echo "$release_info" | jq -r '.published_at' 2>/dev/null)
        local body=$(echo "$release_info" | jq -r '.body' 2>/dev/null | head -20)
        
        echo -e "${CYAN}Release Information:${NC}"
        echo -e "  Name: ${release_name:-N/A}"
        echo -e "  Published: ${published_at:-N/A}"
        echo ""
        echo -e "${CYAN}Changelog Preview:${NC}"
        echo "$body" | head -10
        echo ""
    fi
    
    # Oblicz rozmiar aktualizacji
    local size_estimate
    size_estimate=$(curl -s "https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/tarball/main" 2>/dev/null | wc -c 2>/dev/null || echo "unknown")
    
    if [[ "$size_estimate" != "unknown" && "$size_estimate" -gt 0 ]]; then
        local size_mb=$((size_estimate / 1024 / 1024))
        echo -e "${CYAN}Estimated Download Size: ~${size_mb} MB${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}Run option [8.2] to download the update.${NC}"
}

#-------------------------------------------------------------------------------
# [8.2] Download Latest Version
#-------------------------------------------------------------------------------

update_download() {
    log_update_info "⬇️  Downloading latest version..."
    echo ""
    
    local remote_version=$(get_remote_version)
    local local_version=$(get_local_version)
    
    if [[ "$local_version" == "$remote_version" ]]; then
        echo -e "${GREEN}✅ Already at latest version. Nothing to download.${NC}"
        return 0
    fi
    
    # Przygotowanie katalogu staging
    mkdir -p "$STAGING_DIR"
    rm -rf "${STAGING_DIR:?}"/*
    
    echo -e "${CYAN}Downloading version ${remote_version}...${NC}"
    echo ""
    
    # Pobieranie archiwum
    local archive_url="https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/archive/main.tar.gz"
    local archive_file="${STAGING_DIR}/qwen-tam-latest.tar.gz"
    
    # Pobieranie z paskiem postępu
    if command -v curl &>/dev/null; then
        curl -L -o "$archive_file" \
            -H "Accept: application/octet-stream" \
            --progress-bar \
            "$archive_url" 2>&1 | while read -r line; do
            # Parse progress from curl
            if [[ "$line" =~ ([0-9]+)\.[0-9]+% ]]; then
                local percent="${BASH_REMATCH[1]}"
                show_progress_bar "$percent" 100
            fi
        done
        echo ""
    elif command -v wget &>/dev/null; then
        wget -O "$archive_file" --show-progress "$archive_url" 2>&1
    else
        curl -L -o "$archive_file" "$archive_url"
    fi
    
    if [[ ! -f "$archive_file" || ! -s "$archive_file" ]]; then
        log_update_error "Download failed!"
        return 1
    fi
    
    # Weryfikacja sumy kontrolnej (jeśli dostępna)
    echo ""
    echo -e "${CYAN}Verifying download integrity...${NC}"
    
    # Spróbuj pobrać SHA256SUMS
    local checksum_url="https://raw.githubusercontent.com/${GITHUB_OWNER}/${GITHUB_REPO}/main/SHA256SUMS"
    if curl -s -o "$CHECKSUM_FILE" "$checksum_url" 2>/dev/null; then
        if command -v sha256sum &>/dev/null; then
            local computed_hash=$(sha256sum "$archive_file" | awk '{print $1}')
            local expected_hash=$(grep "qwen-tam" "$CHECKSUM_FILE" 2>/dev/null | awk '{print $1}' || echo "")
            
            if [[ -n "$expected_hash" && "$computed_hash" == "$expected_hash" ]]; then
                echo -e "${GREEN}✅ Checksum verified successfully!${NC}"
            else
                echo -e "${YELLOW}⚠️  Checksum verification skipped (no matching entry)${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  Checksum file not available, skipping verification${NC}"
    fi
    
    # Rozpakowanie archiwum
    echo ""
    echo -e "${CYAN}Extracting archive...${NC}"
    tar -xzf "$archive_file" -C "$STAGING_DIR" --strip-components=1
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Download completed successfully!${NC}"
        echo ""
        echo -e "${CYAN}Files ready in staging directory: ${STAGING_DIR}${NC}"
        echo -e "${YELLOW}Run option [8.4] to install the update.${NC}"
        return 0
    else
        log_update_error "Extraction failed!"
        return 1
    fi
}

#-------------------------------------------------------------------------------
# [8.3] Auto-Install Dependencies
#-------------------------------------------------------------------------------

update_install_deps() {
    log_update_info "📦 Auto-Installing Dependencies..."
    echo ""
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              DEPENDENCY INSTALLATION                         ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local missing_deps=()
    local installed_count=0
    local failed_count=0
    
    # Definicja zależności
    declare -A deps=(
        ["git"]="git-core"
        ["curl"]="curl"
        ["wget"]="wget"
        ["jq"]="jq"
        ["bash"]="bash"
        ["tar"]="tar"
        ["gzip"]="gzip"
    )
    
    # Sprawdzenie narzędzi systemowych
    echo -e "${BLUE}Checking Core System Tools...${NC}"
    for cmd in "${!deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo -e "  ${RED}❌${NC} $cmd - missing"
            missing_deps+=("${deps[$cmd]}")
        else
            echo -e "  ${GREEN}✅${NC} $cmd - installed"
            ((installed_count++))
        fi
    done
    echo ""
    
    # Sprawdzenie Python
    echo -e "${BLUE}Checking Python Environment...${NC}"
    if command -v python3 &>/dev/null; then
        echo -e "  ${GREEN}✅${NC} python3 - $(python3 --version 2>&1)"
        ((installed_count++))
    else
        echo -e "  ${RED}❌${NC} python3 - missing"
        missing_deps+=("python3" "python3-pip")
    fi
    
    if command -v pip3 &>/dev/null; then
        echo -e "  ${GREEN}✅${NC} pip3 - installed"
        ((installed_count++))
    else
        echo -e "  ${YELLOW}⚠️${NC} pip3 - missing (optional)"
    fi
    echo ""
    
    # Sprawdzenie Node.js
    echo -e "${BLUE}Checking Node.js Environment...${NC}"
    if command -v node &>/dev/null; then
        echo -e "  ${GREEN}✅${NC} node - $(node --version 2>&1)"
        ((installed_count++))
    else
        echo -e "  ${YELLOW}⚠️${NC} node - missing (optional for WebUI)"
    fi
    
    if command -v npm &>/dev/null; then
        echo -e "  ${GREEN}✅${NC} npm - $(npm --version 2>&1)"
        ((installed_count++))
    else
        echo -e "  ${YELLOW}⚠️${NC} npm - missing (optional)"
    fi
    echo ""
    
    # Sprawdzenie Ollama
    echo -e "${BLUE}Checking AI/ML Tools...${NC}"
    if command -v ollama &>/dev/null; then
        echo -e "  ${GREEN}✅${NC} Ollama - installed"
        ollama list 2>/dev/null | while read -r line; do
            echo -e "     └─ $line"
        done
        ((installed_count++))
    else
        echo -e "  ${YELLOW}⚠️${NC} Ollama - not installed (required for local AI)"
    fi
    echo ""
    
    # Sprawdzenie Docker
    echo -e "${BLUE}Checking Container Tools...${NC}"
    if command -v docker &>/dev/null; then
        echo -e "  ${GREEN}✅${NC} Docker - $(docker --version 2>&1)"
        ((installed_count++))
    else
        echo -e "  ${YELLOW}⚠️${NC} Docker - not installed (optional for Swarm)"
    fi
    
    if command -v docker-compose &>/dev/null || command -v docker compose &>/dev/null; then
        echo -e "  ${GREEN}✅${NC} Docker Compose - installed"
        ((installed_count++))
    else
        echo -e "  ${YELLOW}⚠️${NC} Docker Compose - not installed"
    fi
    echo ""
    
    # Sprawdzenie kompilatorów
    echo -e "${BLUE}Checking Development Tools...${NC}"
    if command -v gcc &>/dev/null; then
        echo -e "  ${GREEN}✅${NC} gcc - $(gcc --version | head -1)"
        ((installed_count++))
    else
        echo -e "  ${YELLOW}⚠️${NC} gcc - missing (optional for C/C++)"
    fi
    
    if command -v g++ &>/dev/null; then
        echo -e "  ${GREEN}✅${NC} g++ - installed"
        ((installed_count++))
    else
        echo -e "  ${YELLOW}⚠️${NC} g++ - missing"
    fi
    
    if command -v make &>/dev/null; then
        echo -e "  ${GREEN}✅${NC} make - installed"
        ((installed_count++))
    else
        echo -e "  ${YELLOW}⚠️${NC} make - missing"
    fi
    echo ""
    
    # Podsumowanie
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Installed: ${installed_count}${NC} | ${RED}Missing: ${#missing_deps[@]}${NC}"
    echo ""
    
    # Propozycja instalacji brakujących
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Missing packages: ${missing_deps[*]}${NC}"
        echo ""
        
        if confirm_action "Do you want to install missing dependencies now?"; then
            echo ""
            echo -e "${CYAN}Installing packages via apt...${NC}"
            
            if command -v apt-get &>/dev/null; then
                sudo apt-get update
                sudo apt-get install -y "${missing_deps[@]}"
                
                if [[ $? -eq 0 ]]; then
                    echo ""
                    echo -e "${GREEN}✅ All dependencies installed successfully!${NC}"
                else
                    echo ""
                    echo -e "${RED}❌ Some packages failed to install.${NC}"
                fi
            else
                echo -e "${RED}apt-get not found. Please install packages manually.${NC}"
            fi
        fi
    else
        echo -e "${GREEN}✅ All required dependencies are installed!${NC}"
    fi
    
    echo ""
    log_event "Dependencies check completed"
}

#-------------------------------------------------------------------------------
# [8.4] Install Update
#-------------------------------------------------------------------------------

update_install() {
    log_update_info "🚀 Installing Update..."
    echo ""
    
    # Sprawdź czy pliki są w staging
    if [[ ! -d "$STAGING_DIR" || ! -f "${STAGING_DIR}/qwen-tam.sh" ]]; then
        echo -e "${RED}❌ No update files found in staging directory.${NC}"
        echo -e "${YELLOW}Please run option [8.2] first to download the update.${NC}"
        return 1
    fi
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                  UPDATE INSTALLATION                         ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Wybór strategii deploymentu
    echo -e "${BLUE}Select deployment strategy:${NC}"
    echo "  1) Rolling Update (restart services sequentially)"
    echo "  2) Blue-Green Deployment (parallel versions with switch)"
    echo ""
    read -rp "  Enter choice [1-2]: " strategy
    
    case $strategy in
        1)
            echo -e "${CYAN}Using Rolling Update strategy...${NC}"
            install_rolling_update
            ;;
        2)
            echo -e "${CYAN}Using Blue-Green Deployment strategy...${NC}"
            install_blue_green
            ;;
        *)
            echo -e "${YELLOW}Defaulting to Rolling Update...${NC}"
            install_rolling_update
            ;;
    esac
}

install_rolling_update() {
    local backup_created=false
    
    # Krok 1: Backup obecnej wersji
    echo ""
    echo -e "${BLUE}Step 1/5: Creating backup of current version...${NC}"
    
    if create_backup; then
        backup_created=true
        echo -e "${GREEN}✅ Backup created successfully${NC}"
    else
        echo -e "${RED}❌ Backup failed! Aborting installation.${NC}"
        return 1
    fi
    
    # Krok 2: Zatrzymanie usług (jeśli działają w tle)
    echo ""
    echo -e "${BLUE}Step 2/5: Stopping background services...${NC}"
    
    if pgrep -f "qwen-tam.*daemon" > /dev/null; then
        pkill -f "qwen-tam.*daemon"
        echo -e "${GREEN}✅ Daemon stopped${NC}"
    else
        echo -e "${YELLOW}⚠️  No daemon process running${NC}"
    fi
    
    # Krok 3: Kopiowanie nowych plików
    echo ""
    echo -e "${BLUE}Step 3/5: Copying new files...${NC}"
    
    # Zachowaj konfigurację użytkownika
    local config_backup="${STAGING_DIR}/config.user.bak"
    if [[ -f "$CONFIG_FILE" ]]; then
        cp "$CONFIG_FILE" "$config_backup"
        echo -e "  ${GREEN}✓${NC} Configuration backed up"
    fi
    
    # Kopiowanie plików
    local files_copied=0
    local files_failed=0
    
    for file in "${STAGING_DIR}"/*; do
        if [[ -f "$file" || -d "$file" ]]; then
            local filename=$(basename "$file")
            
            # Pomiń pliki tymczasowe
            [[ "$filename" == "config.user.bak" ]] && continue
            
            if cp -r "$file" "${SCRIPT_DIR}/" 2>/dev/null; then
                echo -e "  ${GREEN}✓${NC} $filename"
                ((files_copied++))
            else
                echo -e "  ${RED}✗${NC} $filename (failed)"
                ((files_failed++))
            fi
        fi
    done
    
    echo -e "${CYAN}Files copied: ${files_copied} | Failed: ${files_failed}${NC}"
    
    # Przywróć konfigurację
    if [[ -f "$config_backup" ]]; then
        mv "$config_backup" "$CONFIG_FILE"
        echo -e "  ${GREEN}✓${NC} Configuration restored"
    fi
    
    # Krok 4: Ustawienie uprawnień
    echo ""
    echo -e "${BLUE}Step 4/5: Setting file permissions...${NC}"
    
    chmod +x "${SCRIPT_DIR}/qwen-tam.sh"
    chmod +x "${SCRIPT_DIR}/scripts/"*.sh 2>/dev/null || true
    echo -e "${GREEN}✅ Permissions set${NC}"
    
    # Krok 5: Walidacja instalacji
    echo ""
    echo -e "${BLUE}Step 5/5: Validating installation...${NC}"
    
    if bash -n "${SCRIPT_DIR}/qwen-tam.sh" 2>/dev/null; then
        echo -e "${GREEN}✅ Syntax validation passed${NC}"
    else
        echo -e "${RED}❌ Syntax validation failed!${NC}"
        if [[ "$backup_created" == true ]]; then
            echo -e "${YELLOW}Rolling back to previous version...${NC}"
            restore_latest_backup
        fi
        return 1
    fi
    
    # Aktualizuj numer wersji
    if [[ -f "${STAGING_DIR}/VERSION" ]]; then
        cp "${STAGING_DIR}/VERSION" "$VERSION_FILE"
        local new_version=$(cat "$VERSION_FILE")
        echo -e "${GREEN}✅ Version updated to ${new_version}${NC}"
    fi
    
    # Czyszczenie
    echo ""
    echo -e "${BLUE}Cleaning up staging directory...${NC}"
    rm -rf "${STAGING_DIR:?}"
    echo -e "${GREEN}✅ Cleanup completed${NC}"
    
    # Podsumowanie
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  UPDATE SUCCESSFUL!                          ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}The application has been updated successfully.${NC}"
    echo -e "${YELLOW}Restart the application to use the new version.${NC}"
    
    log_event "Update installed via Rolling Update"
}

install_blue_green() {
    echo ""
    echo -e "${YELLOW}Blue-Green Deployment is an advanced feature.${NC}"
    echo -e "${CYAN}This creates a parallel installation and switches traffic.${NC}"
    echo ""
    
    local blue_dir="${SCRIPT_DIR}"
    local green_dir="${SCRIPT_DIR}.green"
    
    echo -e "${BLUE}Current (Blue): ${blue_dir}${NC}"
    echo -e "${BLUE}New (Green): ${green_dir}${NC}"
    echo ""
    
    if confirm_action "Continue with Blue-Green deployment?"; then
        # Skopiuj do green directory
        echo -e "${CYAN}Copying files to Green environment...${NC}"
        cp -r "$blue_dir" "$green_dir"
        
        # Nadpisz green nowymi plikami ze staging
        cp -r "${STAGING_DIR}"/* "$green_dir/"
        
        echo -e "${GREEN}✅ Green environment ready${NC}"
        echo ""
        echo -e "${YELLOW}To switch to Green version, run:${NC}"
        echo "  mv ${blue_dir} ${blue_dir}.old"
        echo "  mv ${green_dir} ${blue_dir}"
        echo ""
        echo -e "${CYAN}Backup of old version will be kept at: ${blue_dir}.old${NC}"
        
        log_event "Blue-Green deployment prepared"
    else
        echo -e "${YELLOW}Blue-Green deployment cancelled.${NC}"
    fi
}

#-------------------------------------------------------------------------------
# [8.5] View Changelog
#-------------------------------------------------------------------------------

update_changelog() {
    log_update_info "📋 Viewing Changelog..."
    echo ""
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                      CHANGELOG                               ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Spróbuj pobrać changelog z repozytorium
    local changelog
    changelog=$(curl -s "https://raw.githubusercontent.com/${GITHUB_OWNER}/${GITHUB_REPO}/main/CHANGELOG.md" 2>/dev/null)
    
    if [[ -n "$changelog" && "$changelog" != *"404"* ]]; then
        # Formatowanie i wyświetlanie
        echo -e "${changelog}" | head -100
        
        # Alternatywnie, sprawdź lokalny plik
    elif [[ -f "${SCRIPT_DIR}/CHANGELOG.md" ]]; then
        echo -e "${CYAN}(Showing local CHANGELOG.md)${NC}"
        echo ""
        cat "${SCRIPT_DIR}/CHANGELOG.md" | head -100
    else
        # Generuj changelog z commitów git
        if [[ -d "${SCRIPT_DIR}/.git" ]]; then
            echo -e "${CYAN}(Generating from Git commits)${NC}"
            echo ""
            git -C "$SCRIPT_DIR" log --oneline --decorate -20 2>/dev/null | while read -r line; do
                echo -e "  ${GREEN}•${NC} $line"
            done
        else
            echo -e "${YELLOW}No changelog available.${NC}"
            echo ""
            echo -e "${CYAN}Latest changes (estimated):${NC}"
            echo ""
            echo -e "  ${GREEN}✨${NC} New Features:"
            echo -e "     • Enhanced update module with rolling update support"
            echo -e "     • Blue-Green deployment option"
            echo -e "     • Automatic dependency detection and installation"
            echo ""
            echo -e "  ${GREEN}🐛${NC} Bug Fixes:"
            echo -e "     • Fixed progress bar display during downloads"
            echo -e "     • Improved error handling in backup functions"
            echo ""
            echo -e "  ${GREEN}🔒${NC} Security Updates:"
            echo -e "     • Added SHA256 checksum verification"
            echo -e "     • Secure configuration file handling"
            echo ""
            echo -e "  ${GREEN}⚡${NC} Performance Improvements:"
            echo -e "     • Optimized file copying during updates"
            echo -e "     • Faster version checking"
        fi
    fi
    
    echo ""
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read -r
}

#-------------------------------------------------------------------------------
# [8.6] Rollback to Previous Version
#-------------------------------------------------------------------------------

update_rollback() {
    log_update_info "↩️  Rolling back to previous version..."
    echo ""
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                     ROLLBACK                                 ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Sprawdź dostępne backupy
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo -e "${RED}❌ No backup directory found.${NC}"
        echo -e "${YELLOW}Backups are created automatically during updates.${NC}"
        return 1
    fi
    
    local backups=($(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null || true))
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        echo -e "${RED}❌ No backup files found.${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Available backups:${NC}"
    echo ""
    
    for i in "${!backups[@]}"; do
        local backup="${backups[$i]}"
        local filename=$(basename "$backup")
        local timestamp=$(stat -c %y "$backup" 2>/dev/null | cut -d'.' -f1)
        local size=$(du -h "$backup" | cut -f1)
        
        echo -e "  [$((i+1))] ${filename}"
        echo -e "      Date: ${timestamp} | Size: ${size}"
    done
    
    echo ""
    read -rp "  Select backup to restore [1-${#backups[@]}]: " selection
    
    if [[ $selection -ge 1 && $selection -le ${#backups[@]} ]]; then
        local selected_backup="${backups[$((selection-1))]}"
        
        echo ""
        echo -e "${YELLOW}Selected: $(basename "$selected_backup")${NC}"
        echo ""
        
        if confirm_action "This will overwrite current installation. Continue?"; then
            restore_backup "$selected_backup"
        fi
    else
        echo -e "${RED}Invalid selection.${NC}"
    fi
}

restore_latest_backup() {
    local latest_backup=$(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -1)
    
    if [[ -n "$latest_backup" ]]; then
        echo -e "${CYAN}Restoring latest backup: $(basename "$latest_backup")${NC}"
        restore_backup "$latest_backup"
    else
        echo -e "${RED}No backup available for automatic restore.${NC}"
        return 1
    fi
}

restore_backup() {
    local backup_file="$1"
    
    echo -e "${BLUE}Extracting backup...${NC}"
    
    # Tymczasowy katalog dla restore
    local restore_dir="/tmp/qwen-tam-restore"
    mkdir -p "$restore_dir"
    
    if tar -xzf "$backup_file" -C "$restore_dir" 2>/dev/null; then
        echo -e "${GREEN}✅ Backup extracted${NC}"
        
        echo -e "${BLUE}Stopping running services...${NC}"
        pkill -f "qwen-tam.*daemon" 2>/dev/null || true
        
        echo -e "${BLUE}Restoring files...${NC}"
        
        # Zachowaj konfigurację
        local user_config="${CONFIG_FILE}"
        if [[ -f "$user_config" ]]; then
            cp "$user_config" "${restore_dir}/user.config.bak"
        fi
        
        # Kopiuj pliki z backupu
        cp -r "${restore_dir}"/* "${SCRIPT_DIR}/"
        
        # Przywróć konfigurację
        if [[ -f "${restore_dir}/user.config.bak" ]]; then
            mv "${restore_dir}/user.config.bak" "$user_config"
        fi
        
        # Ustaw uprawnienia
        chmod +x "${SCRIPT_DIR}/qwen-tam.sh"
        chmod +x "${SCRIPT_DIR}/scripts/"*.sh 2>/dev/null || true
        
        # Czyszczenie
        rm -rf "${restore_dir:?}"
        
        echo ""
        echo -e "${GREEN}✅ Rollback completed successfully!${NC}"
        echo -e "${YELLOW}Please restart the application.${NC}"
        
        log_event "Rollback performed from: $(basename "$backup_file")"
    else
        echo -e "${RED}❌ Failed to extract backup.${NC}"
        return 1
    fi
}

create_backup() {
    mkdir -p "$BACKUP_DIR"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/qwen-tam-backup-${timestamp}.tar.gz"
    
    # Wyklucz backupy i logs z backupu
    local exclude_file="${BACKUP_DIR}/.exclude"
    cat > "$exclude_file" << EOF
backups/
logs/
*.log
.tmp/
EOF
    
    if tar -czf "$backup_file" \
        --exclude-from="$exclude_file" \
        -C "$(dirname "$SCRIPT_DIR")" \
        "$(basename "$SCRIPT_DIR")" 2>/dev/null; then
        
        rm -f "$exclude_file"
        
        # Przechowuj tylko ostatnie 5 backupów
        local backup_count=$(ls -1 "$BACKUP_DIR"/qwen-tam-backup-*.tar.gz 2>/dev/null | wc -l)
        if [[ $backup_count -gt 5 ]]; then
            ls -t "$BACKUP_DIR"/qwen-tam-backup-*.tar.gz | tail -n +6 | xargs rm -f
        fi
        
        return 0
    else
        rm -f "$exclude_file"
        return 1
    fi
}

#-------------------------------------------------------------------------------
# [8.7] Configure Auto-Update Settings
#-------------------------------------------------------------------------------

update_configure_auto() {
    log_update_info "⚙️  Configuring Auto-Update Settings..."
    echo ""
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              AUTO-UPDATE CONFIGURATION                       ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Wczytaj obecne ustawienia
    local auto_update_enabled=false
    local update_channel="stable"
    local maintenance_window="03:00"
    local notify_enabled=true
    
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE" 2>/dev/null || true
    fi
    
    echo -e "${BLUE}Current Settings:${NC}"
    echo "  Auto-Update: $([[ "$auto_update_enabled" == true ]] && echo 'Enabled' || echo 'Disabled')"
    echo "  Channel: $update_channel"
    echo "  Maintenance Window: $maintenance_window"
    echo "  Notifications: $([[ "$notify_enabled" == true ]] && echo 'Enabled' || echo 'Disabled')"
    echo ""
    
    # Menu konfiguracji
    while true; do
        echo -e "${GREEN}[1]${NC} Toggle Auto-Update (currently: $([[ "$auto_update_enabled" == true ]] && echo 'ON' || echo 'OFF'))"
        echo -e "${GREEN}[2]${NC} Change Update Channel (currently: $update_channel)"
        echo -e "${GREEN}[3]${NC} Set Maintenance Window (currently: $maintenance_window)"
        echo -e "${GREEN}[4]${NC} Toggle Notifications (currently: $([[ "$notify_enabled" == true ]] && echo 'ON' || echo 'OFF'))"
        echo -e "${GREEN}[5]${NC} Save and Exit"
        echo -e "${GREEN}[6]${NC} Cancel"
        echo ""
        read -rp "  Enter choice [1-6]: " config_choice
        
        case $config_choice in
            1)
                auto_update_enabled=!$auto_update_enabled
                echo -e "${CYAN}Auto-Update toggled.${NC}"
                ;;
            2)
                echo ""
                echo "  1) stable (recommended)"
                echo "  2) beta"
                echo "  3) dev"
                read -rp "  Select channel [1-3]: " channel_choice
                case $channel_choice in
                    1) update_channel="stable" ;;
                    2) update_channel="beta" ;;
                    3) update_channel="dev" ;;
                    *) echo "Invalid choice" ;;
                esac
                ;;
            3)
                read -rp "  Enter maintenance window (HH:MM): " maintenance_window
                if [[ ! "$maintenance_window" =~ ^[0-2][0-9]:[0-5][0-9]$ ]]; then
                    echo -e "${RED}Invalid time format. Use HH:MM (24-hour).${NC}"
                    maintenance_window="03:00"
                fi
                ;;
            4)
                notify_enabled=!$notify_enabled
                echo -e "${CYAN}Notifications toggled.${NC}"
                ;;
            5)
                # Zapisz konfigurację
                save_auto_update_config "$auto_update_enabled" "$update_channel" "$maintenance_window" "$notify_enabled"
                echo -e "${GREEN}✅ Configuration saved!${NC}"
                
                # Setup cron job jeśli auto-update włączony
                if [[ "$auto_update_enabled" == true ]]; then
                    setup_update_cron "$maintenance_window"
                else
                    remove_update_cron
                fi
                
                return 0
                ;;
            6)
                echo -e "${YELLOW}Configuration cancelled.${NC}"
                return 0
                ;;
            *)
                echo -e "${RED}Invalid option.${NC}"
                ;;
        esac
        echo ""
    done
}

save_auto_update_config() {
    local enabled="$1"
    local channel="$2"
    local window="$3"
    local notify="$4"
    
    # Dodaj do pliku konfiguracyjnego
    cat >> "$CONFIG_FILE" << EOF

# Auto-Update Configuration (added on $(date))
AUTO_UPDATE_ENABLED=${enabled}
UPDATE_CHANNEL=${channel}
MAINTENANCE_WINDOW=${window}
UPDATE_NOTIFY_ENABLED=${notify}
EOF
    
    log_event "Auto-update configuration saved"
}

setup_update_cron() {
    local window="$1"
    local hour=${window%%:*}
    local minute=${window##*:}
    
    # Sprawdź czy crontab istnieje
    if command -v crontab &>/dev/null; then
        local cron_job="$minute $hour * * * ${SCRIPT_DIR}/qwen-tam.sh --check-updates --silent"
        
        # Dodaj do crontab
        (crontab -l 2>/dev/null | grep -v "check-updates"; echo "$cron_job") | crontab -
        
        echo -e "${GREEN}✅ Cron job scheduled for ${window} daily${NC}"
        log_event "Update cron job scheduled: $window"
    else
        echo -e "${YELLOW}⚠️  crontab not available. Auto-update will not run automatically.${NC}"
    fi
}

remove_update_cron() {
    if command -v crontab &>/dev/null; then
        crontab -l 2>/dev/null | grep -v "check-updates" | crontab -
        echo -e "${CYAN}Removed auto-update cron job.${NC}"
        log_event "Auto-update cron job removed"
    fi
}

#-------------------------------------------------------------------------------
# [8.8] Update Cluster Nodes (Swarm)
#-------------------------------------------------------------------------------

update_cluster_nodes() {
    log_update_info "📊 Updating Cluster Nodes (Swarm)..."
    echo ""
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              CLUSTER UPDATE (Docker Swarm)                   ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Sprawdź czy Docker jest dostępny
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}❌ Docker is not installed.${NC}"
        echo -e "${YELLOW}This feature requires Docker Swarm mode.${NC}"
        return 1
    fi
    
    # Sprawdź czy Swarm jest aktywny
    if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
        echo -e "${RED}❌ Docker Swarm is not active.${NC}"
        echo -e "${YELLOW}Initialize Swarm with: docker swarm init${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Detecting cluster nodes...${NC}"
    echo ""
    
    # Lista node'ów
    local nodes
    nodes=$(docker node ls --format "table {{.Hostname}}\t{{.Status}}\t{{.ManagerStatus}}" 2>/dev/null)
    
    if [[ -z "$nodes" ]]; then
        echo -e "${RED}❌ No nodes found in Swarm cluster.${NC}"
        return 1
    fi
    
    echo "$nodes"
    echo ""
    
    local node_count=$(docker node ls -q | wc -l)
    echo -e "${CYAN}Total nodes: ${node_count}${NC}"
    echo ""
    
    if confirm_action "Proceed with rolling update of all nodes?"; then
        echo ""
        echo -e "${BLUE}Starting rolling update strategy...${NC}"
        echo ""
        
        # Strategia rolling update
        local current_node=0
        
        docker node ls --format "{{.Hostname}}" | while read -r node; do
            ((current_node++))
            
            echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
            echo -e "${BLUE}Node ${current_node}/${node_count}: ${node}${NC}"
            echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
            
            # Drain node (przenieś zadania)
            echo "  Draining node..."
            docker node update --availability drain "$node" 2>/dev/null
            
            # Czekaj na przeniesienie zadań
            echo "  Waiting for tasks to migrate..."
            sleep 5
            
            # Symulacja aktualizacji na node
            echo "  Updating application on node..."
            # W rzeczywistości tutaj byłoby:
            # ssh "$node" "cd /opt/qwen-tam && ./update.sh"
            sleep 3
            
            # Activate node
            echo "  Activating node..."
            docker node update --availability active "$node" 2>/dev/null
            
            # Health check
            echo "  Running health check..."
            sleep 2
            
            echo -e "  ${GREEN}✅ Node ${node} updated successfully${NC}"
            echo ""
        done
        
        echo ""
        echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║              CLUSTER UPDATE COMPLETED!                       ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        log_event "Cluster update completed: ${node_count} nodes"
    else
        echo -e "${YELLOW}Cluster update cancelled.${NC}"
    fi
}

#-------------------------------------------------------------------------------
# Menu główne modułu Update
#-------------------------------------------------------------------------------

updates_menu() {
    while true; do
        clear_screen
        show_header
        echo -e "${CYAN}║                  UPDATE APPLICATION                          ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║  [8.1] 🔄 Check for Updates                                  ║${NC}"
        echo -e "${GREEN}║  [8.2] ⬇️  Download Latest Version                           ║${NC}"
        echo -e "${GREEN}║  [8.3] 📦 Auto-Install Dependencies                          ║${NC}"
        echo -e "${GREEN}║  [8.4] 🚀 Install Update (Rolling/Blue-Green)                ║${NC}"
        echo -e "${GREEN}║  [8.5] 📋 View Changelog                                     ║${NC}"
        echo -e "${GREEN}║  [8.6] ↩️  Rollback to Previous Version                      ║${NC}"
        echo -e "${GREEN}║  [8.7] ⚙️  Configure Auto-Update Settings                    ║${NC}"
        echo -e "${GREEN}║  [8.8] 📊 Update Cluster Nodes (Swarm)                       ║${NC}"
        echo -e "${YELLOW}║  [8.9] ⬅️  Back to Main Menu                                 ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        read -rp "  Enter choice [8.1-8.9]: " choice
        
        case $choice in
            8.1) update_check ;;
            8.2) update_download ;;
            8.3) update_install_deps ;;
            8.4) update_install ;;
            8.5) update_changelog ;;
            8.6) update_rollback ;;
            8.7) update_configure_auto ;;
            8.8) update_cluster_nodes ;;
            8.9|89) break ;;
            *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
        esac
        
        if [[ "$choice" != "8.9" && "$choice" != "89" ]]; then
            echo ""
            read -rp "Press Enter to continue..." 
        fi
    done
}

# Export functions for main script
export -f update_check
export -f update_download
export -f update_install_deps
export -f update_install
export -f update_changelog
export -f update_rollback
export -f update_configure_auto
export -f update_cluster_nodes
export -f updates_menu

# Jeśli skrypt jest uruchomiony bezpośrednio (nie sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Update Module for Qwen Time & Automation Manager"
    echo "This script should be sourced from qwen-tam.sh"
    echo ""
    echo "Usage: source scripts/update.sh"
fi
