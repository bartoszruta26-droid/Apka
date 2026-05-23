#!/bin/bash

# repo.sh - Tworzenie i zarządzanie repozytoriami GitHub
# Część Qwen Time & Automation Manager

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/qwen-tam.log"
REPO_DIR="$HOME/Projects/qwen-tam/repos"

# Źródło skryptu auth.sh
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
}

# Pobranie nagłówków autoryzacyjnych
get_auth_headers() {
    local token
    token=$(get_github_token)
    if [[ -n "$token" ]]; then
        token=$(echo "$token" | base64 -d)
        echo "-H \"Authorization: token $token\""
    fi
}

# Walidacja nazwy repozytorium
validate_repo_name() {
    local name="$1"
    
    # Sprawdzenie czy nazwa nie jest pusta
    if [[ -z "$name" ]]; then
        return 1
    fi
    
    # Sprawdzenie długości (max 100 znaków)
    if [[ ${#name} -gt 100 ]]; then
        return 1
    fi
    
    # Dozwolone znaki: litery, cyfry, -, _, .
    if [[ ! "$name" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        return 1
    fi
    
    return 0
}

# Tworzenie nowego repozytorium GitHub
create_github_repo() {
    local repo_name="$1"
    local description="${2:-}"
    local is_private="${3:-false}"
    local init_readme="${4:-false}"
    local license="${5:-}"
    local gitignore="${6:-}"
    
    # Sprawdzenie autoryzacji
    if ! has_token; then
        log_repo_error "Brak autoryzacji GitHub. Skonfiguruj token w menu Configuration."
        return 1
    fi
    
    # Walidacja nazwy
    if ! validate_repo_name "$repo_name"; then
        log_repo_error "Nieprawidłowa nazwa repozytorium: $repo_name"
        echo "Nazwa może zawierać tylko litery, cyfry, myślniki, podkreślenia i kropki."
        return 1
    fi
    
    local token
    token=$(get_github_token)
    token=$(echo "$token" | base64 -d)
    
    # Budowanie payloadu JSON
    local json_data="{\"name\":\"$repo_name\""
    
    if [[ -n "$description" ]]; then
        json_data+=",\"description\":\"$description\""
    fi
    
    json_data+=",\"private\":$is_private"
    json_data+=",\"auto_init\":$init_readme"
    
    if [[ -n "$license" ]]; then
        json_data+=",\"license_template\":\"$license\""
    fi
    
    if [[ -n "$gitignore" ]]; then
        json_data+=",\"gitignore_template\":\"$gitignore\""
    fi
    
    json_data+="}"
    
    log_repo "Tworzenie repozytorium: $repo_name"
    
    # Wysyłanie żądania API
    local response
    response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Content-Type: application/json" \
        -d "$json_data" \
        "https://api.github.com/user/repos")
    
    local http_code
    http_code=$(echo "$response" | tail -n1)
    local body
    body=$(echo "$response" | sed '$d')
    
    if [[ "$http_code" == "201" ]]; then
        local repo_url
        repo_url=$(echo "$body" | jq -r '.html_url')
        log_repo "Repozytorium utworzone pomyślnie: $repo_url"
        echo -e "${GREEN}✓ Repozytorium utworzone:${NC} $repo_url"
        
        # Klonowanie lokalnie jeśli użytkownik chce
        read -p "Czy chcesz sklonować repozytorium lokalnie? (y/n): " clone_choice
        if [[ "$clone_choice" =~ ^[Yy]$ ]]; then
            clone_repository "$repo_url"
        fi
        
        return 0
    else
        local error_msg
        error_msg=$(echo "$body" | jq -r '.message // "Nieznany błąd"')
        log_repo_error "Błąd tworzenia repozytorium: $error_msg (HTTP $http_code)"
        echo -e "${RED}✗ Błąd:${NC} $error_msg"
        return 1
    fi
}

# Interaktywne tworzenie repozytorium
create_repo_interactive() {
    echo ""
    echo -e "${CYAN}=== Nowe Repozytorium GitHub ===${NC}"
    echo ""
    
    read -p "Nazwa repozytorium: " repo_name
    if ! validate_repo_name "$repo_name"; then
        log_repo_error "Nieprawidłowa nazwa"
        return 1
    fi
    
    read -p "Opis (opcjonalne): " description
    
    echo ""
    echo "Widoczność:"
    echo "1) Prywatne (private)"
    echo "2) Publiczne (public)"
    read -p "Wybierz [1/2]: " visibility_choice
    
    local is_private=true
    if [[ "$visibility_choice" == "2" ]]; then
        is_private=false
    fi
    
    echo ""
    read -p "Zainicjalizować README.md? (y/n): " init_readme_choice
    local init_readme=false
    if [[ "$init_readme_choice" =~ ^[Yy]$ ]]; then
        init_readme=true
    fi
    
    local license=""
    if [[ "$init_readme" == "true" ]]; then
        echo ""
        echo "Licencja (opcjonalne):"
        echo "1) MIT"
        echo "2) GPL-3.0"
        echo "3) Apache-2.0"
        echo "4) Brak licencji"
        read -p "Wybierz [1-4]: " license_choice
        
        case $license_choice in
            1) license="mit" ;;
            2) license="gpl-3.0" ;;
            3) license="apache-2.0" ;;
            *) license="" ;;
        esac
    fi
    
    local gitignore=""
    echo ""
    echo "Gitignore (opcjonalne):"
    echo "1) Python"
    echo "2) Node.js"
    echo "3) Java"
    echo "4) Go"
    echo "5) Brak gitignore"
    read -p "Wybierz [1-5]: " gitignore_choice
    
    case $gitignore_choice in
        1) gitignore="Python" ;;
        2) gitignore="Node" ;;
        3) gitignore="Java" ;;
        4) gitignore="Go" ;;
        *) gitignore="" ;;
    esac
    
    echo ""
    echo "Podsumowanie:"
    echo "  Nazwa: $repo_name"
    echo "  Opis: ${description:-brak}"
    echo "  Widoczność: $([ "$is_private" == "true" ] && echo "Prywatne" || echo "Publiczne")"
    echo "  README: $([ "$init_readme" == "true" ] && echo "Tak" || echo "Nie")"
    echo "  Licencja: ${license:-brak}"
    echo "  Gitignore: ${gitignore:-brak}"
    echo ""
    
    read -p "Czy na pewno stworzyć repozytorium? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        create_github_repo "$repo_name" "$description" "$is_private" "$init_readme" "$license" "$gitignore"
        return $?
    else
        echo "Anulowano"
        return 0
    fi
}

# Klonowanie repozytorium
clone_repository() {
    local repo_url="$1"
    local target_dir="${2:-}"
    
    init_repo_dir
    
    if [[ -z "$repo_url" ]]; then
        read -p "URL repozytorium do sklonowania: " repo_url
    fi
    
    if [[ -z "$repo_url" ]]; then
        log_repo_error "Brak URL repozytorium"
        return 1
    fi
    
    # Wyodrębnienie nazwy repozytorium z URL
    local repo_name
    repo_name=$(basename "$repo_url" .git)
    
    if [[ -z "$target_dir" ]]; then
        target_dir="$REPO_DIR/$repo_name"
    fi
    
    if [[ -d "$target_dir" ]]; then
        echo -e "${YELLOW}Katalog już istnieje:${NC} $target_dir"
        read -p "Czy nadpisać? (y/n): " overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            return 0
        fi
        rm -rf "$target_dir"
    fi
    
    log_repo "Klonowanie: $repo_url -> $target_dir"
    echo "Klonowanie repozytorium..."
    
    # Sprawdzenie czy repo wymaga autoryfikacji
    local token
    token=$(get_github_token)
    
    if [[ -n "$token" ]] && [[ "$repo_url" == *"github.com"* ]]; then
        # Wstrzyknięcie tokena do URL dla repozytoriów prywatnych
        token_decoded=$(echo "$token" | base64 -d)
        local username
        username=$(get_github_username)
        local auth_url
        auth_url=$(echo "$repo_url" | sed "s|https://|https://$username:$token_decoded@|")
        git clone "$auth_url" "$target_dir"
    else
        git clone "$repo_url" "$target_dir"
    fi
    
    if [[ $? -eq 0 ]]; then
        log_repo "Sklonowano pomyślnie: $target_dir"
        echo -e "${GREEN}✓ Sklonowano pomyślnie:${NC} $target_dir"
        
        # Wyświetlenie informacji
        cd "$target_dir" && {
            echo ""
            echo "Struktura projektu:"
            ls -la
            echo ""
        }
        cd - > /dev/null
        
        return 0
    else
        log_repo_error "Błąd klonowania"
        echo -e "${RED}✗ Błąd klonowania${NC}"
        return 1
    fi
}

# Lista repozytoriów użytkownika
list_repositories() {
    if ! has_token; then
        log_repo_error "Brak autoryzacji GitHub"
        return 1
    fi
    
    local token
    token=$(get_github_token)
    token=$(echo "$token" | base64 -d)
    
    log_repo "Pobieranie listy repozytoriów"
    echo ""
    echo -e "${CYAN}=== Twoje Repozytoria GitHub ===${NC}"
    echo ""
    
    local repos
    repos=$(curl -s \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/user/repos?sort=updated&per_page=100")
    
    local count
    count=$(echo "$repos" | jq 'length')
    
    if [[ "$count" == "0" ]]; then
        echo "Brak repozytoriów"
        return 0
    fi
    
    printf "%-30s %-15s %-10s %s\n" "NAZWA" "WIDOCZNOŚĆ" "GWIAZDKI" "OPIS"
    printf "%-30s %-15s %-10s %s\n" "------" "-----------" "----------" "----"
    
    echo "$repos" | jq -r '.[] | "\(.name | .[0:28])\t\(.private | if . then "Private" else "Public" end)\t\(.stargazers_count)\t\(.description // "brak" | .[0:40])"' | \
    while IFS=$'\t' read -r name vis stars desc; do
        printf "%-30s %-15s %-10s %s\n" "$name" "$vis" "$stars" "$desc"
    done
    
    echo ""
    echo "Łącznie: $count repozytoriów"
    
    return 0
}

# Usuwanie repozytorium
delete_repository() {
    local owner="$1"
    local repo="$2"
    
    if ! has_token; then
        log_repo_error "Brak autoryzacji GitHub"
        return 1
    fi
    
    if [[ -z "$owner" || -z "$repo" ]]; then
        read -p "Owner (nazwa użytkownika): " owner
        read -p "Nazwa repozytorium: " repo
    fi
    
    if [[ -z "$owner" || -z "$repo" ]]; then
        log_repo_error "Brak wymaganych danych"
        return 1
    fi
    
    echo ""
    echo -e "${RED}⚠️  UWAGA: Ta operacja jest nieodwracalna!${NC}"
    echo "Repozytorium: $owner/$repo"
    echo ""
    read -p "Wpisz \"$repo\" aby potwierdzić usunięcie: " confirm
    
    if [[ "$confirm" != "$repo" ]]; then
        echo "Anulowano"
        return 0
    fi
    
    local token
    token=$(get_github_token)
    token=$(echo "$token" | base64 -d)
    
    log_repo "Usuwanie repozytorium: $owner/$repo"
    
    local response
    response=$(curl -s -w "\n%{http_code}" \
        -X DELETE \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$owner/$repo")
    
    local http_code
    http_code=$(echo "$response" | tail -n1)
    
    if [[ "$http_code" == "204" ]]; then
        log_repo "Repozytorium usunięte: $owner/$repo"
        echo -e "${GREEN}✓ Repozytorium usunięte pomyślnie${NC}"
        return 0
    else
        local body
        body=$(echo "$response" | sed '$d')
        local error_msg
        error_msg=$(echo "$body" | jq -r '.message // "Nieznany błąd"')
        log_repo_error "Błąd usuwania: $error_msg"
        echo -e "${RED}✗ Błąd:${NC} $error_msg"
        return 1
    fi
}

# Synchronizacja lokalna z remote
sync_local_with_remote() {
    local repo_path="$1"
    
    if [[ -z "$repo_path" ]]; then
        echo "Wybierz katalog repozytorium:"
        echo ""
        
        if [[ ! -d "$REPO_DIR" ]] || [[ -z "$(ls -A "$REPO_DIR" 2>/dev/null)" ]]; then
            echo "Brak lokalnych repozytoriów w $REPO_DIR"
            return 1
        fi
        
        local i=1
        local dirs=()
        for dir in "$REPO_DIR"/*/; do
            if [[ -d "$dir/.git" ]]; then
                dirs+=("$dir")
                echo "$i) $(basename "$dir")"
                ((i++))
            fi
        done
        
        if [[ ${#dirs[@]} -eq 0 ]]; then
            echo "Brak repozytoriów Git"
            return 1
        fi
        
        read -p "Wybierz numer: " choice
        if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ $choice -lt 1 ]] || [[ $choice -gt ${#dirs[@]} ]]; then
            echo "Nieprawidłowy wybór"
            return 1
        fi
        
        repo_path="${dirs[$((choice-1))]}"
    fi
    
    if [[ ! -d "$repo_path/.git" ]]; then
        log_repo_error "To nie jest repozytorium Git: $repo_path"
        return 1
    fi
    
    cd "$repo_path" || return 1
    
    log_repo "Synchronizacja: $repo_path"
    echo "Synchronizacja repozytorium..."
    
    # Pobranie zmian
    git fetch --all
    
    # Sprawdzenie aktualnej gałęzi
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    
    # Pull zmian
    echo "Pull zmian z gałęzi: $current_branch"
    git pull origin "$current_branch"
    
    if [[ $? -eq 0 ]]; then
        log_repo "Synchronizacja zakończona sukcesem"
        echo -e "${GREEN}✓ Synchronizacja zakończona${NC}"
        
        # Status repozytorium
        echo ""
        git status --short
        
        cd - > /dev/null
        return 0
    else
        log_repo_error "Błąd synchronizacji"
        echo -e "${RED}✗ Błąd synchronizacji${NC}"
        cd - > /dev/null
        return 1
    fi
}

# Menu zarządzania repozytoriami
repo_menu() {
    while true; do
        clear
        echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║     GITHUB REPOSITORY MANAGEMENT           ║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
        echo ""
        
        # Sprawdzenie statusu autoryzacji
        if has_token; then
            local username
            username=$(get_github_username)
            echo -e "Zalogowany jako: ${GREEN}$username${NC}"
        else
            echo -e "Status: ${RED}Nie zalogowano${NC}"
        fi
        echo ""
        
        echo -e "${YELLOW}Opcje:${NC}"
        echo "1) Skonfiguruj GitHub Credentials"
        echo "2) Utwórz nowe repozytorium"
        echo "3) Lista moich repozytoriów"
        echo "4) Usuń repozytorium"
        echo "5) Sklonuj repozytorium"
        echo "6) Synchronizuj lokalne z remote"
        echo "7) Wróć"
        echo ""
        
        read -p "Wybierz opcję: " choice
        
        case $choice in
            1)
                source "$SCRIPT_DIR/auth.sh"
                auth_menu
                ;;
            2)
                create_repo_interactive
                echo ""
                read -p "Naciśnij Enter aby kontynuować..."
                ;;
            3)
                list_repositories
                echo ""
                read -p "Naciśnij Enter aby kontynuować..."
                ;;
            4)
                delete_repository
                echo ""
                read -p "Naciśnij Enter aby kontynuować..."
                ;;
            5)
                clone_repository
                echo ""
                read -p "Naciśnij Enter aby kontynuować..."
                ;;
            6)
                sync_local_with_remote
                echo ""
                read -p "Naciśnij Enter aby kontynuować..."
                ;;
            7|q|Q)
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
    repo_menu "$@"
fi
