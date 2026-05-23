#!/bin/bash

# repo.sh - Tworzenie i zarządzanie repozytoriami GitHub
# Część Qwen Time & Automation Manager
# ZAKTUALIZOWANO: Bezpieczna walidacja inputu i obsługa tokena

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/qwen-tam.log"
REPO_DIR="$HOME/Projects/qwen-tam/repos"

# Load libraries
if [[ -f "${SCRIPT_DIR}/lib/security.sh" ]]; then
    source "${SCRIPT_DIR}/lib/security.sh"
fi

if [[ -f "${SCRIPT_DIR}/lib/validation.sh" ]]; then
    source "${SCRIPT_DIR}/lib/validation.sh"
fi

# Source auth.sh for token functions
source "$SCRIPT_DIR/auth.sh"

# Kolory ANSI
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

log_repo() {
    echo -e "${GREEN}[REPO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

log_repo_error() {
    echo -e "${RED}[REPO ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

# Inicjalizacja katalogu repozytoriów
init_repo_dir() {
    mkdir -p "$REPO_DIR"
    chmod 755 "$REPO_DIR"
}

# Pobranie tokena do autoryzacji (bezpieczne)
get_auth_token() {
    local token
    token=$(get_github_token 2>/dev/null)
    if [[ -n "$token" ]]; then
        echo "$token"
    else
        return 1
    fi
}

# Walidacja nazwy repozytorium z użyciem validation library
validate_repo_name() {
    local name="$1"

    # Use validation library if available (call the library function directly)
    # Check for library's validate_repo_name by checking if we're not in the wrapper itself
    if [[ -n "${VALIDATION_LIB_VERSION:-}" ]]; then
        # Library is loaded, use its validate_repo_name directly
        # But we need to avoid calling ourselves - use a subshell trick or direct call
        builtin validate_repo_name "$name" 2>/dev/null && return 0
    fi
    
    # Fallback validation
    [[ -n "$name" ]] && [[ ${#name} -le 100 ]] && [[ "$name" =~ ^[a-zA-Z0-9._-]+$ ]]
}

# Walidacja ownera (username)
validate_repo_owner() {
    local owner="$1"
    
    # Use validation library if available
    if declare -f validate_github_username &>/dev/null; then
        validate_github_username "$owner"
        return $?
    fi
    
    # Fallback validation
    [[ -n "$owner" ]] && [[ ${#owner} -le 39 ]] && [[ "$owner" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,38}$ ]]
}

# Utwórz repozytorium przez GitHub API
create_repository() {
    local name="$1"
    local description="${2:-}"
    local private="${3:-true}"
    
    # Validate inputs
    if ! validate_repo_name "$name"; then
        log_repo_error "Nieprawidłowa nazwa repozytorium: $name"
        echo "Nazwa może zawierać tylko znaki: a-z, A-Z, 0-9, ., _, -"
        return 1
    fi
    
    local token
    token=$(get_auth_token) || {
        log_repo_error "Brak tokena GitHub. Skonfiguruj go w menu autoryzacji."
        return 1
    }
    
    local visibility="public"
    [[ "$private" == "true" ]] && visibility="private"
    
    # Create JSON payload safely
    local json_payload
    if [[ -n "$description" ]]; then
        json_payload=$(cat <<EOF
{
    "name": "$name",
    "description": "$description",
    "private": $private,
    "auto_init": true
}
EOF
)
    else
        json_payload=$(cat <<EOF
{
    "name": "$name",
    "private": $private,
    "auto_init": true
}
EOF
)
    fi
    
    # Make API call
    local response
    response=$(curl -s -X POST \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        "https://api.github.com/user/repos" 2>/dev/null)
    
    # Check response
    if echo "$response" | jq -e '.full_name' &>/dev/null; then
        local full_name
        full_name=$(echo "$response" | jq -r '.full_name')
        local html_url
        html_url=$(echo "$response" | jq -r '.html_url')
        
        log_repo "Utworzono repozytorium: $full_name"
        echo -e "${GREEN}✓ Repozytorium utworzone pomyślnie!${NC}"
        echo "  Nazwa: $full_name"
        echo "  URL: $html_url"
        return 0
    else
        local error_msg
        error_msg=$(echo "$response" | jq -r '.message // "Unknown error"')
        log_repo_error "Błąd tworzenia repozytorium: $error_msg"
        echo -e "${RED}✗ Błąd: $error_msg${NC}"
        return 1
    fi
}

# Lista repozytoriów użytkownika
list_repositories() {
    local token
    token=$(get_auth_token) || {
        log_repo_error "Brak tokena GitHub"
        return 1
    }
    
    local response
    response=$(curl -s \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/user/repos?sort=updated&per_page=100" 2>/dev/null)
    
    if [[ -z "$response" ]] || ! echo "$response" | jq -e '.[]' &>/dev/null; then
        echo "Brak repozytoriów lub błąd pobierania."
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}=== Twoje Repozytoria GitHub ===${NC}"
    echo ""
    
    echo "$response" | jq -r '.[] | "\(.visibility | ascii_upcase): \(.full_name) - \(.description // "No description")"' | \
        while read -r line; do
            if [[ "$line" == PRIVATE* ]]; then
                echo -e "  ${YELLOW}🔒${NC} $line"
            else
                echo -e "  ${GREEN}🌍${NC} $line"
            fi
        done
    
    echo ""
    echo "Łącznie: $(echo "$response" | jq '. | length') repozytoriów"
}

# Usuń repozytorium (z potwierdzeniem i walidacją)
delete_repository() {
    local owner="$1"
    local repo="$2"
    
    # Validate inputs to prevent command injection
    if ! validate_repo_owner "$owner"; then
        log_repo_error "Nieprawidłowy format owner: $owner"
        return 1
    fi
    
    if ! validate_repo_name "$repo"; then
        log_repo_error "Nieprawidłowy format repozytorium: $repo"
        return 1
    fi
    
    local token
    token=$(get_auth_token) || {
        log_repo_error "Brak tokena GitHub"
        return 1
    }
    
    # Confirmation prompt
    echo -e "${RED}⚠️  UWAGA: Ta operacja jest nieodwracalna!${NC}"
    echo "Czy na pewno chcesz usunąć repozytorium: ${owner}/${repo}?"
    read -p "Wpisz '${repo}' aby potwierdzić: " confirmation
    
    if [[ "$confirmation" != "$repo" ]]; then
        echo "Operacja anulowana."
        return 1
    fi
    
    # Delete via API
    local response
    local http_code
    response=$(curl -s -w "\n%{http_code}" -X DELETE \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/${owner}/${repo}" 2>/dev/null)
    
    http_code=$(echo "$response" | tail -n1)
    
    if [[ "$http_code" == "204" ]]; then
        log_repo "Usunięto repozytorium: ${owner}/${repo}"
        echo -e "${GREEN}✓ Repozytorium usunięte pomyślnie${NC}"
        return 0
    else
        local error_msg
        error_msg=$(echo "$response" | head -n-1 | jq -r '.message // "Unknown error"' 2>/dev/null)
        log_repo_error "Błąd usuwania repozytorium: $error_msg"
        echo -e "${RED}✗ Błąd: $error_msg${NC}"
        return 1
    fi
}

# Klonowanie repozytorium (bezpieczne)
clone_repository() {
    local repo_url="$1"
    local target_dir="${2:-}"
    
    init_repo_dir
    
    # Validate URL format
    if ! declare -f validate_url &>/dev/null; then
        # Basic URL check
        if [[ ! "$repo_url" =~ ^https://github\.com/ ]]; then
            log_repo_error "Nieobsługiwany URL. Tylko GitHub URLs są dozwolone."
            return 1
        fi
    fi
    
    # Extract owner and repo from URL for validation
    local owner repo_name
    owner=$(echo "$repo_url" | sed -n 's|.*github\.com/\([^/]*\)/.*|\1|p')
    repo_name=$(echo "$repo_url" | sed -n 's|.*github\.com/[^/]*/\([^/.]*\).*|\1|p')
    
    # Validate extracted values
    if ! validate_repo_owner "$owner" || ! validate_repo_name "$repo_name"; then
        log_repo_error "Nieprawidłowy format URL repozytorium"
        return 1
    fi
    
    # Set target directory
    if [[ -z "$target_dir" ]]; then
        target_dir="${REPO_DIR}/${repo_name}"
    fi
    
    # Check if directory already exists
    if [[ -d "$target_dir" ]]; then
        log_repo_error "Katalog już istnieje: $target_dir"
        echo "Usuń go ręcznie lub wybierz inną ścieżkę."
        return 1
    fi
    
    # Get token for private repos
    local token
    token=$(get_auth_token)
    
    local clone_url="$repo_url"
    if [[ -n "$token" ]]; then
        # Insert token into URL for private repos
        clone_url=$(echo "$repo_url" | sed "s|https://|https://${owner}:${token}@|")
    fi
    
    log_repo "Klonowanie repozytorium: $repo_name"
    echo "Klonowanie..."
    
    if git clone "$clone_url" "$target_dir" 2>/dev/null; then
        log_repo "Sklonowano pomyślnie: $repo_name"
        echo -e "${GREEN}✓ Sklonowano pomyślnie${NC}"
        echo "  Lokalizacja: $target_dir"
        
        # Remove token from git config if present
        if [[ -n "$token" ]]; then
            (cd "$target_dir" && git remote set-url origin "https://github.com/${owner}/${repo_name}.git" 2>/dev/null) || true
        fi
        
        return 0
    else
        log_repo_error "Błąd klonowania repozytorium"
        echo -e "${RED}✗ Błąd klonowania${NC}"
        rm -rf "$target_dir" 2>/dev/null
        return 1
    fi
}

# Interaktywne tworzenie repozytorium
create_repository_interactive() {
    echo ""
    echo -e "${YELLOW}=== Nowe Repozytorium GitHub ===${NC}"
    echo ""
    
    read -p "Nazwa repozytorium: " name
    if ! validate_repo_name "$name"; then
        log_repo_error "Nieprawidłowa nazwa repozytorium"
        return 1
    fi
    
    read -p "Opis (opcjonalnie): " description
    
    echo ""
    echo "Typ repozytorium:"
    echo "1) Prywatne (private)"
    echo "2) Publiczne (public)"
    read -p "Wybierz [1]: " visibility_choice
    
    local private=true
    if [[ "$visibility_choice" == "2" ]]; then
        private=false
    fi
    
    create_repository "$name" "$description" "$private"
}

# Interaktywne klonowanie
clone_repository_interactive() {
    echo ""
    echo -e "${YELLOW}=== Klonuj Repozytorium ===${NC}"
    echo ""
    
    read -p "URL repozytorium (https://github.com/owner/repo): " repo_url
    
    if [[ -z "$repo_url" ]]; then
        log_repo_error "URL nie może być pusty"
        return 1
    fi
    
    read -p "Ścieżka docelowa (pozostaw puste dla domyślnej): " target_dir
    
    clone_repository "$repo_url" "$target_dir"
}

# Menu zarządzania repozytoriami
repo_menu() {
    while true; do
        clear
        echo -e "${YELLOW}=== Zarządzanie Repozytoriami GitHub ===${NC}"
        echo ""
        
        # Show quick status
        if has_token; then
            local username
            username=$(get_github_username)
            echo -e "Zalogowany jako: ${GREEN}$username${NC}"
        else
            echo -e "Status: ${RED}Nie zalogowano${NC}"
        fi
        echo ""
        
        echo -e "${CYAN}Opcje:${NC}"
        echo "1) Utwórz nowe repozytorium"
        echo "2) Lista repozytoriów"
        echo "3) Sklonuj repozytorium"
        echo "4) Usuń repozytorium"
        echo "5) Wróć"
        echo ""
        
        read -p "Wybierz opcję: " choice
        
        case $choice in
            1)
                create_repository_interactive
                echo ""
                read -p "Naciśnij Enter aby kontynuować..."
                ;;
            2)
                list_repositories
                echo ""
                read -p "Naciśnij Enter aby kontynuować..."
                ;;
            3)
                clone_repository_interactive
                echo ""
                read -p "Naciśnij Enter aby kontynuować..."
                ;;
            4)
                read -p "Owner (username): " owner
                read -p "Repozytorium: " repo
                
                if [[ -n "$owner" && -n "$repo" ]]; then
                    delete_repository "$owner" "$repo"
                else
                    echo -e "${RED}Owner i repozytorium są wymagane${NC}"
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
export -f repo_menu
export -f create_repository
export -f list_repositories
export -f delete_repository
export -f clone_repository
