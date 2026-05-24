#!/bin/bash

#===============================================================================
# QWEN TIME & AUTOMATION MANAGER - INSTALACJA v1.0
# Skrypt instalacyjny dla Raspberry Pi 4 Edition
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# Konfiguracja i zmienne globalne
#-------------------------------------------------------------------------------
readonly VERSION="1.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly INSTALL_DIR="${HOME}/Apka"
readonly CONFIG_FILE="${HOME}/.apka_config"
readonly LOG_FILE="/tmp/apka-install.log"

# Kolory ANSI
[[ -z "${RED:-}" ]] && RED=$'\033[0;31m'
[[ -z "${GREEN:-}" ]] && GREEN=$'\033[0;32m'
[[ -z "${YELLOW:-}" ]] && YELLOW=$'\033[1;33m'
[[ -z "${BLUE:-}" ]] && BLUE=$'\033[0;34m'
[[ -z "${CYAN:-}" ]] && CYAN=$'\033[0;36m'
[[ -z "${NC:-}" ]] && NC=$'\033[0m' # No Color

# Tryby pracy
VERBOSE_MODE=false
FORCE_MODE=false
UNINSTALL_MODE=false

#-------------------------------------------------------------------------------
# Funkcje pomocnicze
#-------------------------------------------------------------------------------

log_info() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[INFO]${NC} $timestamp - $*"
    echo "[INFO] $timestamp - $*" >> "$LOG_FILE"
}

log_debug() {
    if [[ "$VERBOSE_MODE" == true ]]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo -e "${CYAN}[DEBUG]${NC} $timestamp - $*" >&2
        echo "[DEBUG] $timestamp - $*" >> "$LOG_FILE"
    fi
}

log_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[ERROR]${NC} $timestamp - $*" >&2
    echo "[ERROR] $timestamp - $*" >> "$LOG_FILE"
}

log_warning() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[WARNING]${NC} $timestamp - $*" >&2
    echo "[WARNING] $timestamp - $*" >> "$LOG_FILE"
}

log_success() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[SUCCESS]${NC} $timestamp - $*"
    echo "[SUCCESS] $timestamp - $*" >> "$LOG_FILE"
}

#-------------------------------------------------------------------------------
# Sprawdzenie uprawnień administratora (sudo)
#-------------------------------------------------------------------------------

check_root() {
    # Nie wymagamy uprawnień root - instalujemy w katalogu użytkownika
    if [[ $EUID -eq 0 ]]; then
        log_warning "Wykryto uprawnienia administratora. Skrypt powinien być uruchomiony jako zwykły użytkownik."
        log_info "Sprawdzanie zmiennej SUDO_USER..."
        if [[ -n "${SUDO_USER:-}" ]]; then
            log_info "Użytkownik wywołujący: ${SUDO_USER}"
            # Przełącz HOME na katalog użytkownika wywołującego
            export HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
            log_info "Ustawiono HOME na: $HOME"
        else
            log_error "Skrypt uruchomiony jako root bez SUDO_USER. Uruchom jako zwykły użytkownik lub użyj 'sudo -E'."
            exit 1
        fi
    fi
    log_debug "Użytkownik: $(whoami), HOME: $HOME"
}

#-------------------------------------------------------------------------------
# Wykrywanie systemu operacyjnego
#-------------------------------------------------------------------------------

detect_os() {
    if [[ -f /etc/os-release ]]; then
        # Używamy lokalnych zmiennych zamiast globalnych aby uniknąć konfliktów
        local os_id_var=""
        local os_version_var=""
        
        while IFS='=' read -r key value; do
            case "$key" in
                ID) os_id_var="$value" ;;
                VERSION_ID) os_version_var="$value" ;;
            esac
        done < /etc/os-release
        
        # Usuń cudzysłowy jeśli są
        os_id_var="${os_id_var//\"/}"
        os_version_var="${os_version_var//\"/}"
        
        OS_ID="$os_id_var"
        OS_VERSION="$os_version_var"
        log_info "Wykryto system: $OS_ID w wersji $OS_VERSION"
    elif [[ -f /etc/debian_version ]]; then
        OS_ID="debian"
        OS_VERSION=$(cat /etc/debian_version)
        log_info "Wykryto system: Debian w wersji $OS_VERSION"
    else
        log_error "Nie można wykryć systemu operacyjnego"
        exit 1
    fi
}

#-------------------------------------------------------------------------------
# Sprawdzenie wymagań systemowych
#-------------------------------------------------------------------------------

check_requirements() {
    log_info "Sprawdzanie wymagań systemowych..."
    
    local missing_deps=()
    
    # Sprawdzenie bash
    if ! command -v bash &>/dev/null; then
        missing_deps+=("bash")
    else
        log_debug "bash: $(bash --version | head -1)"
    fi
    
    # Sprawdzenie curl
    if ! command -v curl &>/dev/null; then
        missing_deps+=("curl")
    else
        log_debug "curl: $(curl --version | head -1)"
    fi
    
    # Sprawdzenie git
    if ! command -v git &>/dev/null; then
        missing_deps+=("git")
    else
        log_debug "git: $(git --version)"
    fi
    
    # Sprawdzenie jq (do parsowania JSON)
    if ! command -v jq &>/dev/null; then
        missing_deps+=("jq")
    else
        log_debug "jq: $(jq --version)"
    fi
    
    # Sprawdzenie wget
    if ! command -v wget &>/dev/null; then
        missing_deps+=("wget")
    else
        log_debug "wget: $(wget --version | head -1)"
    fi
    
    # Sprawdzenie Node.js (wymagane dla Puter AI)
    if ! command -v node &>/dev/null; then
        missing_deps+=("nodejs")
        missing_deps+=("npm")
    else
        log_debug "node: $(node --version)"
        log_debug "npm: $(npm --version)"
    fi
    
    # Opcjonalne: sprawdzenie ollama
    if command -v ollama &>/dev/null; then
        log_success "Ollama wykryte (opcjonalne AI)"
    else
        log_warning "Ollama nie zainstalowane (opcjonalne do lokalnego AI)"
    fi
    
    # Jeśli są brakujące zależności
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_warning "Brakujące pakiety: ${missing_deps[*]}"
        
        if [[ "$FORCE_MODE" != true ]]; then
            echo ""
            read -rp "Czy zainstalować brakujące pakiety? [y/N]: " install_deps
            if [[ "$install_deps" =~ ^[Yy]$ ]]; then
                install_missing_deps "${missing_deps[@]}"
            else
                log_error "Instalacja nie może kontynuować bez wymaganych pakietów"
                exit 1
            fi
        else
            log_info "Tryb FORCE - automatyczna instalacja brakujących pakietów"
            install_missing_deps "${missing_deps[@]}"
        fi
    else
        log_success "Wszystkie wymagane zależności systemowe są zainstalowane"
    fi
    
    # Sprawdzenie i instalacja puter.js
    check_puter_js
}

#-------------------------------------------------------------------------------
# Instalacja brakujących pakietów
#-------------------------------------------------------------------------------

install_missing_deps() {
    local deps=("$@")
    
    log_info "Instalowanie brakujących pakietów: ${deps[*]}"
    
    case $OS_ID in
        ubuntu|debian|raspbian)
            apt-get update -qq
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${deps[@]}"
            ;;
        fedora|centos|rhel)
            dnf install -y "${deps[@]}" 2>/dev/null || yum install -y "${deps[@]}"
            ;;
        arch|manjaro)
            pacman -S --noconfirm "${deps[@]}"
            ;;
        *)
            log_error "Nieobsługiwany system: $OS_ID"
            exit 1
            ;;
    esac
    
    log_success "Zainstalowano wszystkie brakujące pakiety"
}

#-------------------------------------------------------------------------------
# Sprawdzenie i instalacja puter.js
#-------------------------------------------------------------------------------

check_puter_js() {
    log_info "Sprawdzanie biblioteki puter.js..."
    
    # Sprawdź czy Node.js jest zainstalowane
    if ! command -v node &>/dev/null; then
        log_error "Node.js nie jest zainstalowane. puter.js wymaga Node.js"
        return 1
    fi
    
    # Sprawdź czy puter.js jest już zainstalowane globalnie
    if npm list -g @heyputer/puter.js &>/dev/null; then
        log_success "puter.js jest już zainstalowane globalnie"
        return 0
    fi
    
    # Sprawdź lokalną instalację w katalogu użytkownika
    local local_puter_dir="${HOME}/.npm-global/lib/node_modules/@heyputer/puter.js"
    if [[ -d "$local_puter_dir" ]]; then
        log_success "puter.js jest już zainstalowane lokalnie"
        return 0
    fi
    
    log_info "Instalowanie puter.js..."
    
    # Skonfiguruj globalny katalog npm w katalogu użytkownika (bez uprawnień root)
    local npm_global_dir="${HOME}/.npm-global"
    mkdir -p "$npm_global_dir"
    npm config set prefix "$npm_global_dir"
    
    # Dodaj do PATH jeśli nie ma
    if [[ ":$PATH:" != *":$npm_global_dir/bin:"* ]]; then
        log_warning "Dodanie $npm_global_dir/bin do PATH"
        log_info "Dodaj do ~/.bashrc lub ~/.zshrc:"
        log_info '  export PATH="$HOME/.npm-global/bin:$PATH"'
        
        # Automatycznie dodaj do .bashrc jeśli istnieje
        if [[ -f "${HOME}/.bashrc" ]]; then
            if ! grep -q "npm-global/bin" "${HOME}/.bashrc"; then
                echo "" >> "${HOME}/.bashrc"
                echo "# Puter.js - Global npm packages" >> "${HOME}/.bashrc"
                echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "${HOME}/.bashrc"
                log_success "Dodano PATH do ~/.bashrc"
            fi
        fi
        
        # Eksportuj dla bieżącej sesji
        export PATH="$npm_global_dir/bin:$PATH"
    fi
    
    # Zainstaluj puter.js globalnie
    if npm install -g @heyputer/puter.js --silent 2>&1 | tee /tmp/puter-install.log; then
        log_success "puter.js zostało pomyślnie zainstalowane"
        
        # Weryfikacja instalacji
        if command -v puter &>/dev/null || npm list -g @heyputer/puter.js &>/dev/null; then
            log_success "Weryfikacja puter.js zakończona sukcesem"
            return 0
        else
            log_warning "puter.js zainstalowane, ale komenda może być niedostępna"
            log_info "Może być wymagane ponowne zalogowanie lub: source ~/.bashrc"
            return 0
        fi
    else
        log_error "Nie udało się zainstalować puter.js"
        cat /tmp/puter-install.log >&2
        return 1
    fi
}

#-------------------------------------------------------------------------------
# Tworzenie katalogów
#-------------------------------------------------------------------------------

create_directories() {
    log_info "Tworzenie katalogów..."
    
    # Katalog główny aplikacji
    mkdir -p "$INSTALL_DIR"
    log_debug "Utworzono: $INSTALL_DIR"
    
    # Katalog na skrypty
    mkdir -p "$INSTALL_DIR/scripts"
    log_debug "Utworzono: $INSTALL_DIR/scripts"
    
    # Katalog na biblioteki
    mkdir -p "$INSTALL_DIR/scripts/lib"
    log_debug "Utworzono: $INSTALL_DIR/scripts/lib"
    
    # Katalog na logi
    mkdir -p "$INSTALL_DIR/logs"
    chmod 755 "$INSTALL_DIR/logs"
    log_debug "Utworzono: $INSTALL_DIR/logs"
    
    # Katalog na konfigurację
    mkdir -p "$INSTALL_DIR/config"
    log_debug "Utworzono: $INSTALL_DIR/config"
    
    # Katalog na backup
    mkdir -p "$INSTALL_DIR/backups"
    log_debug "Utworzono: $INSTALL_DIR/backups"
    
    # Katalog na templates
    mkdir -p "$INSTALL_DIR/templates"
    log_debug "Utworzono: $INSTALL_DIR/templates"
    
    log_success "Wszystkie katalogi utworzone"
}

#-------------------------------------------------------------------------------
# Kopiowanie plików aplikacji
#-------------------------------------------------------------------------------

copy_files() {
    log_info "Kopiowanie plików aplikacji..."
    
    # Kopiowanie głównego skryptu
    if [[ -f "${SCRIPT_DIR}/qwen-tam.sh" ]]; then
        cp "${SCRIPT_DIR}/qwen-tam.sh" "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/qwen-tam.sh"
        log_debug "Skopiowano: qwen-tam.sh"
    else
        log_error "Nie znaleziono pliku qwen-tam.sh w ${SCRIPT_DIR}"
        exit 1
    fi
    
    # Kopiowanie podskryptów
    if [[ -d "${SCRIPT_DIR}/scripts" ]]; then
        cp -r "${SCRIPT_DIR}/scripts/"* "$INSTALL_DIR/scripts/"
        chmod +x "$INSTALL_DIR/scripts/"*.sh 2>/dev/null || true
        log_debug "Skopiowano: scripts/*"
    else
        log_warning "Katalog scripts/ nie istnieje"
    fi
    
    # Kopiowanie templates
    if [[ -d "${SCRIPT_DIR}/templates" ]]; then
        cp -r "${SCRIPT_DIR}/templates/"* "$INSTALL_DIR/templates/"
        chmod +x "$INSTALL_DIR/templates/"*.sh 2>/dev/null || true
        log_debug "Skopiowano: templates/*"
    else
        log_warning "Katalog templates/ nie istnieje"
    fi
    
    # Kopiowanie dokumentacji
    for doc_file in README.md LICENSE SECURITY_IMPROVEMENTS.md instrukcja.md; do
        if [[ -f "${SCRIPT_DIR}/${doc_file}" ]]; then
            cp "${SCRIPT_DIR}/${doc_file}" "$INSTALL_DIR/"
            log_debug "Skopiowano: $doc_file"
        fi
    done
    
    log_success "Pliki aplikacji skopiowane"
}

#-------------------------------------------------------------------------------
# Tworzenie linku symbolicznego w katalogu bin użytkownika
#-------------------------------------------------------------------------------

create_symlink() {
    log_info "Tworzenie linku symbolicznego w ~/bin..."
    
    local user_bin_dir="${HOME}/bin"
    local symlink_path="${user_bin_dir}/apka"
    
    # Utwórz katalog ~/bin jeśli nie istnieje
    if [[ ! -d "$user_bin_dir" ]]; then
        mkdir -p "$user_bin_dir"
        log_debug "Utworzono katalog: $user_bin_dir"
    fi
    
    # Usuń istniejący link jeśli istnieje
    if [[ -L "$symlink_path" ]]; then
        rm -f "$symlink_path"
        log_debug "Usunięto stary link: $symlink_path"
    fi
    
    # Utwórz nowy link
    ln -s "$INSTALL_DIR/qwen-tam.sh" "$symlink_path"
    chmod +x "$symlink_path"
    log_debug "Utworzono link: $symlink_path -> $INSTALL_DIR/qwen-tam.sh"
    
    # Sprawdź czy ~/bin jest w PATH
    if [[ ":$PATH:" != *":$user_bin_dir:"* ]]; then
        log_warning "Katalog ~/bin nie znajduje się w PATH"
        log_info "Dodanie ~/bin do PATH w pliku .bashrc lub .zshrc:"
        log_info '  export PATH="$HOME/bin:$PATH"'
    fi
    
    log_success "Link symboliczny utworzony"
}

#-------------------------------------------------------------------------------
# Konfiguracja uprawnień
#-------------------------------------------------------------------------------

setup_permissions() {
    log_info "Konfiguracja uprawnień..."
    
    # Właściciel katalogu instalacyjnego - bieżący użytkownik (z zachowaniem grupy)
    local current_user="${SUDO_USER:-$(whoami)}"
    local current_group
    
    # Sprawdź czy użytkownik istnieje w systemie
    if id "$current_user" &>/dev/null; then
        current_group="$(id -gn "$current_user" 2>/dev/null || echo "$current_user")"
        chown -R "${current_user}:${current_group}" "$INSTALL_DIR"
        log_debug "Ustawiono właściciela: ${current_user}:${current_group}"
    else
        # Jeśli użytkownik nie istnieje, użyj obecnego użytkownika
        current_user="$(whoami)"
        current_group="$(id -gn "$current_user" 2>/dev/null || echo "$current_user")"
        chown -R "${current_user}:${current_group}" "$INSTALL_DIR"
        log_debug "Ustawiono właściciela: ${current_user}:${current_group} (użytkownik SUDO_USER nie istnieje)"
    fi
    
    # Uprawnienia dla katalogu logów (wszyscy mogą zapisywać)
    chmod 755 "$INSTALL_DIR/logs"
    
    # Uprawnienia dla skryptów wykonywalnych
    find "$INSTALL_DIR" -name "*.sh" -exec chmod +x {} \;
    
    # Główny skrypt musi być wykonywalny
    chmod +x "$INSTALL_DIR/qwen-tam.sh"
    
    log_success "Uprawnienia skonfigurowane"
}

#-------------------------------------------------------------------------------
# Tworzenie pliku konfiguracyjnego
#-------------------------------------------------------------------------------

create_config() {
    log_info "Tworzenie domyślnej konfiguracji..."
    
    local user_config="${HOME}/.apka_config"
    
    if [[ -f "$user_config" ]]; then
        log_warning "Plik konfiguracyjny już istnieje: $user_config"
        log_info "Tworzenie kopii zapasowej..."
        cp "$user_config" "${user_config}.backup.$(date +%Y%m%d%H%M%S)"
    fi
    
    # Tworzenie nowej konfiguracji
    cat > "$user_config" << EOF
# Apka - Konfiguracja
# Wygenerowano: $(date '+%Y-%m-%d %H:%M:%S')

# Ścieżka do katalogu roboczego
WORK_DIR="${HOME}/apka-projects"

# Konfiguracja GitHub (token należy uzupełnić ręcznie!)
GITHUB_TOKEN=""
GITHUB_USER=""

# Konfiguracja API Qwen
QWEN_API_ENDPOINT="http://localhost:11434"
QWEN_MODEL="qwen2.5:7b"

# Ustawienia aplikacji
DEBUG_MODE=false
VERBOSE_MODE=false
AUTO_COMMIT=false
BACKUP_ENABLED=true

# Powiadomienia
NOTIFY_EMAIL=""
NOTIFY_SLACK_WEBHOOK=""

# Harmonogram zadań
CRON_BACKUP="0 2 * * *"
CRON_SYNC="0 */6 * * *"
EOF
    
    chmod 600 "$user_config"
    log_debug "Utworzono plik konfiguracyjny: $user_config"
    
    log_success "Domyślna konfiguracja utworzona"
    log_warning "WAŻNE: Uzupełnij token GitHub w pliku $user_config"
}

#-------------------------------------------------------------------------------
# Tworzenie katalogu roboczego
#-------------------------------------------------------------------------------

create_work_dir() {
    local work_dir="${HOME}/apka-projects"
    
    if [[ ! -d "$work_dir" ]]; then
        log_info "Tworzenie katalogu roboczego: $work_dir"
        mkdir -p "$work_dir"
        log_debug "Utworzono: $work_dir"
    else
        log_debug "Katalog roboczy już istnieje: $work_dir"
    fi
}

#-------------------------------------------------------------------------------
# Dodanie aliasu do powłoki
#-------------------------------------------------------------------------------

add_shell_alias() {
    log_info "Dodawanie aliasu do powłoki..."
    
    local alias_line='alias apka="apka"'
    local shell_rc=""
    
    # Wykryj powłokę użytkownika
    if [[ -f "${HOME}/.bashrc" ]]; then
        shell_rc="${HOME}/.bashrc"
    elif [[ -f "${HOME}/.zshrc" ]]; then
        shell_rc="${HOME}/.zshrc"
    elif [[ -f "${HOME}/.profile" ]]; then
        shell_rc="${HOME}/.profile"
    else
        log_warning "Nie znaleziono pliku konfiguracyjnego powłoki"
        return 0
    fi
    
    # Sprawdź czy alias już istnieje
    if grep -q "apka" "$shell_rc" 2>/dev/null; then
        log_debug "Alias już istnieje w $shell_rc"
    else
        echo "" >> "$shell_rc"
        echo "# Apka" >> "$shell_rc"
        echo "$alias_line" >> "$shell_rc"
        log_debug "Dodano alias do $shell_rc"
    fi
    
    log_success "Alias dodany do $shell_rc"
}

#-------------------------------------------------------------------------------
# Weryfikacja instalacji
#-------------------------------------------------------------------------------

verify_installation() {
    log_info "Weryfikacja instalacji..."
    
    local errors=0
    
    # Sprawdź katalog instalacyjny
    if [[ ! -d "$INSTALL_DIR" ]]; then
        log_error "Katalog instalacyjny nie istnieje: $INSTALL_DIR"
        ((errors++))
    fi
    
    # Sprawdź główny skrypt
    if [[ ! -x "$INSTALL_DIR/qwen-tam.sh" ]]; then
        log_error "Główny skrypt nie jest wykonywalny"
        ((errors++))
    fi
    
    # Sprawdź link symboliczny w ~/bin
    local user_bin_path="${HOME}/bin/apka"
    if [[ ! -L "$user_bin_path" ]]; then
        log_error "Link symboliczny nie został utworzony: $user_bin_path"
        ((errors++))
    fi
    
    # Sprawdź skrypty
    if [[ ! -d "$INSTALL_DIR/scripts" ]]; then
        log_error "Katalog scripts nie istnieje"
        ((errors++))
    fi
    
    # Sprawdź logi
    if [[ ! -d "$INSTALL_DIR/logs" ]]; then
        log_error "Katalog logs nie istnieje"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        log_success "Instalacja zweryfikowana pomyślnie!"
        return 0
    else
        log_error "Weryfikacja nie powiodła się - liczba błędów: $errors"
        return 1
    fi
}

#-------------------------------------------------------------------------------
# Dodanie ~/bin do PATH w pliku konfiguracyjnym powłoki
#-------------------------------------------------------------------------------

add_bin_to_path() {
    log_info "Dodawanie ~/bin do PATH w pliku konfiguracyjnym powłoki..."
    
    local shell_rc=""
    local path_line='export PATH="$HOME/bin:$PATH"'
    
    # Wykryj powłokę użytkownika
    if [[ -f "${HOME}/.bashrc" ]]; then
        shell_rc="${HOME}/.bashrc"
    elif [[ -f "${HOME}/.zshrc" ]]; then
        shell_rc="${HOME}/.zshrc"
    elif [[ -f "${HOME}/.profile" ]]; then
        shell_rc="${HOME}/.profile"
    else
        # Jeśli nie znaleziono żadnego pliku, utwórz .bashrc
        shell_rc="${HOME}/.bashrc"
        touch "$shell_rc"
        log_debug "Utworzono plik: $shell_rc"
    fi
    
    # Sprawdź czy PATH już zawiera ~/bin
    if grep -q '\$HOME/bin' "$shell_rc" 2>/dev/null || grep -q '~/bin' "$shell_rc" 2>/dev/null; then
        log_debug "~/bin jest już w PATH w pliku $shell_rc"
    else
        echo "" >> "$shell_rc"
        echo "# Apka - dodanie ~/bin do PATH" >> "$shell_rc"
        echo "$path_line" >> "$shell_rc"
        log_debug "Dodano ~/bin do PATH w pliku $shell_rc"
    fi
    
    # Eksportuj PATH dla bieżącej sesji (tylko jeśli nie jest już dodane)
    if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
        export PATH="$HOME/bin:$PATH"
        log_debug "Dodano ~/bin do PATH dla bieżącej sesji"
    fi
    
    log_success "Skonfigurowano PATH dla ~/bin"
}

#-------------------------------------------------------------------------------
# Pokaż informacje po instalacji
#-------------------------------------------------------------------------------

show_post_install_info() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          INSTALACJA ZAKOŃCZONA POMYŚLNIE!                    ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Lokalizacja instalacji:${NC} $INSTALL_DIR"
    echo -e "${GREEN}Plik konfiguracyjny:${NC} ${HOME}/.apka_config"
    echo -e "${GREEN}Katalog roboczy:${NC} ${HOME}/apka-projects"
    echo ""
    echo -e "${BLUE}Jak uruchomić aplikację:${NC}"
    echo "  Uruchom polecenie: ${CYAN}apka${NC}"
    echo "  Lub bezpośrednio: ${CYAN}$INSTALL_DIR/qwen-tam.sh${NC}"
    echo ""
    echo -e "${GREEN}Konfiguracja środowiska:${NC}"
    echo "  ✓ Katalog ~/bin został automatycznie dodany do PATH"
    echo "  ✓ Plik konfiguracyjny powłoki (${HOME}/.bashrc lub ~/.zshrc) został zaktualizowany"
    echo "  ✓ Jeśli to nowa sesja terminala, uruchom: ${CYAN}source ~/.bashrc${NC} (lub ~/.zshrc)"
    echo ""
    echo -e "${YELLOW}Następne kroki:${NC}"
    echo "  1. Uruchom aplikację: ${CYAN}apka${NC}"
    echo "  2. Skonfiguruj token GitHub w menu [5.1]"
    echo "  3. Sprawdź status systemu w menu [7]"
    echo "  4. Zacznij tworzyć projekty!"
    echo ""
    echo -e "${YELLOW}WAŻNE:${NC} Token GitHub musi być ustawiony przed użyciem funkcji GitHub!"
    echo ""
    echo -e "${BLUE}Dokumentacja:${NC} $INSTALL_DIR/README.md"
    echo ""
}

#-------------------------------------------------------------------------------
# Odinstalowanie aplikacji
#-------------------------------------------------------------------------------

uninstall_app() {
    log_warning "Rozpoczynanie odinstalowywania..."
    
    if [[ ! -d "$INSTALL_DIR" ]]; then
        log_error "Aplikacja nie jest zainstalowana w $INSTALL_DIR"
        exit 1
    fi
    
    echo ""
    read -rp "Czy na pewno chcesz odinstalować Apka? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Odinstalowywanie anulowane"
        exit 0
    fi
    
    # Usuń link symboliczny z ~/bin
    rm -f "${HOME}/bin/apka"
    log_debug "Usunięto link symboliczny"
    
    # Usuń katalog instalacyjny
    rm -rf "$INSTALL_DIR"
    log_debug "Usunięto katalog instalacyjny"
    
    # Nie usuwaj konfiguracji użytkownika (może chcieć zachować)
    log_info "Plik konfiguracyjny ${HOME}/.apka_config został zachowany"
    
    log_success "Aplikacja odinstalowana"
    exit 0
}

#-------------------------------------------------------------------------------
# Pokaż pomoc
#-------------------------------------------------------------------------------

show_help() {
    echo "Apka - Skrypt Instalacyjny v${VERSION}"
    echo ""
    echo "Użycie: $SCRIPT_NAME [OPCJE]"
    echo ""
    echo "Opcje:"
    echo "  -h, --help          Pokaż tę pomoc"
    echo "  -v, --verbose       Tryb szczegółowy (więcej informacji)"
    echo "  -f, --force         Wymuś instalację bez pytań"
    echo "  -u, --uninstall     Odinstaluj aplikację"
    echo "  -c, --check         Tylko sprawdź wymagania (bez instalacji)"
    echo ""
    echo "Przykłady:"
    echo "  sudo ./$SCRIPT_NAME                 # Standardowa instalacja"
    echo "  sudo ./$SCRIPT_NAME --force         # Instalacja bez pytań"
    echo "  sudo ./$SCRIPT_NAME --uninstall     # Odinstaluj"
    echo "  sudo ./$SCRIPT_NAME --check         # Sprawdź wymagania"
    echo ""
}

#-------------------------------------------------------------------------------
# Parsowanie argumentów
#-------------------------------------------------------------------------------

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE_MODE=true
                shift
                ;;
            -f|--force)
                FORCE_MODE=true
                shift
                ;;
            -u|--uninstall)
                UNINSTALL_MODE=true
                shift
                ;;
            -c|--check)
                check_root
                detect_os
                check_requirements
                log_success "Sprawdzanie wymagań zakończone"
                exit 0
                ;;
            *)
                log_error "Nieznana opcja: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# Główna funkcja instalacyjna
#-------------------------------------------------------------------------------

main() {
    parse_arguments "$@"
    
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     QWEN TIME & AUTOMATION MANAGER - INSTALATOR v${VERSION}      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Sprawdź tryb odinstalowywania
    if [[ "$UNINSTALL_MODE" == true ]]; then
        check_root
        uninstall_app
    fi
    
    # Standardowa instalacja
    check_root
    detect_os
    check_requirements
    create_directories
    copy_files
    create_symlink
    setup_permissions
    create_config
    create_work_dir
    add_bin_to_path
    add_shell_alias
    verify_installation
    show_post_install_info
    
    log_success "Instalacja zakończona sukcesem!"
}

# Uruchomienie skryptu
main "$@"
