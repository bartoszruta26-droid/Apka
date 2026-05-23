#!/bin/bash

#===============================================================================
# QWEN-TAM PROJECT TEMPLATES MANAGER
# Menu-driven interface for selecting and creating project templates
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# Configuration
#-------------------------------------------------------------------------------
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TEMPLATES_DIR="${SCRIPT_DIR}/templates"
readonly DEFAULT_PROJECTS_DIR="${SCRIPT_DIR}/projects"

# Kolory ANSI
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

#-------------------------------------------------------------------------------
# Helper Functions
#-------------------------------------------------------------------------------

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

clear_screen() {
    clear
}

show_header() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║          QWEN-TAM PROJECT TEMPLATES MANAGER                  ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo -e "${NC}"
}

#-------------------------------------------------------------------------------
# Template Functions
#-------------------------------------------------------------------------------

list_templates() {
    echo -e "${CYAN}Available Templates:${NC}"
    echo ""
    
    local i=1
    for template in "$TEMPLATES_DIR"/*-template.sh; do
        if [[ -f "$template" ]]; then
            local name=$(basename "$template" -template.sh | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
            echo -e "  ${GREEN}[$i]${NC} $name"
            ((i++))
        fi
    done
    
    echo ""
}

get_template_by_index() {
    local index="$1"
    local i=1
    
    # Validate that index is a positive integer
    if ! [[ "$index" =~ ^[0-9]+$ ]]; then
        log_error "Invalid selection: '$index' is not a number"
        return 1
    fi
    
    for template in "$TEMPLATES_DIR"/*-template.sh; do
        if [[ -f "$template" ]]; then
            if [[ $i -eq $index ]]; then
                echo "$template"
                return 0
            fi
            ((i++))
        fi
    done
    
    return 1
}

create_project() {
    local template_file="$1"
    
    echo ""
    read -rp "Enter project name [my-project]: " project_name
    project_name="${project_name:-my-project}"
    
    read -rp "Enter project directory [$DEFAULT_PROJECTS_DIR/$project_name]: " project_dir
    project_dir="${project_dir:-$DEFAULT_PROJECTS_DIR/$project_name}"
    
    echo ""
    log_info "Creating project '$project_name' using template..."
    echo ""
    
    # Execute template script
    if bash "$template_file" "$project_name" "$project_dir"; then
        echo ""
        log_info "✅ Project created successfully!"
        echo ""
        echo -e "${CYAN}Next steps:${NC}"
        echo "  cd $project_dir"
        
        # Suggest next steps based on template type
        if [[ "$template_file" == *"web-app"* ]]; then
            echo "  # Open index.html in browser or run:"
            echo "  python3 -m http.server 8000"
        elif [[ "$template_file" == *"python-app"* ]]; then
            echo "  python3 -m venv venv"
            echo "  source venv/bin/activate"
            echo "  pip install -r requirements.txt"
        elif [[ "$template_file" == *"cpp-app"* ]]; then
            echo "  mkdir build && cd build"
            echo "  cmake .."
            echo "  make"
        elif [[ "$template_file" == *"nodejs-app"* ]]; then
            echo "  npm install"
            echo "  npm run dev"
        fi
        echo ""
    else
        log_error "Failed to create project"
        return 1
    fi
}

show_template_info() {
    local template_file="$1"
    
    echo ""
    echo -e "${CYAN}Template Information:${NC}"
    echo "  File: $(basename "$template_file")"
    echo "  Location: $template_file"
    echo "  Size: $(wc -c < "$template_file") bytes"
    echo "  Created: $(stat -c %y "$template_file" 2>/dev/null || stat -f %Sm "$template_file" 2>/dev/null || echo 'unknown')"
    echo ""
}

#-------------------------------------------------------------------------------
# Menu Functions
#-------------------------------------------------------------------------------

show_main_menu() {
    clear_screen
    show_header
    echo -e "${CYAN}║  PROJECT TEMPLATES MENU                                      ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  [1] 📋 List Available Templates                               ║${NC}"
    echo -e "${GREEN}║  [2] 🆕 Create New Project from Template                       ║${NC}"
    echo -e "${GREEN}║  [3] ℹ️  View Template Information                             ║${NC}"
    echo -e "${GREEN}║  [4] 📂 Open Projects Directory                                ║${NC}"
    echo -e "${YELLOW}║  [5] ⬅️  Back to Main qwen-tam.sh Menu                         ║${NC}"
    echo -e "${YELLOW}║  [6] 🚪 Exit                                                   ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║  Templates Directory: $TEMPLATES_DIR${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

handle_templates_menu() {
    while true; do
        show_main_menu
        
        read -rp "  Enter choice [1-6]: " choice
        
        case $choice in
            1)
                list_templates
                read -rp "Press Enter to continue..."
                ;;
            2)
                list_templates
                read -rp "Select template number: " template_num
                
                template_file=$(get_template_by_index "$template_num")
                
                if [[ -n "$template_file" && -f "$template_file" ]]; then
                    create_project "$template_file"
                    read -rp "Press Enter to continue..."
                else
                    log_error "Invalid template selection"
                    sleep 2
                fi
                ;;
            3)
                list_templates
                read -rp "Select template number: " template_num
                
                template_file=$(get_template_by_index "$template_num")
                
                if [[ -n "$template_file" && -f "$template_file" ]]; then
                    show_template_info "$template_file"
                    read -rp "Press Enter to continue..."
                else
                    log_error "Invalid template selection"
                    sleep 2
                fi
                ;;
            4)
                if [[ -d "$DEFAULT_PROJECTS_DIR" ]]; then
                    log_info "Projects directory: $DEFAULT_PROJECTS_DIR"
                    echo ""
                    echo "Contents:"
                    ls -la "$DEFAULT_PROJECTS_DIR"
                else
                    log_warning "Projects directory does not exist. Creating..."
                    mkdir -p "$DEFAULT_PROJECTS_DIR"
                    log_info "Created: $DEFAULT_PROJECTS_DIR"
                fi
                read -rp "Press Enter to continue..."
                ;;
            5)
                break
                ;;
            6)
                echo -e "${CYAN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                log_error "Invalid option!"
                sleep 1
                ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# CLI Interface
#-------------------------------------------------------------------------------

show_help() {
    cat << EOF
QWEN-TAM Project Templates Manager

Usage: $(basename "$0") [OPTIONS]

Options:
  -l, --list              List available templates
  -t, --template NAME     Select template by name
  -n, --name NAME         Set project name
  -d, --directory DIR     Set project directory
  -h, --help              Show this help message
  -v, --version           Show version

Examples:
  $(basename "$0") --list
  $(basename "$0") --template web-app --name mysite
  $(basename "$0") -t python-app -n myapi -d ~/projects/myapi

Available Templates:
EOF

    for template in "$TEMPLATES_DIR"/*-template.sh; do
        if [[ -f "$template" ]]; then
            local name=$(basename "$template" -template.sh)
            echo "  - $name"
        fi
    done
}

parse_arguments() {
    local template_name=""
    local project_name=""
    local project_dir=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -l|--list)
                list_templates
                exit 0
                ;;
            -t|--template)
                shift
                template_name="$1"
                ;;
            -n|--name)
                shift
                project_name="$1"
                ;;
            -d|--directory)
                shift
                project_dir="$1"
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "QWEN-TAM Templates Manager v1.0"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done
    
    # If template specified in CLI mode
    if [[ -n "$template_name" ]]; then
        local template_file="$TEMPLATES_DIR/${template_name}-template.sh"
        
        if [[ ! -f "$template_file" ]]; then
            log_error "Template not found: $template_file"
            exit 1
        fi
        
        project_name="${project_name:-my-project}"
        project_dir="${project_dir:-$DEFAULT_PROJECTS_DIR/$project_name}"
        
        bash "$template_file" "$project_name" "$project_dir"
        exit $?
    fi
}

#-------------------------------------------------------------------------------
# Main Entry Point
#-------------------------------------------------------------------------------

main() {
    # Check if running with arguments
    if [[ $# -gt 0 ]]; then
        parse_arguments "$@"
    fi
    
    # Ensure templates directory exists
    if [[ ! -d "$TEMPLATES_DIR" ]]; then
        log_error "Templates directory not found: $TEMPLATES_DIR"
        exit 1
    fi
    
    # Ensure projects directory exists
    mkdir -p "$DEFAULT_PROJECTS_DIR"
    
    # Run interactive menu
    handle_templates_menu
}

# Run main function
main "$@"
