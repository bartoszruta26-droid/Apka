#!/bin/bash
# ============================================================================
# Multi-Agent AI Workflow Manager
# Zarządzanie zaawansowanymi workflow multi-agent z wykorzystaniem
# wielu lokalnych modeli LLM na różnych Raspberry Pi 4
# ============================================================================

set -euo pipefail

# Kolory wyjścia
[[ -z "${RED:-}" ]] && RED='\033[0;31m'
[[ -z "${GREEN:-}" ]] && GREEN='\033[0;32m'
[[ -z "${YELLOW:-}" ]] && YELLOW='\033[1;33m'
[[ -z "${BLUE:-}" ]] && BLUE='\033[0;34m'
[[ -z "${CYAN:-}" ]] && CYAN='\033[0;36m'
[[ -z "${NC:-}" ]] && NC='\033[0m' # No Color

# Ścieżki
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
CONFIG_FILE="${HOME}/.qwen_tam_config"
CLUSTER_CONFIG="${HOME}/.qwen_tam_cluster"
LOG_DIR="${HOME}/.qwen_tam_logs"
AGENT_STATE_DIR="${LOG_DIR}/agents"

# Inicjalizacja logowania
mkdir -p "$LOG_DIR" "$AGENT_STATE_DIR"

# ============================================================================
# FUNKCJE POMOCNICZE
# ============================================================================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "${LOG_DIR}/multi_agent.log"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1" >> "${LOG_DIR}/multi_agent.log"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "${LOG_DIR}/multi_agent.log"
}

log_debug() {
    if [[ "${DEBUG_MODE:-false}" == "true" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] $1" >> "${LOG_DIR}/multi_agent.log"
}

# ============================================================================
# KONFIGURACJA KLASTRA
# ============================================================================

init_cluster_config() {
    if [[ ! -f "$CLUSTER_CONFIG" ]]; then
        cat > "$CLUSTER_CONFIG" << 'EOF'
# Qwen TAM Cluster Configuration
# Format: NODE_ID|HOSTNAME|IP_ADDRESS|PORT|MODEL|ROLE|STATUS

# Przykładowa konfiguracja:
# node1|rpi4-master|192.168.1.100|11434|qwen2.5-coder:7b|coordinator|active
# node2|rpi4-worker1|192.168.1.101|11434|qwen2.5:7b|worker|active
# node3|rpi4-worker2|192.168.1.102|11434|qwen2.5:7b|worker|active
# node4|rpi4-validator|192.168.1.103|11434|qwen2.5-coder:7b|validator|active

# Domyślny węzeł (lokalny)
local|localhost|127.0.0.1|11434|qwen2.5:7b|coordinator|inactive
EOF
        chmod 600 "$CLUSTER_CONFIG"
        log_info "Utworzono domyślną konfigurację klastra: $CLUSTER_CONFIG"
    fi
}

get_active_nodes() {
    local role="${1:-}"
    if [[ -f "$CLUSTER_CONFIG" ]]; then
        grep -v "^#" "$CLUSTER_CONFIG" | grep -v "^$" | grep "|active$" | \
            if [[ -n "$role" ]]; then
                grep "|${role}|"
            else
                cat
            fi
    fi
}

get_node_by_id() {
    local node_id="$1"
    if [[ -f "$CLUSTER_CONFIG" ]]; then
        grep -v "^#" "$CLUSTER_CONFIG" | grep -v "^$" | grep "^${node_id}|"
    fi
}

count_active_nodes() {
    get_active_nodes | wc -l
}

# ============================================================================
# ZARZĄDZANIE WĘZŁAMI
# ============================================================================

add_node() {
    local node_id="$1"
    local hostname="$2"
    local ip_address="$3"
    local port="${4:-11434}"
    local model="${5:-qwen2.5:7b}"
    local role="${6:-worker}"
    
    init_cluster_config
    
    # Sprawdź czy node_id już istnieje
    if get_node_by_id "$node_id" > /dev/null 2>&1; then
        log_error "Węzeł o ID '$node_id' już istnieje!"
        return 1
    fi
    
    # Test połączenia z węzłem
    log_info "Testowanie połączenia z węzłem $hostname ($ip_address:$port)..."
    if ! test_node_connection "$ip_address" "$port"; then
        log_warn "Nie udało się połączyć z węzłem. Dodaję mimo to (może być offline)."
    fi
    
    # Dodaj węzeł do konfiguracji
    echo "${node_id}|${hostname}|${ip_address}|${port}|${model}|${role}|active" >> "$CLUSTER_CONFIG"
    log_info "Dodano węzeł: $node_id ($hostname) jako $role z modelem $model"
    
    return 0
}

remove_node() {
    local node_id="$1"
    
    if [[ ! -f "$CLUSTER_CONFIG" ]]; then
        log_error "Plik konfiguracji klastra nie istnieje!"
        return 1
    fi
    
    if ! get_node_by_id "$node_id" > /dev/null 2>&1; then
        log_error "Węzeł '$node_id' nie istnieje!"
        return 1
    fi
    
    # Usuń węzeł (zachowując nagłówek i komentarze)
    local temp_file=$(mktemp)
    grep "^#" "$CLUSTER_CONFIG" > "$temp_file"
    grep -v "^#" "$CLUSTER_CONFIG" | grep -v "^$" | grep -v "^${node_id}|" >> "$temp_file"
    mv "$temp_file" "$CLUSTER_CONFIG"
    chmod 600 "$CLUSTER_CONFIG"
    
    log_info "Usunięto węzeł: $node_id"
    return 0
}

update_node_status() {
    local node_id="$1"
    local status="$2"  # active|inactive|maintenance
    
    if [[ ! -f "$CLUSTER_CONFIG" ]]; then
        return 1
    fi
    
    local node_line=$(get_node_by_id "$node_id")
    if [[ -z "$node_line" ]]; then
        return 1
    fi
    
    # Aktualizuj status
    local IFS='|'
    read -ra parts <<< "$node_line"
    parts[6]="$status"
    local new_line="${parts[0]}|${parts[1]}|${parts[2]}|${parts[3]}|${parts[4]}|${parts[5]}|${parts[6]}"
    
    local temp_file=$(mktemp)
    grep "^#" "$CLUSTER_CONFIG" > "$temp_file"
    # Aktualizuj linię węzła w konfiguracji
    while IFS= read -r line; do
        if [[ -n "$line" ]] && [[ ! "$line" =~ ^# ]]; then
            local current_id=$(echo "$line" | cut -d'|' -f1)
            if [[ "$current_id" == "$node_id" ]]; then
                echo "$new_line" >> "$temp_file"
            else
                echo "$line" >> "$temp_file"
            fi
        fi
    done < <(grep -v "^#" "$CLUSTER_CONFIG" | grep -v "^$")
    # Aktualizuj linię węzła w konfiguracji
    while IFS= read -r line; do
        if [[ -n "$line" ]] && [[ ! "$line" =~ ^# ]]; then
            local current_id=$(echo "$line" | cut -d'|' -f1)
            if [[ "$current_id" == "$node_id" ]]; then
                echo "$new_line" >> "$temp_file"
            else
                echo "$line" >> "$temp_file"
            fi
        fi
    done < <(grep -v "^#" "$CLUSTER_CONFIG" | grep -v "^$")
    # Aktualizuj linię węzła w konfiguracji
    while IFS= read -r line; do
        if [[ -n "$line" ]] && [[ ! "$line" =~ ^# ]]; then
            local current_id=$(echo "$line" | cut -d'|' -f1)
            if [[ "$current_id" == "$node_id" ]]; then
                echo "$new_line" >> "$temp_file"
            else
                echo "$line" >> "$temp_file"
            fi
        fi
    done < <(grep -v "^#" "$CLUSTER_CONFIG" | grep -v "^$")
    # Aktualizuj linię węzła w konfiguracji
    while IFS= read -r line; do
        if [[ -n "$line" ]] && [[ ! "$line" =~ ^# ]]; then
            local current_id=$(echo "$line" | cut -d'|' -f1)
            if [[ "$current_id" == "$node_id" ]]; then
                echo "$new_line" >> "$temp_file"
            else
                echo "$line" >> "$temp_file"
            fi
        fi
    done < <(grep -v "^#" "$CLUSTER_CONFIG" | grep -v "^$")
    log_info "Zaktualizowano status węzła $node_id na: $status"
}

test_node_connection() {
    local ip="$1"
    local port="$2"
    
    # Spróbuj połączyć się z API Ollama/LM Studio
    if command -v curl &> /dev/null; then
        if curl -s --connect-timeout 5 "http://${ip}:${port}/api/tags" > /dev/null 2>&1; then
            return 0
        fi
    fi
    
    # Alternatywnie sprawdź port
    if command -v nc &> /dev/null; then
        if nc -z -w 5 "$ip" "$port" 2>/dev/null; then
            return 0
        fi
    fi
    
    return 1
}

scan_network_for_nodes() {
    local network_prefix="${1:-192.168.1}"
    local port="${2:-11434}"
    
    log_info "Skanowanie sieci $network_prefix.x w poszukiwaniu węzłów AI (port $port)..."
    
    local found_count=0
    for i in {1..254}; do
        local ip="${network_prefix}.${i}"
        if test_node_connection "$ip" "$port"; then
            log_info "Znaleziono aktywny węzeł: $ip:$port"
            echo "$ip"
            ((found_count++))
        fi
    done
    
    log_info "Znaleziono $found_count aktywnych węzłów"
    return 0
}

# ============================================================================
# DEFINIOWANIE AGENTÓW I RÓL
# ============================================================================

define_agent() {
    local agent_id="$1"
    local agent_type="$2"  # coordinator|worker|validator|specialist
    local node_id="$3"
    local capabilities="$4"  # JSON lub lista umiejętności
    
    local agent_file="${AGENT_STATE_DIR}/${agent_id}.agent"
    
    cat > "$agent_file" << EOF
AGENT_ID=$agent_id
AGENT_TYPE=$agent_type
NODE_ID=$node_id
CAPABILITIES=$capabilities
CREATED_AT=$(date -Iseconds)
STATUS=idle
TASKS_COMPLETED=0
LAST_ACTIVE=$(date -Iseconds)
EOF
    
    chmod 600 "$agent_file"
    log_info "Zdefiniowano agenta: $agent_id (typ: $agent_type) na węźle $node_id"
}

get_agent_info() {
    local agent_id="$1"
    local agent_file="${AGENT_STATE_DIR}/${agent_id}.agent"
    
    if [[ -f "$agent_file" ]]; then
        cat "$agent_file"
    else
        log_error "Agent '$agent_id' nie istnieje!"
        return 1
    fi
}

list_agents() {
    echo ""
    echo "=== Lista Aktywnych Agentów ==="
    echo ""
    
    if [[ ! -d "$AGENT_STATE_DIR" ]] || [[ -z "$(ls -A "$AGENT_STATE_DIR" 2>/dev/null)" ]]; then
        echo "Brak zdefiniowanych agentów."
        return 0
    fi
    
    printf "%-20s %-15s %-15s %-10s %-10s\n" "AGENT_ID" "TYPE" "NODE_ID" "STATUS" "TASKS"
    echo "--------------------------------------------------------------------------------"
    
    for agent_file in "$AGENT_STATE_DIR"/*.agent; do
        if [[ -f "$agent_file" ]]; then
            source "$agent_file"
            printf "%-20s %-15s %-15s %-10s %-10s\n" \
                "$AGENT_ID" "$AGENT_TYPE" "$NODE_ID" "$STATUS" "$TASKS_COMPLETED"
        fi
    done
    
    echo ""
}

# ============================================================================
# MULTI-AGENT WORKFLOW ENGINE
# ============================================================================

create_workflow() {
    local workflow_id="$1"
    local workflow_name="$2"
    local workflow_file="${AGENT_STATE_DIR}/${workflow_id}.workflow"
    
    cat > "$workflow_file" << EOF
WORKFLOW_ID=$workflow_id
WORKFLOW_NAME=$workflow_name
CREATED_AT=$(date -Iseconds)
STATUS=pending
STEPS_COUNT=0
CURRENT_STEP=0
EOF
    
    # Katalog na kroki workflow
    mkdir -p "${AGENT_STATE_DIR}/${workflow_id}_steps"
    
    log_info "Utworzono workflow: $workflow_id ($workflow_name)"
}

add_workflow_step() {
    local workflow_id="$1"
    local step_number="$2"
    local step_type="$3"  # generate|validate|transform|aggregate
    local agent_id="$4"
    local prompt="$5"
    local input_data="${6:-}"
    local output_file="${7:-}"
    
    local step_file="${AGENT_STATE_DIR}/${workflow_id}_steps/step_${step_number}.sh"
    
    cat > "$step_file" << 'STEP_EOF'
#!/bin/bash
# Step STEP_NUMBER dla workflow WORKFLOW_ID
STEP_TYPE="STEP_TYPE"
AGENT_ID="AGENT_ID"
PROMPT="PROMPT"
INPUT_DATA="INPUT_DATA"
OUTPUT_FILE="OUTPUT_FILE"
STATUS=pending
START_TIME=""
END_TIME=""
STEP_EOF
    
    # Podstaw wartości
    sed -i "s/STEP_NUMBER/$step_number/g" "$step_file"
    sed -i "s/WORKFLOW_ID/$workflow_id/g" "$step_file"
    sed -i "s/STEP_TYPE/$step_type/g" "$step_file"
    sed -i "s/AGENT_ID/$agent_id/g" "$step_file"
    sed -i "s|PROMPT|$prompt|g" "$step_file"
    sed -i "s|INPUT_DATA|$input_data|g" "$step_file"
    sed -i "s|OUTPUT_FILE|$output_file|g" "$step_file"
    
    chmod +x "$step_file"
    
    # Aktualizuj licznik kroków
    local workflow_file="${AGENT_STATE_DIR}/${workflow_id}.workflow"
    if [[ -f "$workflow_file" ]]; then
        local current_count=$(grep "^STEPS_COUNT=" "$workflow_file" | cut -d= -f2)
        local new_count=$((current_count + 1))
        sed -i "s/^STEPS_COUNT=.*/STEPS_COUNT=$new_count/" "$workflow_file"
    fi
    
    log_info "Dodano krok $step_number do workflow $workflow_id"
}

execute_workflow() {
    local workflow_id="$1"
    local workflow_file="${AGENT_STATE_DIR}/${workflow_id}.workflow"
    
    if [[ ! -f "$workflow_file" ]]; then
        log_error "Workflow '$workflow_id' nie istnieje!"
        return 1
    fi
    
    source "$workflow_file"
    
    log_info "Rozpoczynanie workflow: $WORKFLOW_NAME ($workflow_id)"
    sed -i "s/^STATUS=.*/STATUS=running/" "$workflow_file"
    
    local steps_dir="${AGENT_STATE_DIR}/${workflow_id}_steps"
    local total_steps=$(ls -1 "$steps_dir"/step_*.sh 2>/dev/null | wc -l)
    
    for step_file in $(ls -1 "$steps_dir"/step_*.sh | sort -V); do
        local step_number=$(basename "$step_file" | sed 's/step_\([0-9]*\).sh/\1/')
        
        log_info "Wykonywanie kroku $step_number/$total_steps..."
        sed -i "s/^CURRENT_STEP=.*/CURRENT_STEP=$step_number/" "$workflow_file"
        
        # Wykonaj krok
        if bash "$step_file"; then
            log_info "Krok $step_number zakończony sukcesem"
        else
            log_error "Krok $step_number nie powiódł się!"
            sed -i "s/^STATUS=.*/STATUS=failed/" "$workflow_file"
            return 1
        fi
    done
    
    sed -i "s/^STATUS=.*/STATUS=completed/" "$workflow_file"
    log_info "Workflow $workflow_id zakończony sukcesem!"
    return 0
}

# ============================================================================
# KOMUNIKACJA MIĘDZY WĘZŁAMI
# ============================================================================

send_to_node() {
    local node_id="$1"
    local payload="$2"
    local endpoint="${3:-/api/generate}"
    
    local node_info=$(get_node_by_id "$node_id")
    if [[ -z "$node_info" ]]; then
        log_error "Nie znaleziono węzła: $node_id"
        return 1
    fi
    
    local IFS='|'
    read -ra parts <<< "$node_info"
    local ip="${parts[2]}"
    local port="${parts[3]}"
    
    log_debug "Wysyłanie żądania do $ip:$port$endpoint"
    
    # Wyślij żądanie do API Ollama
    local response=$(curl -s --connect-timeout 30 -X POST \
        "http://${ip}:${port}${endpoint}" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    echo "$response"
}

broadcast_to_all() {
    local payload="$1"
    local endpoint="${2:-/api/generate}"
    local role_filter="${3:-}"
    
    log_info "Wysyłanie broadcast do wszystkich aktywnych węzłów..."
    
    local nodes=$(get_active_nodes "$role_filter")
    local success_count=0
    local fail_count=0
    
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local node_id=$(echo "$line" | cut -d'|' -f1)
            log_debug "Wysyłanie do węzła: $node_id"
            
            if send_to_node "$node_id" "$payload" "$endpoint" > /dev/null 2>&1; then
                ((success_count++))
            else
                ((fail_count++))
                log_warn "Nie udało się wysłać do węzła: $node_id"
            fi
        fi
    done <<< "$nodes"
    
    log_info "Broadcast zakończony: $success_count sukcesów, $fail_count błędów"
}

# ============================================================================
# LOAD BALANCING I FAILOVER
# ============================================================================

select_best_node() {
    local required_model="${1:-}"
    local preferred_role="${2:-worker}"
    
    # Pobierz wszystkie aktywne węzły
    local candidates=$(get_active_nodes "$preferred_role")
    
    if [[ -z "$candidates" ]]; then
        # Spróbuj znaleźć dowolny aktywny węzeł
        candidates=$(get_active_nodes)
    fi
    
    if [[ -z "$candidates" ]]; then
        log_error "Brak dostępnych węzłów!"
        return 1
    fi
    
    # Prosty load balancing: wybierz pierwszy dostępny
    # W przyszłości można dodać ważenie na podstawie obciążenia
    local selected=$(echo "$candidates" | head -n1)
    local node_id=$(echo "$selected" | cut -d'|' -f1)
    
    log_debug "Wybrano węzeł: $node_id"
    echo "$node_id"
}

health_check_all_nodes() {
    log_info "Sprawdzanie zdrowia wszystkich węzłów..."
    
    local healthy_count=0
    local unhealthy_count=0
    
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local node_id=$(echo "$line" | cut -d'|' -f1)
            local ip=$(echo "$line" | cut -d'|' -f3)
            local port=$(echo "$line" | cut -d'|' -f4)
            
            if test_node_connection "$ip" "$port"; then
                log_info "✓ $node_id ($ip:$port) - HEALTHY"
                ((healthy_count++))
            else
                log_warn "✗ $node_id ($ip:$port) - UNHEALTHY"
                update_node_status "$node_id" "inactive"
                ((unhealthy_count++))
            fi
        fi
    done < <(grep -v "^#" "$CLUSTER_CONFIG" 2>/dev/null | grep -v "^$")
    
    echo ""
    log_info "Podsumowanie: $healthy_count zdrowych, $unhealthy_count chorych węzłów"
}

# ============================================================================
# PRZYKŁADOWE WORKFLOW MULTI-AGENT
# ============================================================================

run_collaborative_coding_workflow() {
    local project_name="$1"
    local description="$2"
    
    log_info "Uruchamianie collaborative coding workflow dla: $project_name"
    
    # Utwórz workflow
    local workflow_id="coding_$(date +%s)"
    create_workflow "$workflow_id" "Collaborative Coding: $project_name"
    
    # Krok 1: Coordinator analizuje wymagania
    add_workflow_step "$workflow_id" 1 "analyze" "coordinator_01" \
        "Analizuj wymagania projektu: $description. Stwórz listę komponentów." \
        "" "${LOG_DIR}/${workflow_id}_requirements.json"
    
    # Krok 2: Worker generuje kod
    add_workflow_step "$workflow_id" 2 "generate" "worker_01" \
        "Na podstawie wymagań wygeneruj kod źródłowy." \
        "${LOG_DIR}/${workflow_id}_requirements.json" \
        "${LOG_DIR}/${workflow_id}_code.tar.gz"
    
    # Krok 3: Validator sprawdza jakość
    add_workflow_step "$workflow_id" 3 "validate" "validator_01" \
        "Przeprowadź code review i sprawdź bezpieczeństwo." \
        "${LOG_DIR}/${workflow_id}_code.tar.gz" \
        "${LOG_DIR}/${workflow_id}_review.json"
    
    # Krok 4: Aggregator tworzy finalny wynik
    add_workflow_step "$workflow_id" 4 "aggregate" "coordinator_01" \
        "Połącz wszystkie wyniki i stwórz finalny raport." \
        "" "${LOG_DIR}/${workflow_id}_final_report.md"
    
    # Wykonaj workflow
    execute_workflow "$workflow_id"
}

run_distributed_processing_workflow() {
    local input_data="$1"
    local task_type="$2"
    
    log_info "Uruchamianie distributed processing workflow (typ: $task_type)"
    
    local workflow_id="distproc_$(date +%s)"
    create_workflow "$workflow_id" "Distributed Processing: $task_type"
    
    # Podziel zadanie na części
    local num_workers=$(get_active_nodes "worker" | wc -l)
    if [[ $num_workers -eq 0 ]]; then
        log_error "Brak dostępnych worker nodes!"
        return 1
    fi
    
    local step=1
    for worker_node in $(get_active_nodes "worker" | cut -d'|' -f1); do
        add_workflow_step "$workflow_id" $step "process" "worker_${worker_node}" \
            "Przetwórz fragment danych (task: $task_type)" \
            "$input_data" "${LOG_DIR}/${workflow_id}_result_${step}.json"
        ((step++))
    done
    
    # Agregacja wyników
    add_workflow_step "$workflow_id" $step "aggregate" "coordinator_01" \
        "Połącz wyniki z wszystkich workerów" \
        "" "${LOG_DIR}/${workflow_id}_aggregated.json"
    
    execute_workflow "$workflow_id"
}

# ============================================================================
# INTERFEJS UŻYTKOWNIKA TUI
# ============================================================================

show_cluster_status() {
    clear
    echo "============================================================================"
    echo "                    STATUS KLASTRA RASPBERRY PI"
    echo "============================================================================"
    echo ""
    
    if [[ ! -f "$CLUSTER_CONFIG" ]]; then
        echo "Konfiguracja klastra nie istnieje. Użyj opcji 2 aby dodać węzły."
        return
    fi
    
    echo "Plik konfiguracyjny: $CLUSTER_CONFIG"
    echo ""
    
    local total=0
    local active=0
    local inactive=0
    
    echo "WĘZŁY:"
    echo "--------------------------------------------------------------------------------"
    printf "%-10s %-20s %-18s %-8s %-25s %-12s %-10s\n" \
        "ID" "HOSTNAME" "IP" "PORT" "MODEL" "ROLE" "STATUS"
    echo "--------------------------------------------------------------------------------"
    
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local IFS='|'
            read -ra parts <<< "$line"
            local node_id="${parts[0]}"
            local hostname="${parts[1]}"
            local ip="${parts[2]}"
            local port="${parts[3]}"
            local model="${parts[4]}"
            local role="${parts[5]}"
            local status="${parts[6]}"
            
            printf "%-10s %-20s %-18s %-8s %-25s %-12s %-10s\n" \
                "$node_id" "$hostname" "$ip" "$port" "$model" "$role" "$status"
            
            ((total++))
            if [[ "$status" == "active" ]]; then
                ((active++))
            else
                ((inactive++))
            fi
        fi
    done < <(grep -v "^#" "$CLUSTER_CONFIG" | grep -v "^$")
    
    echo "--------------------------------------------------------------------------------"
    echo ""
    echo "PODSUMOWANIE:"
    echo "  Total: $total | Active: $active | Inactive: $inactive"
    echo ""
}

show_agents_status() {
    clear
    echo "============================================================================"
    echo "                    STATUS AGENTÓW AI"
    echo "============================================================================"
    echo ""
    
    list_agents
    
    echo ""
    echo "Definicje ról:"
    echo "  - coordinator: Koordynuje pracę innych agentów, podejmuje decyzje"
    echo "  - worker: Wykonuje zadania (generowanie kodu, analiza, etc.)"
    echo "  - validator: Sprawdza jakość, bezpieczeństwo, poprawność"
    echo "  - specialist: Wąska specjalizacja (np. security, optimization)"
    echo ""
}

multi_agent_menu() {
    while true; do
        clear
        echo "============================================================================"
        echo "         ADVANCED AI WORKFLOWS - MULTI-AGENT SYSTEM"
        echo "============================================================================"
        echo ""
        echo "1. Pokaż status klastra"
        echo "2. Dodaj nowy węzeł (RPi4)"
        echo "3. Usuń węzeł"
        echo "4. Skanuj sieć w poszukiwaniu węzłów"
        echo "5. Check health wszystkich węzłów"
        echo ""
        echo "6. Zdefiniuj nowego agenta"
        echo "7. Pokaż listę agentów"
        echo ""
        echo "8. Utwórz nowe workflow"
        echo "9. Uruchom przykładowe workflow (collaborative coding)"
        echo "10. Uruchom distributed processing"
        echo ""
        echo "11. Wyślij testowe żądanie do węzła"
        echo "12. Broadcast do wszystkich węzłów"
        echo ""
        echo "0. Powrót do menu głównego"
        echo ""
        echo "============================================================================"
        read -rp "Wybierz opcję [0-12]: " choice
        
        case $choice in
            1)
                show_cluster_status
                read -rp "Naciśnij Enter aby kontynuować..."
                ;;
            2)
                echo ""
                read -rp "Node ID (np. node1): " node_id
                read -rp "Hostname (np. rpi4-worker1): " hostname
                read -rp "IP Address (np. 192.168.1.101): " ip_addr
                read -rp "Port [11434]: " port
                port=${port:-11434}
                read -rp "Model name (np. qwen2.5:7b): " model
                read -rp "Role [worker]: " role
                role=${role:-worker}
                
                add_node "$node_id" "$hostname" "$ip_addr" "$port" "$model" "$role"
                read -rp "Naciśnij Enter aby kontynuować..."
                ;;
            3)
                echo ""
                read -rp "Node ID do usunięcia: " node_id
                remove_node "$node_id"
                read -rp "Naciśnij Enter aby kontynuować..."
                ;;
            4)
                echo ""
                read -rp "Prefix sieci (np. 192.168.1) [192.168.1]: " net_prefix
                net_prefix=${net_prefix:-192.168.1}
                scan_network_for_nodes "$net_prefix"
                read -rp "Naciśnij Enter aby kontynuować..."
                ;;
            5)
                health_check_all_nodes
                read -rp "Naciśnij Enter aby kontynuować..."
                ;;
            6)
                echo ""
                read -rp "Agent ID (np. coordinator_01): " agent_id
                echo "Typy: coordinator, worker, validator, specialist"
                read -rp "Agent type: " agent_type
                read -rp "Node ID: " node_id
                read -rp "Capabilities (opis umiejętności): " capabilities
                
                define_agent "$agent_id" "$agent_type" "$node_id" "$capabilities"
                read -rp "Naciśnij Enter aby kontynuować..."
                ;;
            7)
                show_agents_status
                read -rp "Naciśnij Enter aby kontynuować..."
                ;;
            8)
                echo ""
                read -rp "Workflow ID (np. my_workflow_1): " wf_id
                read -rp "Workflow name: " wf_name
                create_workflow "$wf_id" "$wf_name"
                
                echo ""
                echo "Teraz dodaj kroki workflow używając funkcji add_workflow_step"
                echo "Przykład:"
                echo "  add_workflow_step \"$wf_id\" 1 \"generate\" \"worker_01\" \"Twój prompt\""
                read -rp "Naciśnij Enter aby kontynuować..."
                ;;
            9)
                echo ""
                read -rp "Nazwa projektu: " proj_name
                read -rp "Opis projektu: " proj_desc
                run_collaborative_coding_workflow "$proj_name" "$proj_desc"
                read -rp "Naciśnij Enter aby kontynuować..."
                ;;
            10)
                echo ""
                read -rp "Dane wejściowe (lub ścieżka do pliku): " input_data
                read -rp "Typ zadania (np. text_analysis, code_gen, data_proc): " task_type
                run_distributed_processing_workflow "$input_data" "$task_type"
                read -rp "Naciśnij Enter aby kontynuować..."
                ;;
            11)
                echo ""
                read -rp "Node ID: " node_id
                read -rp "Prompt: " prompt
                read -rp "Endpoint [/api/generate]: " endpoint
                endpoint=${endpoint:-/api/generate}
                
                local payload="{\"model\": \"qwen2.5:7b\", \"prompt\": \"$prompt\", \"stream\": false}"
                echo ""
                echo "Odpowiedź:"
                send_to_node "$node_id" "$payload" "$endpoint"
                read -rp "Naciśnij Enter aby kontynuować..."
                ;;
            12)
                echo ""
                read -rp "Prompt do wysłania: " prompt
                read -rp "Filtr roli (puste = wszystkie): " role_filter
                role_filter=${role_filter:-}
                
                local payload="{\"model\": \"qwen2.5:7b\", \"prompt\": \"$prompt\", \"stream\": false}"
                broadcast_to_all "$payload" "/api/generate" "$role_filter"
                read -rp "Naciśnij Enter aby kontynuować..."
                ;;
            0)
                return 0
                ;;
            *)
                echo "Nieprawidłowy wybór!"
                sleep 1
                ;;
        esac
    done
}

# ============================================================================
# GŁÓWNY PUNKT WEJŚCIA
# ============================================================================

main() {
    init_cluster_config
    
    if [[ "${1:-}" == "--menu" ]] || [[ "${1:-}" == "" ]]; then
        multi_agent_menu
    elif [[ "${1:-}" == "--status" ]]; then
        show_cluster_status
    elif [[ "${1:-}" == "--health" ]]; then
        health_check_all_nodes
    elif [[ "${1:-}" == "--list-agents" ]]; then
        list_agents
    else
        echo "Użycie: $0 [--menu|--status|--health|--list-agents]"
        exit 1
    fi
}

# Jeśli skrypt jest uruchamiany bezpośrednio, a nie sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
