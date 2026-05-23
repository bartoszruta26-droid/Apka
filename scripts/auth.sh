#!/bin/bash

# auth.sh - Autoryzacja i zarządzanie tokenem GitHub
# Część Qwen Time & Automation Manager
# ZAKTUALIZOWANO: Bezpieczne szyfrowanie AES-256 zamiast base64

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/qwen-tam"
GITHUB_CONF="$CONFIG_DIR/github.conf.enc"
LOG_FILE="/tmp/qwen-tam.log"

# Load security library
if [[ -f "${SCRIPT_DIR}/lib/security.sh" ]]; then
    source "${SCRIPT_DIR}/lib/security.sh"
fi

# Load validation library  
if [[ -f "${SCRIPT_DIR}/lib/validation.sh" ]]; then
    source "${SCRIPT_DIR}/lib/validation.sh"
fi

# Kolory ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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
    
    # Initialize security system
    if [[ -f "${SCRIPT_DIR}/lib/security.sh" ]]; then
        init_security 2>/dev/null || true
    fi
}

# Sprawdzenie czy token istnieje
has_token() {
    [[ -f "$GITHUB_CONF" ]] && [[ -s "$GITHUB_CONF" ]]
}

# Pobranie tokena z konfiguracji (DESZYFROWANIE)
get_github_token() {
    if [[ -f "$GITHUB_CONF" ]]; then
        # Check if using new encrypted format
        if grep -q "^TOKEN_ENCRYPTED=" "$GITHUB_CONF" 2>/dev/null; then
            retrieve_github_token_secure 2>/dev/null || return 1
        else
            # Legacy base64 format - decrypt
            local encoded_token
            encoded_token=$(grep "^TOKEN=" "$GITHUB_CONF" 2>/dev/null | cut -d'=' -f2-)
            if [[ -n "$encoded_token" ]]; then
                echo "$encoded_token" | base64 -d 2>/dev/null
            fi
        fi
    fi
}

# Pobranie nazwy użytkownika z konfiguracji
get_github_username() {
    if [[ -f "$GITHUB_CONF" ]]; then
        # Try new format first
        if grep -q "^USERNAME=" "$GITHUB_CONF" 2>/dev/null; then
            grep "^USERNAME=" "$GITHUB_CONF" | cut -d'=' -f2-
        else
            get_github_username_secure 2>/dev/null
        fi
    fi
}

# Walidacja tokena GitHub API
validate_github_token() {
    local token="$1"
    
    if [[ -z "$token" ]]; then
        return 1
    fi
    
    # Validate token format first
    if declare -f validate_github_token_format &>/dev/null; then
        if ! validate_github_token_format "$token"; then
            log_auth_error "Invalid token format"
            return 1
        fi
    fi
    
    # Sprawdzenie tokena przez GitHub API
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/user" 2>/dev/null)
    
    if [[ "$response" == "200" ]]; then
        return 0
    else
        return 1
    fi
}

# Zapisanie tokena w konfiguracji (SZYFROWANIE AES-256)
save_github_token() {
    local token="$1"
    local username="$2"
    
    init_config_dir
    
    # Use secure encryption from security library
    if declare -f store_github_token_secure &>/dev/null; then
        if store_github_token_secure "$token" "$username"; then
            log_auth "Token zapisany pomyślnie (AES-256 encryption) dla użytkownika: $username"
            
            if validate_github_token "$token"; then
                return 0
            else
                log_auth_error "Nie udało się zwalidować tokena"
                return 1
            fi
        else
            log_auth_error "Failed to encrypt and save token"
            return 1
        fi
    else
        # Fallback to base64 (legacy, insecure - should upgrade)
        log_auth_error "WARNING: Security library not available, using insecure base64 encoding"
        
        local encoded_token
        encoded_token=$(echo -n "$token" | base64)
        
        cat > "$GITHUB_CONF" << EOF
# Qwen TAM - GitHub Configuration (INSECURE - Upgrade recommended)
# Created: $(date '+%Y-%m-%d %H:%M:%S')
USERNAME=$username
TOKEN=$encoded_token
ENCRYPTED=false
SECURITY_WARNING="Base64 is not encryption! Upgrade to use AES-256."
EOF
        
        chmod 600 "$GITHUB_CONF"
        
        if validate_github_token "$token"; then
            log_auth "Token zapisany (base64 - UPGRADE RECOMMENDED) dla użytkownika: $username"
            return 0
        else
            log_auth_error "Nie udało się zwalidować tokena"
            rm -f "$GITHUB_CONF"
            return 1
        fi
    fi
}

# Usunięcie zapisanego tokena
remove_github_token() {
    if [[ -f "$GITHUB_CONF" ]]; then
        # Secure delete if security library available
        if declare -f delete_credentials_secure &>/dev/null; then
            delete_credentials_secure
        else
            rm -f "$GITHUB_CONF"
        fi
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
    echo -e "${GREEN}Nowość: Tokeny są teraz szyfrowane algorytmem AES-256!${NC}"
    echo ""
    
    read -p "Podaj swój GitHub username: " username
    
    # Validate username
    if declare -f validate_github_username &>/dev/null; then
        if ! validate_github_username "$username"; then
            log_auth_error "Nieprawidłowy format nazwy użytkownika GitHub"
            echo "Username musi zawierać 1-39 znaków alfanumerycznych i myślników"
            return 1
        fi
    elif [[ -z "$username" ]]; then
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
            "https://api.github.com/user" 2>/dev/null | jq -r '.login' 2>/dev/null)
        
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
            
            # Check encryption status
            if grep -q "^TOKEN_ENCRYPTED=" "$GITHUB_CONF" 2>/dev/null; then
                echo -e "Bezpieczeństwo: ${GREEN}AES-256 Encryption${NC}"
            elif grep -q "SECURITY_WARNING" "$GITHUB_CONF" 2>/dev/null; then
                echo -e "Bezpieczeństwo: ${RED}Base64 (Upgrade recommended!)${NC}"
            else
                echo -e "Bezpieczeństwo: ${YELLOW}Unknown${NC}"
            fi
            
            # Sprawdzenie ważności tokena
            local token
            token=$(get_github_token)
            
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
        echo "4) Sprawdź integralność szyfrowania"
        echo "5) Wróć"
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
                    echo -n "Weryfikacja tokena... "
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
            4)
                if declare -f verify_encryption_integrity &>/dev/null; then
                    verify_encryption_integrity
                else
                    echo -e "${YELLOW}Security library not available${NC}"
                fi
                echo ""
                read -p "Naciśnij Enter aby kontynuować..."
                ;;
            5|*)
                break
                ;;
        esac
    done
}

# Export functions
export -f auth_menu
export -f get_github_token
export -f get_github_username
export -f has_token
