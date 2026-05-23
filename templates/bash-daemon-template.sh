#!/bin/bash

#===============================================================================
# Szablon projektu: Bash Daemon (Systemd Service)
# Template: Bash Daemon Application
#===============================================================================

set -euo pipefail

PROJECT_NAME="${1:-my-bash-daemon}"
PROJECT_DIR="${2:-./${PROJECT_NAME}}"

echo "🐚 Tworzenie projektu Bash Daemon: $PROJECT_NAME"
echo "Lokalizacja: $PROJECT_DIR"

# Tworzenie struktury katalogów
mkdir -p "$PROJECT_DIR"/{bin,config,logs,scripts}

# bin/daemon.sh - Główny skrypt daemona
cat > "$PROJECT_DIR/bin/daemon.sh" << 'EOF'
#!/bin/bash

#===============================================================================
# Bash Daemon Service
# A robust background bash service with logging and signal handling
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# Configuration
#-------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAEMON_NAME="${DAEMON_NAME:-my-daemon}"
PID_FILE="${PID_FILE:-/tmp/${DAEMON_NAME}.pid}"
LOG_FILE="${LOG_FILE:-/var/log/${DAEMON_NAME}/${DAEMON_NAME}.log}"
CONFIG_FILE="${CONFIG_FILE:-/etc/${DAEMON_NAME}/config.conf}"
CHECK_INTERVAL="${CHECK_INTERVAL:-60}"
MAX_RETRIES="${MAX_RETRIES:-3}"
RETRY_DELAY="${RETRY_DELAY:-5}"

#-------------------------------------------------------------------------------
# Logging Functions
#-------------------------------------------------------------------------------
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE" 2>/dev/null || echo "[$timestamp] [$level] $message"
}

log_info() {
    log "INFO" "$@"
}

log_error() {
    log "ERROR" "$@"
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        log "DEBUG" "$@"
    fi
}

#-------------------------------------------------------------------------------
# Signal Handlers
#-------------------------------------------------------------------------------
cleanup() {
    log_info "Cleaning up..."
    remove_pid_file
    log_info "Daemon stopped"
    exit 0
}

reload_config() {
    log_info "Reloading configuration..."
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
        log_info "Configuration reloaded"
    else
        log_error "Configuration file not found: $CONFIG_FILE"
    fi
}

#-------------------------------------------------------------------------------
# PID File Management
#-------------------------------------------------------------------------------
create_pid_file() {
    local pid=$$
    
    if [[ -f "$PID_FILE" ]]; then
        local old_pid=$(cat "$PID_FILE")
        if kill -0 "$old_pid" 2>/dev/null; then
            log_error "Daemon is already running (PID: $old_pid)"
            return 1
        else
            log_info "Removing stale PID file"
            rm -f "$PID_FILE"
        fi
    fi
    
    echo "$pid" > "$PID_FILE"
    log_info "PID file created: $PID_FILE (PID: $pid)"
}

remove_pid_file() {
    if [[ -f "$PID_FILE" ]]; then
        rm -f "$PID_FILE"
        log_debug "Removed PID file: $PID_FILE"
    fi
}

check_pid_file() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "$pid"
            return 0
        fi
    fi
    return 1
}

#-------------------------------------------------------------------------------
# Load Configuration
#-------------------------------------------------------------------------------
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
        log_debug "Configuration loaded from: $CONFIG_FILE"
    else
        log_debug "Using default configuration"
    fi
    
    # Ensure log directory exists
    local log_dir=$(dirname "$LOG_FILE")
    mkdir -p "$log_dir" 2>/dev/null || true
}

#-------------------------------------------------------------------------------
# Main Work Function
#-------------------------------------------------------------------------------
do_work() {
    # TODO: Implement your daemon's work here
    log_debug "Performing scheduled work..."
    
    # Example: Check a file, process data, send requests, etc.
    # Your custom logic goes here
    
    return 0
}

#-------------------------------------------------------------------------------
# Main Loop
#-------------------------------------------------------------------------------
main_loop() {
    local iteration=0
    local retry_count=0
    
    while true; do
        ((iteration++))
        log_debug "Iteration $iteration"
        
        if do_work; then
            retry_count=0
        else
            ((retry_count++))
            log_error "Work failed (attempt $retry_count/$MAX_RETRIES)"
            
            if [[ $retry_count -ge $MAX_RETRIES ]]; then
                log_error "Max retries reached, stopping"
                cleanup
            fi
            
            log_info "Retrying in $RETRY_DELAY seconds..."
            sleep "$RETRY_DELAY"
            continue
        fi
        
        # Sleep for check interval
        local slept=0
        while [[ $slept -lt $CHECK_INTERVAL ]]; do
            sleep 1
            ((slept++))
        done
    done
}

#-------------------------------------------------------------------------------
# Command Functions
#-------------------------------------------------------------------------------
cmd_start() {
    log_info "Starting daemon: $DAEMON_NAME"
    
    if check_pid_file >/dev/null 2>&1; then
        log_error "Daemon is already running"
        return 1
    fi
    
    load_config
    create_pid_file || return 1
    
    # Setup signal handlers
    trap cleanup SIGTERM SIGINT EXIT
    trap reload_config SIGHUP
    
    log_info "Daemon started successfully"
    main_loop
}

cmd_stop() {
    log_info "Stopping daemon: $DAEMON_NAME"
    
    local pid
    if pid=$(check_pid_file); then
        log_info "Sending SIGTERM to PID $pid"
        kill -TERM "$pid" 2>/dev/null || true
        
        # Wait for process to stop
        local count=0
        while kill -0 "$pid" 2>/dev/null && [[ $count -lt 30 ]]; do
            sleep 1
            ((count++))
        done
        
        if kill -0 "$pid" 2>/dev/null; then
            log_info "Sending SIGKILL to PID $pid"
            kill -9 "$pid" 2>/dev/null || true
        fi
        
        remove_pid_file
        log_info "Daemon stopped"
    else
        log_info "Daemon is not running"
        remove_pid_file
    fi
}

cmd_status() {
    local pid
    if pid=$(check_pid_file); then
        echo "Daemon is running (PID: $pid)"
        return 0
    else
        echo "Daemon is not running"
        return 1
    fi
}

cmd_restart() {
    cmd_stop
    sleep 2
    cmd_start
}

cmd_reload() {
    local pid
    if pid=$(check_pid_file); then
        log_info "Sending SIGHUP to PID $pid"
        kill -HUP "$pid"
        echo "Configuration reload signal sent"
    else
        echo "Daemon is not running"
        return 1
    fi
}

#-------------------------------------------------------------------------------
# Usage
#-------------------------------------------------------------------------------
usage() {
    cat << USAGE
Usage: $(basename "$0") {start|stop|status|restart|reload}

Commands:
  start     Start the daemon
  stop      Stop the daemon
  status    Check daemon status
  restart   Restart the daemon
  reload    Reload configuration

Environment Variables:
  DAEMON_NAME     Daemon name (default: my-daemon)
  PID_FILE        PID file path (default: /tmp/\${DAEMON_NAME}.pid)
  LOG_FILE        Log file path (default: /var/log/\${DAEMON_NAME}/\${DAEMON_NAME}.log)
  CONFIG_FILE     Config file path (default: /etc/\${DAEMON_NAME}/config.conf)
  CHECK_INTERVAL  Work interval in seconds (default: 60)
  MAX_RETRIES     Max retry attempts (default: 3)
  RETRY_DELAY     Delay between retries in seconds (default: 5)
  DEBUG           Enable debug logging (default: false)

USAGE
}

#-------------------------------------------------------------------------------
# Main Entry Point
#-------------------------------------------------------------------------------
main() {
    local command="${1:-}"
    
    case "$command" in
        start)
            cmd_start
            ;;
        stop)
            cmd_stop
            ;;
        status)
            cmd_status
            ;;
        restart)
            cmd_restart
            ;;
        reload)
            cmd_reload
            ;;
        -h|--help|help)
            usage
            exit 0
            ;;
        *)
            echo "Error: Unknown command '$command'" >&2
            usage
            exit 1
            ;;
    esac
}

main "$@"
EOF

chmod +x "$PROJECT_DIR/bin/daemon.sh"

# config/default.conf - Domyślna konfiguracja
cat > "$PROJECT_DIR/config/default.conf" << 'EOF'
# Daemon Configuration
# Copy this file to /etc/my-daemon/config.conf and customize

# Daemon name
DAEMON_NAME="my-daemon"

# PID file location
PID_FILE="/tmp/my-daemon.pid"

# Log file location
LOG_FILE="/var/log/my-daemon/my-daemon.log"

# Configuration file location
CONFIG_FILE="/etc/my-daemon/config.conf"

# Work interval in seconds
CHECK_INTERVAL=60

# Retry settings
MAX_RETRIES=3
RETRY_DELAY=5

# Enable debug logging (true/false)
DEBUG=false

# Custom settings
# Add your custom configuration variables here
# CUSTOM_VAR="value"
EOF

# scripts/install.sh - Skrypt instalacyjny
cat > "$PROJECT_DIR/scripts/install.sh" << 'EOF'
#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Installing bash daemon service..."

# Detect daemon name from project directory
DAEMON_NAME=$(basename "$PROJECT_DIR" | sed 's/-daemon$//')
DAEMON_NAME="${DAEMON_NAME:-my-daemon}"

# Create directories
sudo mkdir -p "/etc/${DAEMON_NAME}"
sudo mkdir -p "/var/log/${DAEMON_NAME}"
sudo mkdir -p "/opt/${DAEMON_NAME}"

# Copy files
sudo cp -r "$PROJECT_DIR/bin"/* "/opt/${DAEMON_NAME}/"
sudo cp "$PROJECT_DIR/config/default.conf" "/etc/${DAEMON_NAME}/config.conf"
sudo cp "$SCRIPT_DIR/${DAEMON_NAME}.service" "/etc/systemd/system/" 2>/dev/null || \
    sudo cp "$SCRIPT_DIR/daemon.service" "/etc/systemd/system/${DAEMON_NAME}.service"

# Set permissions
sudo chmod +x "/opt/${DAEMON_NAME}/daemon.sh"
sudo chown -R root:root "/opt/${DAEMON_NAME}"

# Create symlink
sudo ln -sf "/opt/${DAEMON_NAME}/daemon.sh" "/usr/local/bin/${DAEMON_NAME}"

echo ""
echo "✅ Installation complete!"
echo ""
echo "To enable and start the service:"
echo "  sudo systemctl daemon-reload"
echo "  sudo systemctl enable ${DAEMON_NAME}"
echo "  sudo systemctl start ${DAEMON_NAME}"
echo ""
echo "To check status:"
echo "  sudo systemctl status ${DAEMON_NAME}"
echo "  sudo journalctl -u ${DAEMON_NAME} -f"
EOF

# scripts/daemon.service - Systemd unit file
cat > "$PROJECT_DIR/scripts/daemon.service" << 'EOF'
[Unit]
Description=Bash Daemon Service
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/my-daemon
ExecStart=/opt/my-daemon/daemon.sh start
ExecStop=/opt/my-daemon/daemon.sh stop
ExecReload=/opt/my-daemon/daemon.sh reload
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=my-daemon

# Environment
Environment="DAEMON_NAME=my-daemon"
Environment="CONFIG_FILE=/etc/my-daemon/config.conf"

# Security hardening
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log/my-daemon
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

# scripts/uninstall.sh
cat > "$PROJECT_DIR/scripts/uninstall.sh" << 'EOF'
#!/bin/bash

set -euo pipefail

echo "Uninstalling daemon service..."

# Detect daemon name
DAEMON_NAME="${1:-my-daemon}"

# Stop and disable service
sudo systemctl stop "${DAEMON_NAME}" 2>/dev/null || true
sudo systemctl disable "${DAEMON_NAME}" 2>/dev/null || true

# Remove systemd service file
sudo rm -f "/etc/systemd/system/${DAEMON_NAME}.service"

# Remove installation files
sudo rm -rf "/opt/${DAEMON_NAME}"
sudo rm -rf "/etc/${DAEMON_NAME}"
sudo rm -f "/usr/local/bin/${DAEMON_NAME}"

# Keep logs (optional - uncomment to remove)
# sudo rm -rf "/var/log/${DAEMON_NAME}"

# Reload systemd
sudo systemctl daemon-reload

echo ""
echo "✅ Uninstallation complete!"
echo ""
echo "Note: Log files in /var/log/${DAEMON_NAME} were preserved."
echo "To remove them manually: sudo rm -rf /var/log/${DAEMON_NAME}"
EOF

# README.md
cat > "$PROJECT_DIR/README.md" << EOF
# $PROJECT_NAME

A robust Bash daemon service with systemd integration.

## Structure

\`\`\`
$PROJECT_NAME/
├── bin/                    # Executable scripts
│   └── daemon.sh           # Main daemon script
├── config/                 # Configuration files
│   └── default.conf
├── logs/                   # Log files directory
├── scripts/                # Installation and service scripts
│   ├── install.sh
│   ├── uninstall.sh
│   └── daemon.service
└── README.md               # This file
\`\`\`

## Features

- Signal handling (SIGTERM, SIGINT, SIGHUP)
- PID file management
- Configurable logging
- Systemd service integration
- Graceful shutdown
- Automatic restart on failure
- Security hardening options
- Pure Bash implementation

## Installation

### Quick Install

\`\`\`bash
cd $PROJECT_NAME
chmod +x bin/daemon.sh
./bin/daemon.sh --help
\`\`\`

### System Service Installation

\`\`\`bash
# Run installation script
sudo bash scripts/install.sh

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable my-daemon
sudo systemctl start my-daemon
\`\`\`

## Usage

### Manual Control

\`\`\`bash
# Start (foreground)
./bin/daemon.sh start

# Stop
./bin/daemon.sh stop

# Status
./bin/daemon.sh status

# Restart
./bin/daemon.sh restart

# Reload configuration
./bin/daemon.sh reload

# Show help
./bin/daemon.sh --help
\`\`\`

### Manage as systemd service

\`\`\`bash
# Start
sudo systemctl start my-daemon

# Stop
sudo systemctl stop my-daemon

# Restart
sudo systemctl restart my-daemon

# Status
sudo systemctl status my-daemon

# View logs
sudo journalctl -u my-daemon -f

# Reload configuration
sudo systemctl reload my-daemon
\`\`\`

## Configuration

Copy \`config/default.conf\` to \`/etc/my-daemon/config.conf\` and customize:

\`\`\`bash
# Daemon name
DAEMON_NAME="my-daemon"

# Work interval in seconds
CHECK_INTERVAL=60

# Retry settings
MAX_RETRIES=3
RETRY_DELAY=5

# Enable debug logging
DEBUG=false
\`\`\`

## Development

### Testing locally

\`\`\`bash
# Run in foreground with debug
DEBUG=true ./bin/daemon.sh start

# Check logs
tail -f /tmp/my-daemon.log
\`\`\`

### Customizing the work function

Edit the \`do_work()\` function in \`bin/daemon.sh\`:

\`\`\`bash
do_work() {
    # Your custom logic here
    log_debug "Processing..."
    
    # Example: Check a file
    if [[ -f "/path/to/watch/file" ]]; then
        # Process the file
        log_info "File detected, processing..."
    fi
    
    return 0
}
\`\`\`

## Troubleshooting

### Check if daemon is running

\`\`\`bash
ps aux | grep my-daemon
cat /tmp/my-daemon.pid
\`\`\`

### View logs

\`\`\`bash
# Systemd journal
sudo journalctl -u my-daemon -f

# Log file
tail -f /var/log/my-daemon/my-daemon.log
\`\`\`

### Common issues

1. **Permission denied**: Run with sudo or adjust file permissions
2. **Already running**: Check PID file and stale processes
3. **Not starting**: Check logs for error messages

## License

MIT License
EOF

# .gitignore
cat > "$PROJECT_DIR/.gitignore" << 'EOF'
# Logs
logs/
*.log

# PID files
*.pid

# Configuration (keep default, ignore local)
!config/default.conf
config/local.conf
/etc/

# OS
.DS_Store
Thumbs.db

# Editor
*.swp
*.swo
*~
.idea/
.vscode/
EOF

echo ""
echo "✅ Projekt Bash Daemon utworzony pomyślnie!"
echo ""
echo "Struktura projektu:"
find "$PROJECT_DIR" -type f | sort | sed "s|$PROJECT_DIR||"
echo ""
echo "Aby uruchomić:"
echo "  cd $PROJECT_DIR"
echo "  chmod +x bin/daemon.sh"
echo "  ./bin/daemon.sh start"
echo ""
echo "Aby zainstalować jako usługę systemową:"
echo "  sudo bash scripts/install.sh"
echo "  sudo systemctl enable my-daemon"
echo "  sudo systemctl start my-daemon"
