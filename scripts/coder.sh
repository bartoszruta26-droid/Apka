#!/bin/bash

#===============================================================================
# QWEN CODER - CODE GENERATION MODULE
# Integracja z lokalnym modelem Qwen Coder do generowania kodu
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# Konfiguracja i zmienne
#-------------------------------------------------------------------------------
readonly CODER_VERSION="1.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_FILE="${HOME}/.qwen_tam_config"
readonly LOG_DIR="${SCRIPT_DIR}/../logs"
readonly WORK_DIR="${SCRIPT_DIR}/../projects"
readonly QWEN_API_ENDPOINT="${QWEN_API_ENDPOINT:-http://localhost:11434/api/generate}"
readonly QWEN_MODEL="${QWEN_MODEL:-qwen-coder:latest}"

# Kolory ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
readonly PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Zmienne sesji
DEBUG_MODE=false
VERBOSE_MODE=false
CONTEXT_HISTORY=()
MAX_CONTEXT_SIZE=10

#-------------------------------------------------------------------------------
# Funkcje logowania
#-------------------------------------------------------------------------------

log_info() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[INFO]${NC} $timestamp - $*"
    [[ -d "$LOG_DIR" ]] && echo "[INFO] $timestamp - $*" >> "${LOG_DIR}/app.log"
}

log_debug() {
    if [[ "$DEBUG_MODE" == true ]]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo -e "${CYAN}[DEBUG]${NC} $timestamp - $*" >&2
        [[ -d "$LOG_DIR" ]] && echo "[DEBUG] $timestamp - $*" >> "${LOG_DIR}/debug.log"
    fi
}

log_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[ERROR]${NC} $timestamp - $*" >&2
    [[ -d "$LOG_DIR" ]] && echo "[ERROR] $timestamp - $*" >> "${LOG_DIR}/app.log"
}

log_event() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    [[ -d "$LOG_DIR" ]] && echo "[EVENT] $timestamp - $*" >> "${LOG_DIR}/events.log"
}

#-------------------------------------------------------------------------------
# Funkcje pomocnicze
#-------------------------------------------------------------------------------

clear_screen() { clear; }

show_header() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║           QWEN CODER - CODE GENERATION v${CODER_VERSION}          ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

wait_for_enter() {
    read -rp "Press Enter to continue..."
}

validate_file_path() {
    local path="$1"
    local base_dir=$(dirname "$path")
    
    # Sprawdź czy ścieżka nie wychodzi poza dozwolone katalogi
    if [[ ! "$path" =~ ^(/|~/|\.) ]]; then
        return 1
    fi
    
    # Sprawdź czy nie ma niebezpiecznych znaków
    if [[ "$path" =~ [\;\|\&\$\`] ]]; then
        return 1
    fi
    
    return 0
}

get_language_extension() {
    case "$1" in
        markdown|md) echo ".md" ;;
        bash|shell|sh) echo ".sh" ;;
        python|py) echo ".py" ;;
        javascript|js|node) echo ".js" ;;
        html) echo ".html" ;;
        css) echo ".css" ;;
        typescript|ts) echo ".ts" ;;
        json) echo ".json" ;;
        yaml|yml) echo ".yaml" ;;
        c) echo ".c" ;;
        cpp|cxx) echo ".cpp" ;;
        java) echo ".java" ;;
        go|golang) echo ".go" ;;
        rust) echo ".rs" ;;
        php) echo ".php" ;;
        ruby|rb) echo ".rb" ;;
        *) echo ".txt" ;;
    esac
}

#-------------------------------------------------------------------------------
# Komunikacja z Qwen Coder API
#-------------------------------------------------------------------------------

check_qwen_availability() {
    log_debug "Checking Qwen Coder availability at $QWEN_API_ENDPOINT"
    
    if command -v curl &> /dev/null; then
        if curl -s --connect-timeout 5 "$QWEN_API_ENDPOINT" > /dev/null 2>&1; then
            log_debug "Qwen Coder is available"
            return 0
        fi
    fi
    
    log_debug "Qwen Coder is not available, using mock mode"
    return 1
}

call_qwen_coder() {
    local prompt="$1"
    local language="$2"
    local context="${3:-}"
    local response=""
    
    log_debug "Calling Qwen Coder with prompt: ${prompt:0:50}..."
    
    # Sprawdź dostępność API
    if check_qwen_availability; then
        # Budowanie payloadu JSON
        local json_payload
        json_payload=$(cat <<EOF
{
    "model": "$QWEN_MODEL",
    "prompt": "You are an expert programmer. Generate $language code based on this request: $prompt\n\nContext: $context",
    "stream": false,
    "options": {
        "temperature": 0.7,
        "top_p": 0.9,
        "num_predict": 2048
    }
}
EOF
)
        
        # Wysyłanie żądania API
        response=$(curl -s -X POST "$QWEN_API_ENDPOINT" \
            -H "Content-Type: application/json" \
            -d "$json_payload" 2>/dev/null || echo "")
        
        if [[ -n "$response" ]]; then
            # Parsowanie odpowiedzi (zależne od formatu API)
            if command -v jq &> /dev/null; then
                response=$(echo "$response" | jq -r '.response // .text // empty' 2>/dev/null || echo "$response")
            fi
        fi
    fi
    
    # Jeśli brak odpowiedzi z API, użyj trybu mock/demo
    if [[ -z "$response" ]]; then
        log_info "Using demo mode (Qwen API not available)"
        response=$(generate_mock_code "$prompt" "$language")
    fi
    
    echo "$response"
}

generate_mock_code() {
    local prompt="$1"
    local language="$2"
    
    case "$language" in
        markdown|md)
            cat << 'MARKDOWN'
# Project Documentation

## Overview
This is a generated documentation file.

## Features
- Feature 1: Description here
- Feature 2: Description here

## Installation
```bash
./install.sh
```

## Usage
```bash
./script.sh --option value
```

## License
MIT License
MARKDOWN
            ;;
        bash|shell|sh)
            cat << 'BASH'
#!/bin/bash
# Generated shell script

set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

log_info() {
    echo "[INFO] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

main() {
    log_info "Starting $SCRIPT_NAME"
    
    # Your code here
    echo "Hello from generated script!"
    
    log_info "Completed successfully"
}

main "$@"
BASH
            ;;
        python|py)
            cat << 'PYTHON'
#!/usr/bin/env python3
"""Generated Python script."""

import sys
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def main():
    """Main function."""
    logging.info("Starting script")
    
    # Your code here
    print("Hello from generated script!")
    
    logging.info("Completed successfully")

if __name__ == "__main__":
    main()
PYTHON
            ;;
        javascript|js)
            cat << 'JAVASCRIPT'
/**
 * Generated JavaScript file
 */

const log = {
    info: (msg) => console.log(`[INFO] ${msg}`),
    error: (msg) => console.error(`[ERROR] ${msg}`)
};

function main() {
    log.info('Starting application');
    
    // Your code here
    console.log('Hello from generated script!');
    
    log.info('Completed successfully');
}

main();
JAVASCRIPT
            ;;
        html)
            cat << 'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Generated Page</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #333; }
    </style>
</head>
<body>
    <h1>Welcome</h1>
    <p>This is a generated HTML page.</p>
</body>
</html>
HTML
            ;;
        *)
            echo "# Generated file for $language"
            echo "# Prompt: $prompt"
            echo ""
            echo "// Add your code here"
            ;;
    esac
}

#-------------------------------------------------------------------------------
# Funkcje generowania kodu
#-------------------------------------------------------------------------------

generate_markdown() {
    show_header
    echo -e "${CYAN}Generate Markdown Documentation${NC}"
    echo ""
    
    read -rp "Enter document title: " title
    read -rp "Enter description/requirements: " description
    read -rp "Output filename (default: README.md): " output_file
    output_file="${output_file:-README.md}"
    
    if ! validate_file_path "$output_file"; then
        log_error "Invalid file path"
        return 1
    fi
    
    local prompt="Create a Markdown document titled '$title'. $description"
    log_info "Generating Markdown documentation..."
    
    local content
    content=$(call_qwen_coder "$prompt" "markdown" "")
    
    # Zapis do pliku
    mkdir -p "$(dirname "$output_file")"
    echo "$content" > "$output_file"
    
    log_info "Markdown saved to: $output_file"
    log_event "Generated Markdown: $output_file"
    
    # Podgląd
    echo ""
    echo -e "${GREEN}Preview:${NC}"
    head -20 "$output_file"
    echo "..."
    
    wait_for_enter
}

generate_source_code() {
    show_header
    echo -e "${CYAN}Generate Source Code${NC}"
    echo ""
    
    echo "Select language:"
    echo "1) Python"
    echo "2) Bash/Shell"
    echo "3) JavaScript"
    echo "4) C/C++"
    echo "5) Java"
    echo "6) Go"
    echo "7) Rust"
    echo "8) Other"
    read -rp "Choice [1-8]: " lang_choice
    
    local language
    case $lang_choice in
        1) language="python" ;;
        2) language="bash" ;;
        3) language="javascript" ;;
        4) language="cpp" ;;
        5) language="java" ;;
        6) language="go" ;;
        7) language="rust" ;;
        8) read -rp "Enter language: " language ;;
        *) log_error "Invalid choice"; return 1 ;;
    esac
    
    read -rp "Describe what the code should do: " description
    read -rp "Output filename: " output_file
    
    if [[ -z "$output_file" ]]; then
        local ext=$(get_language_extension "$language")
        output_file="generated_${RANDOM}${ext}"
    fi
    
    if ! validate_file_path "$output_file"; then
        log_error "Invalid file path"
        return 1
    fi
    
    log_info "Generating $language code..."
    
    local content
    content=$(call_qwen_coder "$description" "$language" "")
    
    mkdir -p "$(dirname "$output_file")"
    echo "$content" > "$output_file"
    
    log_info "Code saved to: $output_file"
    log_event "Generated $language code: $output_file"
    
    # Sprawdzenie składni (opcjonalne)
    if [[ "$language" == "bash" ]]; then
        if bash -n "$output_file" 2>/dev/null; then
            echo -e "${GREEN}✓ Syntax check passed${NC}"
        else
            echo -e "${YELLOW}⚠ Syntax warnings detected${NC}"
        fi
    elif [[ "$language" == "python" ]]; then
        if python3 -m py_compile "$output_file" 2>/dev/null; then
            echo -e "${GREEN}✓ Syntax check passed${NC}"
        else
            echo -e "${YELLOW}⚠ Syntax warnings detected${NC}"
        fi
    fi
    
    wait_for_enter
}

generate_shell_scripts() {
    show_header
    echo -e "${CYAN}Generate Shell Scripts${NC}"
    echo ""
    
    read -rp "Describe the shell script functionality: " description
    read -rp "Script name (default: script.sh): " script_name
    script_name="${script_name:-script.sh}"
    
    # Dodaj rozszerzenie jeśli brak
    [[ ! "$script_name" =~ \.sh$ ]] && script_name="${script_name}.sh"
    
    if ! validate_file_path "$script_name"; then
        log_error "Invalid file path"
        return 1
    fi
    
    log_info "Generating shell script..."
    
    local content
    content=$(call_qwen_coder "$description" "bash" "")
    
    mkdir -p "$(dirname "$script_name")"
    echo "$content" > "$script_name"
    chmod +x "$script_name"
    
    log_info "Shell script saved to: $script_name (executable)"
    log_event "Generated shell script: $script_name"
    
    wait_for_enter
}

generate_python_scripts() {
    show_header
    echo -e "${CYAN}Generate Python Scripts${NC}"
    echo ""
    
    read -rp "Describe the Python script functionality: " description
    read -rp "Script name (default: script.py): " script_name
    script_name="${script_name:-script.py}"
    
    [[ ! "$script_name" =~ \.py$ ]] && script_name="${script_name}.py"
    
    if ! validate_file_path "$script_name"; then
        log_error "Invalid file path"
        return 1
    fi
    
    log_info "Generating Python script..."
    
    local content
    content=$(call_qwen_coder "$description" "python" "")
    
    mkdir -p "$(dirname "$script_name")"
    echo "$content" > "$script_name"
    chmod +x "$script_name"
    
    log_info "Python script saved to: $script_name"
    log_event "Generated Python script: $script_name"
    
    wait_for_enter
}

generate_web_files() {
    show_header
    echo -e "${CYAN}Generate Web Files (HTML/CSS/JS)${NC}"
    echo ""
    
    echo "Select file type:"
    echo "1) HTML"
    echo "2) CSS"
    echo "3) JavaScript"
    echo "4) Complete set (HTML+CSS+JS)"
    read -rp "Choice [1-4]: " file_type
    
    read -rp "Describe the web page/component: " description
    read -rp "Base filename (without extension): " base_name
    base_name="${base_name:-index}"
    
    case $file_type in
        1)
            local content
            content=$(call_qwen_coder "$description" "html" "")
            echo "$content" > "${base_name}.html"
            log_info "HTML saved to: ${base_name}.html"
            ;;
        2)
            local content
            content=$(call_qwen_coder "$description" "css" "")
            echo "$content" > "${base_name}.css"
            log_info "CSS saved to: ${base_name}.css"
            ;;
        3)
            local content
            content=$(call_qwen_coder "$description" "javascript" "")
            echo "$content" > "${base_name}.js"
            log_info "JavaScript saved to: ${base_name}.js"
            ;;
        4)
            log_info "Generating complete web files..."
            
            local html_content=$(call_qwen_coder "$description - create HTML structure" "html" "")
            local css_content=$(call_qwen_coder "$description - create CSS styles" "css" "")
            local js_content=$(call_qwen_coder "$description - create JavaScript functionality" "javascript" "")
            
            echo "$html_content" > "${base_name}.html"
            echo "$css_content" > "${base_name}.css"
            echo "$js_content" > "${base_name}.js"
            
            log_info "Web files created: ${base_name}.html, ${base_name}.css, ${base_name}.js"
            ;;
        *)
            log_error "Invalid choice"
            return 1
            ;;
    esac
    
    log_event "Generated web files: $base_name"
    wait_for_enter
}

create_project_structure() {
    show_header
    echo -e "${CYAN}Create Project Structure${NC}"
    echo ""
    
    read -rp "Project name: " project_name
    read -rp "Project type (web/python/node/mixed): " project_type
    project_type="${project_type:-mixed}"
    
    local project_dir="${WORK_DIR}/${project_name}"
    
    log_info "Creating project structure for: $project_name"
    
    mkdir -p "$project_dir"
    
    case $project_type in
        web)
            mkdir -p "$project_dir"/{css,js,images,templates}
            touch "$project_dir/index.html"
            touch "$project_dir/css/style.css"
            touch "$project_dir/js/app.js"
            touch "$project_dir/README.md"
            ;;
        python)
            mkdir -p "$project_dir"/{src,tests,data,docs}
            touch "$project_dir/src/__init__.py"
            touch "$project_dir/tests/__init__.py"
            touch "$project_dir/requirements.txt"
            touch "$project_dir/setup.py"
            touch "$project_dir/README.md"
            ;;
        node)
            mkdir -p "$project_dir"/{src,test,public}
            echo '{"name":"'"$project_name"'","version":"1.0.0","main":"src/index.js"}' > "$project_dir/package.json"
            touch "$project_dir/src/index.js"
            touch "$project_dir/README.md"
            ;;
        mixed|*)
            mkdir -p "$project_dir"/{src,lib,tests,docs,config,data}
            touch "$project_dir/README.md"
            touch "$project_dir/.gitignore"
            cat > "$project_dir/.gitignore" << 'GITIGNORE'
__pycache__/
*.py[cod]
node_modules/
.env
*.log
.DS_Store
GITIGNORE
            ;;
    esac
    
    # Generuj README
    local readme_content=$(call_qwen_coder "Create README for $project_name - a $project_type project" "markdown" "")
    echo "$readme_content" > "$project_dir/README.md"
    
    log_info "Project structure created in: $project_dir"
    log_event "Created project: $project_name"
    
    # Wyświetl strukturę
    echo ""
    echo -e "${GREEN}Project structure:${NC}"
    find "$project_dir" -type f | sort | sed "s|$project_dir||"
    
    wait_for_enter
}

edit_existing_file() {
    show_header
    echo -e "${CYAN}Edit Existing File with AI${NC}"
    echo ""
    
    read -rp "Enter path to existing file: " file_path
    
    if [[ ! -f "$file_path" ]]; then
        log_error "File not found: $file_path"
        wait_for_enter
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}Current content:${NC}"
    cat "$file_path"
    echo ""
    
    read -rp "Describe changes to make: " changes_desc
    
    local current_content=$(cat "$file_path")
    local prompt="Modify this code: $changes_desc. Current code: $current_content"
    
    log_info "Applying AI edits..."
    
    local new_content
    new_content=$(call_qwen_coder "$prompt" "code" "$current_content")
    
    # Backup przed edycją
    cp "$file_path" "${file_path}.bak.$(date +%Y%m%d%H%M%S)"
    
    echo "$new_content" > "$file_path"
    
    log_info "File updated: $file_path"
    log_event "AI-edited file: $file_path"
    
    echo ""
    echo -e "${GREEN}Updated content:${NC}"
    cat "$file_path"
    
    wait_for_enter
}

#-------------------------------------------------------------------------------
# C/C++/C# Code with GUI Generation
#-------------------------------------------------------------------------------

generate_cpp_gui_code() {
    show_header
    echo -e "${CYAN}Create/Update C/C++/C# Code with GUI${NC}"
    echo ""
    
    echo "Select language:"
    echo "1) C with GTK"
    echo "2) C++ with Qt"
    echo "3) C# with WinForms/WPF"
    read -rp "Choice [1-3]: " lang_choice
    
    local language=""
    local framework=""
    case $lang_choice in
        1) language="c"; framework="GTK" ;;
        2) language="cpp"; framework="Qt" ;;
        3) language="csharp"; framework="WinForms" ;;
        *) log_error "Invalid choice"; wait_for_enter; return 1 ;;
    esac
    
    read -rp "Describe the GUI application functionality: " description
    read -rp "Output filename (without extension): " base_name
    base_name="${base_name:-app}"
    
    log_info "Generating $language code with $framework GUI..."
    
    local content
    content=$(call_qwen_coder "Create a $language GUI application using $framework. $description" "$language" "")
    
    local ext=""
    case $language in
        c) ext=".c" ;;
        cpp) ext=".cpp" ;;
        csharp) ext=".cs" ;;
    esac
    
    mkdir -p "$(dirname "$base_name")"
    echo "$content" > "${base_name}${ext}"
    
    log_info "GUI code saved to: ${base_name}${ext}"
    log_event "Generated $language GUI code: ${base_name}${ext}"
    
    wait_for_enter
}

#-------------------------------------------------------------------------------
# WebUI Script Generation
#-------------------------------------------------------------------------------

generate_webui_scripts() {
    show_header
    echo -e "${CYAN}Create/Update WebUI Script${NC}"
    echo ""
    
    echo "Select WebUI type:"
    echo "1) React Component"
    echo "2) Vue.js Component"
    echo "3) Angular Component"
    echo "4) Plain HTML/CSS/JS"
    echo "5) Svelte Component"
    read -rp "Choice [1-5]: " webui_choice
    
    local framework=""
    case $webui_choice in
        1) framework="React" ;;
        2) framework="Vue.js" ;;
        3) framework="Angular" ;;
        4) framework="Plain" ;;
        5) framework="Svelte" ;;
        *) log_error "Invalid choice"; wait_for_enter; return 1 ;;
    esac
    
    read -rp "Describe the WebUI component/page: " description
    read -rp "Component name: " component_name
    component_name="${component_name:-Component}"
    
    log_info "Generating $framework WebUI component..."
    
    local content
    content=$(call_qwen_coder "Create a $framework WebUI component. $description" "javascript" "")
    
    local ext=".jsx"
    [[ "$framework" == "Vue.js" ]] && ext=".vue"
    [[ "$framework" == "Angular" ]] && ext=".ts"
    [[ "$framework" == "Svelte" ]] && ext=".svelte"
    [[ "$framework" == "Plain" ]] && ext=".html"
    
    mkdir -p "$(dirname "$component_name")"
    echo "$content" > "${component_name}${ext}"
    
    log_info "WebUI component saved to: ${component_name}${ext}"
    log_event "Generated $framework WebUI: ${component_name}${ext}"
    
    wait_for_enter
}

#-------------------------------------------------------------------------------
# Android App Creation
#-------------------------------------------------------------------------------

create_android_app() {
    show_header
    echo -e "${CYAN}Create/Update Android App${NC}"
    echo ""
    
    echo "Select project type:"
    echo "1) Native Android (Kotlin)"
    echo "2) Native Android (Java)"
    echo "3) Flutter (Dart)"
    echo "4) React Native"
    read -rp "Choice [1-4]: " android_choice
    
    local platform=""
    case $android_choice in
        1) platform="Kotlin" ;;
        2) platform="Java" ;;
        3) platform="Flutter" ;;
        4) platform="ReactNative" ;;
        *) log_error "Invalid choice"; wait_for_enter; return 1 ;;
    esac
    
    read -rp "App name: " app_name
    app_name="${app_name:-MyApp}"
    read -rp "Describe app functionality: " description
    
    local app_dir="${WORK_DIR}/${app_name}"
    
    log_info "Creating $platform Android app: $app_name"
    
    mkdir -p "$app_dir"
    
    # Generate basic structure based on platform
    case $platform in
        Kotlin|Java)
            mkdir -p "$app_dir"/{app/src/main/{java/com/example/${app_name,,},res/{layout,values,drawable}},gradle/wrapper}
            touch "$app_dir/app/build.gradle"
            touch "$app_dir/build.gradle"
            touch "$app_dir/settings.gradle"
            touch "$app_dir/gradle.properties"
            touch "$app_dir/README.md"
            ;;
        Flutter)
            mkdir -p "$app_dir"/{lib,test,android,ios,pub}
            touch "$app_dir/lib/main.dart"
            touch "$app_dir/pubspec.yaml"
            touch "$app_dir/README.md"
            ;;
        ReactNative)
            mkdir -p "$app_dir"/{src,android,ios,__tests__}
            touch "$app_dir/App.js"
            touch "$app_dir/package.json"
            touch "$app_dir/README.md"
            ;;
    esac
    
    # Generate main code file
    local main_prompt="Create a basic $platform Android app structure for: $description"
    local main_content
    main_content=$(call_qwen_coder "$main_prompt" "$platform" "")
    
    case $platform in
        Kotlin) echo "$main_content" > "$app_dir/app/src/main/java/com/example/${app_name,,}/MainActivity.kt" ;;
        Java) echo "$main_content" > "$app_dir/app/src/main/java/com/example/${app_name,,}/MainActivity.java" ;;
        Flutter) echo "$main_content" > "$app_dir/lib/main.dart" ;;
        ReactNative) echo "$main_content" > "$app_dir/App.js" ;;
    esac
    
    log_info "Android app created: $app_dir"
    log_event "Created $platform Android app: $app_name"
    
    echo ""
    echo -e "${GREEN}Project structure created at: $app_dir${NC}"
    
    wait_for_enter
}

#-------------------------------------------------------------------------------
# Menu główne modułu Coder
#-------------------------------------------------------------------------------

show_coder_menu() {
    while true; do
        clear_screen
        show_header
        echo -e "${YELLOW}Select option:${NC}"
        echo "  1) 📁 Create/Update Project Structure"
        echo "  2) 📜 Create/Update Shell Script"
        echo "  3) 💻 Create/Update C/C#/C++ Code with GUI"
        echo "  4) 🌐 Create/Update WebUI Script"
        echo "  5) 📱 Create/Update Android App"
        echo "  6) ✏️  Edit Existing File with AI"
        echo "  7) ⬅️  Back to Main Menu"
        echo ""
        
        read -rp "  Choice [1-7]: " choice
        
        case $choice in
            1) create_project_structure ;;
            2) generate_shell_scripts ;;
            3) generate_cpp_gui_code ;;
            4) generate_webui_scripts ;;
            5) create_android_app ;;
            6) edit_existing_file ;;
            7) break ;;
            *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# Obsługa argumentów CLI
#-------------------------------------------------------------------------------

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --project)
                shift
                create_project_cli "$@"
                exit 0
                ;;
            --shell)
                shift
                generate_shell_cli "$@"
                exit 0
                ;;
            --cpp-gui)
                shift
                generate_cpp_gui_cli "$@"
                exit 0
                ;;
            --webui)
                shift
                generate_webui_cli "$@"
                exit 0
                ;;
            --android)
                shift
                create_android_cli "$@"
                exit 0
                ;;
            --edit)
                shift
                edit_file_cli "$@"
                exit 0
                ;;
            --debug)
                DEBUG_MODE=true
                shift
                ;;
            --verbose)
                VERBOSE_MODE=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --project NAME TYPE     Create project structure"
                echo "  --shell DESC FILE       Generate shell script"
                echo "  --cpp-gui LANG DESC     Generate C/C++/C# GUI code"
                echo "  --webui TYPE DESC NAME  Generate WebUI component"
                echo "  --android TYPE NAME DESC Create Android app"
                echo "  --edit FILE CHANGES     Edit file with AI"
                echo "  --debug                 Enable debug mode"
                echo "  --verbose               Enable verbose output"
                echo "  --help, -h              Show this help"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

generate_shell_cli() {
    local desc="$1"
    local file="${2:-script.sh}"
    
    local content=$(call_qwen_coder "$desc" "bash" "")
    
    mkdir -p "$(dirname "$file")"
    echo "$content" > "$file"
    chmod +x "$file"
    log_info "Shell script generated: $file"
}

generate_cpp_gui_cli() {
    local lang="$1"
    local desc="$2"
    local file="${3:-app}"
    
    local framework=""
    case "$lang" in
        c) framework="GTK" ;;
        cpp|c++) framework="Qt" ;;
        csharp|cs) framework="WinForms" ;;
        *) framework="Qt" ;;
    esac
    
    local content=$(call_qwen_coder "Create a $lang GUI application using $framework. $desc" "$lang" "")
    
    local ext=""
    case "$lang" in
        c) ext=".c" ;;
        cpp|c++) ext=".cpp" ;;
        csharp|cs) ext=".cs" ;;
        *) ext=".cpp" ;;
    esac
    
    mkdir -p "$(dirname "$file")"
    echo "$content" > "${file}${ext}"
    log_info "GUI code generated: ${file}${ext}"
}

generate_webui_cli() {
    local type="$1"
    local desc="$2"
    local name="${3:-Component}"
    
    local ext=".jsx"
    case "$type" in
        react|React) ext=".jsx" ;;
        vue|Vue.js) ext=".vue" ;;
        angular|Angular) ext=".ts" ;;
        svelte|Svelte) ext=".svelte" ;;
        plain|Plain) ext=".html" ;;
    esac
    
    local content=$(call_qwen_coder "Create a $type WebUI component. $desc" "javascript" "")
    
    mkdir -p "$(dirname "$name")"
    echo "$content" > "${name}${ext}"
    log_info "WebUI component generated: ${name}${ext}"
}

create_android_cli() {
    local type="$1"
    local name="${2:-MyApp}"
    local desc="${3:-Android app}"
    
    local app_dir="${WORK_DIR}/${name}"
    mkdir -p "$app_dir"
    
    case "$type" in
        kotlin|Kotlin)
            mkdir -p "$app_dir"/{app/src/main/java,gradle/wrapper}
            touch "$app_dir/app/build.gradle"
            touch "$app_dir/README.md"
            ;;
        java|Java)
            mkdir -p "$app_dir"/{app/src/main/java,gradle/wrapper}
            touch "$app_dir/app/build.gradle"
            touch "$app_dir/README.md"
            ;;
        flutter|Flutter)
            mkdir -p "$app_dir"/{lib,test}
            touch "$app_dir/lib/main.dart"
            touch "$app_dir/pubspec.yaml"
            touch "$app_dir/README.md"
            ;;
        reactnative|ReactNative)
            mkdir -p "$app_dir"/{src,__tests__}
            touch "$app_dir/App.js"
            touch "$app_dir/package.json"
            touch "$app_dir/README.md"
            ;;
    esac
    
    log_info "Android app project created: $app_dir"
}

create_project_cli() {
    local name="$1"
    local type="${2:-mixed}"
    
    local project_dir="${WORK_DIR}/${name}"
    mkdir -p "$project_dir"
    
    # Uproszczona wersja create_project_structure
    mkdir -p "$project_dir"/{src,tests,docs}
    touch "$project_dir/README.md"
    
    log_info "Project created: $project_dir"
}

edit_file_cli() {
    local file="$1"
    local changes="$2"
    
    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        exit 1
    fi
    
    local content=$(cat "$file")
    local prompt="Modify this code: $changes. Current code: $content"
    local new_content=$(call_qwen_coder "$prompt" "code" "$content")
    
    cp "$file" "${file}.bak"
    echo "$new_content" > "$file"
    log_info "File edited: $file"
}

#-------------------------------------------------------------------------------
# Punkt wejścia
#-------------------------------------------------------------------------------

main() {
    # Inicjalizacja
    mkdir -p "$LOG_DIR" "$WORK_DIR"
    
    # Sprawdź czy wywołano z argumentami (tryb CLI)
    if [[ $# -gt 0 ]]; then
        parse_arguments "$@"
    else
        # Tryb interaktywny
        log_info "Starting Qwen Coder module"
        log_event "Coder module started"
        show_coder_menu
    fi
}

# Uruchomienie
main "$@"
