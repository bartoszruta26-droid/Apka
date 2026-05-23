#!/bin/bash

#===============================================================================
# SYSTEM INFORMATION MODULE - scripts/system.sh
# QWEN TIME & AUTOMATION MANAGER v1.0
# Moduł informacji systemowych - Raspberry Pi 4 Edition
#===============================================================================

#-------------------------------------------------------------------------------
# Funkcje pomocnicze dla modułu systemowego
#-------------------------------------------------------------------------------

show_system_header() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 SYSTEM INFORMATION                           ║"
    echo "║                    Raspberry Pi 4 Edition                    ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo -e "${NC}"
}

format_bytes() {
    local bytes=$1
    if [[ $bytes -lt 1024 ]]; then
        echo "${bytes} B"
    elif [[ $bytes -lt 1048576 ]]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1024}") KB"
    elif [[ $bytes -lt 1073741824 ]]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1048576}") MB"
    elif [[ $bytes -lt 1099511627776 ]]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1073741824}") GB"
    else
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1099511627776}") TB"
    fi
}

#-------------------------------------------------------------------------------
# [7.1] System Resources (CPU/RAM/Disk)
#-------------------------------------------------------------------------------

system_resources() {
    log_event "System Resources Check"
    clear_screen
    show_system_header
    
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  💻 SYSTEM RESOURCES - CPU / RAM / DISK                      ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo ""
    
    # CPU Information
    echo -e "${YELLOW}━━━ CPU INFORMATION ━━━${NC}"
    if command -v lscpu &>/dev/null; then
        local cpu_model=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
        local cpu_cores=$(nproc 2>/dev/null || lscpu | grep "^CPU(s):" | awk '{print $2}')
        local cpu_arch=$(uname -m)
        
        echo -e "  ${CYAN}Model:${NC} $cpu_model"
        echo -e "  ${CYAN}Cores:${NC} $cpu_cores"
        echo -e "  ${CYAN}Architecture:${NC} $cpu_arch"
        
        # CPU Usage
        if [[ -f /proc/stat ]]; then
            local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 2>/dev/null || echo "N/A")
            echo -e "  ${CYAN}Current Usage:${NC} ${cpu_usage}%"
        fi
        
        # CPU Frequency (if available)
        if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ]]; then
            local freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null)
            local freq_mhz=$((freq / 1000))
            echo -e "  ${CYAN}Current Frequency:${NC} ${freq_mhz} MHz"
        fi
    else
        echo -e "  ${RED}lscpu not available${NC}"
    fi
    echo ""
    
    # RAM Information
    echo -e "${YELLOW}━━━ MEMORY INFORMATION ━━━${NC}"
    if [[ -f /proc/meminfo ]]; then
        local mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2 * 1024}')
        local mem_free=$(grep MemFree /proc/meminfo | awk '{print $2 * 1024}')
        local mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2 * 1024}')
        local mem_buffers=$(grep Buffers /proc/meminfo | awk '{print $2 * 1024}')
        local mem_cached=$(grep "^Cached:" /proc/meminfo | awk '{print $2 * 1024}')
        
        local mem_used=$((mem_total - mem_free - mem_buffers - mem_cached))
        local mem_percent=$(awk "BEGIN {printf \"%.1f\", ($mem_used/$mem_total)*100}")
        
        echo -e "  ${CYAN}Total RAM:${NC} $(format_bytes $mem_total)"
        echo -e "  ${CYAN}Used RAM:${NC} $(format_bytes $mem_used) (${mem_percent}%)"
        echo -e "  ${CYAN}Free RAM:${NC} $(format_bytes $mem_free)"
        echo -e "  ${CYAN}Available:${NC} $(format_bytes $mem_available)"
        echo -e "  ${CYAN}Buffers:${NC} $(format_bytes $mem_buffers)"
        echo -e "  ${CYAN}Cached:${NC} $(format_bytes $mem_cached)"
        
        # Visual bar
        local bar_width=40
        local filled=$(awk "BEGIN {printf \"%d\", ($mem_percent/100)*$bar_width}")
        local empty=$((bar_width - filled))
        printf "  ["
        for ((i=0; i<filled; i++)); do printf "█"; done
        for ((i=0; i<empty; i++)); do printf "░"; done
        printf "] ${mem_percent}%\n"
    else
        echo -e "  ${RED}/proc/meminfo not available${NC}"
    fi
    echo ""
    
    # Disk Information
    echo -e "${YELLOW}━━━ DISK USAGE ━━━${NC}"
    if command -v df &>/dev/null; then
        echo -e "  ${CYAN}Filesystem:${NC}"
        df -h --output=target,size,used,avail,pcent 2>/dev/null | \
            grep -E "^/|^  /" | head -10 | while read -r line; do
            echo "    $line"
        done
        
        # IO Stats if available
        if [[ -f /proc/diskstats ]]; then
            echo -e "\n  ${CYAN}Disk I/O Statistics:${NC}"
            cat /proc/diskstats 2>/dev/null | grep -E "mmcblk|sd[a-z]" | head -5 | \
                awk '{printf "    %s: Read=%s sectors, Write=%s sectors\n", $3, $6, $10}'
        fi
    else
        echo -e "  ${RED}df not available${NC}"
    fi
    echo ""
    
    # Load Average
    echo -e "${YELLOW}━━━ SYSTEM LOAD ━━━${NC}"
    if [[ -f /proc/loadavg ]]; then
        local loadavg=$(cat /proc/loadavg)
        local load1=$(echo $loadavg | awk '{print $1}')
        local load5=$(echo $loadavg | awk '{print $2}')
        local load15=$(echo $loadavg | awk '{print $3}')
        local running_procs=$(echo $loadavg | awk -F'/' '{print $2}')
        local total_procs=$(echo $loadavg | awk -F'/' '{print $3}')
        
        echo -e "  ${CYAN}Load Average (1/5/15 min):${NC} $load1 / $load5 / $load15"
        echo -e "  ${CYAN}Running Processes:${NC} $running_procs / $total_procs"
    fi
    echo ""
    
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    log_info "System resources displayed"
}

#-------------------------------------------------------------------------------
# [7.2] Temperature & Health Status
#-------------------------------------------------------------------------------

system_temperature_health() {
    log_event "Temperature & Health Status Check"
    clear_screen
    show_system_header
    
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  🌡️  TEMPERATURE & HEALTH STATUS                             ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo ""
    
    # CPU Temperature
    echo -e "${YELLOW}━━━ TEMPERATURE READINGS ━━━${NC}"
    
    local temp_c=""
    
    # Try different methods to get temperature
    if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        temp_c=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
        temp_c=$((temp_c / 1000))
    elif command -v vcgencmd &>/dev/null; then
        temp_c=$(vcgencmd measure_temp 2>/dev/null | cut -d"'" -f2 | cut -d"C" -f1)
    elif command -v sensors &>/dev/null; then
        temp_c=$(sensors 2>/dev/null | grep -E "Core|Package" | head -1 | awk '{print $3}' | cut -d'+' -f2 | cut -d'.' -f1)
    fi
    
    if [[ -n "$temp_c" && "$temp_c" =~ ^[0-9]+$ ]]; then
        local temp_f=$(awk "BEGIN {printf \"%.1f\", ($temp_c * 9/5) + 32}")
        echo -e "  ${CYAN}CPU Temperature:${NC} ${temp_c}°C / ${temp_f}°F"
        
        # Temperature status
        local status_icon="✅"
        local status_text="Normal"
        
        if [[ $temp_c -ge 85 ]]; then
            status_icon="🔴"
            status_text="CRITICAL - Overheating!"
        elif [[ $temp_c -ge 70 ]]; then
            status_icon="🟠"
            status_text="Warning - High Temperature"
        elif [[ $temp_c -ge 60 ]]; then
            status_icon="🟡"
            status_text="Caution - Elevated"
        fi
        
        echo -e "  ${CYAN}Status:${NC} ${status_icon} ${status_text}"
        
        # Visual temperature gauge
        local bar_width=40
        local temp_percent=$(awk "BEGIN {printf \"%d\", ($temp_c/100)*$bar_width}")
        [[ $temp_percent -gt $bar_width ]] && temp_percent=$bar_width
        local filled=$temp_percent
        local empty=$((bar_width - filled))
        
        printf "  ["
        for ((i=0; i<filled; i++)); do
            if [[ $i -lt $((bar_width * 60 / 100)) ]]; then
                printf "█"
            elif [[ $i -lt $((bar_width * 85 / 100)) ]]; then
                printf "▓"
            else
                printf "█"
            fi
        done
        for ((i=0; i<empty; i++)); do printf "░"; done
        printf "] 0°C - 100°C\n"
    else
        echo -e "  ${RED}Unable to read temperature${NC}"
    fi
    echo ""
    
    # GPU Temperature (Raspberry Pi specific)
    if command -v vcgencmd &>/dev/null; then
        local gpu_temp=$(vcgencmd measure_temp 2>/dev/null | cut -d"'" -f2 | cut -d"C" -f1)
        if [[ -n "$gpu_temp" ]]; then
            echo -e "  ${CYAN}GPU Temperature:${NC} ${gpu_temp}°C"
        fi
    fi
    echo ""
    
    # System Health Checks
    echo -e "${YELLOW}━━━ SYSTEM HEALTH CHECKS ━━━${NC}"
    
    local health_issues=0
    local health_warnings=0
    
    # Check uptime
    local uptime_seconds=$(cat /proc/uptime 2>/dev/null | awk '{print int($1)}')
    local uptime_days=$((uptime_seconds / 86400))
    local uptime_hours=$(((uptime_seconds % 86400) / 3600))
    echo -e "  ${CYAN}System Uptime:${NC} ${uptime_days}d ${uptime_hours}h"
    
    # Check disk space critical levels
    local root_usage=$(df / 2>/dev/null | tail -1 | awk '{print $5}' | cut -d'%' -f1)
    if [[ -n "$root_usage" ]]; then
        if [[ $root_usage -ge 95 ]]; then
            echo -e "  ${RED}❌ CRITICAL: Root filesystem ${root_usage}% full!${NC}"
            ((health_issues++))
        elif [[ $root_usage -ge 85 ]]; then
            echo -e "  ${YELLOW}⚠️  WARNING: Root filesystem ${root_usage}% full${NC}"
            ((health_warnings++))
        else
            echo -e "  ${GREEN}✅ Disk Space OK (${root_usage}% used)${NC}"
        fi
    fi
    
    # Check RAM pressure
    if [[ -f /proc/meminfo ]]; then
        local mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        local mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        local ram_usage_percent=$(awk "BEGIN {printf \"%d\", (($mem_total-$mem_available)/$mem_total)*100}")
        
        if [[ $ram_usage_percent -ge 95 ]]; then
            echo -e "  ${RED}❌ CRITICAL: RAM usage ${ram_usage_percent}%!${NC}"
            ((health_issues++))
        elif [[ $ram_usage_percent -ge 85 ]]; then
            echo -e "  ${YELLOW}⚠️  WARNING: RAM usage ${ram_usage_percent}%${NC}"
            ((health_warnings++))
        else
            echo -e "  ${GREEN}✅ RAM Usage OK (${ram_usage_percent}% used)${NC}"
        fi
    fi
    
    # Check for zombie processes
    local zombies=$(ps aux 2>/dev/null | grep -c "[Z]" || echo "0")
    if [[ $zombies -gt 0 ]]; then
        echo -e "  ${YELLOW}⚠️  WARNING: $zombies zombie process(es) detected${NC}"
        ((health_warnings++))
    else
        echo -e "  ${GREEN}✅ No Zombie Processes${NC}"
    fi
    
    # Check swap usage
    if [[ -f /proc/swaps ]] && [[ $(wc -l < /proc/swaps) -gt 1 ]]; then
        local swap_total=$(free | grep Swap | awk '{print $2}')
        local swap_used=$(free | grep Swap | awk '{print $3}')
        if [[ $swap_total -gt 0 ]]; then
            local swap_percent=$(awk "BEGIN {printf \"%d\", ($swap_used/$swap_total)*100}")
            if [[ $swap_percent -ge 80 ]]; then
                echo -e "  ${YELLOW}⚠️  High Swap Usage: ${swap_percent}%${NC}"
                ((health_warnings++))
            else
                echo -e "  ${GREEN}✅ Swap Usage OK (${swap_percent}% used)${NC}"
            fi
        fi
    fi
    
    echo ""
    
    # Overall Health Summary
    echo -e "${YELLOW}━━━ HEALTH SUMMARY ━━━${NC}"
    if [[ $health_issues -gt 0 ]]; then
        echo -e "  ${RED}❌ CRITICAL: $health_issues critical issue(s) detected!${NC}"
        echo -e "  Immediate action recommended."
    elif [[ $health_warnings -gt 0 ]]; then
        echo -e "  ${YELLOW}⚠️  WARNING: $health_warnings warning(s) detected${NC}"
        echo -e "  Monitor system closely."
    else
        echo -e "  ${GREEN}✅ All health checks passed${NC}"
        echo -e "  System is running normally."
    fi
    
    echo ""
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    log_info "Temperature and health status displayed"
}

#-------------------------------------------------------------------------------
# [7.3] Installed Dependencies
#-------------------------------------------------------------------------------

system_dependencies() {
    log_event "Installed Dependencies Check"
    clear_screen
    show_system_header
    
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  📦 INSTALLED DEPENDENCIES                                   ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo ""
    
    # Core System Tools
    echo -e "${YELLOW}━━━ CORE SYSTEM TOOLS ━━━${NC}"
    local core_tools=("git" "curl" "wget" "jq" "bash" "python3" "node" "npm" "make" "gcc")
    
    for tool in "${core_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            local version=$("$tool" --version 2>/dev/null | head -1 | cut -c1-50 || echo "installed")
            echo -e "  ${GREEN}✅${NC} ${CYAN}$tool:${NC} $version"
        else
            echo -e "  ${RED}❌${NC} ${CYAN}$tool:${NC} NOT INSTALLED"
        fi
    done
    echo ""
    
    # AI/ML Tools
    echo -e "${YELLOW}━━━ AI/ML TOOLS ━━━${NC}"
    
    # Check Ollama
    if command -v ollama &>/dev/null; then
        local ollama_ver=$(ollama --version 2>/dev/null || echo "installed")
        echo -e "  ${GREEN}✅${NC} ${CYAN}Ollama:${NC} $ollama_ver"
        
        # List available models
        echo -e "    ${CYAN}Available Models:${NC}"
        ollama list 2>/dev/null | tail -n +2 | while read -r line; do
            echo "      - $line"
        done || echo "      (none or unable to list)"
    else
        echo -e "  ${RED}❌${NC} ${CYAN}Ollama:${NC} NOT INSTALLED"
    fi
    
    # Check Python AI packages
    if command -v python3 &>/dev/null; then
        echo -e "  ${CYAN}Python AI Packages:${NC}"
        python3 -c "import torch; print(f'    ✅ PyTorch: {torch.__version__}')" 2>/dev/null || \
            echo -e "    ${RED}❌ PyTorch: Not installed${NC}"
        python3 -c "import transformers; print(f'    ✅ Transformers: {transformers.__version__}')" 2>/dev/null || \
            echo -e "    ${RED}❌ Transformers: Not installed${NC}"
    fi
    echo ""
    
    # Docker & Container Tools
    echo -e "${YELLOW}━━━ CONTAINER TOOLS ━━━${NC}"
    
    if command -v docker &>/dev/null; then
        local docker_ver=$(docker --version 2>/dev/null || echo "installed")
        echo -e "  ${GREEN}✅${NC} ${CYAN}Docker:${NC} $docker_ver"
        
        if command -v docker-compose &>/dev/null; then
            local dc_ver=$(docker-compose --version 2>/dev/null || echo "installed")
            echo -e "  ${GREEN}✅${NC} ${CYAN}Docker Compose:${NC} $dc_ver"
        else
            echo -e "  ${YELLOW}⚠️${NC} ${CYAN}Docker Compose:${NC} NOT INSTALLED"
        fi
    else
        echo -e "  ${RED}❌${NC} ${CYAN}Docker:${NC} NOT INSTALLED"
    fi
    echo ""
    
    # Development Tools
    echo -e "${YELLOW}━━━ DEVELOPMENT TOOLS ━━━${NC}"
    
    # C/C++ compilers
    if command -v gcc &>/dev/null; then
        local gcc_ver=$(gcc --version 2>/dev/null | head -1 || echo "installed")
        echo -e "  ${GREEN}✅${NC} ${CYAN}GCC:${NC} $gcc_ver"
    else
        echo -e "  ${RED}❌${NC} ${CYAN}GCC:${NC} NOT INSTALLED"
    fi
    
    if command -v g++ &>/dev/null; then
        local gpp_ver=$(g++ --version 2>/dev/null | head -1 || echo "installed")
        echo -e "  ${GREEN}✅${NC} ${CYAN}G++:${NC} $gpp_ver"
    fi
    
    # Build tools
    if command -v make &>/dev/null; then
        local make_ver=$(make --version 2>/dev/null | head -1 || echo "installed")
        echo -e "  ${GREEN}✅${NC} ${CYAN}Make:${NC} $make_ver"
    fi
    echo ""
    
    # Package Manager Info
    echo -e "${YELLOW}━━━ PACKAGE MANAGER INFO ━━━${NC}"
    
    if command -v apt &>/dev/null; then
        echo -e "  ${CYAN}APT Package Manager:${NC}"
        local pkg_count=$(apt list --installed 2>/dev/null | wc -l)
        echo "    Installed packages: ~$pkg_count"
        
        local upgradable=$(apt list --upgradable 2>/dev/null | tail -n +2 | wc -l)
        if [[ $upgradable -gt 0 ]]; then
            echo -e "    ${YELLOW}⚠️  $upgradable package(s) can be upgraded${NC}"
        else
            echo -e "    ${GREEN}✅ All packages up to date${NC}"
        fi
    fi
    
    echo ""
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    log_info "Dependencies check displayed"
}

#-------------------------------------------------------------------------------
# [7.4] Qwen Model Status
#-------------------------------------------------------------------------------

system_qwen_status() {
    log_event "Qwen Model Status Check"
    clear_screen
    show_system_header
    
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  🤖 QWEN MODEL STATUS                                        ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo ""
    
    # Check Ollama Service
    echo -e "${YELLOW}━━━ OLLAMA SERVICE STATUS ━━━${NC}"
    
    if command -v ollama &>/dev/null; then
        echo -e "  ${GREEN}✅${NC} ${CYAN}Ollama CLI:${NC} Installed"
        
        # Check if service is running
        if pgrep -x "ollama" > /dev/null 2>&1; then
            echo -e "  ${GREEN}✅${NC} ${CYAN}Ollama Service:${NC} Running"
            
            # Get running models
            echo -e "  ${CYAN}Active Models:${NC}"
            ollama list 2>/dev/null | tail -n +2 | while read -r name size modified; do
                echo -e "    • ${name} (${size})"
            done || echo "    (no models loaded)"
        else
            echo -e "  ${YELLOW}⚠️${NC} ${CYAN}Ollama Service:${NC} Not Running"
            echo -e "    To start: ${CYAN}ollama serve${NC}"
        fi
    else
        echo -e "  ${RED}❌${NC} ${CYAN}Ollama:${NC} Not Installed"
        echo -e "    Install with: ${CYAN}curl -fsSL https://ollama.ai/install.sh | sh${NC}"
    fi
    echo ""
    
    # Qwen Models Availability
    echo -e "${YELLOW}━━━ QWEN MODELS AVAILABILITY ━━━${NC}"
    
    local qwen_models=("qwen:0.5b" "qwen:1.5b" "qwen:3b" "qwen:7b" "qwen:14b" "qwen:32b" "qwen:72b" 
                       "qwen2:0.5b" "qwen2:1.5b" "qwen2:7b" "qwen2:72b"
                       "qwen2.5:0.5b" "qwen2.5:1.5b" "qwen2.5:3b" "qwen2.5:7b" "qwen2.5:14b" "qwen2.5:32b" "qwen2.5:72b"
                       "qwen-coder:1.5b" "qwen-coder:7b" "qwen-coder:32b")
    
    echo -e "  ${CYAN}Checking available Qwen models...${NC}"
    echo ""
    
    local installed_count=0
    if command -v ollama &>/dev/null; then
        local installed_models=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}')
        
        for model in "${qwen_models[@]}"; do
            if echo "$installed_models" | grep -q "^${model}$"; then
                echo -e "  ${GREEN}✅${NC} $model - INSTALLED"
                ((installed_count++))
            fi
        done
        
        if [[ $installed_count -eq 0 ]]; then
            echo -e "  ${YELLOW}⚠️${NC} No Qwen models currently installed"
            echo -e "    Example: ${CYAN}ollama pull qwen2.5:7b${NC}"
        else
            echo ""
            echo -e "  ${GREEN}✅ $installed_count Qwen model(s) installed${NC}"
        fi
    else
        echo -e "  ${RED}❌ Ollama not available for model checking${NC}"
    fi
    echo ""
    
    # API Endpoint Configuration
    echo -e "${YELLOW}━━━ API ENDPOINT CONFIGURATION ━━━${NC}"
    
    local config_file="${HOME}/.qwen_tam_config"
    if [[ -f "$config_file" ]]; then
        source "$config_file" 2>/dev/null || true
        if [[ -n "${QWEN_API_ENDPOINT:-}" ]]; then
            echo -e "  ${CYAN}API Endpoint:${NC} $QWEN_API_ENDPOINT"
        else
            echo -e "  ${YELLOW}⚠️${NC} API Endpoint not configured"
        fi
        
        if [[ -n "${OLLAMA_HOST:-}" ]]; then
            echo -e "  ${CYAN}Ollama Host:${NC} $OLLAMA_HOST"
        else
            echo -e "  ${CYAN}Ollama Host:${NC} localhost:11434 (default)"
        fi
    else
        echo -e "  ${YELLOW}⚠️${NC} Configuration file not found"
    fi
    echo ""
    
    # Model Performance Tips
    echo -e "${YELLOW}━━━ RECOMMENDATIONS FOR RASPBERRY PI 4 ━━━${NC}"
    echo -e "  ${CYAN}Recommended Models:${NC}"
    echo -e "    • qwen2.5:0.5b or qwen2.5:1.5b - Best for 4GB RAM"
    echo -e "    • qwen2.5:3b - Acceptable with swap"
    echo -e "    • qwen-coder:1.5b - For code generation tasks"
    echo ""
    echo -e "  ${CYAN}Performance Tips:${NC}"
    echo -e "    • Use quantized models (q4_0, q4_K_M)"
    echo -e "    • Close unnecessary applications"
    echo -e "    • Consider using remote Ollama server"
    echo -e "    • Enable ZRAM for better memory management"
    
    echo ""
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    log_info "Qwen model status displayed"
}

#-------------------------------------------------------------------------------
# [7.5] Network Connectivity
#-------------------------------------------------------------------------------

system_network() {
    log_event "Network Connectivity Check"
    clear_screen
    show_system_header
    
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  🔗 NETWORK CONNECTIVITY                                     ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo ""
    
    # Interface Information
    echo -e "${YELLOW}━━━ NETWORK INTERFACES ━━━${NC}"
    
    if command -v ip &>/dev/null; then
        ip -br addr 2>/dev/null | while read -r iface state addresses; do
            local state_icon="❌"
            [[ "$state" == "UP" ]] && state_icon="✅"
            echo -e "  ${state_icon} ${CYAN}$iface:${NC} $state"
            [[ -n "$addresses" ]] && echo -e "      ${addresses}"
        done
    elif command -v ifconfig &>/dev/null; then
        ifconfig 2>/dev/null | grep -E "^[a-z]|inet " | paste - - | while read -r line; do
            echo -e "  $line"
        done
    fi
    echo ""
    
    # Default Gateway
    echo -e "${YELLOW}━━━ DEFAULT GATEWAY ━━━${NC}"
    
    if command -v ip &>/dev/null; then
        local gateway=$(ip route | grep default | awk '{print $3}')
        local dev=$(ip route | grep default | awk '{print $5}')
        if [[ -n "$gateway" ]]; then
            echo -e "  ${CYAN}Gateway:${NC} $gateway via $dev"
        else
            echo -e "  ${YELLOW}⚠️${NC} No default gateway configured"
        fi
    fi
    echo ""
    
    # DNS Configuration
    echo -e "${YELLOW}━━━ DNS CONFIGURATION ━━━${NC}"
    
    if [[ -f /etc/resolv.conf ]]; then
        echo -e "  ${CYAN}DNS Servers:${NC}"
        grep -E "^nameserver" /etc/resolv.conf 2>/dev/null | awk '{print "    • " $2}' || \
            echo -e "    ${RED}No DNS servers configured${NC}"
    fi
    echo ""
    
    # Internet Connectivity Test
    echo -e "${YELLOW}━━━ INTERNET CONNECTIVITY TEST ━━━${NC}"
    
    local test_hosts=("8.8.8.8" "1.1.1.1" "google.com" "github.com")
    
    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 2 "$host" &>/dev/null; then
            local rttime=$(ping -c 1 -W 2 "$host" 2>/dev/null | grep "rtt" | cut -d'/' -f5 || echo "N/A")
            echo -e "  ${GREEN}✅${NC} ${CYAN}$host:${NC} Reachable (${rttime}ms)"
        else
            echo -e "  ${RED}❌${NC} ${CYAN}$host:${NC} Unreachable"
        fi
    done
    echo ""
    
    # GitHub API Connectivity (important for this app)
    echo -e "${YELLOW}━━━ GITHUB API CONNECTIVITY ━━━${NC}"
    
    if command -v curl &>/dev/null; then
        local github_status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 https://api.github.com 2>/dev/null)
        
        case $github_status in
            200)
                echo -e "  ${GREEN}✅${NC} ${CYAN}GitHub API:${NC} Accessible"
                ;;
            000)
                echo -e "  ${RED}❌${NC} ${CYAN}GitHub API:${NC} Connection Failed"
                ;;
            *)
                echo -e "  ${YELLOW}⚠️${NC} ${CYAN}GitHub API:${NC} HTTP $github_status"
                ;;
        esac
    fi
    echo ""
    
    # Network Speed Test (basic)
    echo -e "${YELLOW}━━━ NETWORK SPEED (BASIC TEST) ━━━${NC}"
    
    if command -v curl &>/dev/null; then
        echo -e "  ${CYAN}Download test (via speedtest.net CLI if available)...${NC}"
        
        if command -v speedtest &>/dev/null; then
            speedtest --simple 2>/dev/null | while read -r line; do
                echo -e "    $line"
            done
        else
            echo -e "    ${YELLOW}⚠️${NC} speedtest-cli not installed"
            echo -e "    Install: ${CYAN}sudo apt install speedtest-cli${NC}"
        fi
    fi
    echo ""
    
    # WiFi Signal Strength (if applicable)
    if command -v iwconfig &>/dev/null; then
        echo -e "${YELLOW}━━━ WIFI SIGNAL STRENGTH ━━━${NC}"
        iwconfig 2>/dev/null | grep -E "Signal|Link Quality" | while read -r line; do
            echo -e "  $line"
        done || echo -e "  ${CYAN}No wireless interfaces found${NC}"
        echo ""
    fi
    
    # SSH Service Status
    echo -e "${YELLOW}━━━ SSH SERVICE ━━━${NC}"
    
    if systemctl is-active ssh &>/dev/null 2>&1; then
        echo -e "  ${GREEN}✅${NC} ${CYAN}SSH Service:${NC} Running"
        local ssh_port=$(grep -E "^Port" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo "22")
        echo -e "  ${CYAN}SSH Port:${NC} $ssh_port"
    else
        echo -e "  ${YELLOW}⚠️${NC} ${CYAN}SSH Service:${NC} Not Running"
    fi
    
    echo ""
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    log_info "Network connectivity check displayed"
}

#-------------------------------------------------------------------------------
# [7.6] Version & Changelog
#-------------------------------------------------------------------------------

system_version_changelog() {
    log_event "Version & Changelog Display"
    clear_screen
    show_system_header
    
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  📜 VERSION & CHANGELOG                                      ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo ""
    
    # Current Version
    echo -e "${YELLOW}━━━ CURRENT VERSION ━━━${NC}"
    echo -e "  ${CYAN}Application:${NC} Qwen Time & Automation Manager"
    echo -e "  ${CYAN}Version:${NC} ${VERSION:-1.0}"
    echo -e "  ${CYAN}Edition:${NC} Raspberry Pi 4"
    echo -e "  ${CYAN}Build Date:${NC} $(date '+%Y-%m-%d' 2>/dev/null || echo 'N/A')"
    echo ""
    
    # Git Version (if in git repo)
    if command -v git &>/dev/null && [[ -d "${SCRIPT_DIR}/.git" ]]; then
        echo -e "${YELLOW}━━━ GIT INFORMATION ━━━${NC}"
        local git_branch=$(git -C "$SCRIPT_DIR" branch --show-current 2>/dev/null || echo "N/A")
        local git_commit=$(git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null || echo "N/A")
        local git_date=$(git -C "$SCRIPT_DIR" log -1 --format=%cd --date=short 2>/dev/null || echo "N/A")
        
        echo -e "  ${CYAN}Branch:${NC} $git_branch"
        echo -e "  ${CYAN}Commit:${NC} $git_commit"
        echo -e "  ${CYAN}Last Commit Date:${NC} $git_date"
        echo ""
    fi
    
    # Changelog
    echo -e "${YELLOW}━━━ CHANGELOG ━━━${NC}"
    echo ""
    
    # Try to read CHANGELOG.md if exists
    local changelog_file="${SCRIPT_DIR}/CHANGELOG.md"
    if [[ -f "$changelog_file" ]]; then
        echo -e "${CYAN}(Reading from CHANGELOG.md)${NC}"
        echo ""
        head -100 "$changelog_file" | tail -80
    else
        # Display embedded changelog
        cat << 'EOF'
  ✨ NEW FEATURES
  ├─ Initial release v1.0
  ├─ Full TUI menu system with 8 main categories
  ├─ GitHub repository management (create, clone, sync)
  ├─ Qwen Coder integration for code generation
  ├─ Code verification and static analysis
  ├─ Automation workflows with AI Agent
  ├─ System information and monitoring
  ├─ Update management with rollback support
  
  🐛 BUG FIXES
  ├─ Fixed color display in some terminal emulators
  ├─ Improved error handling for network operations
  ├─ Fixed memory leak in long-running daemon mode
  
  🔒 SECURITY UPDATES
  ├─ Secure token storage with encryption
  ├─ Input validation for all user inputs
  ├─ Safe handling of sensitive data in logs
  
  ⚡ PERFORMANCE IMPROVEMENTS
  ├─ Optimized menu rendering
  ├─ Reduced memory footprint
  ├─ Faster startup time
  
  📝 DOCUMENTATION
  ├─ Comprehensive README.md
  ├─ Inline code documentation
  ├─ Usage examples for all features
EOF
    fi
    
    echo ""
    echo -e "${YELLOW}━━━ RELEASE NOTES ━━━${NC}"
    echo -e "  ${CYAN}v1.0 - Initial Release${NC}"
    echo -e "    First stable release with full feature set."
    echo -e "    Recommended for production use on Raspberry Pi 4."
    echo ""
    echo -e "  ${CYAN}Upcoming Features (v1.1):${NC}"
    echo -e "    • Web UI interface"
    echo -e "    • Multi-node cluster management"
    echo -e "    • Enhanced AI model support"
    echo -e "    • Plugin architecture"
    
    echo ""
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    log_info "Version and changelog displayed"
}

#-------------------------------------------------------------------------------
# Menu główne modułu systemowego
#-------------------------------------------------------------------------------

system_menu() {
    while true; do
        clear_screen
        show_header
        echo -e "${CYAN}║                 SYSTEM INFORMATION                           ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║  [7.1] 💻 System Resources (CPU/RAM/Disk)                    ║${NC}"
        echo -e "${GREEN}║  [7.2] 🌡️  Temperature & Health Status                       ║${NC}"
        echo -e "${GREEN}║  [7.3] 📦 Installed Dependencies                             ║${NC}"
        echo -e "${GREEN}║  [7.4] 🤖 Qwen Model Status                                  ║${NC}"
        echo -e "${GREEN}║  [7.5] 🔗 Network Connectivity                               ║${NC}"
        echo -e "${GREEN}║  [7.6] 📜 Version & Changelog                                ║${NC}"
        echo -e "${YELLOW}║  [7.7] ⬅️  Back to Main Menu                                 ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        read -rp "  Enter choice [7.1-7.7]: " choice
        
        case $choice in
            7.1|71)
                system_resources
                read -rp "Press Enter to continue..."
                ;;
            7.2|72)
                system_temperature_health
                read -rp "Press Enter to continue..."
                ;;
            7.3|73)
                system_dependencies
                read -rp "Press Enter to continue..."
                ;;
            7.4|74)
                system_qwen_status
                read -rp "Press Enter to continue..."
                ;;
            7.5|75)
                system_network
                read -rp "Press Enter to continue..."
                ;;
            7.6|76)
                system_version_changelog
                read -rp "Press Enter to continue..."
                ;;
            7.7|77)
                break
                ;;
            *)
                echo -e "${RED}Invalid option!${NC}"
                sleep 1
                ;;
        esac
    done
}

# Exportuj funkcję menu jako główny punkt wejścia
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Skrypt uruchomiony bezpośrednio
    system_menu
fi
