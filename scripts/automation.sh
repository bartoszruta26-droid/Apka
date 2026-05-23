#!/bin/bash

#===============================================================================
# AUTOMATION.SH - Automatyzacja z Qwen Agent
# Obsługa wszystkich funkcji z Podmenu 4: Automation & AI Agent
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# Konfiguracja i zmienne globalne
#-------------------------------------------------------------------------------
readonly AGENT_VERSION="1.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly WORKFLOW_DIR="${SCRIPT_DIR}/workflows"
readonly TASKS_DIR="${SCRIPT_DIR}/tasks"
readonly HISTORY_FILE="${SCRIPT_DIR}/logs/task_history.log"
readonly AGENT_LOG="${SCRIPT_DIR}/logs/agent.log"

# Kolory ANSI
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m' # No Color

#-------------------------------------------------------------------------------
# Funkcje pomocnicze
#-------------------------------------------------------------------------------

log_agent() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[AGENT] $timestamp - $*" >> "$AGENT_LOG"
}

log_task() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[TASK] $timestamp - $*" >> "$HISTORY_FILE"
}

show_agent_header() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              QWEN AGENT - AUTOMATION MODULE                  ║"
    echo "║                       v${AGENT_VERSION}                              ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo -e "${NC}"
}

display_menu_box() {
    local title="$1"
    shift
    local options=("$@")
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    printf "${CYAN}║  %-62s${NC}\n" "$title"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    
    for opt in "${options[@]}"; do
        printf "${GREEN}║  ${NC}%-62s${NC}\n" "$opt"
    done
    
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

#-------------------------------------------------------------------------------
# [4.1] Start AI Discussion Session
#-------------------------------------------------------------------------------

ai_discussion_session() {
    clear
    show_agent_header
    display_menu_box "💬 AI DISCUSSION SESSION" \
        "Rozpocznij sesję dyskusyjną z Qwen Agent" \
        "Agent pomoże zrozumieć wymagania i zaplanować automatyzację"
    
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Witaj w sesji dyskusyjnej z Qwen Agent!${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    log_agent "Starting AI discussion session"
    
    # Inicjalizacja kontekstu sesji
    local session_id="session_$(date +%Y%m%d_%H%M%S)"
    local context_file="/tmp/qwen_agent_${session_id}.ctx"
    
    # Powitanie i zebranie celu
    echo -e "${CYAN}🤖 AGENT:${NC} Cześć! Jestem Qwen Agent. Pomogę Ci zaplanować"
    echo "         automatyzację zadań. Opisz mi, co chcesz osiągnąć."
    echo ""
    read -rp "📝 Twój cel: " user_goal
    
    if [[ -z "$user_goal" ]]; then
        echo -e "${RED}❌ Cel nie może być pusty!${NC}"
        sleep 2
        return 1
    fi
    
    echo "$user_goal" > "$context_file"
    log_agent "Session $session_id - User goal: $user_goal"
    
    # Pytania doprecyzowujące
    echo ""
    echo -e "${CYAN}🤖 AGENT:${NC} Doskonale! Aby lepiej zrozumieć Twoje wymagania,"
    echo "         odpiedz proszę na kilka pytań:"
    echo ""
    
    # Pytanie 1: Częstotliwość
    echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"
    read -rp "📅 Jak często ma być wykonywane to zadanie? (jednorazowo/dziennie/tygodniowo/ciągle): " frequency
    echo "$frequency" >> "$context_file"
    
    # Pytanie 2: Warunki wyzwalania
    echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"
    read -rp "⚡ Co ma wyzwalać wykonanie zadania? (czas/zdarzenie/ręczne): " trigger_type
    echo "$trigger_type" >> "$context_file"
    
    # Pytanie 3: Akcje
    echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"
    read -rp "🔧 Jakie główne akcje mają być wykonane? (np. backup, commit, analiza): " actions
    echo "$actions" >> "$context_file"
    
    # Pytanie 4: Powiadomienia
    echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"
    read -rp "🔔 Czy chcesz otrzymywać powiadomienia? (tak/nie): " notifications
    echo "$notifications" >> "$context_file"
    
    # Generowanie planu workflow
    echo ""
    echo -e "${CYAN}🤖 AGENT:${NC} Dziękuję! Na podstawie Twoich odpowiedzi generuję plan..."
    echo ""
    
    sleep 2
    
    # Wyświetlenie planu
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  📋 PROPLANOWANY WORKFLOW:${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  📁 ID Sesji: $session_id"
    echo "  🎯 Cel: $user_goal"
    echo "  📅 Częstotliwość: $frequency"
    echo "  ⚡ Wyzwalacz: $trigger_type"
    echo "  🔧 Akcje: $actions"
    echo "  🔔 Powiadomienia: $notifications"
    echo ""
    
    # Zapis planu jako workflow
    local workflow_file="${WORKFLOW_DIR}/${session_id}.workflow"
    mkdir -p "$WORKFLOW_DIR"
    
    cat > "$workflow_file" << EOF
# Workflow Configuration
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
SESSION_ID=$session_id
GOAL=$user_goal
FREQUENCY=$frequency
TRIGGER_TYPE=$trigger_type
ACTIONS=$actions
NOTIFICATIONS=$notifications
STATUS=pending
CREATED_AT=$(date -Iseconds)
EOF
    
    log_agent "Workflow created: $workflow_file"
    log_task "Discussion session completed - workflow $session_id created"
    
    echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"
    echo -e "${GREEN}✅ Plan został zapisany!${NC}"
    echo "   Plik workflow: $workflow_file"
    echo ""
    echo -e "${CYAN}🤖 AGENT:${NC} Możesz teraz uruchomić ten workflow z menu 4.3"
    echo "         lub edytować go ręcznie przed uruchomieniem."
    echo ""
    
    read -rp "Naciśnij Enter aby kontynuować..."
    
    # Cleanup
    rm -f "$context_file"
}

#-------------------------------------------------------------------------------
# [4.2] Create Automation Workflow
#-------------------------------------------------------------------------------

create_automation_workflow() {
    clear
    show_agent_header
    display_menu_box "📋 CREATE AUTOMATION WORKFLOW" \
        "Utwórz nowy workflow automatyzacji" \
        "Definicja kroków, warunków i wyjątków"
    
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Kreator Workflow Automatyzacji${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    log_agent "Creating new automation workflow"
    
    # Pobranie nazwy workflow
    read -rp "📛 Nazwa workflow (bez spacji, np. daily_backup): " workflow_name
    
    if [[ -z "$workflow_name" ]]; then
        echo -e "${RED}❌ Nazwa workflow nie może być pusta!${NC}"
        sleep 2
        return 1
    fi
    
    mkdir -p "$WORKFLOW_DIR"
    local workflow_file="${WORKFLOW_DIR}/${workflow_name}.workflow"
    
    if [[ -f "$workflow_file" ]]; then
        echo -e "${YELLOW}⚠️  Workflow o tej nazwie już istnieje!${NC}"
        read -rp "Czy nadpisać? (t/n): " overwrite
        if [[ "$overwrite" != "t" && "$overwrite" != "T" ]]; then
            return 1
        fi
    fi
    
    echo ""
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}  Definiowanie kroków workflow:${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    local steps=()
    local step_num=1
    
    while true; do
        echo -e "${GREEN}KROK ${step_num}:${NC}"
        read -rp "  Opis czynności: " step_desc
        
        if [[ -z "$step_desc" && $step_num -gt 1 ]]; then
            break
        elif [[ -z "$step_desc" ]]; then
            echo -e "${RED}  Pierwszy krok jest wymagany!${NC}"
            continue
        fi
        
        read -rp "  Komenda do wykonania: " step_cmd
        read -rp "  Warunek powodzenia (exit code, domyślnie 0): " step_success
        step_success=${step_success:-0}
        
        steps+=("${step_num}|${step_desc}|${step_cmd}|${step_success}")
        echo -e "${GREEN}  ✓ Dodano krok ${step_num}${NC}"
        echo ""
        
        ((step_num++))
        
        if [[ $step_num -gt 10 ]]; then
            echo -e "${YELLOW}  ⚠️  Maksymalna liczba kroków (10) osiągnięta${NC}"
            break
        fi
        
        read -rp "  Dodać kolejny krok? (t/n): " add_more
        if [[ "$add_more" != "t" && "$add_more" != "T" ]]; then
            break
        fi
        echo ""
    done
    
    # Warunki i wyjątki
    echo ""
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}  Konfiguracja obsługi błędów:${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    read -rp "  Akcja przy błędzie (stop/retry/continue): " error_action
    error_action=${error_action:-stop}
    
    read -rp "  Liczba prób retry (0 = brak): " retry_count
    retry_count=${retry_count:-0}
    
    read -rp "  Czas oczekiwania między retry (sekundy): " retry_delay
    retry_delay=${retry_delay:-5}
    
    # Harmonogram
    echo ""
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}  Harmonogram wykonania:${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    read -rp "  Typ harmonogramu (once/daily/weekly/custom): " schedule_type
    schedule_type=${schedule_type:-once}
    
    local schedule_expr=""
    if [[ "$schedule_type" == "daily" ]]; then
        read -rp "  Godzina wykonania (HH:MM): " schedule_time
        schedule_expr="0 ${schedule_time#*:} ${schedule_time%:*} * * *"
    elif [[ "$schedule_type" == "weekly" ]]; then
        read -rp "  Dzień tygodnia (1-7, 1=poniedziałek): " weekday
        read -rp "  Godzina wykonania (HH:MM): " schedule_time
        schedule_expr="0 ${schedule_time#*:} ${schedule_time%:*} * * $weekday"
    elif [[ "$schedule_type" == "custom" ]]; then
        read -rp "  Wyrażenie cron: " schedule_expr
    fi
    
    # Zapis workflow
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Zapisywanie workflow...${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    cat > "$workflow_file" << EOF
# Workflow: $workflow_name
# Created: $(date '+%Y-%m-%d %H:%M:%S')

[METADATA]
NAME=$workflow_name
CREATED_AT=$(date -Iseconds)
STATUS=pending

[SCHEDULE]
TYPE=$schedule_type
CRON=$schedule_expr

[ERROR_HANDLING]
ON_ERROR=$error_action
RETRY_COUNT=$retry_count
RETRY_DELAY=$retry_delay

[STEPS]
EOF
    
    for step in "${steps[@]}"; do
        echo "STEP_$step" >> "$workflow_file"
    done
    
    log_agent "Workflow created: $workflow_file with ${#steps[@]} steps"
    log_task "Workflow $workflow_name created with ${#steps[@]} steps"
    
    echo -e "${GREEN}✅ Workflow zapisany pomyślnie!${NC}"
    echo "   Lokalizacja: $workflow_file"
    echo "   Liczba kroków: ${#steps[@]}"
    echo "   Harmonogram: $schedule_type"
    echo ""
    
    read -rp "Naciśnij Enter aby kontynuować..."
}

#-------------------------------------------------------------------------------
# [4.3] Run Automation Task
#-------------------------------------------------------------------------------

run_automation_task() {
    clear
    show_agent_header
    display_menu_box "▶️  RUN AUTOMATION TASK" \
        "Uruchom zadanie automatyzacji" \
        "Wybierz workflow i wykonaj go"
    
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Uruchamianie Zadania Automatyzacji${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Lista dostępnych workflow
    if [[ ! -d "$WORKFLOW_DIR" ]] || [[ -z "$(ls -A "$WORKFLOW_DIR" 2>/dev/null)" ]]; then
        echo -e "${RED}❌ Brak dostępnych workflow!${NC}"
        echo "   Utwórz workflow najpierw z menu 4.2"
        echo ""
        read -rp "Naciśnij Enter aby kontynuować..."
        return 1
    fi
    
    echo -e "${CYAN}Dostępne workflow:${NC}"
    echo ""
    
    local workflows=()
    local idx=1
    
    for wf in "$WORKFLOW_DIR"/*.workflow; do
        if [[ -f "$wf" ]]; then
            local name=$(basename "$wf" .workflow)
            echo "  [$idx] $name"
            workflows+=("$wf")
            ((idx++))
        fi
    done
    
    echo ""
    read -rp "Wybierz workflow [1-$((idx-1))]: " selection
    
    if [[ $selection -lt 1 || $selection -gt ${#workflows[@]} ]]; then
        echo -e "${RED}❌ Nieprawidłowy wybór!${NC}"
        sleep 2
        return 1
    fi
    
    local selected_wf="${workflows[$((selection-1))]}"
    local wf_name=$(basename "$selected_wf" .workflow)
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Przygotowanie do uruchomienia: $wf_name${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Tryb wykonania
    echo -e "${YELLOW}Tryb wykonania:${NC}"
    echo "  [1] Normalny (z potwierdzeniami)"
    echo "  [2] Verbose (szczegółowe logi)"
    echo "  [3] Dry-run (symulacja bez zmian)"
    read -rp "Wybierz tryb [1-3]: " run_mode
    run_mode=${run_mode:-1}
    
    echo ""
    read -rp "Czy na pewno uruchomić workflow? (t/n): " confirm
    if [[ "$confirm" != "t" && "$confirm" != "T" ]]; then
        echo -e "${YELLOW}Anulowano uruchomienie${NC}"
        sleep 1
        return 0
    fi
    
    # Wykonanie workflow
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  URUCHAMIANIE WORKFLOW: $wf_name${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    log_agent "Starting workflow execution: $wf_name (mode: $run_mode)"
    log_task "Workflow $wf_name started"
    
    local start_time=$(date +%s)
    local total_steps=0
    local successful_steps=0
    local failed_steps=0
    
    # Parsowanie i wykonanie kroków
    while IFS='=' read -r key value; do
        if [[ "$key" =~ ^STEP_[0-9]+ ]]; then
            ((total_steps++))
            
            IFS='|' read -r step_num step_desc step_cmd step_success <<< "$value"
            
            echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
            echo -e "${GREEN}KROK ${step_num}/${total_steps}:${NC} $step_desc"
            echo -e "${YELLOW}Komenda:${NC} $step_cmd"
            
            if [[ "$run_mode" == "3" ]]; then
                echo -e "${YELLOW}[DRY-RUN] Pominięto wykonanie${NC}"
                ((successful_steps++))
                continue
            fi
            
            # Wykonanie komendy
            set +e
            eval "$step_cmd" > /tmp/step_output_$$.txt 2>&1
            local exit_code=$?
            set -e
            
            if [[ $exit_code -eq $step_success ]]; then
                echo -e "${GREEN}✓ Sukces (exit code: $exit_code)${NC}"
                ((successful_steps++))
            else
                echo -e "${RED}✗ Błąd (exit code: $exit_code, oczekiwano: $step_success)${NC}"
                ((failed_steps++))
                
                # Obsługa błędu
                local on_error=$(grep "^ON_ERROR=" "$selected_wf" | cut -d'=' -f2)
                case "$on_error" in
                    stop)
                        echo -e "${RED}Zatrzymywanie workflow...${NC}"
                        break
                        ;;
                    retry)
                        local retry_count=$(grep "^RETRY_COUNT=" "$selected_wf" | cut -d'=' -f2)
                        local retry_delay=$(grep "^RETRY_DELAY=" "$selected_wf" | cut -d'=' -f2)
                        
                        for ((i=1; i<=retry_count; i++)); do
                            echo -e "${YELLOW}Próba $i/$retry_count za $retry_delay sekund...${NC}"
                            sleep "$retry_delay"
                            
                            set +e
                            eval "$step_cmd" > /tmp/step_output_$$.txt 2>&1
                            exit_code=$?
                            set -e
                            
                            if [[ $exit_code -eq $step_success ]]; then
                                echo -e "${GREEN}✓ Sukces po retry!${NC}"
                                ((successful_steps++))
                                break 2
                            fi
                        done
                        ((failed_steps++))
                        ;;
                    continue)
                        echo -e "${YELLOW}Kontynuowanie pomimo błędu...${NC}"
                        ;;
                esac
            fi
            
            [[ "$run_mode" == "2" ]] && cat /tmp/step_output_$$.txt
            rm -f /tmp/step_output_$$.txt
            echo ""
        fi
    done < "$selected_wf"
    
    # Podsumowanie
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  PODSUMOWANIE WYKONANIA${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  Workflow: $wf_name"
    echo "  Czas trwania: ${duration}s"
    echo "  Kroki łącznie: $total_steps"
    echo -e "  ${GREEN}✓ Sukcesy: $successful_steps${NC}"
    echo -e "  ${RED}✗ Błędy: $failed_steps${NC}"
    echo ""
    
    log_agent "Workflow $wf_name completed: $successful_steps/$total_steps steps successful"
    log_task "Workflow $wf_name finished - success: $successful_steps, failed: $failed_steps, duration: ${duration}s"
    
    read -rp "Naciśnij Enter aby kontynuować..."
}

#-------------------------------------------------------------------------------
# [4.4] Pause/Resume Background Tasks
#-------------------------------------------------------------------------------

pause_resume_tasks() {
    clear
    show_agent_header
    display_menu_box "⏸️  PAUSE/RESUME BACKGROUND TASKS" \
        "Zarządzanie zadaniami w tle" \
        "Pauzowanie i wznawianie procesów"
    
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Zarządzanie Zadaniami w Tle${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Sprawdzenie PID file
    local pid_dir="${SCRIPT_DIR}/pids"
    mkdir -p "$pid_dir"
    
    local running_tasks=()
    
    echo -e "${CYAN}Sprawdzanie uruchomionych zadań...${NC}"
    echo ""
    
    for pid_file in "$pid_dir"/*.pid; do
        if [[ -f "$pid_file" ]]; then
            local task_name=$(basename "$pid_file" .pid)
            local pid=$(cat "$pid_file")
            
            if kill -0 "$pid" 2>/dev/null; then
                echo "  [✓] $task_name (PID: $pid) - RUNNING"
                running_tasks+=("$task_name:$pid")
            else
                echo "  [✗] $task_name (PID: $pid) - STALE (usunięto)"
                rm -f "$pid_file"
            fi
        fi
    done
    
    if [[ ${#running_tasks[@]} -eq 0 ]]; then
        echo -e "${YELLOW}Brak uruchomionych zadań w tle${NC}"
        echo ""
        read -rp "Naciśnij Enter aby kontynuować..."
        return 0
    fi
    
    echo ""
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
    echo "Dostępne akcje:"
    echo "  [1] Pauzuj zadanie"
    echo "  [2] Wznów zadanie"
    echo "  [3] Wyjdź"
    echo ""
    
    read -rp "Wybierz akcję [1-3]: " action
    
    case "$action" in
        1)
            echo ""
            read -rp "Podaj nazwę zadania do pauzy: " task_to_pause
            
            for task in "${running_tasks[@]}"; do
                local name="${task%%:*}"
                local pid="${task##*:}"
                
                if [[ "$name" == "$task_to_pause" ]]; then
                    kill -STOP "$pid"
                    echo -e "${GREEN}✓ Zadanie $name zostało pauzowane (PID: $pid)${NC}"
                    log_agent "Task paused: $name (PID: $pid)"
                    break
                fi
            done
            ;;
        2)
            echo ""
            read -rp "Podaj nazwę zadania do wznowienia: " task_to_resume
            
            for task in "${running_tasks[@]}"; do
                local name="${task%%:*}"
                local pid="${task##*:}"
                
                if [[ "$name" == "$task_to_resume" ]]; then
                    kill -CONT "$pid"
                    echo -e "${GREEN}✓ Zadanie $name zostało wznowione (PID: $pid)${NC}"
                    log_agent "Task resumed: $name (PID: $pid)"
                    break
                fi
            done
            ;;
        3)
            echo "Wyjście..."
            ;;
        *)
            echo -e "${RED}Nieprawidłowy wybór!${NC}"
            ;;
    esac
    
    echo ""
    read -rp "Naciśnij Enter aby kontynuować..."
}

#-------------------------------------------------------------------------------
# [4.5] Stop Running Tasks
#-------------------------------------------------------------------------------

stop_running_tasks() {
    clear
    show_agent_header
    display_menu_box "🛑 STOP RUNNING TASKS" \
        "Zatrzymaj działające zadania" \
        "Bezpieczne kończenie procesów"
    
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Zatrzymywanie Zadań${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    local pid_dir="${SCRIPT_DIR}/pids"
    mkdir -p "$pid_dir"
    
    local running_tasks=()
    
    echo -e "${CYAN}Uruchomione zadania:${NC}"
    echo ""
    
    for pid_file in "$pid_dir"/*.pid; do
        if [[ -f "$pid_file" ]]; then
            local task_name=$(basename "$pid_file" .pid)
            local pid=$(cat "$pid_file")
            
            if kill -0 "$pid" 2>/dev/null; then
                echo "  [$task_name] PID: $pid"
                running_tasks+=("$task_name:$pid")
            else
                rm -f "$pid_file"
            fi
        fi
    done
    
    if [[ ${#running_tasks[@]} -eq 0 ]]; then
        echo -e "${YELLOW}Brak zadań do zatrzymania${NC}"
        echo ""
        read -rp "Naciśnij Enter aby kontynuować..."
        return 0
    fi
    
    echo ""
    echo -e "${RED}───────────────────────────────────────────────────────────────${NC}"
    echo -e "${RED} UWAGA: Zatrzymanie zadania może spowodować utratę danych!${NC}"
    echo -e "${RED}───────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    read -rp "Podaj nazwę zadania do zatrzymania (lub 'ALL' dla wszystkich): " task_to_stop
    
    if [[ "$task_to_stop" == "ALL" || "$task_to_stop" == "all" ]]; then
        for task in "${running_tasks[@]}"; do
            local pid="${task##*:}"
            kill -TERM "$pid" 2>/dev/null && echo -e "${GREEN}✓ Zatrzymano (PID: $pid)${NC}"
        done
        rm -f "$pid_dir"/*.pid
        log_agent "All tasks stopped"
    else
        for task in "${running_tasks[@]}"; do
            local name="${task%%:*}"
            local pid="${task##*:}"
            
            if [[ "$name" == "$task_to_stop" ]]; then
                kill -TERM "$pid" 2>/dev/null
                echo -e "${GREEN}✓ Zadanie $name zatrzymane (PID: $pid)${NC}"
                rm -f "$pid_file"
                log_agent "Task stopped: $name (PID: $pid)"
                break
            fi
        done
    fi
    
    echo ""
    read -rp "Naciśnij Enter aby kontynuować..."
}

#-------------------------------------------------------------------------------
# [4.6] Schedule Automated Task
#-------------------------------------------------------------------------------

schedule_automated_task() {
    clear
    show_agent_header
    display_menu_box "📅 SCHEDULE AUTOMATED TASK" \
        "Zaplanuj zadanie automatyczne" \
        "Konfiguracja cron dla workflow"
    
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Harmonogram Zadań Automatycznych${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Lista workflow
    if [[ ! -d "$WORKFLOW_DIR" ]] || [[ -z "$(ls -A "$WORKFLOW_DIR" 2>/dev/null)" ]]; then
        echo -e "${RED}❌ Brak dostępnych workflow!${NC}"
        read -rp "Naciśnij Enter aby kontynuować..."
        return 1
    fi
    
    echo -e "${CYAN}Dostępne workflow:${NC}"
    local workflows=()
    local idx=1
    
    for wf in "$WORKFLOW_DIR"/*.workflow; do
        if [[ -f "$wf" ]]; then
            local name=$(basename "$wf" .workflow)
            echo "  [$idx] $name"
            workflows+=("$wf")
            ((idx++))
        fi
    done
    
    echo ""
    read -rp "Wybierz workflow do zaplanowania [1-$((idx-1))]: " selection
    
    if [[ $selection -lt 1 || $selection -gt ${#workflows[@]} ]]; then
        echo -e "${RED}❌ Nieprawidłowy wybór!${NC}"
        sleep 2
        return 1
    fi
    
    local selected_wf="${workflows[$((selection-1))]}"
    local wf_name=$(basename "$selected_wf" .workflow)
    
    echo ""
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}  Konfiguracja harmonogramu dla: $wf_name${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    echo "Typy harmonogramów:"
    echo "  [1] Codziennie o określonej godzinie"
    echo "  [2] Co tydzień w określony dzień"
    echo "  [3] Własne wyrażenie cron"
    echo "  [4] Usuń istniejący harmonogram"
    read -rp "Wybierz typ [1-4]: " schedule_type
    
    local cron_expr=""
    
    case "$schedule_type" in
        1)
            read -rp "Godzina (format HH:MM): " time_str
            local hour="${time_str%:*}"
            local min="${time_str#*:}"
            cron_expr="$min $hour * * *"
            ;;
        2)
            echo "Dni tygodnia: 1=Pon, 2=Wt, 3=Śr, 4=Czw, 5=Pt, 6=Sob, 7=Ndz"
            read -rp "Dzień tygodnia (1-7): " dow
            read -rp "Godzina (format HH:MM): " time_str
            local hour="${time_str%:*}"
            local min="${time_str#*:}"
            cron_expr="$min $hour * * $dow"
            ;;
        3)
            read -rp "Wyrażenie cron: " cron_expr
            ;;
        4)
            crontab -l 2>/dev/null | grep -v "$wf_name" | crontab -
            echo -e "${GREEN}✓ Usunięto harmonogram dla $wf_name${NC}"
            log_agent "Schedule removed for $wf_name"
            read -rp "Naciśnij Enter aby kontynuować..."
            return 0
            ;;
        *)
            echo -e "${RED}Nieprawidłowy wybór!${NC}"
            sleep 1
            return 1
            ;;
    esac
    
    # Dodanie do crontab
    local script_path="${SCRIPT_DIR}/../qwen-tam.sh"
    local cron_job="$cron_expr $script_path --run-workflow $wf_name >> ${SCRIPT_DIR}/logs/cron.log 2>&1"
    
    echo ""
    echo -e "${YELLOW}Planowany wpis crontab:${NC}"
    echo "  $cron_job"
    echo ""
    
    read -rp "Czy dodać do crontab? (t/n): " confirm
    if [[ "$confirm" == "t" || "$confirm" == "T" ]]; then
        (crontab -l 2>/dev/null | grep -v "$wf_name"; echo "$cron_job") | crontab -
        echo -e "${GREEN}✓ Dodano harmonogram do crontab${NC}"
        log_agent "Schedule added for $wf_name: $cron_expr"
        log_task "Scheduled workflow $wf_name with cron: $cron_expr"
    else
        echo -e "${YELLOW}Anulowano dodawanie do crontab${NC}"
    fi
    
    echo ""
    read -rp "Naciśnij Enter aby kontynuować..."
}

#-------------------------------------------------------------------------------
# [4.7] View Task History
#-------------------------------------------------------------------------------

view_task_history() {
    clear
    show_agent_header
    display_menu_box "📜 VIEW TASK HISTORY" \
        "Przegląd historii zadań" \
        "Logi wykonanych automatyzacji"
    
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Historia Zadań${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [[ ! -f "$HISTORY_FILE" ]]; then
        echo -e "${YELLOW}Brak historii zadań${NC}"
        echo ""
        read -rp "Naciśnij Enter aby kontynuować..."
        return 0
    fi
    
    echo -e "${CYAN}Opcje wyświetlania:${NC}"
    echo "  [1] Ostatnie 10 wpisów"
    echo "  [2] Wszystkie wpisy"
    echo "  [3] Szukaj po nazwie workflow"
    echo "  [4] Statystyki"
    echo "  [5] Wyczyść historię"
    echo "  [6] Eksportuj do pliku"
    echo ""
    
    read -rp "Wybierz opcję [1-6]: " option
    
    case "$option" in
        1)
            echo ""
            echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
            echo -e "${CYAN}  Ostatnie 10 wpisów:${NC}"
            echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
            tail -10 "$HISTORY_FILE"
            ;;
        2)
            echo ""
            echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
            echo -e "${CYAN}  Cała historia:${NC}"
            echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
            cat "$HISTORY_FILE"
            ;;
        3)
            read -rp "Szukana nazwa workflow: " search_name
            echo ""
            grep -i "$search_name" "$HISTORY_FILE" || echo "Brak wyników"
            ;;
        4)
            echo ""
            echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
            echo -e "${CYAN}  Statystyki:${NC}"
            echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
            echo "  Łączna liczba zadań: $(wc -l < "$HISTORY_FILE")"
            echo "  Rozpoczęte: $(grep -c "started" "$HISTORY_FILE" || echo 0)"
            echo "  Zakończone: $(grep -c "finished" "$HISTORY_FILE" || echo 0)"
            echo "  Błędy: $(grep -ci "error\|failed" "$HISTORY_FILE" || echo 0)"
            ;;
        5)
            read -rp "Czy na pewno wyczyścić historię? (t/n): " confirm
            if [[ "$confirm" == "t" || "$confirm" == "T" ]]; then
                > "$HISTORY_FILE"
                echo -e "${GREEN}✓ Historia wyczyszczona${NC}"
                log_agent "Task history cleared"
            fi
            ;;
        6)
            local export_file="${SCRIPT_DIR}/logs/task_history_export_$(date +%Y%m%d_%H%M%S).txt"
            cp "$HISTORY_FILE" "$export_file"
            echo -e "${GREEN}✓ Wyeksportowano do: $export_file${NC}"
            ;;
        *)
            echo -e "${RED}Nieprawidłowa opcja!${NC}"
            ;;
    esac
    
    echo ""
    read -rp "Naciśnij Enter aby kontynuować..."
}

#-------------------------------------------------------------------------------
# [4.8.1] Quick Auto-commit & Push
#-------------------------------------------------------------------------------

quick_autocommit_push() {
    clear
    show_agent_header
    display_menu_box "⚡ AUTO-COMMIT & PUSH" \
        "Szybka automatyzacja commit i push" \
        "Automatyczne zatwierdzanie zmian"
    
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Auto-Commit & Push${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Sprawdzenie czy jesteśmy w repozytorium git
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}❌ Nie jesteś w repozytorium Git!${NC}"
        echo ""
        read -rp "Naciśnij Enter aby kontynuować..."
        return 1
    fi
    
    echo -e "${CYAN}Status repozytorium:${NC}"
    git status --short
    echo ""
    
    local changes=$(git status --short | wc -l)
    
    if [[ $changes -eq 0 ]]; then
        echo -e "${GREEN}✓ Brak zmian do zatwierdzenia${NC}"
        read -rp "Naciśnij Enter aby kontynuować..."
        return 0
    fi
    
    echo -e "${YELLOW}Znaleziono $changes zmienionych plików${NC}"
    echo ""
    
    # Generowanie komunikatu commit z AI
    echo -e "${CYAN}🤖 AGENT:${NC} Analizuję zmiany i generuję komunikat commit..."
    echo ""
    
    local diff_summary=$(git diff --cached --stat 2>/dev/null || git diff --stat)
    local commit_msg="Auto-commit: $(date '+%Y-%m-%d %H:%M') - $changes files changed"
    
    echo -e "${YELLOW}Proponowany komunikat:${NC}"
    echo "  $commit_msg"
    echo ""
    
    read -rp "Czy użyć tego komunikatu? (t/n): " use_default
    if [[ "$use_default" != "t" && "$use_default" != "T" ]]; then
        read -rp "Podaj własny komunikat: " commit_msg
    fi
    
    echo ""
    echo -e "${GREEN}───────────────────────────────────────────────────────────────${NC}"
    echo -e "${GREEN}  Wykonywanie operacji...${NC}"
    echo -e "${GREEN}───────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    # Add all changes
    echo "  [1/3] Dodawanie plików..."
    git add -A
    echo -e "  ${GREEN}✓ Dodano pliki${NC}"
    
    # Commit
    echo "  [2/3] Tworzenie commit..."
    git commit -m "$commit_msg"
    echo -e "  ${GREEN}✓ Utworzono commit${NC}"
    
    # Push
    read -rp "Czy wykonać push do remote? (t/n): " do_push
    if [[ "$do_push" == "t" || "$do_push" == "T" ]]; then
        echo "  [3/3] Push do remote..."
        git push
        echo -e "  ${GREEN}✓ Push zakończony sukcesem${NC}"
    fi
    
    echo ""
    log_agent "Auto-commit completed: $commit_msg"
    log_task "Auto-commit & push executed - $changes files"
    
    echo -e "${GREEN}✅ Operacja zakończona pomyślnie!${NC}"
    echo ""
    read -rp "Naciśnij Enter aby kontynuować..."
}

#-------------------------------------------------------------------------------
# [4.8.2] Quick Daily Backup
#-------------------------------------------------------------------------------

quick_daily_backup() {
    clear
    show_agent_header
    display_menu_box "⚡ DAILY BACKUP" \
        "Szybka kopia zapasowa" \
        "Archiwizacja katalogu roboczego"
    
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Szybka Kopia Zapasowa${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    local backup_dir="${SCRIPT_DIR}/backups"
    mkdir -p "$backup_dir"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="backup_${timestamp}.tar.gz"
    local backup_path="${backup_dir}/${backup_name}"
    
    echo -e "${CYAN}Parametry kopii:${NC}"
    echo "  Katalog źródłowy: $SCRIPT_DIR"
    echo "  Katalog backupu: $backup_dir"
    echo "  Nazwa pliku: $backup_name"
    echo ""
    
    read -rp "Czy utworzyć kopię zapasową? (t/n): " confirm
    if [[ "$confirm" != "t" && "$confirm" != "T" ]]; then
        echo -e "${YELLOW}Anulowano${NC}"
        sleep 1
        return 0
    fi
    
    echo ""
    echo -e "${GREEN}───────────────────────────────────────────────────────────────${NC}"
    echo -e "${GREEN}  Tworzenie kopii zapasowej...${NC}"
    echo -e "${GREEN}───────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    # Wykluczenia
    local excludes="--exclude=logs/* --exclude=backups/* --exclude=.git/* --exclude=tmp/*"
    
    tar $excludes -czf "$backup_path" -C "$(dirname "$SCRIPT_DIR")" "$(basename "$SCRIPT_DIR")" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        local size=$(du -h "$backup_path" | cut -f1)
        echo -e "${GREEN}✓ Kopia utworzona pomyślnie!${NC}"
        echo "  Plik: $backup_path"
        echo "  Rozmiar: $size"
        
        log_agent "Backup created: $backup_name ($size)"
        log_task "Daily backup executed - $backup_name"
        
        # Weryfikacja integralności
        echo ""
        echo -e "${CYAN}Weryfikacja integralności...${NC}"
        if tar -tzf "$backup_path" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Integralność potwierdzona${NC}"
        else
            echo -e "${RED}⚠️  Ostrzeżenie: Problem z weryfikacją archiwum${NC}"
        fi
    else
        echo -e "${RED}❌ Błąd tworzenia kopii zapasowej!${NC}"
        log_agent "Backup failed: $backup_name"
    fi
    
    echo ""
    read -rp "Naciśnij Enter aby kontynuować..."
}

#-------------------------------------------------------------------------------
# [4.8.3] Quick Code Review Loop
#-------------------------------------------------------------------------------

quick_code_review_loop() {
    clear
    show_agent_header
    display_menu_box "⚡ CODE REVIEW LOOP" \
        "Automatyczny przegląd kodu" \
        "Analiza zmian z ostatnich commitów"
    
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Automatyczny Przegląd Kodu${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Sprawdzenie czy jesteśmy w repozytorium git
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}❌ Nie jesteś w repozytorium Git!${NC}"
        read -rp "Naciśnij Enter aby kontynuować..."
        return 1
    fi
    
    echo -e "${CYAN}Ostatnie commity:${NC}"
    git log --oneline -5
    echo ""
    
    read -rp "Liczba commitów do analizy (domyślnie 5): " num_commits
    num_commits=${num_commits:-5}
    
    echo ""
    echo -e "${CYAN}🤖 AGENT:${NC} Analizuję zmiany w ostatnich $num_commits commitach..."
    echo ""
    
    local review_file="/tmp/code_review_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "CODE REVIEW REPORT"
        echo "=================="
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Commits analyzed: $num_commits"
        echo ""
        echo "CHANGES SUMMARY"
        echo "---------------"
        git diff HEAD~$num_commits --stat
        echo ""
        echo "DETAILED CHANGES"
        echo "----------------"
        git diff HEAD~$num_commits
        echo ""
        echo "FILES CHANGED"
        echo "-------------"
        git diff HEAD~$num_commits --name-only
    } > "$review_file"
    
    echo -e "${GREEN}Raport wygenerowany!${NC}"
    echo ""
    
    # Prosta analiza statyczna
    echo -e "${CYAN}Wstępna analiza:${NC}"
    
    local additions=$(git diff HEAD~$num_commits --numstat | awk '{sum+=$1} END {print sum}')
    local deletions=$(git diff HEAD~$num_commits --numstat | awk '{sum+=$2} END {print sum}')
    
    echo "  Dodane linie: $additions"
    echo "  Usunięte linie: $deletions"
    echo "  Bilans: $((additions - deletions))"
    
    # Sprawdzenie potencjalnych problemów
    echo ""
    echo -e "${YELLOW}Potencjalne problemy:${NC}"
    
    if git diff HEAD~$num_commits | grep -q "^[+].*TODO\|^[+].*FIXME\|^[+].*XXX"; then
        echo "  ⚠️  Znaleziono TODO/FIXME w nowych zmianach"
    fi
    
    if git diff HEAD~$num_commits | grep -q "^[+].*import.*python\|^[+].*\.py"; then
        echo "  🚫 WYKRYTO PYTHON - naruszenie zasady NO PYTHON!"
    else
        echo "  ✓ Brak odwołań do Pythona"
    fi
    
    if git diff HEAD~$num_commits --name-only | grep -q "\.sh$"; then
        echo "  ℹ️  Zmieniono skrypty bash - zalecana weryfikacja składni"
    fi
    
    echo ""
    echo -e "${CYAN}Pełny raport zapisany w: $review_file${NC}"
    echo ""
    
    read -rp "Czy wyświetlić pełny raport? (t/n): " show_report
    if [[ "$show_report" == "t" || "$show_report" == "T" ]]; then
        cat "$review_file" | less
    fi
    
    log_agent "Code review completed for $num_commits commits"
    log_task "Code review loop executed - $num_commits commits analyzed"
    
    rm -f "$review_file"
    echo ""
    read -rp "Naciśnij Enter aby kontynuować..."
}

#-------------------------------------------------------------------------------
# [4.8.4] Quick Custom Script Runner
#-------------------------------------------------------------------------------

quick_custom_script_runner() {
    clear
    show_agent_header
    display_menu_box "⚡ CUSTOM SCRIPT RUNNER" \
        "Uruchom własne skrypty" \
        "Sekwencja komend z walidacją"
    
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Uruchamianie Własnych Skryptów${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${CYAN}Opcje:${NC}"
    echo "  [1] Uruchom pojedynczą komendę"
    echo "  [2] Uruchom sekwencję komend"
    echo "  [3] Załaduj listę komend z pliku"
    echo ""
    
    read -rp "Wybierz opcję [1-3]: " option
    
    case "$option" in
        1)
            read -rp "Podaj komendę do wykonania: " cmd
            echo ""
            echo -e "${GREEN}Wykonywanie:${NC} $cmd"
            echo ""
            eval "$cmd"
            ;;
        2)
            echo -e "${CYAN}Podawaj komendy jedna po drugiej (pusta linia kończy):${NC}"
            local commands=()
            
            while true; do
                read -rp "  Komenda: " cmd
                [[ -z "$cmd" ]] && break
                commands+=("$cmd")
            done
            
            if [[ ${#commands[@]} -eq 0 ]]; then
                echo -e "${YELLOW}Brak komend do wykonania${NC}"
                return 0
            fi
            
            echo ""
            echo -e "${GREEN}───────────────────────────────────────────────────────────────${NC}"
            echo -e "${GREEN}  Wykonywanie sekwencji (${#commands[@]} komend)...${NC}"
            echo -e "${GREEN}───────────────────────────────────────────────────────────────${NC}"
            echo ""
            
            local success=0
            local failed=0
            
            for cmd in "${commands[@]}"; do
                echo -e "${CYAN}>>${NC} $cmd"
                set +e
                eval "$cmd"
                local result=$?
                set -e
                
                if [[ $result -eq 0 ]]; then
                    echo -e "${GREEN}✓${NC}"
                    ((success++))
                else
                    echo -e "${RED}✗ (exit code: $result)${NC}"
                    ((failed++))
                    
                    read -rp "Kontynuować pomimo błędu? (t/n): " cont
                    if [[ "$cont" != "t" && "$cont" != "T" ]]; then
                        echo -e "${YELLOW}Przerwano sekwencję${NC}"
                        break
                    fi
                fi
                echo ""
            done
            
            echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
            echo -e "${GREEN}  PODSUMOWANIE${NC}"
            echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
            echo "  Sukcesy: $success"
            echo "  Błędy: $failed"
            ;;
        3)
            read -rp "Podaj ścieżkę do pliku z komendami: " script_file
            
            if [[ ! -f "$script_file" ]]; then
                echo -e "${RED}❌ Plik nie istnieje!${NC}"
                sleep 2
                return 1
            fi
            
            echo ""
            echo -e "${CYAN}Ładowanie komend z: $script_file${NC}"
            echo ""
            
            local line_num=0
            while IFS= read -r cmd || [[ -n "$cmd" ]]; do
                # Pomijaj komentarze i puste linie
                [[ "$cmd" =~ ^#.*$ || -z "$cmd" ]] && continue
                
                ((line_num++))
                echo -e "${CYAN}[$line_num]${NC} $cmd"
                eval "$cmd" || echo -e "${RED}Błąd w linii $line_num${NC}"
            done < "$script_file"
            ;;
        *)
            echo -e "${RED}Nieprawidłowa opcja!${NC}"
            ;;
    esac
    
    echo ""
    log_agent "Custom script runner executed"
    log_task "Custom script runner used"
    
    read -rp "Naciśnij Enter aby kontynuować..."
}

#-------------------------------------------------------------------------------
# [4.9] Back - powrót do menu głównego
#-------------------------------------------------------------------------------

# Ta funkcja jest obsługiwana przez główny skrypt qwen-tam.sh

#-------------------------------------------------------------------------------
# Menu główne modułu Automation
#-------------------------------------------------------------------------------

automation_menu() {
    while true; do
        clear
        show_agent_header
        
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║               AUTOMATION & AI AGENT MENU                     ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║  [1] 💬 Start AI Discussion Session                          ║${NC}"
        echo -e "${GREEN}║  [2] 📋 Create Automation Workflow                           ║${NC}"
        echo -e "${GREEN}║  [3] ▶️  Run Automation Task                                 ║${NC}"
        echo -e "${GREEN}║  [4] ⏸️  Pause/Resume Background Tasks                       ║${NC}"
        echo -e "${GREEN}║  [5] 🛑 Stop Running Tasks                                   ║${NC}"
        echo -e "${GREEN}║  [6] 📅 Schedule Automated Task                              ║${NC}"
        echo -e "${GREEN}║  [7] 📜 View Task History                                    ║${NC}"
        echo -e "${GREEN}║  [8] ⚡ Quick Automations                                    ║${NC}"
        echo -e "${GREEN}║      ├─ [8.1] Auto-commit & Push                             ║${NC}"
        echo -e "${GREEN}║      ├─ [8.2] Daily Backup                                   ║${NC}"
        echo -e "${GREEN}║      ├─ [8.3] Code Review Loop                               ║${NC}"
        echo -e "${GREEN}║      └─ [8.4] Custom Script Runner                           ║${NC}"
        echo -e "${YELLOW}║  [9] ⬅️  Back to Main Menu                                   ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        read -rp "  Enter choice [1-9, 8.1-8.4]: " choice
        
        case $choice in
            1|1.1|4.1) ai_discussion_session ;;
            2|2.1|4.2) create_automation_workflow ;;
            3|3.1|4.3) run_automation_task ;;
            4|4.1|4.4) pause_resume_tasks ;;
            5|5.1|4.5) stop_running_tasks ;;
            6|6.1|4.6) schedule_automated_task ;;
            7|7.1|4.7) view_task_history ;;
            8.1|81) quick_autocommit_push ;;
            8.2|82) quick_daily_backup ;;
            8.3|83) quick_code_review_loop ;;
            8.4|84) quick_custom_script_runner ;;
            9|9.1|4.9) break ;;
            *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# Inicjalizacja przy source
#-------------------------------------------------------------------------------

# Jeśli skrypt jest uruchomiony bezpośrednio (nie sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Tworzenie katalogów
    mkdir -p "$WORKFLOW_DIR" "$TASKS_DIR" "$(dirname "$AGENT_LOG")"
    touch "$HISTORY_FILE"
    
    # Uruchomienie menu
    automation_menu
fi
