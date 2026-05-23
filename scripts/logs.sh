#!/bin/bash

#===============================================================================
# QWEN TIME & AUTOMATION MANAGER - LOGS MODULE
# Moduł do zarządzania logami i monitoringu
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# Konfiguracja modułu logs
#-------------------------------------------------------------------------------
readonly LOG_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/logs"
readonly APP_LOG="${LOG_DIR}/app.log"
readonly DEBUG_LOG="${LOG_DIR}/debug.log"
readonly EVENTS_LOG="${LOG_DIR}/events.log"
readonly EXPORT_DIR="${LOG_DIR}/exports"
readonly MAX_LOG_AGE_DAYS=30
readonly MAX_LOG_SIZE_MB=50

# Kolory ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

#-------------------------------------------------------------------------------
# Funkcje pomocnicze
#-------------------------------------------------------------------------------

ensure_log_dir() {
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR"
    fi
    if [[ ! -d "$EXPORT_DIR" ]]; then
        mkdir -p "$EXPORT_DIR"
    fi
}

log_info_local() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[INFO]${NC} $timestamp - $*"
}

log_error_local() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[ERROR]${NC} $timestamp - $*" >&2
}

print_box_header() {
    local title="$1"
    local width=${2:-70}
    local padding=$(( (width - ${#title}) / 2 ))
    
    printf "%${width}s\n" | tr ' ' '═'
    printf "═%*s%s%*s═\n" "$padding" "" "$title" "$((width - padding - ${#title} - 2))" ""
    printf "%${width}s\n" | tr ' ' '═'
}

#-------------------------------------------------------------------------------
# [6.1] View Application Log (app.log)
#-------------------------------------------------------------------------------
logs_view_app() {
    ensure_log_dir
    
    clear
    print_box_header "📄 APPLICATION LOG (app.log)"
    echo ""
    
    if [[ ! -f "$APP_LOG" ]]; then
        echo -e "${YELLOW}⚠️  Application log file does not exist yet.${NC}"
        echo "Log will be created after first application action."
        read -rp "Press Enter to continue..."
        return 0
    fi
    
    local line_count=$(wc -l < "$APP_LOG")
    echo -e "${CYAN}Total lines:${NC} $line_count"
    echo -e "${CYAN}File size:${NC} $(du -h "$APP_LOG" | cut -f1)"
    echo -e "${CYAN}Last modified:${NC} $(stat -c '%y' "$APP_LOG" 2>/dev/null || stat -f '%Sm' "$APP_LOG" 2>/dev/null)"
    echo ""
    
    # Wybór sposobu wyświetlania
    echo -e "${GREEN}Display options:${NC}"
    echo "  [1] View last 50 lines"
    echo "  [2] View last 100 lines"
    echo "  [3] View last 200 lines"
    echo "  [4] View entire file"
    echo "  [5] Search in log"
    echo "  [6] Back"
    echo ""
    
    read -rp "  Enter choice [1-6]: " choice
    
    case $choice in
        1)
            echo ""
            echo -e "${CYAN}─── Last 50 lines ───${NC}"
            tail -n 50 "$APP_LOG" | less -R
            ;;
        2)
            echo ""
            echo -e "${CYAN}─── Last 100 lines ───${NC}"
            tail -n 100 "$APP_LOG" | less -R
            ;;
        3)
            echo ""
            echo -e "${CYAN}─── Last 200 lines ───${NC}"
            tail -n 200 "$APP_LOG" | less -R
            ;;
        4)
            echo ""
            echo -e "${CYAN}─── Entire file ───${NC}"
            less -R "$APP_LOG"
            ;;
        5)
            logs_search_in_file "$APP_LOG" "Application"
            ;;
        6|*)
            echo "Returning to menu..."
            ;;
    esac
    
    echo ""
}

#-------------------------------------------------------------------------------
# [6.2] View Debug Log (debug.log)
#-------------------------------------------------------------------------------
logs_view_debug() {
    ensure_log_dir
    
    clear
    print_box_header "🐛 DEBUG LOG (debug.log)"
    echo ""
    
    if [[ ! -f "$DEBUG_LOG" ]]; then
        echo -e "${YELLOW}⚠️  Debug log file does not exist yet.${NC}"
        echo "Enable DEBUG_MODE to generate debug logs."
        read -rp "Press Enter to continue..."
        return 0
    fi
    
    local line_count=$(wc -l < "$DEBUG_LOG")
    echo -e "${CYAN}Total lines:${NC} $line_count"
    echo -e "${CYAN}File size:${NC} $(du -h "$DEBUG_LOG" | cut -f1)"
    echo -e "${CYAN}Last modified:${NC} $(stat -c '%y' "$DEBUG_LOG" 2>/dev/null || stat -f '%Sm' "$DEBUG_LOG" 2>/dev/null)"
    echo ""
    
    # Statystyki debug log
    echo -e "${CYAN}Debug statistics:${NC}"
    if command -v grep &> /dev/null; then
        local errors=$(grep -c "\[ERROR\]" "$DEBUG_LOG" 2>/dev/null || echo "0")
        local warnings=$(grep -c "\[WARN\]" "$DEBUG_LOG" 2>/dev/null || echo "0")
        local debug_msgs=$(grep -c "\[DEBUG\]" "$DEBUG_LOG" 2>/dev/null || echo "0")
        echo "  Errors: $errors"
        echo "  Warnings: $warnings"
        echo "  Debug messages: $debug_msgs"
    fi
    echo ""
    
    # Wybór sposobu wyświetlania
    echo -e "${GREEN}Display options:${NC}"
    echo "  [1] View last 50 lines"
    echo "  [2] View last 100 lines"
    echo "  [3] View last 200 lines"
    echo "  [4] View entire file"
    echo "  [5] Show only errors"
    echo "  [6] Search in log"
    echo "  [7] Back"
    echo ""
    
    read -rp "  Enter choice [1-7]: " choice
    
    case $choice in
        1)
            echo ""
            echo -e "${CYAN}─── Last 50 lines ───${NC}"
            tail -n 50 "$DEBUG_LOG" | less -R
            ;;
        2)
            echo ""
            echo -e "${CYAN}─── Last 100 lines ───${NC}"
            tail -n 100 "$DEBUG_LOG" | less -R
            ;;
        3)
            echo ""
            echo -e "${CYAN}─── Last 200 lines ───${NC}"
            tail -n 200 "$DEBUG_LOG" | less -R
            ;;
        4)
            echo ""
            echo -e "${CYAN}─── Entire file ───${NC}"
            less -R "$DEBUG_LOG"
            ;;
        5)
            echo ""
            echo -e "${RED}─── Errors only ───${NC}"
            grep "\[ERROR\]" "$DEBUG_LOG" | less -R
            ;;
        6)
            logs_search_in_file "$DEBUG_LOG" "Debug"
            ;;
        7|*)
            echo "Returning to menu..."
            ;;
    esac
    
    echo ""
}

#-------------------------------------------------------------------------------
# [6.3] View Events Log (events.log)
#-------------------------------------------------------------------------------
logs_view_events() {
    ensure_log_dir
    
    clear
    print_box_header "📊 EVENTS LOG (events.log)"
    echo ""
    
    if [[ ! -f "$EVENTS_LOG" ]]; then
        echo -e "${YELLOW}⚠️  Events log file does not exist yet.${NC}"
        echo "Event log will be created after first application event."
        read -rp "Press Enter to continue..."
        return 0
    fi
    
    local line_count=$(wc -l < "$EVENTS_LOG")
    echo -e "${CYAN}Total events:${NC} $line_count"
    echo -e "${CYAN}File size:${NC} $(du -h "$EVENTS_LOG" | cut -f1)"
    echo -e "${CYAN}Last modified:${NC} $(stat -c '%y' "$EVENTS_LOG" 2>/dev/null || stat -f '%Sm' "$EVENTS_LOG" 2>/dev/null)"
    echo ""
    
    # Statystyki zdarzeń
    echo -e "${CYAN}Event categories:${NC}"
    if command -v grep &> /dev/null; then
        local github_events=$(grep -c "GitHub" "$EVENTS_LOG" 2>/dev/null || echo "0")
        local coder_events=$(grep -c "Coder" "$EVENTS_LOG" 2>/dev/null || echo "0")
        local agent_events=$(grep -c "Agent" "$EVENTS_LOG" 2>/dev/null || echo "0")
        local config_events=$(grep -c "Config" "$EVENTS_LOG" 2>/dev/null || echo "0")
        echo "  GitHub operations: $github_events"
        echo "  Coder operations: $coder_events"
        echo "  Agent operations: $agent_events"
        echo "  Configuration changes: $config_events"
    fi
    echo ""
    
    # Wybór sposobu wyświetlania
    echo -e "${GREEN}Display options:${NC}"
    echo "  [1] View last 30 events"
    echo "  [2] View last 100 events"
    echo "  [3] View all events"
    echo "  [4] View by category (filter)"
    echo "  [5] Timeline view (grouped by hour)"
    echo "  [6] Back"
    echo ""
    
    read -rp "  Enter choice [1-6]: " choice
    
    case $choice in
        1)
            echo ""
            echo -e "${CYAN}─── Last 30 events ───${NC}"
            tail -n 30 "$EVENTS_LOG" | less -R
            ;;
        2)
            echo ""
            echo -e "${CYAN}─── Last 100 events ───${NC}"
            tail -n 100 "$EVENTS_LOG" | less -R
            ;;
        3)
            echo ""
            echo -e "${CYAN}─── All events ───${NC}"
            less -R "$EVENTS_LOG"
            ;;
        4)
            logs_filter_events_by_category
            ;;
        5)
            logs_timeline_view
            ;;
        6|*)
            echo "Returning to menu..."
            ;;
    esac
    
    echo ""
}

#-------------------------------------------------------------------------------
# [6.4] Search Logs
#-------------------------------------------------------------------------------
logs_search() {
    ensure_log_dir
    
    clear
    print_box_header "🔍 SEARCH LOGS"
    echo ""
    
    echo "Available log files:"
    local files=()
    if [[ -f "$APP_LOG" ]]; then
        local app_lines=$(wc -l < "$APP_LOG")
        files+=("$APP_LOG")
        echo "  [1] app.log ($app_lines lines)"
    fi
    [[ -f "$DEBUG_LOG" ]] && files+=("$DEBUG_LOG") && echo "  [2] debug.log"
    [[ -f "$EVENTS_LOG" ]] && files+=("$EVENTS_LOG") && echo "  [3] events.log"
    echo "  [4] Search in all logs"
    echo "  [5] Back"
    echo ""
    
    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  No log files found.${NC}"
        read -rp "Press Enter to continue..."
        return 0
    fi
    
    read -rp "  Select log file [1-$(( ${#files[@]} + 1 ))]: " file_choice
    
    if [[ "$file_choice" == "$(( ${#files[@]} + 1 ))" ]]; then
        echo "Returning to menu..."
        return 0
    fi
    
    if [[ "$file_choice" == "4" && ${#files[@]} -ge 3 ]]; then
        logs_search_all
        return 0
    fi
    
    local selected_file=""
    case $file_choice in
        1) [[ -f "$APP_LOG" ]] && selected_file="$APP_LOG" ;;
        2) [[ -f "$DEBUG_LOG" ]] && selected_file="$DEBUG_LOG" ;;
        3) [[ -f "$EVENTS_LOG" ]] && selected_file="$EVENTS_LOG" ;;
        *) echo "Invalid choice"; return 1 ;;
    esac
    
    if [[ -n "$selected_file" ]]; then
        local log_name=$(basename "$selected_file" .log)
        logs_search_in_file "$selected_file" "$log_name"
    else
        echo -e "${RED}Selected file does not exist.${NC}"
    fi
}

#-------------------------------------------------------------------------------
# Helper: Search in specific file
#-------------------------------------------------------------------------------
logs_search_in_file() {
    local file="$1"
    local log_type="${2:-Log}"
    
    if [[ ! -f "$file" ]]; then
        echo -e "${RED}File not found: $file${NC}"
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}Searching in ${log_type} log...${NC}"
    echo "Enter search pattern (supports regex):"
    read -rp "  Pattern: " pattern
    
    if [[ -z "$pattern" ]]; then
        echo "Empty pattern, returning..."
        return 0
    fi
    
    echo ""
    echo -e "${CYAN}Search results for '$pattern':${NC}"
    echo "──────────────────────────────────────────────────────────────"
    
    local matches=$(grep -in "$pattern" "$file" 2>/dev/null || true)
    
    if [[ -z "$matches" ]]; then
        echo -e "${YELLOW}No matches found.${NC}"
    else
        local count=$(echo "$matches" | wc -l)
        echo -e "${GREEN}Found $count match(es):${NC}"
        echo ""
        echo "$matches" | head -n 50 | less -R
        
        if [[ $count -gt 50 ]]; then
            echo ""
            echo -e "${YELLOW}Showing first 50 of $count matches. Use 'View' option to see full log.${NC}"
        fi
    fi
    
    echo ""
    
    # Opcja zapisu wyników
    read -rp "Save results to file? [y/N]: " save_choice
    if [[ "$save_choice" =~ ^[Yy]$ ]]; then
        local timestamp=$(date '+%Y%m%d_%H%M%S')
        local result_file="${EXPORT_DIR}/search_${log_type}_${timestamp}.txt"
        echo "$matches" > "$result_file"
        echo -e "${GREEN}Results saved to: $result_file${NC}"
    fi
}

#-------------------------------------------------------------------------------
# Helper: Search in all logs
#-------------------------------------------------------------------------------
logs_search_all() {
    echo ""
    echo -e "${CYAN}Searching in ALL logs...${NC}"
    echo "Enter search pattern (supports regex):"
    read -rp "  Pattern: " pattern
    
    if [[ -z "$pattern" ]]; then
        echo "Empty pattern, returning..."
        return 0
    fi
    
    echo ""
    echo -e "${CYAN}Search results for '$pattern' in all logs:${NC}"
    echo "──────────────────────────────────────────────────────────────"
    
    local total_matches=0
    
    for log_file in "$APP_LOG" "$DEBUG_LOG" "$EVENTS_LOG"; do
        if [[ -f "$log_file" ]]; then
            local log_name=$(basename "$log_file")
            local matches=$(grep -in "$pattern" "$log_file" 2>/dev/null || true)
            if [[ -n "$matches" ]]; then
                local count=$(echo "$matches" | wc -l)
                echo ""
                echo -e "${GREEN}In $log_name: $count match(es)${NC}"
                echo "$matches" | head -n 10
                total_matches=$((total_matches + count))
            fi
        fi
    done
    
    if [[ $total_matches -eq 0 ]]; then
        echo -e "${YELLOW}No matches found in any log file.${NC}"
    else
        echo ""
        echo -e "${GREEN}Total matches: $total_matches${NC}"
    fi
    
    echo ""
}

#-------------------------------------------------------------------------------
# Helper: Filter events by category
#-------------------------------------------------------------------------------
logs_filter_events_by_category() {
    if [[ ! -f "$EVENTS_LOG" ]]; then
        echo -e "${YELLOW}Events log not found.${NC}"
        return 1
    fi
    
    echo ""
    echo "Select category to filter:"
    echo "  [1] GitHub operations"
    echo "  [2] Coder operations"
    echo "  [3] Agent operations"
    echo "  [4] Configuration changes"
    echo "  [5] System events"
    echo "  [6] Custom filter"
    echo "  [7] Back"
    echo ""
    
    read -rp "  Enter choice [1-7]: " cat_choice
    
    local filter=""
    case $cat_choice in
        1) filter="GitHub" ;;
        2) filter="Coder" ;;
        3) filter="Agent" ;;
        4) filter="Config" ;;
        5) filter="System" ;;
        6) 
            read -rp "  Enter custom filter: " filter
            ;;
        7|*)
            echo "Returning..."
            return 0
            ;;
        *)
            echo "Invalid choice"
            return 1
            ;;
    esac
    
    echo ""
    echo -e "${CYAN}Filtered events for '$filter':${NC}"
    echo "──────────────────────────────────────────────────────────────"
    
    local matches=$(grep -i "$filter" "$EVENTS_LOG" 2>/dev/null || true)
    
    if [[ -z "$matches" ]]; then
        echo -e "${YELLOW}No matching events found.${NC}"
    else
        echo "$matches" | less -R
    fi
    
    echo ""
}

#-------------------------------------------------------------------------------
# Helper: Timeline view
#-------------------------------------------------------------------------------
logs_timeline_view() {
    if [[ ! -f "$EVENTS_LOG" ]]; then
        echo -e "${YELLOW}Events log not found.${NC}"
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}Timeline view (events grouped by hour):${NC}"
    echo "──────────────────────────────────────────────────────────────"
    
    # Extract hour from timestamps and count
    awk -F'[][]' '{print $2}' "$EVENTS_LOG" 2>/dev/null | \
        cut -d' ' -f2 | \
        cut -d':' -f1 | \
        sort | uniq -c | \
        while read count hour; do
            printf "%s:00 - %s:59 : %d events\n" "$hour" "$hour" "$count"
        done | less -R
    
    echo ""
}

#-------------------------------------------------------------------------------
# [6.5] Clear Old Logs
#-------------------------------------------------------------------------------
logs_clear_old() {
    ensure_log_dir
    
    clear
    print_box_header "🧹 CLEAR OLD LOGS"
    echo ""
    
    echo -e "${YELLOW}⚠️  WARNING: This will delete old log files!${NC}"
    echo ""
    echo "Current log files:"
    ls -lh "$LOG_DIR"/*.log 2>/dev/null || echo "  No log files found."
    echo ""
    
    echo "Cleanup options:"
    echo "  [1] Delete logs older than 7 days"
    echo "  [2] Delete logs older than 30 days"
    echo "  [3] Delete logs older than 90 days"
    echo "  [4] Truncate current log files (keep structure)"
    echo "  [5] Delete ALL logs (dangerous!)"
    echo "  [6] Back"
    echo ""
    
    read -rp "  Enter choice [1-6]: " choice
    
    case $choice in
        1)
            logs_cleanup_by_age 7
            ;;
        2)
            logs_cleanup_by_age 30
            ;;
        3)
            logs_cleanup_by_age 90
            ;;
        4)
            logs_truncate_current
            ;;
        5)
            logs_delete_all
            ;;
        6|*)
            echo "Operation cancelled."
            ;;
    esac
    
    echo ""
}

#-------------------------------------------------------------------------------
# Helper: Cleanup logs by age
#-------------------------------------------------------------------------------
logs_cleanup_by_age() {
    local days="$1"
    
    echo ""
    echo -e "${CYAN}Finding log files older than $days days...${NC}"
    
    local deleted=0
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            echo "  Deleting: $file"
            rm -f "$file"
            ((deleted++))
        fi
    done < <(find "$LOG_DIR" -name "*.log.*" -type f -mtime +"$days" 2>/dev/null)
    
    # Also check rotated logs
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            echo "  Deleting: $file"
            rm -f "$file"
            ((deleted++))
        fi
    done < <(find "$LOG_DIR" -name "*.log.[0-9]*" -type f -mtime +"$days" 2>/dev/null)
    
    echo ""
    echo -e "${GREEN}Deleted $deleted file(s).${NC}"
}

#-------------------------------------------------------------------------------
# Helper: Truncate current log files
#-------------------------------------------------------------------------------
logs_truncate_current() {
    echo ""
    echo -e "${CYAN}Truncating current log files...${NC}"
    
    local truncated=0
    for log_file in "$APP_LOG" "$DEBUG_LOG" "$EVENTS_LOG"; do
        if [[ -f "$log_file" ]]; then
            local size=$(du -h "$log_file" | cut -f1)
            : > "$log_file"  # Truncate file
            echo "  Truncated: $log_file (was $size)"
            ((truncated++))
        fi
    done
    
    echo ""
    echo -e "${GREEN}Truncated $truncated file(s).${NC}"
}

#-------------------------------------------------------------------------------
# Helper: Delete all logs
#-------------------------------------------------------------------------------
logs_delete_all() {
    echo ""
    echo -e "${RED}⚠️  DANGER ZONE ⚠️${NC}"
    echo "This will PERMANENTLY DELETE ALL LOG FILES!"
    echo ""
    read -rp "Type 'DELETE' to confirm: " confirm
    
    if [[ "$confirm" != "DELETE" ]]; then
        echo "Operation cancelled."
        return 0
    fi
    
    local deleted=0
    for log_file in "$LOG_DIR"/*.log "$LOG_DIR"/*.log.*; do
        if [[ -f "$log_file" ]]; then
            rm -f "$log_file"
            echo "  Deleted: $log_file"
            ((deleted++))
        fi
    done
    
    echo ""
    echo -e "${GREEN}Deleted $deleted file(s).${NC}"
    echo -e "${YELLOW}Note: New log files will be created on next application action.${NC}"
}

#-------------------------------------------------------------------------------
# [6.6] Export Logs
#-------------------------------------------------------------------------------
logs_export() {
    ensure_log_dir
    
    clear
    print_box_header "📥 EXPORT LOGS"
    echo ""
    
    echo "Available log files:"
    local count=1
    declare -a log_files=()
    
    if [[ -f "$APP_LOG" ]]; then
        log_files+=("$APP_LOG")
        echo "  [$count] app.log ($(du -h "$APP_LOG" | cut -f1))"
        ((count++))
    fi
    
    if [[ -f "$DEBUG_LOG" ]]; then
        log_files+=("$DEBUG_LOG")
        echo "  [$count] debug.log ($(du -h "$DEBUG_LOG" | cut -f1))"
        ((count++))
    fi
    
    if [[ -f "$EVENTS_LOG" ]]; then
        log_files+=("$EVENTS_LOG")
        echo "  [$count] events.log ($(du -h "$EVENTS_LOG" | cut -f1))"
        ((count++))
    fi
    
    echo "  [$count] Export ALL logs as ZIP"
    ((count++))
    echo "  [$count] Back"
    echo ""
    
    local total_options=${#log_files[@]}
    [[ $total_options -gt 0 ]] && total_options=$((total_options + 2)) || total_options=2
    
    read -rp "  Enter choice [1-$total_options]: " choice
    
    if [[ "$choice" == "$((total_options))" ]]; then
        echo "Returning to menu..."
        return 0
    fi
    
    if [[ "$choice" == "$((total_options - 1))" && ${#log_files[@]} -gt 0 ]]; then
        logs_export_all_as_zip
        return 0
    fi
    
    local idx=$((choice - 1))
    if [[ $idx -ge 0 && $idx -lt ${#log_files[@]} ]]; then
        logs_export_single "${log_files[$idx]}"
    else
        echo "Invalid choice."
    fi
    
    echo ""
}

#-------------------------------------------------------------------------------
# Helper: Export single log file
#-------------------------------------------------------------------------------
logs_export_single() {
    local log_file="$1"
    
    if [[ ! -f "$log_file" ]]; then
        echo -e "${RED}File not found: $log_file${NC}"
        return 1
    fi
    
    local base_name=$(basename "$log_file")
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local export_name="${base_name%.log}_${timestamp}.log"
    local export_path="${EXPORT_DIR}/${export_name}"
    
    cp "$log_file" "$export_path"
    
    echo ""
    echo -e "${GREEN}✓ Export successful!${NC}"
    echo "  Source: $log_file"
    echo "  Destination: $export_path"
    echo "  Size: $(du -h "$export_path" | cut -f1)"
}

#-------------------------------------------------------------------------------
# Helper: Export all logs as ZIP
#-------------------------------------------------------------------------------
logs_export_all_as_zip() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local zip_name="qwen_tam_logs_${timestamp}.zip"
    local zip_path="${EXPORT_DIR}/${zip_name}"
    
    echo ""
    echo -e "${CYAN}Creating ZIP archive...${NC}"
    
    # Check if zip is available
    if ! command -v zip &> /dev/null; then
        echo -e "${YELLOW}⚠️  'zip' command not found. Using tar instead.${NC}"
        local tar_name="qwen_tam_logs_${timestamp}.tar.gz"
        local tar_path="${EXPORT_DIR}/${tar_name}"
        
        tar -czf "$tar_path" -C "$LOG_DIR" . 2>/dev/null
        
        echo ""
        echo -e "${GREEN}✓ Export successful!${NC}"
        echo "  Destination: $tar_path"
        echo "  Size: $(du -h "$tar_path" | cut -f1)"
        return 0
    fi
    
    # Create temporary directory for export
    local temp_dir=$(mktemp -d)
    
    # Copy log files
    for log_file in "$APP_LOG" "$DEBUG_LOG" "$EVENTS_LOG"; do
        if [[ -f "$log_file" ]]; then
            cp "$log_file" "$temp_dir/"
        fi
    done
    
    # Create ZIP
    cd "$temp_dir" && zip -r "$zip_path" . > /dev/null 2>&1
    cd - > /dev/null
    
    # Cleanup
    rm -rf "$temp_dir"
    
    echo ""
    echo -e "${GREEN}✓ Export successful!${NC}"
    echo "  Destination: $zip_path"
    echo "  Size: $(du -h "$zip_path" | cut -f1)"
}

#-------------------------------------------------------------------------------
# [6.7] Real-time Log Monitor
#-------------------------------------------------------------------------------
logs_realtime_monitor() {
    ensure_log_dir
    
    clear
    print_box_header "📈 REAL-TIME LOG MONITOR"
    echo ""
    
    echo -e "${CYAN}Select log to monitor:${NC}"
    echo "  [1] Application Log (app.log)"
    echo "  [2] Debug Log (debug.log)"
    echo "  [3] Events Log (events.log)"
    echo "  [4] Monitor ALL logs (multiplexed)"
    echo "  [5] Back"
    echo ""
    
    read -rp "  Enter choice [1-5]: " choice
    
    case $choice in
        1)
            if [[ -f "$APP_LOG" ]]; then
                echo ""
                echo -e "${CYAN}Monitoring app.log (Press Ctrl+C to stop)...${NC}"
                echo "──────────────────────────────────────────────────────────────"
                tail -f "$APP_LOG" 2>/dev/null
            else
                echo -e "${YELLOW}Log file not created yet.${NC}"
            fi
            ;;
        2)
            if [[ -f "$DEBUG_LOG" ]]; then
                echo ""
                echo -e "${CYAN}Monitoring debug.log (Press Ctrl+C to stop)...${NC}"
                echo "──────────────────────────────────────────────────────────────"
                tail -f "$DEBUG_LOG" 2>/dev/null
            else
                echo -e "${YELLOW}Log file not created yet.${NC}"
            fi
            ;;
        3)
            if [[ -f "$EVENTS_LOG" ]]; then
                echo ""
                echo -e "${CYAN}Monitoring events.log (Press Ctrl+C to stop)...${NC}"
                echo "──────────────────────────────────────────────────────────────"
                tail -f "$EVENTS_LOG" 2>/dev/null
            else
                echo -e "${YELLOW}Log file not created yet.${NC}"
            fi
            ;;
        4)
            logs_monitor_multiplexed
            ;;
        5|*)
            echo "Returning to menu..."
            ;;
    esac
    
    echo ""
}

#-------------------------------------------------------------------------------
# Helper: Multiplexed log monitor
#-------------------------------------------------------------------------------
logs_monitor_multiplexed() {
    echo ""
    echo -e "${CYAN}Monitoring ALL logs (Press Ctrl+C to stop)...${NC}"
    echo "Format: [SOURCE] message"
    echo "──────────────────────────────────────────────────────────────"
    
    # Use tail with multiple files if available
    local files_to_monitor=()
    [[ -f "$APP_LOG" ]] && files_to_monitor+=("$APP_LOG")
    [[ -f "$DEBUG_LOG" ]] && files_to_monitor+=("$DEBUG_LOG")
    [[ -f "$EVENTS_LOG" ]] && files_to_monitor+=("$EVENTS_LOG")
    
    if [[ ${#files_to_monitor[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No log files to monitor.${NC}"
        return 0
    fi
    
    tail -f "${files_to_monitor[@]}" 2>/dev/null | \
        while IFS= read -r line; do
            local source="UNKNOWN"
            if [[ "$line" == *"app.log"* ]]; then
                source="APP"
            elif [[ "$line" == *"debug.log"* ]]; then
                source="DBG"
            elif [[ "$line" == *"events.log"* ]]; then
                source="EVT"
            fi
            
            # Skip the "==>" lines from tail
            if [[ "$line" != "==>"* ]]; then
                echo -e "${BLUE}[$source]${NC} $line"
            fi
        done
}

#-------------------------------------------------------------------------------
# Menu główne modułu Logs
#-------------------------------------------------------------------------------
logs_menu() {
    while true; do
        clear
        show_header_logs_submenu
        read -rp "  Enter choice [6.1-6.8]: " choice
        
        case $choice in
            6.1) logs_view_app ;;
            6.2) logs_view_debug ;;
            6.3) logs_view_events ;;
            6.4) logs_search ;;
            6.5) logs_clear_old ;;
            6.6) logs_export ;;
            6.7) logs_realtime_monitor ;;
            6.8|68) 
                echo "Returning to main menu..."
                break
                ;;
            *) 
                echo -e "${RED}Invalid option!${NC}"
                sleep 1
                ;;
        esac
        
        if [[ "$choice" != "6.8" && "$choice" != "68" ]]; then
            read -rp "Press Enter to continue..."
        fi
    done
}

#-------------------------------------------------------------------------------
# Display submenu header
#-------------------------------------------------------------------------------
show_header_logs_submenu() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                  LOGS & MONITORING                           ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo -e "${GREEN}║  [6.1] 📄 View Application Log (app.log)                     ║${NC}"
    echo -e "${GREEN}║  [6.2] 🐛 View Debug Log (debug.log)                         ║${NC}"
    echo -e "${GREEN}║  [6.3] 📊 View Events Log (events.log)                       ║${NC}"
    echo -e "${GREEN}║  [6.4] 🔍 Search Logs                                        ║${NC}"
    echo -e "${GREEN}║  [6.5] 🧹 Clear Old Logs                                     ║${NC}"
    echo -e "${GREEN}║  [6.6] 📥 Export Logs                                        ║${NC}"
    echo -e "${GREEN}║  [6.7] 📈 Real-time Log Monitor                              ║${NC}"
    echo -e "${YELLOW}║  [6.8] ⬅️  Back to Main Menu                                 ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Jeśli skrypt jest uruchamiany bezpośrednio (nie source'owany)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Ustawienie SCRIPT_DIR dla samodzielnego uruchomienia
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    logs_menu
fi
