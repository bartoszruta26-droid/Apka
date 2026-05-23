#!/bin/bash

# auth.sh - Autoryzacja i zarządzanie tokenem GitHub
# Część Qwen Time & Automation Manager

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/qwen-tam"
GITHUB_CONF="$CONFIG_DIR/github.conf"
LOG_FILE="/tmp/qwen-tam.log"

# Kolory ANSI
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log_auth() {
    echo -e "${GREEN}[AUTH]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

log_auth_error() {
    echo -e "${RED}[AUTH ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

# Inicjalizacja katalogu konfiguracyjnego
init_config_dir() {
    mkdir -p "$CONFIG_DIR"
    chmod 700 "$CONFIG_DIR"
}

# Sprawdzenie czy token istnieje
has_token() {
    [[ -f "$GITHUB_CONF" ]] && [[ -s "$GITHUB_CONF" ]]
}

# Pobranie tokena z konfiguracji
get_github_token() {
    if [[ -f "$GITHUB_CONF" ]]; then
        grep "^TOKEN=" "$GITHUB_CONF" | cut -d'=' -f2-
    fi
}

# Pobranie nazwy użytkownika z konfiguracji
get_github_username() {
    if [[ -f "$GITHUB_CONF" ]]; then
        grep "^USERNAME=" "$GITHUB_CONF" | cut -d'=' -f2-
    fi
}

# Walidacja tokena GitHub API
validate_github_token() {
    local token="$1"
    
    if [[ -z "$token" ]]; then
        return 1
    fi
    
    # Sprawdzenie tokena przez GitHub API
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/user")
    
    if [[ "$response" == "200" ]]; then
        return 0
    else
        return 1
    fi
}

# Zapisanie tokena w konfiguracji (szyfrowane)
save_github_token() {
    local token="$1"
    local username="$2"
    
    init_config_dir
    
    # Szyfrowanie tokena przy użyciu base64 (można zastąpić GPG/openssl)
    local encoded_token
    encoded_token=$(echo -n "$token" | base64)
    
    cat > "$GITHUB_CONF" << EOF
# Qwen TAM - GitHub Configuration
# Created: $(date '+%Y-%m-%d %H:%M:%S')
USERNAME=$username
TOKEN=$encoded_token
ENCRYPTED=true
EOF
    
    chmod 600 "$GITHUB_CONF"
    
    if validate_github_token "$token"; then
        log_auth "Token zapisany pomyślnie dla użytkownika: $username"
        return 0
    else
        log_auth_error "Nie udało się zwalidować tokena"
        rm -f "$GITHUB_CONF"
        return 1
    fi
}

# Usunięcie zapisanego tokena
remove_github_token() {
    if [[ -f "$GITHUB_CONF" ]]; then
        rm -f "$GITHUB_CONF"
        log_auth "Token usunięty"
        return 0
    fi
    return 1
}

# Interaktywna konfiguracja tokena
configure_github_interactive() {
    echo ""
    echo -e "${YELLOW}=== Konfiguracja GitHub ===${NC}"
    echo ""
    
    read -p "Podaj swój GitHub username: " username
    if [[ -z "$username" ]]; then
        log_auth_error "Nazwa użytkownika nie może być pusta"
        return 1
    fi
    
    echo ""
    echo "Wklej swój GitHub Personal Access Token:"
    echo "(Token musi mieć uprawnienia: repo, user)"
    echo ""
    read -s -p "Token: " token
    echo ""
    
    if [[ -z "$token" ]]; then
        log_auth_error "Token nie może być pusty"
        return 1
    fi
    
    # Walidacja tokena
    echo -n "Walidacja tokena... "
    if validate_github_token "$token"; then
        echo -e "${GREEN}OK${NC}"
        
        # Pobranie rzeczywistej nazwy użytkownika z API
        local api_username
        api_username=$(curl -s -H "Authorization: token $token" \
            -H "Accept: application/vnd.github.v3+json" \
            "https://api.github.com/user" | jq -r '.login')
        
        if [[ -n "$api_username" && "$api_username" != "null" ]]; then
            username="$api_username"
            echo "Znaleziono użytkownika: $username"
        fi
        
        save_github_token "$token" "$username"
        return $?
    else
        echo -e "${RED}BŁĄD${NC}"
        log_auth_error "Nieprawidłowy token GitHub"
        echo "Sprawdź czy token jest poprawny i ma odpowiednie uprawnienia."
        return 1
    fi
}

# Wyświetlenie statusu autoryzacji
show_auth_status() {
    echo ""
    echo -e "${YELLOW}=== Status Autoryzacji GitHub ===${NC}"
    echo ""
    
    if has_token; then
        local username
        username=$(get_github_username)
        
        if [[ -n "$username" ]]; then
            echo -e "Status: ${GREEN}Zalogowany${NC}"
            echo "Użytkownik: $username"
            
            # Sprawdzenie ważności tokena
            local token
            token=$(get_github_token)
            token=$(echo "$token" | base64 -d)
            
            if validate_github_token "$token"; then
                echo -e "Token: ${GREEN}Ważny${NC}"
            else
                echo -e "Token: ${RED}Nieważny${NC}"
            fi
        else
            echo -e "Status: ${YELLOW}Brak danych użytkownika${NC}"
        fi
    else
        echo -e "Status: ${RED}Nie zalogowano${NC}"
        echo "Skonfiguruj token GitHub w menu konfiguracji."
    fi
    echo ""
}

# Główna funkcja menu autoryzacji
auth_menu() {
    while true; do
        clear
        show_auth_status
        
        echo -e "${YELLOW}Opcje:${NC}"
        echo "1) Skonfiguruj nowy token GitHub"
        echo "2) Usuń zapisany token"
        echo "3) Zweryfikuj token"
        echo "4) Wróć"
        echo ""
        
        read -p "Wybierz opcję: " choice
        
        case $choice in
            1)
                configure_github_interactive
                echo ""
                read -p "Naciśnij Enter aby kontynuować..."
                ;;
            2)
                if remove_github_token; then
                    echo -e "${GREEN}Token usunięty pomyślnie${NC}"
                else
                    echo -e "${YELLOW}Brak zapisanego tokena${NC}"
                fi
                echo ""
                read -p "Naciśnij Enter aby kontynuować..."
                ;;
            3)
                local token
                token=$(get_github_token)
                if [[ -n "$token" ]]; then
                    token=$(echo "$token" | base64 -d)
                    if validate_github_token "$token"; then
                        echo -e "${GREEN}Token jest ważny${NC}"
                    else
                        echo -e "${RED}Token jest nieważny${NC}"
                    fi
                else
                    echo -e "${YELLOW}Brak zapisanego tokena${NC}"
                fi
                echo ""
                read -p "Naciśnij Enter aby kontynuować..."
                ;;
            4|q|Q)
                break
                ;;
            *)
                echo -e "${RED}Nieprawidłowa opcja${NC}"
                sleep 1
                ;;
        esac
    done
}

# Jeśli skrypt jest uruchomiony bezpośrednio
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    auth_menu "$@"
fi
