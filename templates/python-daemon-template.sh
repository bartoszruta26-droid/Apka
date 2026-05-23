#!/bin/bash

#===============================================================================
# Szablon projektu: Python Daemon (Systemd Service)
# Template: Python Daemon Application
#===============================================================================

set -euo pipefail

PROJECT_NAME="${1:-my-python-daemon}"
PROJECT_DIR="${2:-./${PROJECT_NAME}}"

echo "🐍 Tworzenie projektu Python Daemon: $PROJECT_NAME"
echo "Lokalizacja: $PROJECT_DIR"

# Tworzenie struktury katalogów
mkdir -p "$PROJECT_DIR"/{src,logs,config,scripts,tests}

# src/__init__.py
cat > "$PROJECT_DIR/src/__init__.py" << EOF
"""
$PROJECT_NAME - Daemon service package
"""
__version__ = "1.0.0"
__author__ = "Your Name"
EOF

# src/daemon.py - Główny plik daemona
cat > "$PROJECT_DIR/src/daemon.py" << 'EOF'
#!/usr/bin/env python3
"""
Python Daemon Service
A robust background service with logging, signal handling, and configuration.
"""

import argparse
import logging
import os
import signal
import sys
import time
from pathlib import Path
from typing import Optional
from datetime import datetime
import threading
import json

# Try importing optional dependencies
try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False

try:
    from pid import PidFile
    HAS_PID = True
except ImportError:
    HAS_PID = False


class DaemonConfig:
    """Configuration manager for the daemon."""
    
    def __init__(self, config_path: str):
        self.config_path = Path(config_path)
        self.config = self._load_config()
    
    def _load_config(self) -> dict:
        """Load configuration from file."""
        if not self.config_path.exists():
            return self._default_config()
        
        try:
            if HAS_YAML and self.config_path.suffix in ['.yaml', '.yml']:
                with open(self.config_path, 'r') as f:
                    return yaml.safe_load(f) or self._default_config()
            else:
                with open(self.config_path, 'r') as f:
                    return json.load(f) or self._default_config()
        except Exception as e:
            logging.warning(f"Failed to load config: {e}, using defaults")
            return self._default_config()
    
    def _default_config(self) -> dict:
        """Return default configuration."""
        return {
            "daemon": {
                "name": "my-daemon",
                "pid_file": "/tmp/my-daemon.pid",
                "log_file": "/tmp/my-daemon.log",
                "log_level": "INFO",
                "check_interval": 60
            },
            "service": {
                "enabled": True,
                "retry_count": 3,
                "retry_delay": 5
            }
        }
    
    def get(self, key: str, default=None):
        """Get configuration value by dot-notation key."""
        keys = key.split('.')
        value = self.config
        for k in keys:
            if isinstance(value, dict):
                value = value.get(k, default)
            else:
                return default
        return value


class DaemonService:
    """Main daemon service class."""
    
    def __init__(self, config: DaemonConfig):
        self.config = config
        self.name = config.get('daemon.name', 'my-daemon')
        self.running = False
        self.logger = self._setup_logging()
        self._setup_signal_handlers()
        self.work_thread = None
    
    def _setup_logging(self) -> logging.Logger:
        """Configure logging for the daemon."""
        log_level = getattr(logging, self.config.get('daemon.log_level', 'INFO'))
        log_file = self.config.get('daemon.log_file', '/tmp/my-daemon.log')
        
        # Ensure log directory exists
        log_path = Path(log_file)
        log_path.parent.mkdir(parents=True, exist_ok=True)
        
        logger = logging.getLogger(self.name)
        logger.setLevel(log_level)
        
        # File handler
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(log_level)
        
        # Console handler
        console_handler = logging.StreamHandler()
        console_handler.setLevel(log_level)
        
        # Formatter
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        file_handler.setFormatter(formatter)
        console_handler.setFormatter(formatter)
        
        logger.addHandler(file_handler)
        logger.addHandler(console_handler)
        
        return logger
    
    def _setup_signal_handlers(self):
        """Setup signal handlers for graceful shutdown."""
        signal.signal(signal.SIGTERM, self._signal_handler)
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGHUP, self._signal_handler)
    
    def _signal_handler(self, signum, frame):
        """Handle system signals."""
        sig_name = signal.Signals(signum).name
        self.logger.info(f"Received signal: {sig_name}")
        
        if signum in [signal.SIGTERM, signal.SIGINT]:
            self.logger.info("Shutdown requested")
            self.stop()
        elif signum == signal.SIGHUP:
            self.logger.info("Reloading configuration")
            self.config.config = self.config._load_config()
    
    def start(self):
        """Start the daemon service."""
        self.running = True
        self.logger.info(f"Starting daemon: {self.name}")
        
        # Write PID file if available
        if HAS_PID:
            try:
                pid_file = self.config.get('daemon.pid_file')
                if pid_file:
                    with PidFile(pid_file):
                        self.logger.info(f"PID file created: {pid_file}")
            except Exception as e:
                self.logger.warning(f"Failed to create PID file: {e}")
        
        # Start main work loop
        self._main_loop()
    
    def stop(self):
        """Stop the daemon service."""
        self.logger.info("Stopping daemon...")
        self.running = False
        
        # Cleanup
        self._cleanup()
        self.logger.info("Daemon stopped")
    
    def _cleanup(self):
        """Cleanup resources before exit."""
        pid_file = self.config.get('daemon.pid_file')
        if pid_file and Path(pid_file).exists():
            try:
                Path(pid_file).unlink()
                self.logger.debug(f"Removed PID file: {pid_file}")
            except Exception as e:
                self.logger.warning(f"Failed to remove PID file: {e}")
    
    def _main_loop(self):
        """Main daemon work loop."""
        check_interval = self.config.get('daemon.check_interval', 60)
        iteration = 0
        
        while self.running:
            try:
                iteration += 1
                self.logger.debug(f"Iteration {iteration}")
                
                # Perform daemon work
                self._do_work()
                
                # Wait for next iteration
                for _ in range(check_interval * 10):
                    if not self.running:
                        break
                    time.sleep(0.1)
                    
            except Exception as e:
                self.logger.error(f"Error in main loop: {e}", exc_info=True)
                retry_count = self.config.get('service.retry_count', 3)
                retry_delay = self.config.get('service.retry_delay', 5)
                
                if retry_count > 0:
                    self.logger.info(f"Retrying in {retry_delay} seconds...")
                    time.sleep(retry_delay)
                else:
                    self.logger.error("Max retries reached, stopping")
                    self.stop()
    
    def _do_work(self):
        """
        Override this method to implement your daemon's work.
        This is called every check_interval seconds.
        """
        self.logger.debug("Performing scheduled work...")
        # TODO: Implement your daemon logic here
        pass


def parse_arguments() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Python Daemon Service",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument(
        "-c", "--config",
        type=str,
        default="/etc/my-daemon/config.yaml",
        help="Path to configuration file"
    )
    
    parser.add_argument(
        "-f", "--foreground",
        action="store_true",
        help="Run in foreground mode"
    )
    
    parser.add_argument(
        "action",
        nargs="?",
        choices=["start", "stop", "status", "restart"],
        default="start",
        help="Action to perform"
    )
    
    return parser.parse_args()


def main() -> int:
    """Main entry point."""
    args = parse_arguments()
    
    # Load configuration
    config = DaemonConfig(args.config)
    
    # Create daemon instance
    daemon = DaemonService(config)
    
    if args.action == "start":
        daemon.start()
    elif args.action == "stop":
        daemon.stop()
    elif args.action == "status":
        print(f"Daemon status: {'running' if daemon.running else 'stopped'}")
    elif args.action == "restart":
        daemon.stop()
        daemon.start()
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
EOF

# config/default.yaml - Domyślna konfiguracja
cat > "$PROJECT_DIR/config/default.yaml" << 'EOF'
# Daemon Configuration
daemon:
  name: "my-daemon"
  pid_file: "/tmp/my-daemon.pid"
  log_file: "/var/log/my-daemon/daemon.log"
  log_level: "INFO"
  check_interval: 60  # seconds between work cycles

# Service settings
service:
  enabled: true
  retry_count: 3
  retry_delay: 5

# Custom settings
custom:
  database_url: "sqlite:///data.db"
  api_endpoint: "http://localhost:8080"
  max_workers: 4
EOF

# scripts/install.sh - Skrypt instalacyjny
cat > "$PROJECT_DIR/scripts/install.sh" << 'EOF'
#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Installing daemon service..."

# Create directories
sudo mkdir -p /etc/my-daemon
sudo mkdir -p /var/log/my-daemon
sudo mkdir -p /opt/my-daemon

# Copy files
sudo cp -r "$PROJECT_DIR/src" /opt/my-daemon/
sudo cp -r "$PROJECT_DIR/config" /opt/my-daemon/
sudo cp "$SCRIPT_DIR/my-daemon.service" /etc/systemd/system/

# Set permissions
sudo chmod +x /opt/my-daemon/src/daemon.py
sudo chown -R root:root /opt/my-daemon

# Create symlink
sudo ln -sf /opt/my-daemon/src/daemon.py /usr/local/bin/my-daemon

echo "✅ Installation complete!"
echo ""
echo "To enable and start the service:"
echo "  sudo systemctl daemon-reload"
echo "  sudo systemctl enable my-daemon"
echo "  sudo systemctl start my-daemon"
echo ""
echo "To check status:"
echo "  sudo systemctl status my-daemon"
EOF

# scripts/my-daemon.service - Systemd unit file
cat > "$PROJECT_DIR/scripts/my-daemon.service" << 'EOF'
[Unit]
Description=My Python Daemon Service
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/my-daemon
ExecStart=/usr/bin/python3 /opt/my-daemon/src/daemon.py start -c /etc/my-daemon/config.yaml
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=my-daemon

# Security hardening
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log/my-daemon

[Install]
WantedBy=multi-user.target
EOF

# tests/test_daemon.py
cat > "$PROJECT_DIR/tests/test_daemon.py" << 'EOF'
#!/usr/bin/env python3
"""
Unit tests for daemon module
"""

import unittest
import tempfile
import os
from pathlib import Path


class TestDaemonConfig(unittest.TestCase):
    """Test cases for DaemonConfig class."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.temp_dir = tempfile.mkdtemp()
        self.config_file = Path(self.temp_dir) / "test_config.yaml"
    
    def tearDown(self):
        """Clean up after tests."""
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)
    
    def test_default_config(self):
        """Test default configuration loading."""
        from src.daemon import DaemonConfig
        config = DaemonConfig(str(self.config_file))
        
        self.assertIsNotNone(config.get('daemon.name'))
        self.assertEqual(config.get('daemon.log_level'), 'INFO')
    
    def test_custom_config(self):
        """Test custom configuration loading."""
        config_content = """
daemon:
  name: "test-daemon"
  log_level: "DEBUG"
"""
        with open(self.config_file, 'w') as f:
            f.write(config_content)
        
        from src.daemon import DaemonConfig
        config = DaemonConfig(str(self.config_file))
        
        self.assertEqual(config.get('daemon.name'), 'test-daemon')
        self.assertEqual(config.get('daemon.log_level'), 'DEBUG')


class TestDaemonService(unittest.TestCase):
    """Test cases for DaemonService class."""
    
    def test_service_initialization(self):
        """Test service initialization."""
        from src.daemon import DaemonConfig, DaemonService
        
        config = DaemonConfig("/nonexistent/config.yaml")
        service = DaemonService(config)
        
        self.assertFalse(service.running)
        self.assertIsNotNone(service.logger)


if __name__ == "__main__":
    unittest.main()
EOF

# requirements.txt
cat > "$PROJECT_DIR/requirements.txt" << 'EOF'
# Core dependencies
pid>=3.0.0
pyyaml>=6.0

# Development dependencies
pytest>=7.0.0
black>=22.0.0
flake8>=4.0.0

# Optional dependencies
# systemd-python>=234
EOF

# README.md
cat > "$PROJECT_DIR/README.md" << EOF
# $PROJECT_NAME

A robust Python daemon service with systemd integration.

## Structure

\`\`\`
$PROJECT_NAME/
├── src/                    # Source code
│   ├── __init__.py
│   └── daemon.py           # Main daemon implementation
├── config/                 # Configuration files
│   └── default.yaml
├── logs/                   # Log files directory
├── scripts/                # Installation and service scripts
│   ├── install.sh
│   └── my-daemon.service
├── tests/                  # Unit tests
│   └── test_daemon.py
├── requirements.txt        # Dependencies
└── README.md               # This file
\`\`\`

## Features

- Signal handling (SIGTERM, SIGINT, SIGHUP)
- PID file management
- Configurable logging
- YAML/JSON configuration support
- Systemd service integration
- Graceful shutdown
- Automatic restart on failure
- Security hardening options

## Installation

### Quick Install

\`\`\`bash
cd $PROJECT_NAME
pip install -r requirements.txt
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

### Run in foreground

\`\`\`bash
python src/daemon.py start -c config/default.yaml --foreground
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
\`\`\`

## Configuration

Edit \`config/default.yaml\` to customize:

- Daemon name and PID file location
- Log file path and level
- Check interval for work cycles
- Retry settings
- Custom application settings

## Development

\`\`\`bash
# Install dev dependencies
pip install -r requirements.txt

# Run tests
pytest tests/

# Code formatting
black src/ tests/

# Linting
flake8 src/ tests/
\`\`\`

## License

MIT License
EOF

# .gitignore
cat > "$PROJECT_DIR/.gitignore" << 'EOF'
# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class

# Distribution / packaging
.Python
build/
dist/
*.egg-info/

# Environments
.env
.venv
venv/

# Logs
logs/
*.log

# PID files
*.pid

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Configuration (keep default, ignore local)
!config/default.yaml
config/local.yaml
EOF

echo ""
echo "✅ Projekt Python Daemon utworzony pomyślnie!"
echo ""
echo "Struktura projektu:"
find "$PROJECT_DIR" -type f | sort | sed "s|$PROJECT_DIR||"
echo ""
echo "Aby uruchomić:"
echo "  cd $PROJECT_DIR"
echo "  pip install -r requirements.txt"
echo "  python src/daemon.py start --foreground"
echo ""
echo "Aby zainstalować jako usługę systemową:"
echo "  sudo bash scripts/install.sh"
echo "  sudo systemctl enable my-daemon"
echo "  sudo systemctl start my-daemon"
