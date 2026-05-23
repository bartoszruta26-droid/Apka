#!/bin/bash

#===============================================================================
# Szablon projektu: Aplikacja Python (CLI/GUI)
# Template: Python Application
#===============================================================================

set -euo pipefail

PROJECT_NAME="${1:-my-python-app}"
PROJECT_DIR="${2:-./${PROJECT_NAME}}"

echo "🐍 Tworzenie projektu Python: $PROJECT_NAME"
echo "Lokalizacja: $PROJECT_DIR"

# Tworzenie struktury katalogów
mkdir -p "$PROJECT_DIR"/{src,tests,data,docs,utils}

# src/__init__.py
cat > "$PROJECT_DIR/src/__init__.py" << EOF
"""
$PROJECT_NAME - Main application package
"""
__version__ = "1.0.0"
__author__ = "Your Name"
EOF

# src/main.py
cat > "$PROJECT_DIR/src/main.py" << 'EOF'
#!/usr/bin/env python3
"""
Main entry point for the application
"""

import argparse
import sys
from typing import Optional


def parse_arguments() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="My Python Application",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument(
        "-v", "--version",
        action="version",
        version="%(prog)s 1.0.0"
    )
    
    parser.add_argument(
        "-d", "--debug",
        action="store_true",
        help="Enable debug mode"
    )
    
    parser.add_argument(
        "-c", "--config",
        type=str,
        default="config.yaml",
        help="Path to configuration file"
    )
    
    parser.add_argument(
        "action",
        nargs="?",
        choices=["run", "test", "info"],
        default="run",
        help="Action to perform"
    )
    
    return parser.parse_args()


def main() -> int:
    """Main application entry point."""
    args = parse_arguments()
    
    if args.debug:
        print("[DEBUG] Debug mode enabled")
    
    if args.action == "run":
        print("Running application...")
        # Add your main logic here
        return 0
    
    elif args.action == "test":
        print("Running tests...")
        # Add test logic here
        return 0
    
    elif args.action == "info":
        print("Application Information:")
        print("  Version: 1.0.0")
        print("  Python: ", sys.version)
        return 0
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
EOF

# utils/helpers.py
cat > "$PROJECT_DIR/utils/helpers.py" << 'EOF'
"""
Helper utilities for the application
"""

import logging
from pathlib import Path
from typing import Any, Dict, List, Optional


def setup_logging(debug: bool = False) -> logging.Logger:
    """Configure and return a logger instance."""
    level = logging.DEBUG if debug else logging.INFO
    
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    
    return logging.getLogger(__name__)


def load_config(config_path: str) -> Dict[str, Any]:
    """Load configuration from YAML file."""
    # Placeholder for config loading
    return {
        "app_name": "my-python-app",
        "version": "1.0.0",
        "debug": False
    }


def save_results(data: List[Dict], output_path: str) -> None:
    """Save results to a file."""
    path = Path(output_path)
    path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(path, 'w') as f:
        for item in data:
            f.write(f"{item}\n")


def validate_input(value: str, pattern: Optional[str] = None) -> bool:
    """Validate input string against optional pattern."""
    if not value:
        return False
    
    if pattern:
        import re
        return bool(re.match(pattern, value))
    
    return True
EOF

# tests/__init__.py
cat > "$PROJECT_DIR/tests/__init__.py" << 'EOF'
"""
Test package for the application
"""
EOF

# tests/test_main.py
cat > "$PROJECT_DIR/tests/test_main.py" << 'EOF'
#!/usr/bin/env python3
"""
Unit tests for main module
"""

import unittest
from pathlib import Path


class TestApplication(unittest.TestCase):
    """Test cases for the main application."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.test_data = {"key": "value"}
    
    def tearDown(self):
        """Clean up after tests."""
        pass
    
    def test_example(self):
        """Example test case."""
        self.assertEqual(2 + 2, 4)
    
    def test_data_structure(self):
        """Test data structure handling."""
        self.assertIn("key", self.test_data)
        self.assertEqual(self.test_data["key"], "value")


if __name__ == "__main__":
    unittest.main()
EOF

# requirements.txt
cat > "$PROJECT_DIR/requirements.txt" << 'EOF'
# Core dependencies
requests>=2.28.0
pyyaml>=6.0
click>=8.0.0

# Development dependencies
pytest>=7.0.0
black>=22.0.0
flake8>=4.0.0
mypy>=0.950

# Optional dependencies
# rich>=12.0.0
# tqdm>=4.64.0
EOF

# setup.py
cat > "$PROJECT_DIR/setup.py" << 'EOF'
#!/usr/bin/env python3
"""
Setup script for the application
"""

from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="my-python-app",
    version="1.0.0",
    author="Your Name",
    author_email="your.email@example.com",
    description="A Python application template",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/username/my-python-app",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
    python_requires=">=3.8",
    install_requires=[
        "requests>=2.28.0",
        "pyyaml>=6.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.0.0",
            "black>=22.0.0",
            "flake8>=4.0.0",
        ],
    },
    entry_points={
        "console_scripts": [
            "my-app=my_python_app.main:main",
        ],
    },
)
EOF

# pyproject.toml
cat > "$PROJECT_DIR/pyproject.toml" << 'EOF'
[build-system]
requires = ["setuptools>=45", "wheel"]
build-backend = "setuptools.build_meta"

[tool.black]
line-length = 88
target-version = ['py38', 'py39', 'py310', 'py311']
include = '\.pyi?$'

[tool.flake8]
max-line-length = 88
exclude = ["build", "dist", ".git", "__pycache__"]

[tool.mypy]
python_version = "3.8"
warn_return_any = true
warn_unused_configs = true
ignore_missing_imports = true

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = "test_*.py"
python_functions = "test_*"
EOF

# README.md
cat > "$PROJECT_DIR/README.md" << EOF
# $PROJECT_NAME

A modern Python application template with best practices.

## Structure

\`\`\`
$PROJECT_NAME/
├── src/                    # Source code
│   ├── __init__.py
│   └── main.py             # Main entry point
├── tests/                  # Unit tests
│   ├── __init__.py
│   └── test_main.py
├── utils/                  # Utility modules
│   └── helpers.py
├── data/                   # Data files
├── docs/                   # Documentation
├── requirements.txt        # Dependencies
├── setup.py                # Setup script
├── pyproject.toml          # Project configuration
└── README.md               # This file
\`\`\`

## Installation

\`\`\`bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\\Scripts\\activate

# Install dependencies
pip install -r requirements.txt

# Install in development mode
pip install -e .
\`\`\`

## Usage

\`\`\`bash
# Run the application
python src/main.py run

# Run with debug mode
python src/main.py --debug run

# Run tests
pytest tests/

# Code formatting
black src/ tests/

# Linting
flake8 src/ tests/
\`\`\`

## Features

- Modern Python 3.8+ syntax
- Type hints support
- Comprehensive testing setup
- Code formatting with Black
- Linting with Flake8
- Static typing with MyPy
- Easy packaging and distribution

## License

MIT License
EOF

# .gitignore
cat > "$PROJECT_DIR/.gitignore" << 'EOF'
# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class

# C extensions
*.so

# Distribution / packaging
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# PyInstaller
*.manifest
*.spec

# Installer logs
pip-log.txt
pip-delete-this-directory.txt

# Unit test / coverage reports
htmlcov/
.tox/
.nox/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
*.py,cover
.hypothesis/
.pytest_cache/

# Translations
*.mo
*.pot

# Environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
EOF

echo ""
echo "✅ Projekt Python utworzony pomyślnie!"
echo ""
echo "Struktura projektu:"
find "$PROJECT_DIR" -type f | sort | sed "s|$PROJECT_DIR||"
echo ""
echo "Aby uruchomić:"
echo "  cd $PROJECT_DIR"
echo "  python3 -m venv venv"
echo "  source venv/bin/activate"
echo "  pip install -r requirements.txt"
echo "  python src/main.py --help"
