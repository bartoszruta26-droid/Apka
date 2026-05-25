#!/bin/bash

#===============================================================================
# QWEN TIME & AUTOMATION MANAGER v1.0
# Raspberry Pi 4 Edition
# Główny skrypt inicjujący i menu TUI
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# Konfiguracja i zmienne globalne
#-------------------------------------------------------------------------------
readonly VERSION="1.0"
readonly SCRIPT_NAME="$(basename "$0")"
# Get script directory (only if not already set)
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
CONFIG_FILE="${HOME}/.qwen_tam_config"
LOG_DIR="${SCRIPT_DIR}/logs"
APP_LOG="${LOG_DIR}/app.log"
DEBUG_LOG="${LOG_DIR}/debug.log"
EVENTS_LOG="${LOG_DIR}/events.log"

# Ścieżki do podskryptów - najpierw sprawdzaj katalog użytkownika, potem lokalny
USER_SCRIPTS_DIR="${HOME}/Apka/scripts"
if [[ -d "$USER_SCRIPTS_DIR" ]]; then
    SCRIPTS_DIR="$USER_SCRIPTS_DIR"
else
    SCRIPTS_DIR="${SCRIPT_DIR}/scripts"
fi

# Tryby pracy
DEBUG_MODE=false
VERBOSE_MODE=false
DAEMON_MODE=false
INTERACTIVE_MODE=true

# Kolory ANSI
[[ -z "${RED:-}" ]] && RED='\033[0;31m'
[[ -z "${GREEN:-}" ]] && GREEN='\033[0;32m'
[[ -z "${YELLOW:-}" ]] && YELLOW='\033[1;33m'
[[ -z "${BLUE:-}" ]] && BLUE='\033[0;34m'
[[ -z "${CYAN:-}" ]] && CYAN='\033[0;36m'
[[ -z "${NC:-}" ]] && NC='\033[0m' # No Color

#-------------------------------------------------------------------------------
# Funkcje pomocnicze (utils.sh)
#-------------------------------------------------------------------------------

log_info() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[INFO]${NC} $timestamp - $*"
    [[ -d "$LOG_DIR" ]] && echo "[INFO] $timestamp - $*" >> "$APP_LOG"
}

log_debug() {
    if [[ "$DEBUG_MODE" == true ]]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo -e "${CYAN}[DEBUG]${NC} $timestamp - $*" >&2
        [[ -d "$LOG_DIR" ]] && echo "[DEBUG] $timestamp - $*" >> "$DEBUG_LOG"
    fi
}

log_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[ERROR]${NC} $timestamp - $*" >&2
    [[ -d "$LOG_DIR" ]] && echo "[ERROR] $timestamp - $*" >> "$APP_LOG"
}

log_event() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    [[ -d "$LOG_DIR" ]] && echo "[EVENT] $timestamp - $*" >> "$EVENTS_LOG"
}

cleanup() {
    log_debug "Cleaning up before exit..."
    # Czyszczenie zmiennych wrażliwych
    unset GITHUB_TOKEN 2>/dev/null || true
    exit 0
}

#-------------------------------------------------------------------------------
# Inicjalizacja środowiska
#-------------------------------------------------------------------------------

init_environment() {
    log_debug "Initializing environment..."
    
    # Tworzenie katalogów
    mkdir -p "$LOG_DIR"
    mkdir -p "${SCRIPT_DIR}/config"
    
    # Set default FINISH_DIR before loading config
    FINISH_DIR="${SCRIPT_DIR}/finish"
    
    # Ładowanie konfiguracji
    if [[ -f "$CONFIG_FILE" ]]; then
        log_debug "Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE"
        # Override FINISH_DIR with user-configured EXPORT_FINISH_DIR if set
        if [[ -n "${EXPORT_FINISH_DIR:-}" ]]; then
            FINISH_DIR="$EXPORT_FINISH_DIR"
            log_debug "Using configured finish directory: $FINISH_DIR"
        fi
    else
        log_info "Configuration file not found. Will create on first use."
    fi
    
    log_event "Environment initialized"
}

#-------------------------------------------------------------------------------
# Obsługa sygnałów systemowych
#-------------------------------------------------------------------------------

setup_signal_handlers() {
    trap cleanup SIGINT SIGTERM
}

#-------------------------------------------------------------------------------
# Funkcje wyświetlania TUI
#-------------------------------------------------------------------------------

clear_screen() {
    clear
}

show_header() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           QWEN TIME & AUTOMATION MANAGER v${VERSION}                ║"
    echo "║                    Raspberry Pi 4 Edition                    ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo -e "${NC}"
}

show_main_menu() {
    clear_screen
    show_header
    echo -e "${CYAN}║  MAIN MENU                                                   ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  [1] 📁 GitHub Repository Management                         ║${NC}"
    echo -e "${GREEN}║  [2] 🤖 Qwen Coder - Code Generation                         ║${NC}"
    echo -e "${GREEN}║  [3] ✅ Code Verification                                    ║${NC}"
    echo -e "${GREEN}║  [4] 🔄 Automation & AI Agent                                ║${NC}"
    echo -e "${GREEN}║  [5] ⚙️  Configuration & Settings                            ║${NC}"
    echo -e "${GREEN}║  [6] 📊 Logs & Monitoring                                    ║${NC}"
    echo -e "${GREEN}║  [7] ℹ️  System Information                                  ║${NC}"
    echo -e "${GREEN}║  [8] 🔄 Update Application                                   ║${NC}"
    echo -e "${GREEN}║  [9] 📤 Export Results (Moodle/Joomla/Nextcloud)            ║${NC}"
    echo -e "${YELLOW}║  [10] 🚪 Exit                                                 ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    
    local status_icon="●"
    local mode_text="Interactive"
    local debug_text="OFF"
    [[ "$DEBUG_MODE" == true ]] && debug_text="ON"
    
    echo -e "${CYAN}║  Status: ${status_icon} Connected  |  Mode: ${mode_text}  |  Debug: ${debug_text}   ║${NC}"
    echo -e "${CYAN}║  Press 'D' for Debug mode | 'V' for Verbose | 'Q' to quit   ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_submenu_github() {
    clear_screen
    show_header
    echo -e "${CYAN}║              GITHUB REPOSITORY MANAGEMENT                    ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  [1] 🔐 Configure GitHub Credentials                       ║${NC}"
    echo -e "${GREEN}║  [2] ➕ Create New Repository                              ║${NC}"
    echo -e "${GREEN}║  [3] 📋 List My Repositories                               ║${NC}"
    echo -e "${GREEN}║  [4] 🗑️  Delete Repository                                 ║${NC}"
    echo -e "${GREEN}║  [5] 📥 Clone Repository                                   ║${NC}"
    echo -e "${GREEN}║  [6] 🔄 Sync Local with Remote                             ║${NC}"
    echo -e "${YELLOW}║  [7] ⬅️  Back to Main Menu                                 ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_submenu_coder() {
    clear_screen
    show_header
    echo -e "${CYAN}║                QWEN CODER - CODE GENERATION                  ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  [1] 📁 Create New Project (with AI setup)                 ║${NC}"
    echo -e "${GREEN}║  [2] 📂 Load Existing Project                              ║${NC}"
    echo -e "${GREEN}║  [3] 📜 Create/Update Shell Script                         ║${NC}"
    echo -e "${GREEN}║  [4] 💻 Create/Update C/C#/C++ Code with GUI               ║${NC}"
    echo -e "${GREEN}║  [5] 🌐 Create/Update WebUI Script                         ║${NC}"
    echo -e "${GREEN}║  [6] 📱 Create/Update Android App                          ║${NC}"
    echo -e "${GREEN}║  [7] ✏️  Edit Existing File with AI                        ║${NC}"
    echo -e "${GREEN}║  [8] 📂 Project Templates Manager                          ║${NC}"
    echo -e "${GREEN}║  [9] ⚙️  Daemon/Service Generator                          ║${NC}"
    echo -e "${GREEN}║  [A] 🌿 Ziołowy Gostynin - Generator Rozdziałów AI         ║${NC}"
    echo -e "${YELLOW}║  [0] ⬅️  Back to Main Menu                                 ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_submenu_verification() {
    clear_screen
    show_header
    echo -e "${CYAN}║                   CODE VERIFICATION                          ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  [1] 🔍 Syntax Check (Shell)                               ║${NC}"
    echo -e "${GREEN}║  [2] 🔍 Syntax Check (C/C++)                               ║${NC}"
    echo -e "${GREEN}║  [3] 🛡️  Security Scan                                     ║${NC}"
    echo -e "${GREEN}║  [4] 📏 Code Style Check                                   ║${NC}"
    echo -e "${GREEN}║  [5] 🧪 Run Unit Tests                                     ║${NC}"
    echo -e "${GREEN}║  [6] 📊 Generate Verification Report                       ║${NC}"
    echo -e "${YELLOW}║  [7] ⬅️  Back to Main Menu                                 ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_submenu_automation() {
    clear_screen
    show_header
    echo -e "${CYAN}║               AUTOMATION & AI AGENT                          ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  [1] 💬 Start AI Discussion Session                        ║${NC}"
    echo -e "${GREEN}║  [2] 📋 Create Automation Workflow                         ║${NC}"
    echo -e "${GREEN}║  [3] ▶️  Run Automation Task                               ║${NC}"
    echo -e "${GREEN}║  [4] ⏸️  Pause/Resume Background Tasks                     ║${NC}"
    echo -e "${GREEN}║  [5] 🛑 Stop Running Tasks                                 ║${NC}"
    echo -e "${GREEN}║  [6] 📅 Schedule Automated Task                            ║${NC}"
    echo -e "${GREEN}║  [7] 📜 View Task History                                  ║${NC}"
    echo -e "${GREEN}║  [8] ⚡ Quick Automations                                  ║${NC}"
    echo -e "${GREEN}║      ├─ [81] Auto-commit & Push                           ║${NC}"
    echo -e "${GREEN}║      ├─ [82] Daily Backup                                 ║${NC}"
    echo -e "${GREEN}║      ├─ [83] Code Review Loop                             ║${NC}"
    echo -e "${GREEN}║      └─ [84] Custom Script Runner                         ║${NC}"
    echo -e "${BLUE}║  [9] 🤖 Multi-Agent Workflows (Cluster RPi4)                ║${NC}"
    echo -e "${YELLOW}║  [10] ⬅️  Back to Main Menu                                ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_submenu_config() {
    clear_screen
    show_header
    echo -e "${CYAN}║               CONFIGURATION & SETTINGS                       ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
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

show_submenu_logs() {
    clear_screen
    show_header
    echo -e "${CYAN}║                  LOGS & MONITORING                           ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  [1] 📄 View Application Log (app.log)                     ║${NC}"
    echo -e "${GREEN}║  [2] 🐛 View Debug Log (debug.log)                         ║${NC}"
    echo -e "${GREEN}║  [3] 📊 View Events Log (events.log)                       ║${NC}"
    echo -e "${GREEN}║  [4] 🔍 Search Logs                                        ║${NC}"
    echo -e "${GREEN}║  [5] 🧹 Clear Old Logs                                     ║${NC}"
    echo -e "${GREEN}║  [6] 📥 Export Logs                                        ║${NC}"
    echo -e "${GREEN}║  [7] 📈 Real-time Log Monitor                              ║${NC}"
    echo -e "${YELLOW}║  [8] ⬅️  Back to Main Menu                                 ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_submenu_system() {
    clear_screen
    show_header
    echo -e "${CYAN}║                 SYSTEM INFORMATION                           ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  [1] 💻 System Resources (CPU/RAM/Disk)                    ║${NC}"
    echo -e "${GREEN}║  [2] 🌡️  Temperature & Health Status                       ║${NC}"
    echo -e "${GREEN}║  [3] 📦 Installed Dependencies                             ║${NC}"
    echo -e "${GREEN}║  [4] 🤖 Qwen Model Status                                  ║${NC}"
    echo -e "${GREEN}║  [5] 🔗 Network Connectivity                               ║${NC}"
    echo -e "${GREEN}║  [6] 📜 Version & Changelog                                ║${NC}"
    echo -e "${YELLOW}║  [7] ⬅️  Back to Main Menu                                 ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_submenu_update() {
    clear_screen
    show_header
    echo -e "${CYAN}║                  UPDATE APPLICATION                          ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  [1] 🔄 Check for Updates                                  ║${NC}"
    echo -e "${GREEN}║  [2] ⬇️  Download Latest Version                           ║${NC}"
    echo -e "${GREEN}║  [3] 📦 Auto-Install Dependencies                          ║${NC}"
    echo -e "${GREEN}║  [4] 🚀 Install Update (Rolling/Blue-Green)                ║${NC}"
    echo -e "${GREEN}║  [5] 📋 View Changelog                                     ║${NC}"
    echo -e "${GREEN}║  [6] ↩️  Rollback to Previous Version                      ║${NC}"
    echo -e "${GREEN}║  [7] ⚙️  Configure Auto-Update Settings                    ║${NC}"
    echo -e "${GREEN}║  [8] 📊 Update Cluster Nodes (Swarm)                       ║${NC}"
    echo -e "${YELLOW}║  [9] ⬅️  Back to Main Menu                                 ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

#-------------------------------------------------------------------------------
# Integracja z podskryptami - GitHub Repository Management
#-------------------------------------------------------------------------------

# GitHub Repository Management - delegowanie do podskryptów
github_configure_credentials() {
    log_event "GitHub Configure Credentials"
    if [[ -f "${SCRIPTS_DIR}/auth.sh" ]]; then
        source "${SCRIPTS_DIR}/auth.sh"
        auth_menu
    else
        log_error "Podskrypt auth.sh nie znaleziony!"
        echo "Uruchomienie trybu interaktywnego konfiguracji GitHub..."
        echo "Wymagane pliki: scripts/auth.sh"
    fi
}

github_create_repository() {
    log_event "GitHub Create Repository"
    if [[ -f "${SCRIPTS_DIR}/repo.sh" ]]; then
        source "${SCRIPTS_DIR}/repo.sh"
        create_repo_interactive
    else
        log_error "Podskrypt repo.sh nie znaleziony!"
        echo "Tworzenie nowego repozytorium GitHub..."
    fi
}

github_list_repositories() {
    log_event "GitHub List Repositories"
    if [[ -f "${SCRIPTS_DIR}/repo.sh" ]]; then
        source "${SCRIPTS_DIR}/repo.sh"
        list_repositories
        read -rp "Press Enter to continue..."
    else
        log_error "Podskrypt repo.sh nie znaleziony!"
    fi
}

github_delete_repository() {
    log_event "GitHub Delete Repository"
    if [[ -f "${SCRIPTS_DIR}/repo.sh" ]]; then
        source "${SCRIPTS_DIR}/repo.sh"
        delete_repository
        read -rp "Press Enter to continue..."
    else
        log_error "Podskrypt repo.sh nie znaleziony!"
    fi
}

github_clone_repository() {
    log_event "GitHub Clone Repository"
    if [[ -f "${SCRIPTS_DIR}/repo.sh" ]]; then
        source "${SCRIPTS_DIR}/repo.sh"
        clone_repository
        read -rp "Press Enter to continue..."
    else
        log_error "Podskrypt repo.sh nie znaleziony!"
    fi
}

github_sync_local_remote() {
    log_event "GitHub Sync Local with Remote"
    if [[ -f "${SCRIPTS_DIR}/repo.sh" ]]; then
        source "${SCRIPTS_DIR}/repo.sh"
        sync_local_with_remote
        read -rp "Press Enter to continue..."
    else
        log_error "Podskrypt repo.sh nie znaleziony!"
    fi
}

# Qwen Coder - funkcje stub (nieużywane, gdy coder.sh jest dostępny)
# coder_generate_markdown() { log_info "Generate Markdown Documentation (stub)"; }
# coder_generate_source_code() { log_info "Generate Source Code (stub)"; }
# coder_generate_shell_scripts() { log_info "Generate Shell Scripts (stub)"; }
# coder_generate_python_scripts() { log_info "Generate Python Scripts (stub)"; }
# coder_generate_web_files() { log_info "Generate Web Files (stub)"; }
# coder_create_project_structure() { log_info "Create Project Structure (stub)"; }
# coder_edit_existing_file() { log_info "Edit Existing File with AI (stub)"; }
# coder_execute_custom_command() { log_info "Execute Custom Command (stub)"; }

# Code Verification - delegowanie do podskryptu verify.sh
verify_syntax_shell() {
    log_event "Code Verification - Syntax Check Shell"
    if [[ -f "${SCRIPTS_DIR}/verify.sh" ]]; then
        source "${SCRIPTS_DIR}/verify.sh"
        verify_syntax_shell
    else
        log_error "Podskrypt verify.sh nie znaleziony!"
    fi
}

verify_syntax_cpp() {
    log_event "Code Verification - Syntax Check C/C++"
    if [[ -f "${SCRIPTS_DIR}/verify.sh" ]]; then
        source "${SCRIPTS_DIR}/verify.sh"
        verify_syntax_cpp
    else
        log_error "Podskrypt verify.sh nie znaleziony!"
    fi
}

verify_security_scan() {
    log_event "Code Verification - Security Scan"
    if [[ -f "${SCRIPTS_DIR}/verify.sh" ]]; then
        source "${SCRIPTS_DIR}/verify.sh"
        verify_security_scan
    else
        log_error "Podskrypt verify.sh nie znaleziony!"
    fi
}

verify_code_style() {
    log_event "Code Verification - Code Style Check"
    if [[ -f "${SCRIPTS_DIR}/verify.sh" ]]; then
        source "${SCRIPTS_DIR}/verify.sh"
        verify_code_style
    else
        log_error "Podskrypt verify.sh nie znaleziony!"
    fi
}

verify_run_unit_tests() {
    log_event "Code Verification - Run Unit Tests"
    if [[ -f "${SCRIPTS_DIR}/verify.sh" ]]; then
        source "${SCRIPTS_DIR}/verify.sh"
        verify_run_unit_tests
    else
        log_error "Podskrypt verify.sh nie znaleziony!"
    fi
}

verify_generate_report() {
    log_event "Code Verification - Generate Report"
    if [[ -f "${SCRIPTS_DIR}/verify.sh" ]]; then
        source "${SCRIPTS_DIR}/verify.sh"
        verify_generate_report
    else
        log_error "Podskrypt verify.sh nie znaleziony!"
    fi
}

# Automation & AI Agent - delegowanie do podskryptu automation.sh
automation_start_discussion() {
    log_event "Automation Start Discussion Session"
    if [[ -f "${SCRIPTS_DIR}/automation.sh" ]]; then
        source "${SCRIPTS_DIR}/automation.sh"
        ai_discussion_session
    else
        log_error "Podskrypt automation.sh nie znaleziony!"
        echo "Uruchomienie trybu interaktywnego sesji dyskusyjnej z AI..."
    fi
}

automation_create_workflow() {
    log_event "Automation Create Workflow"
    if [[ -f "${SCRIPTS_DIR}/automation.sh" ]]; then
        source "${SCRIPTS_DIR}/automation.sh"
        create_automation_workflow
    else
        log_error "Podskrypt automation.sh nie znaleziony!"
        echo "Tworzenie nowego workflow automatyzacji..."
    fi
}

automation_run_task() {
    log_event "Automation Run Task"
    if [[ -f "${SCRIPTS_DIR}/automation.sh" ]]; then
        source "${SCRIPTS_DIR}/automation.sh"
        run_automation_task
    else
        log_error "Podskrypt automation.sh nie znaleziony!"
        echo "Uruchamianie zadania automatyzacji..."
    fi
}

automation_pause_resume() {
    log_event "Automation Pause/Resume Tasks"
    if [[ -f "${SCRIPTS_DIR}/automation.sh" ]]; then
        source "${SCRIPTS_DIR}/automation.sh"
        pause_resume_tasks
    else
        log_error "Podskrypt automation.sh nie znaleziony!"
        echo "Zarządzanie zadaniami w tle..."
    fi
}

automation_stop_tasks() {
    log_event "Automation Stop Tasks"
    if [[ -f "${SCRIPTS_DIR}/automation.sh" ]]; then
        source "${SCRIPTS_DIR}/automation.sh"
        stop_running_tasks
    else
        log_error "Podskrypt automation.sh nie znaleziony!"
        echo "Zatrzymywanie działających zadań..."
    fi
}

automation_schedule_task() {
    log_event "Automation Schedule Task"
    if [[ -f "${SCRIPTS_DIR}/automation.sh" ]]; then
        source "${SCRIPTS_DIR}/automation.sh"
        schedule_automated_task
    else
        log_error "Podskrypt automation.sh nie znaleziony!"
        echo "Planowanie zadania automatycznego..."
    fi
}

automation_view_history() {
    log_event "Automation View History"
    if [[ -f "${SCRIPTS_DIR}/automation.sh" ]]; then
        source "${SCRIPTS_DIR}/automation.sh"
        view_task_history
    else
        log_error "Podskrypt automation.sh nie znaleziony!"
        echo "Przegląd historii zadań..."
    fi
}

automation_quick_autocommit() {
    log_event "Automation Quick Auto-commit"
    if [[ -f "${SCRIPTS_DIR}/automation.sh" ]]; then
        source "${SCRIPTS_DIR}/automation.sh"
        quick_autocommit_push
    else
        log_error "Podskrypt automation.sh nie znaleziony!"
        echo "Auto-commit & Push..."
    fi
}

automation_quick_backup() {
    log_event "Automation Quick Backup"
    if [[ -f "${SCRIPTS_DIR}/automation.sh" ]]; then
        source "${SCRIPTS_DIR}/automation.sh"
        quick_daily_backup
    else
        log_error "Podskrypt automation.sh nie znaleziony!"
        echo "Daily Backup..."
    fi
}

automation_quick_review() {
    log_event "Automation Quick Code Review"
    if [[ -f "${SCRIPTS_DIR}/automation.sh" ]]; then
        source "${SCRIPTS_DIR}/automation.sh"
        quick_code_review_loop
    else
        log_error "Podskrypt automation.sh nie znaleziony!"
        echo "Code Review Loop..."
    fi
}

automation_quick_custom() {
    log_event "Automation Quick Custom Script"
    if [[ -f "${SCRIPTS_DIR}/automation.sh" ]]; then
        source "${SCRIPTS_DIR}/automation.sh"
        quick_custom_script_runner
    else
        log_error "Podskrypt automation.sh nie znaleziony!"
        echo "Custom Script Runner..."
    fi
}

#-------------------------------------------------------------------------------
# Configuration & Settings - delegowanie do podskryptu config.sh
#-------------------------------------------------------------------------------

config_manage_github_token() {
    log_event "Configuration: Manage GitHub Token"
    if [[ -f "${SCRIPTS_DIR}/config.sh" ]]; then
        source "${SCRIPTS_DIR}/config.sh"
        menu_manage_github_token
    else
        log_error "Podskrypt config.sh nie znaleziony!"
        echo "Uruchomienie trybu interaktywnego konfiguracji..."
    fi
}

config_configure_qwen_api() {
    log_event "Configuration: Configure Qwen API Endpoint"
    if [[ -f "${SCRIPTS_DIR}/config.sh" ]]; then
        source "${SCRIPTS_DIR}/config.sh"
        menu_configure_qwen_api
    else
        log_error "Podskrypt config.sh nie znaleziony!"
    fi
}

config_set_working_directory() {
    log_event "Configuration: Set Working Directory"
    if [[ -f "${SCRIPTS_DIR}/config.sh" ]]; then
        source "${SCRIPTS_DIR}/config.sh"
        menu_set_working_directory
    else
        log_error "Podskrypt config.sh nie znaleziony!"
    fi
}

config_theme_display() {
    log_event "Configuration: Theme & Display Options"
    if [[ -f "${SCRIPTS_DIR}/config.sh" ]]; then
        source "${SCRIPTS_DIR}/config.sh"
        menu_theme_display
    else
        log_error "Podskrypt config.sh nie znaleziony!"
    fi
}

config_notification_settings() {
    log_event "Configuration: Notification Settings"
    if [[ -f "${SCRIPTS_DIR}/config.sh" ]]; then
        source "${SCRIPTS_DIR}/config.sh"
        menu_notification_settings
    else
        log_error "Podskrypt config.sh nie znaleziony!"
    fi
}

config_backup() {
    log_event "Configuration: Backup Configuration"
    if [[ -f "${SCRIPTS_DIR}/config.sh" ]]; then
        source "${SCRIPTS_DIR}/config.sh"
        menu_backup_configuration
    else
        log_error "Podskrypt config.sh nie znaleziony!"
    fi
}

config_restore() {
    log_event "Configuration: Restore Configuration"
    if [[ -f "${SCRIPTS_DIR}/config.sh" ]]; then
        source "${SCRIPTS_DIR}/config.sh"
        menu_restore_configuration
    else
        log_error "Podskrypt config.sh nie znaleziony!"
    fi
}

config_reset_defaults() {
    log_event "Configuration: Reset to Defaults"
    if [[ -f "${SCRIPTS_DIR}/config.sh" ]]; then
        source "${SCRIPTS_DIR}/config.sh"
        menu_reset_defaults
    else
        log_error "Podskrypt config.sh nie znaleziony!"
    fi
}

#-------------------------------------------------------------------------------
# Integracja z podskryptami - Logs & Monitoring
#-------------------------------------------------------------------------------

# Logs & Monitoring - delegowanie do podskryptu logs.sh
handle_logs_menu() {
    log_event "Logs & Monitoring Menu"
    if [[ -f "${SCRIPTS_DIR}/logs.sh" ]]; then
        source "${SCRIPTS_DIR}/logs.sh"
        logs_menu
    else
        log_error "Podskrypt logs.sh nie znaleziony!"
        echo "Uruchomienie trybu interaktywnego Logs & Monitoring..."
        echo "Wymagane pliki: scripts/logs.sh"
        read -rp "Press Enter to continue..."
    fi
}

# Pozostałe funkcje logs jako fallback (gdyby logs.sh nie był dostępny)
logs_view_app() { log_info "View Application Log (stub)"; }
logs_view_debug() { log_info "View Debug Log (stub)"; }
logs_view_events() { log_info "View Events Log (stub)"; }
logs_search() { log_info "Search Logs (stub)"; }
logs_clear_old() { log_info "Clear Old Logs (stub)"; }
logs_export() { log_info "Export Logs (stub)"; }
logs_realtime_monitor() { log_info "Real-time Log Monitor (stub)"; }

# System Information - delegowanie do podskryptu system.sh
system_resources() {
    log_event "System Resources Check"
    if [[ -f "${SCRIPTS_DIR}/system.sh" ]]; then
        source "${SCRIPTS_DIR}/system.sh"
        system_resources
    else
        log_info "💻 System Resources:"
        echo "  CPU: $(nproc 2>/dev/null || echo 'N/A') cores"
        echo "  RAM: $(free -h 2>/dev/null | grep Mem | awk '{print $3 "/" $2}' || echo 'N/A')"
        echo "  Disk: $(df -h / 2>/dev/null | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}' || echo 'N/A')"
    fi
}

system_temperature_health() {
    log_event "Temperature & Health Status Check"
    if [[ -f "${SCRIPTS_DIR}/system.sh" ]]; then
        source "${SCRIPTS_DIR}/system.sh"
        system_temperature_health
    else
        log_info "🌡️  Temperature & Health Status:"
        if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
            local temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
            echo "  CPU Temp: $((temp / 1000))°C"
        else
            echo "  Temperature sensor not available"
        fi
        echo "  System Health: OK"
    fi
}

system_dependencies() {
    log_event "Installed Dependencies Check"
    if [[ -f "${SCRIPTS_DIR}/system.sh" ]]; then
        source "${SCRIPTS_DIR}/system.sh"
        system_dependencies
    else
        log_info "📦 Installed Dependencies:"
        echo "  git: $(command -v git &>/dev/null && echo '✅' || echo '❌')"
        echo "  curl: $(command -v curl &>/dev/null && echo '✅' || echo '❌')"
        echo "  jq: $(command -v jq &>/dev/null && echo '✅' || echo '❌')"
        echo "  python3: $(command -v python3 &>/dev/null && echo '✅' || echo '❌')"
    fi
}

system_qwen_status() {
    log_event "Qwen Model Status Check"
    if [[ -f "${SCRIPTS_DIR}/system.sh" ]]; then
        source "${SCRIPTS_DIR}/system.sh"
        system_qwen_status
    else
        log_info "🤖 Qwen Model Status:"
        if command -v ollama &>/dev/null; then
            echo "  Ollama: ✅ Installed"
            echo "  Models: $(ollama list 2>/dev/null | wc -l) installed"
        else
            echo "  Ollama: ❌ Not installed"
        fi
    fi
}

system_network() {
    log_event "Network Connectivity Check"
    if [[ -f "${SCRIPTS_DIR}/system.sh" ]]; then
        source "${SCRIPTS_DIR}/system.sh"
        system_network
    else
        log_info "🔗 Network Connectivity:"
        echo "  Hostname: $(hostname 2>/dev/null || echo 'N/A')"
        echo "  GitHub API: $(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 3 https://api.github.com 2>/dev/null)"
    fi
}

system_version_changelog() {
    log_event "Version & Changelog Display"
    if [[ -f "${SCRIPTS_DIR}/system.sh" ]]; then
        source "${SCRIPTS_DIR}/system.sh"
        system_version_changelog
    else
        log_info "📜 Version & Changelog:"
        echo "  Version: ${VERSION:-1.0}"
        echo "  Edition: Raspberry Pi 4"
    fi
}

# Update Application
update_check() { log_info "Check for Updates (stub)"; }
update_download() { log_info "Download Latest Version (stub)"; }
update_install_deps() { log_info "Auto-Install Dependencies (stub)"; }
update_install() { log_info "Install Update (stub)"; }
update_changelog() { log_info "View Changelog (stub)"; }
update_rollback() { log_info "Rollback to Previous Version (stub)"; }
update_configure_auto() { log_info "Configure Auto-Update Settings (stub)"; }
update_cluster_nodes() { log_info "Update Cluster Nodes (stub)"; }

#-------------------------------------------------------------------------------
# Obsługa podmenu
#-------------------------------------------------------------------------------

handle_github_menu() {
    while true; do
        show_submenu_github
        read -rp "  Enter choice [1-7]: " choice
        case $choice in
            1) github_configure_credentials ;;
            2) github_create_repository ;;
            3) github_list_repositories ;;
            4) github_delete_repository ;;
            5) github_clone_repository ;;
            6) github_sync_local_remote ;;
            7) break ;;
            *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
        esac
        [[ $choice != "7" ]] && read -rp "Press Enter to continue..." 
    done
}

handle_coder_menu() {
    # Wywołanie zewnętrznego podskryptu coder.sh
    if [[ -f "${SCRIPTS_DIR}/coder.sh" ]]; then
        log_debug "Loading coder module from scripts/coder.sh"
        # Uruchom jako osobny proces bash
        bash "${SCRIPTS_DIR}/coder.sh"
    else
        log_error "Coder module not found: ${SCRIPTS_DIR}/coder.sh"
        echo -e "${RED}Error: Coder module script not found!${NC}"
        sleep 2
    fi
}

# Funkcja do otwierania generatora rozdziałów Ziołowy Gostynin
handle_ziolowy_gostynin_generator() {
    clear_screen
    show_header
    echo -e "${CYAN}║         🌿 ZIOŁOWY GOSTYNIN - GENERATOR ROZDZIAŁÓW AI       ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo ""
    echo -e "${GREEN}Generator wykorzystuje Puter.js i Qwen API do automatycznego${NC}"
    echo -e "${GREEN}tworzenia rozdziałów książki na podstawie spisu treści.${NC}"
    echo ""
    echo -e "${YELLOW}Wymagania:${NC}"
    echo "  - Przeglądarka internetowa"
    echo "  - Dostęp do Puter.com (konto użytkownika)"
    echo "  - Połączenie z internetem"
    echo ""
    echo -e "${CYAN}Lokalizacja pliku HTML:${NC}"
    echo "  ${SCRIPT_DIR}/projekty/ziolowy/generator-rozdzialow.html"
    echo ""
    echo -e "${YELLOW}Instrukcja uruchomienia:${NC}"
    echo "  1. Otwórz przeglądarkę internetową"
    echo "  2. Przejdź na https://puter.com"
    echo "  3. Zaloguj się na swoje konto"
    echo "  4. Utwórz nowy projekt lub otwórz istniejący"
    echo "  5. Skopiuj plik generator-rozdzialow.html do projektu"
    echo "  6. Otwórz plik w przeglądarce Puter"
    echo "  7. Kliknij 'Wczytaj Spis Treści' i generuj rozdziały!"
    echo ""
    echo -e "${GREEN}Alternatywnie, możesz otworzyć plik lokalnie:${NC}"
    echo "  xdg-open ${SCRIPT_DIR}/projekty/ziolowy/generator-rozdzialow.html"
    echo ""
    
    read -rp "Czy chcesz otworzyć plik w przeglądarce? [t/N]: " open_browser
    if [[ "$open_browser" == "t" || "$open_browser" == "T" || "$open_browser" == "tak" || "$open_browser" == "Tak" ]]; then
        if command -v xdg-open &> /dev/null; then
            xdg-open "${SCRIPT_DIR}/projekty/ziolowy/generator-rozdzialow.html" &
            echo -e "${GREEN}Otwieram plik w przeglądarce...${NC}"
        elif command -v gnome-open &> /dev/null; then
            gnome-open "${SCRIPT_DIR}/projekty/ziolowy/generator-rozdzialow.html" &
            echo -e "${GREEN}Otwieram plik w przeglądarce...${NC}"
        else
            echo -e "${YELLOW}Nie znaleziono polecenia do otwierania plików.${NC}"
            echo -e "${YELLOW}Otwórz plik ręcznie: ${SCRIPT_DIR}/projekty/ziolowy/generator-rozdzialow.html${NC}"
        fi
    fi
    
    echo ""
    read -rp "Press Enter to continue..."
}

handle_verification_menu() {
    while true; do
        show_submenu_verification
        read -rp "  Enter choice [1-7]: " choice
        case $choice in
            1) verify_syntax_shell ;;
            2) verify_syntax_cpp ;;
            3) verify_security_scan ;;
            4) verify_code_style ;;
            5) verify_run_unit_tests ;;
            6) verify_generate_report ;;
            7) break ;;
            *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
        esac
        [[ $choice != "7" ]] && read -rp "Press Enter to continue..."
    done
}

handle_automation_menu() {
    while true; do
        show_submenu_automation
        read -rp "  Enter choice [1-10, 81-84]: " choice
        case $choice in
            1) automation_start_discussion ;;
            2) automation_create_workflow ;;
            3) automation_run_task ;;
            4) automation_pause_resume ;;
            5) automation_stop_tasks ;;
            6) automation_schedule_task ;;
            7) automation_view_history ;;
            81) automation_quick_autocommit ;;
            82) automation_quick_backup ;;
            83) automation_quick_review ;;
            84) automation_quick_custom ;;
            9)
                # Multi-Agent Workflows
                log_event "Multi-Agent Workflows Menu"
                if [[ -f "${SCRIPTS_DIR}/multi_agent.sh" ]]; then
                    source "${SCRIPTS_DIR}/multi_agent.sh"
                    multi_agent_menu
                else
                    log_error "Podskrypt multi_agent.sh nie znaleziony!"
                    echo "Wymagane pliki: scripts/multi_agent.sh"
                    read -rp "Press Enter to continue..."
                fi
                ;;
            10) break ;;
            *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
        esac
        [[ $choice != "10" ]] && read -rp "Press Enter to continue..."
    done
}

handle_config_menu() {
    while true; do
        show_submenu_config
        read -rp "  Enter choice [1-9]: " choice
        case $choice in
            1) config_manage_github_token ;;
            2) config_configure_qwen_api ;;
            3) config_set_working_directory ;;
            4) config_theme_display ;;
            5) config_notification_settings ;;
            6) config_backup ;;
            7) config_restore ;;
            8) config_reset_defaults ;;
            9) break ;;
            *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
        esac
        [[ $choice != "9" ]] && read -rp "Press Enter to continue..."
    done
}

# Usunięto - handle_logs_menu jest teraz w scripts/logs.sh

handle_system_menu() {
    while true; do
        show_submenu_system
        read -rp "  Enter choice [1-7]: " choice
        case $choice in
            1) system_resources ;;
            2) system_temperature_health ;;
            3) system_dependencies ;;
            4) system_qwen_status ;;
            5) system_network ;;
            6) system_version_changelog ;;
            7) break ;;
            *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
        esac
        [[ $choice != "7" ]] && read -rp "Press Enter to continue..."
    done
}

#-------------------------------------------------------------------------------
# Integracja z podskryptami - Update Application
#-------------------------------------------------------------------------------

# Update Application - delegowanie do podskryptu update.sh
handle_update_menu() {
    log_event "Update Application Menu"
    if [[ -f "${SCRIPTS_DIR}/update.sh" ]]; then
        source "${SCRIPTS_DIR}/update.sh"
        updates_menu
    else
        log_error "Podskrypt update.sh nie znaleziony!"
        echo "Uruchomienie trybu interaktywnego Update..."
        echo "Wymagane pliki: scripts/update.sh"
        read -rp "Press Enter to continue..."
    fi
}

#-------------------------------------------------------------------------------
# Export Results Module - Moodle/Joomla/Nextcloud
#-------------------------------------------------------------------------------
# Konfiguracja eksportu - Export Configuration
#-------------------------------------------------------------------------------

# Stałe konfiguracyjne dla eksportu - Export configuration constants
# Note: FINISH_DIR will be set after loading config to allow user override
readonly MOODLE_DEFAULT_FORMAT="book"
readonly JOOMLA_DEFAULT_CATEGORY="1"
readonly NEXTCLOUD_DEFAULT_PATH="/"

# Funkcje eksportu
export_to_moodle_book() {
    log_event "Export to Moodle as Book Activity"
    echo ""
    echo -e "${CYAN}═══ EXPORT TO MOODLE - BOOK ACTIVITY ═══${NC}"
    echo ""
    
    # Sprawdź czy katalog /finish istnieje
    if [[ ! -d "$FINISH_DIR" ]]; then
        log_error "Directory $FINISH_DIR does not exist!"
        echo "Creating directory: $FINISH_DIR"
        mkdir -p "$FINISH_DIR"
    fi
    
    # Lista plików w /finish
    echo "Available files in $FINISH_DIR:"
    ls -la "$FINISH_DIR" 2>/dev/null || echo "No files found."
    echo ""
    
    read -rp "Enter Moodle URL (e.g., https://moodle.example.com): " moodle_url
    read -rp "Enter Moodle username: " moodle_username
    read -sp "Enter Moodle password/token: " moodle_password
    echo ""
    read -rp "Enter course ID: " course_id
    read -rp "Enter book title: " book_title
    read -rp "Enter chapter name (or press Enter for auto): " chapter_name
    [[ -z "$chapter_name" ]] && chapter_name="Auto-generated chapter"
    
    echo ""
    echo -e "${GREEN}Preparing export to Moodle...${NC}"
    echo "  Target: $moodle_url"
    echo "  Course ID: $course_id"
    echo "  Book Title: $book_title"
    echo "  Chapter: $chapter_name"
    echo ""
    
    # Symulacja eksportu (do implementacji API Moodle)
    log_info "Moodle export initiated (stub - requires Moodle Web Services API)"
    echo -e "${YELLOW}Note: Full implementation requires Moodle Web Services configuration.${NC}"
    echo ""
    read -rp "Press Enter to continue..."
}

export_to_moodle_file() {
    log_event "Export to Moodle as MD File"
    echo ""
    echo -e "${CYAN}═══ EXPORT TO MOODLE - MARKDOWN FILE ═══${NC}"
    echo ""
    
    # Sprawdź czy katalog /finish istnieje
    if [[ ! -d "$FINISH_DIR" ]]; then
        log_error "Directory $FINISH_DIR does not exist!"
        mkdir -p "$FINISH_DIR"
    fi
    
    # Lista plików w /finish
    echo "Available files in $FINISH_DIR:"
    ls -la "$FINISH_DIR" 2>/dev/null || echo "No files found."
    echo ""
    
    read -rp "Enter Moodle URL (e.g., https://moodle.example.com): " moodle_url
    read -rp "Enter Moodle username: " moodle_username
    read -sp "Enter Moodle password/token: " moodle_password
    echo ""
    read -rp "Enter target directory path (press Enter for root): " target_path
    [[ -z "$target_path" ]] && target_path="/"
    
    echo ""
    echo -e "${GREEN}Preparing .md file export to Moodle...${NC}"
    echo "  Target: $moodle_url"
    echo "  Directory: $target_path"
    echo ""
    
    # Symulacja eksportu
    log_info "Moodle .md file export initiated (stub - requires Moodle Web Services API)"
    echo -e "${YELLOW}Note: Full implementation requires Moodle Web Services configuration.${NC}"
    echo ""
    read -rp "Press Enter to continue..."
}

export_to_joomla_article() {
    log_event "Export to Joomla as Article"
    echo ""
    echo -e "${CYAN}═══ EXPORT TO JOOMLA - ARTICLE ═══${NC}"
    echo ""
    
    # Sprawdź czy katalog /finish istnieje
    if [[ ! -d "$FINISH_DIR" ]]; then
        log_error "Directory $FINISH_DIR does not exist!"
        mkdir -p "$FINISH_DIR"
    fi
    
    # Lista plików w /finish
    echo "Available files in $FINISH_DIR:"
    ls -la "$FINISH_DIR" 2>/dev/null || echo "No files found."
    echo ""
    
    read -rp "Enter Joomla URL (e.g., https://joomla.example.com): " joomla_url
    read -rp "Enter Joomla username: " joomla_username
    read -sp "Enter Joomla password: " joomla_password
    echo ""
    read -rp "Enter article title: " article_title
    read -rp "Enter category ID (default: $JOOMLA_DEFAULT_CATEGORY): " category_id
    [[ -z "$category_id" ]] && category_id="$JOOMLA_DEFAULT_CATEGORY"
    read -rp "Enter article alias (optional): " article_alias
    
    echo ""
    echo -e "${GREEN}Preparing export to Joomla...${NC}"
    echo "  Target: $joomla_url"
    echo "  Title: $article_title"
    echo "  Category ID: $category_id"
    echo "  Alias: ${article_alias:-auto-generated}"
    echo ""
    
    # Symulacja eksportu
    log_info "Joomla article export initiated (stub - requires Joomla API)"
    echo -e "${YELLOW}Note: Full implementation requires Joomla Web Services configuration.${NC}"
    echo ""
    read -rp "Press Enter to continue..."
}

export_to_nextcloud() {
    log_event "Export to Nextcloud"
    echo ""
    echo -e "${CYAN}═══ EXPORT TO NEXTCLOUD ═══${NC}"
    echo ""
    
    # Sprawdź czy katalog /finish istnieje
    if [[ ! -d "$FINISH_DIR" ]]; then
        log_error "Directory $FINISH_DIR does not exist!"
        mkdir -p "$FINISH_DIR"
    fi
    
    # Lista plików w /finish
    echo "Available files in $FINISH_DIR:"
    ls -la "$FINISH_DIR" 2>/dev/null || echo "No files found."
    echo ""
    
    read -rp "Enter Nextcloud URL (e.g., https://nextcloud.example.com): " nextcloud_url
    read -rp "Enter Nextcloud username: " nextcloud_username
    read -sp "Enter Nextcloud password/app-token: " nextcloud_password
    echo ""
    read -rp "Enter target path in Nextcloud (default: $NEXTCLOUD_DEFAULT_PATH): " target_path
    [[ -z "$target_path" ]] && target_path="$NEXTCLOUD_DEFAULT_PATH"
    
    echo ""
    echo -e "${GREEN}Preparing export to Nextcloud...${NC}"
    echo "  Target: $nextcloud_url"
    echo "  Path: $target_path"
    echo ""
    
    # Symulacja eksportu
    log_info "Nextcloud export initiated (stub - requires Nextcloud WebDAV/API)"
    echo -e "${YELLOW}Note: Full implementation requires Nextcloud WebDAV or OCS API configuration.${NC}"
    echo ""
    read -rp "Press Enter to continue..."
}

show_submenu_export() {
    clear_screen
    show_header
    echo -e "${CYAN}║           EXPORT RESULTS - MOODLE/JOOMLA/NEXTCLOUD           ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  [1] 📚 Export to Moodle as Book Activity                 ║${NC}"
    echo -e "${GREEN}║  [2] 📄 Export to Moodle as Markdown File                 ║${NC}"
    echo -e "${GREEN}║  [3] 📝 Export to Joomla as Article                       ║${NC}"
    echo -e "${GREEN}║  [4] ☁️  Export to Nextcloud                               ║${NC}"
    echo -e "${GREEN}║  [5] ⚙️  Configure Export Settings                         ║${NC}"
    echo -e "${YELLOW}║  [6] ⬅️  Back to Main Menu                                 ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

handle_export_menu() {
    while true; do
        show_submenu_export
        read -rp "  Enter choice [1-6]: " choice
        case $choice in
            1) export_to_moodle_book ;;
            2) export_to_moodle_file ;;
            3) export_to_joomla_article ;;
            4) export_to_nextcloud ;;
            5) export_configure_settings ;;
            6) break ;;
            *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
        esac
        [[ $choice != "6" ]] && read -rp "Press Enter to continue..."
    done
}

export_configure_settings() {
    log_event "Configure Export Settings"
    echo ""
    echo -e "${CYAN}═══ CONFIGURE EXPORT SETTINGS ═══${NC}"
    echo ""
    echo "This menu allows you to configure export constants."
    echo "Settings will be saved to: $CONFIG_FILE"
    echo ""
    
    # Dodaj nowe stałe do pliku konfiguracyjnego
    echo "Current export settings:"
    grep -E "^EXPORT_|^MOODLE_|^JOOMLA_|^NEXTCLOUD_" "$CONFIG_FILE" 2>/dev/null || echo "No export settings configured yet."
    echo ""
    
    read -rp "Enter default Moodle URL: " moodle_url_default
    read -rp "Enter default Joomla URL: " joomla_url_default
    read -rp "Enter default Nextcloud URL: " nextcloud_url_default
    read -rp "Enter default finish directory path (default: $FINISH_DIR): " finish_dir
    [[ -z "$finish_dir" ]] && finish_dir="$FINISH_DIR"
    
    # Zapisz do pliku konfiguracyjnego
    cat >> "$CONFIG_FILE" << EOF

# Export Settings - Added by qwen-tam.sh
EXPORT_MOODLE_URL="${moodle_url_default}"
EXPORT_JOOMLA_URL="${joomla_url_default}"
EXPORT_NEXTCLOUD_URL="${nextcloud_url_default}"
EXPORT_FINISH_DIR="${finish_dir}"
EOF
    
    echo ""
    echo -e "${GREEN}Export settings saved to $CONFIG_FILE${NC}"
    read -rp "Press Enter to continue..."
}


main_menu_loop() {
    while true; do
        show_main_menu
        read -rp "  Enter choice [1-10]: " choice
        
        case $choice in
            1) handle_github_menu ;;
            2) handle_coder_menu ;;
            3) handle_verification_menu ;;
            4) handle_automation_menu ;;
            5) handle_config_menu ;;
            6) handle_logs_menu ;;
            7) handle_system_menu ;;
            8) handle_update_menu ;;
            9) handle_export_menu ;;
            10) 
                log_info "Exiting Qwen Time & Automation Manager"
                log_event "Application exited by user"
                clear_screen
                exit 0
                ;;
            D|d) 
                DEBUG_MODE=!$DEBUG_MODE
                log_info "Debug mode toggled: $DEBUG_MODE"
                ;;
            V|v) 
                VERBOSE_MODE=!$VERBOSE_MODE
                log_info "Verbose mode toggled: $VERBOSE_MODE"
                ;;
            Q|q) 
                log_info "Quitting application"
                clear_screen
                exit 0
                ;;
            *) 
                echo -e "${RED}Invalid option!${NC}"
                sleep 1
                ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# Parsowanie argumentów wiersza poleceń
#-------------------------------------------------------------------------------

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --daemon)
                DAEMON_MODE=true
                INTERACTIVE_MODE=false
                shift
                ;;
            --debug)
                DEBUG_MODE=true
                shift
                ;;
            --verbose)
                VERBOSE_MODE=true
                shift
                ;;
            --config=*)
                CONFIG_FILE="${1#*=}"
                shift
                ;;
            --create-repo)
                log_info "CLI mode: Create repository $2 (stub)"
                exit 0
                ;;
            --generate-code)
                log_info "CLI mode: Generate code (stub)"
                exit 0
                ;;
            --verify)
                log_info "CLI mode: Verify $2 (stub)"
                exit 0
                ;;
            --automate)
                log_info "CLI mode: Automate $2 (stub)"
                exit 0
                ;;
            --help|-h)
                echo "Usage: $SCRIPT_NAME [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --daemon              Run in background mode"
                echo "  --debug               Enable debug mode"
                echo "  --verbose             Enable verbose output"
                echo "  --config=FILE         Use custom config file"
                echo "  --create-repo NAME    Create GitHub repository"
                echo "  --generate-code ...   Generate code with AI"
                echo "  --verify FILE         Verify code file"
                echo "  --automate TASK       Run automation task"
                echo "  --help, -h            Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# Punkt wejścia
#-------------------------------------------------------------------------------

main() {
    parse_arguments "$@"
    init_environment
    setup_signal_handlers
    
    if [[ "$DAEMON_MODE" == true ]]; then
        log_info "Starting daemon mode..."
        # Implementacja trybu daemon
        log_event "Daemon mode started"
    elif [[ "$INTERACTIVE_MODE" == true ]]; then
        log_info "Starting interactive mode..."
        log_event "Interactive mode started"
        main_menu_loop
    fi
}

# Uruchomienie aplikacji
main "$@"
