#!/bin/bash

#===============================================================================
# PUTER AI INTEGRATION MODULE
# Moduł do obsługi darmowego API Puter.com (Qwen i OpenAI)
# Na podstawie: https://developer.puter.com/tutorials/
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# Konfiguracja i zmienne globalne
#-------------------------------------------------------------------------------
readonly PUTER_MODULE_VERSION="1.0"
# Get script directory (only if not already set by parent script)
if [[ -z "${PUTER_SCRIPT_DIR:-}" ]]; then
    readonly PUTER_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
LOG_DIR="${PUTER_SCRIPT_DIR}/../logs"

# Domyślne modele
DEFAULT_QWEN_MODEL="qwen/qwen3.6-plus"
DEFAULT_OPENAI_MODEL="gpt-5.4-nano"

# Kolory ANSI
[[ -z "${RED:-}" ]] && RED='\033[0;31m'
[[ -z "${GREEN:-}" ]] && GREEN='\033[0;32m'
[[ -z "${YELLOW:-}" ]] && YELLOW='\033[1;33m'
[[ -z "${BLUE:-}" ]] && BLUE='\033[0;34m'
[[ -z "${CYAN:-}" ]] && CYAN='\033[0;36m'
[[ -z "${MAGENTA:-}" ]] && MAGENTA='\033[0;35m'
[[ -z "${NC:-}" ]] && NC='\033[0m' # No Color

#-------------------------------------------------------------------------------
# Funkcje pomocnicze
#-------------------------------------------------------------------------------

log_puter_info() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[PUTER INFO]${NC} $timestamp - $*"
    [[ -d "$LOG_DIR" ]] && echo "[PUTER INFO] $timestamp - $*" >> "${LOG_DIR}/app.log"
}

log_puter_debug() {
    if [[ "${DEBUG_MODE:-false}" == "true" ]]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo -e "${CYAN}[PUTER DEBUG]${NC} $timestamp - $*" >&2
        [[ -d "$LOG_DIR" ]] && echo "[PUTER DEBUG] $timestamp - $*" >> "${LOG_DIR}/debug.log"
    fi
}

log_puter_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[PUTER ERROR]${NC} $timestamp - $*" >&2
    [[ -d "$LOG_DIR" ]] && echo "[PUTER ERROR] $timestamp - $*" >> "${LOG_DIR}/app.log"
}

#-------------------------------------------------------------------------------
# Funkcje generowania treści z Puter AI
#-------------------------------------------------------------------------------

# Generowanie tekstu za pomocą Qwen API
generate_qwen_text() {
    local prompt="$1"
    local model="${2:-$DEFAULT_QWEN_MODEL}"
    local temperature="${3:-0.7}"
    local max_tokens="${4:-2048}"
    
    log_puter_debug "Generating text with Qwen model: $model"
    
    # Sprawdzenie dostępności Node.js
    if ! command -v node &> /dev/null; then
        log_puter_error "Node.js is required but not installed"
        return 1
    fi
    
    # Bezpieczne przekazanie danych przez zmienne środowiskowe
    local result
    result=$(PROMPT_INPUT="$prompt" MODEL_INPUT="$model" TEMPERATURE_INPUT="$temperature" MAX_TOKENS_INPUT="$max_tokens" node -e '
const { puter } = require("@heyputer/puter.js");

const prompt = process.env.PROMPT_INPUT;
const model = process.env.MODEL_INPUT;
const temperature = parseFloat(process.env.TEMPERATURE_INPUT);
const max_tokens = parseInt(process.env.MAX_TOKENS_INPUT, 10);

puter.ai.chat(prompt, { 
    model: model,
    temperature: temperature,
    max_tokens: max_tokens
}).then(response => {
    console.log(response.message.content);
}).catch(error => {
    console.error("Error:", error.message);
    process.exit(1);
});
' 2>&1) || {
        log_puter_error "Failed to generate text: $result"
        return 1
    }
    
    echo "$result"
}

# Generowanie tekstu za pomocą OpenAI API
generate_openai_text() {
    local prompt="$1"
    local model="${2:-$DEFAULT_OPENAI_MODEL}"
    local temperature="${3:-0.7}"
    local max_tokens="${4:-2048}"
    
    log_puter_debug "Generating text with OpenAI model: $model"
    
    # Sprawdzenie dostępności Node.js
    if ! command -v node &> /dev/null; then
        log_puter_error "Node.js is required but not installed"
        return 1
    fi
    
    # Bezpieczne przekazanie danych przez zmienne środowiskowe
    local result
    result=$(PROMPT_INPUT="$prompt" MODEL_INPUT="$model" TEMPERATURE_INPUT="$temperature" MAX_TOKENS_INPUT="$max_tokens" node -e '
const { puter } = require("@heyputer/puter.js");

const prompt = process.env.PROMPT_INPUT;
const model = process.env.MODEL_INPUT;
const temperature = parseFloat(process.env.TEMPERATURE_INPUT);
const max_tokens = parseInt(process.env.MAX_TOKENS_INPUT, 10);

puter.ai.chat(prompt, { 
    model: model,
    temperature: temperature,
    max_tokens: max_tokens
}).then(response => {
    console.log(response.message.content);
}).catch(error => {
    console.error("Error:", error.message);
    process.exit(1);
});
' 2>&1) || {
        log_puter_error "Failed to generate text: $result"
        return 1
    }
    
    echo "$result"
}

# Generowanie kodu za pomocą Qwen Coder
generate_qwen_code() {
    local prompt="$1"
    local language="${2:-javascript}"
    local model="qwen/qwen3.6-max-preview"
    
    log_puter_debug "Generating $language code with Qwen Coder"
    
    local full_prompt="Generate $language code based on this request: $prompt. Provide only the code without explanations."
    
    generate_qwen_text "$full_prompt" "$model"
}

# Generowanie kodu za pomocą OpenAI Codex
generate_openai_code() {
    local prompt="$1"
    local language="${2:-javascript}"
    local model="openai/gpt-5.3-codex"
    
    log_puter_debug "Generating $language code with OpenAI Codex"
    
    local full_prompt="Generate $language code based on this request: $prompt. Provide only the code without explanations."
    
    generate_openai_text "$full_prompt" "$model"
}

# Generowanie obrazu za pomocą Qwen Image
generate_qwen_image() {
    local prompt="$1"
    local output_file="${2:-output.png}"
    local model="qwen/qwen-image-2.0"
    
    log_puter_debug "Generating image with Qwen Image: $model"
    
    if ! command -v node &> /dev/null; then
        log_puter_error "Node.js is required but not installed"
        return 1
    fi
    
    # Bezpieczne przekazanie danych przez zmienne środowiskowe
    PROMPT_INPUT="$prompt" OUTPUT_FILE_INPUT="$output_file" MODEL_INPUT="$model" node -e '
const { puter } = require("@heyputer/puter.js");
const fs = require("fs");

const prompt = process.env.PROMPT_INPUT;
const outputFile = process.env.OUTPUT_FILE_INPUT;
const model = process.env.MODEL_INPUT;

puter.ai.txt2img(prompt, { model: model }).then(response => {
    // Zapisz obraz do pliku
    const buffer = Buffer.from(response.base64, "base64");
    fs.writeFileSync(outputFile, buffer);
    console.log("Image saved to: " + outputFile);
}).catch(error => {
    console.error("Error:", error.message);
    process.exit(1);
});
' 2>&1
}

# Generowanie obrazu za pomocą GPT Image / DALL-E
generate_openai_image() {
    local prompt="$1"
    local output_file="${2:-output.png}"
    local model="${3:-gpt-image-2}"
    
    log_puter_debug "Generating image with OpenAI: $model"
    
    if ! command -v node &> /dev/null; then
        log_puter_error "Node.js is required but not installed"
        return 1
    fi
    
    # Bezpieczne przekazanie danych przez zmienne środowiskowe
    PROMPT_INPUT="$prompt" OUTPUT_FILE_INPUT="$output_file" MODEL_INPUT="$model" node -e '
const { puter } = require("@heyputer/puter.js");
const fs = require("fs");

const prompt = process.env.PROMPT_INPUT;
const outputFile = process.env.OUTPUT_FILE_INPUT;
const model = process.env.MODEL_INPUT;

puter.ai.txt2img(prompt, { model: model }).then(response => {
    const buffer = Buffer.from(response.base64, "base64");
    fs.writeFileSync(outputFile, buffer);
    console.log("Image saved to: " + outputFile);
}).catch(error => {
    console.error("Error:", error.message);
    process.exit(1);
});
' 2>&1
}

# Generowanie mowy (text-to-speech)
generate_speech() {
    local text="$1"
    local output_file="${2:-output.mp3}"
    local model="${3:-tts-1}"
    
    log_puter_debug "Generating speech with model: $model"
    
    if ! command -v node &> /dev/null; then
        log_puter_error "Node.js is required but not installed"
        return 1
    fi
    
    # Bezpieczne przekazanie danych przez zmienne środowiskowe
    TEXT_INPUT="$text" OUTPUT_FILE_INPUT="$output_file" MODEL_INPUT="$model" node -e '
const { puter } = require("@heyputer/puter.js");
const fs = require("fs");

const text = process.env.TEXT_INPUT;
const outputFile = process.env.OUTPUT_FILE_INPUT;
const model = process.env.MODEL_INPUT;

puter.ai.txt2speech(text, { model: model }).then(response => {
    const buffer = Buffer.from(response.base64, "base64");
    fs.writeFileSync(outputFile, buffer);
    console.log("Audio saved to: " + outputFile);
}).catch(error => {
    console.error("Error:", error.message);
    process.exit(1);
});
' 2>&1
}

#-------------------------------------------------------------------------------
# Menu Puter AI
#-------------------------------------------------------------------------------

show_puter_menu() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              PUTER AI INTEGRATION MENU                       ║"
    echo "║        Free Unlimited Qwen & OpenAI API via Puter.com       ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo -e "${NC}"
    echo -e "${GREEN}║  [1] 💬 Qwen Chat - Generate Text                        ║${NC}"
    echo -e "${GREEN}║  [2] 💻 Qwen Coder - Generate Code                       ║${NC}"
    echo -e "${GREEN}║  [3] 🎨 Qwen Image - Generate Images                     ║${NC}"
    echo -e "${GREEN}║  [4] 💬 OpenAI Chat - Generate Text                      ║${NC}"
    echo -e "${GREEN}║  [5] 💻 OpenAI Codex - Generate Code                     ║${NC}"
    echo -e "${GREEN}║  [6] 🎨 OpenAI Image - Generate Images                   ║${NC}"
    echo -e "${GREEN}║  [7] 🔊 Text-to-Speech                                   ║${NC}"
    echo -e "${GREEN}║  [8] ⚙️  Configure Models                                ║${NC}"
    echo -e "${YELLOW}║  [9] ⬅️  Back to Main Menu                               ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║  Supported Models:                                           ║${NC}"
    echo -e "${CYAN}║  Qwen: qwen3.6-plus, qwen3.6-flash, qwen3.6-max-preview     ║${NC}"
    echo -e "${CYAN}║  OpenAI: gpt-5.4-nano, gpt-5.5, gpt-5.3-codex, gpt-image-2  ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

menu_qwen_chat() {
    echo -e "${CYAN}Enter your prompt for Qwen:${NC}"
    read -r prompt
    
    echo -e "${CYAN}Generating response...${NC}"
    local response
    response=$(generate_qwen_text "$prompt")
    
    echo -e "${GREEN}Response:${NC}"
    echo "$response"
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r
}

menu_qwen_coder() {
    echo -e "${CYAN}Enter code description:${NC}"
    read -r prompt
    
    echo -e "${CYAN}Programming language (default: javascript):${NC}"
    read -r language
    language="${language:-javascript}"
    
    echo -e "${CYAN}Generating code...${NC}"
    local response
    response=$(generate_qwen_code "$prompt" "$language")
    
    echo -e "${GREEN}Generated Code:${NC}"
    echo "$response"
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r
}

menu_qwen_image() {
    echo -e "${CYAN}Enter image description:${NC}"
    read -r prompt
    
    echo -e "${CYAN}Output filename (default: qwen_output.png):${NC}"
    read -r output_file
    output_file="${output_file:-qwen_output.png}"
    
    echo -e "${CYAN}Generating image...${NC}"
    generate_qwen_image "$prompt" "$output_file"
    
    echo -e "${GREEN}Image saved to: $output_file${NC}"
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r
}

menu_openai_chat() {
    echo -e "${CYAN}Enter your prompt for OpenAI:${NC}"
    read -r prompt
    
    echo -e "${CYAN}Generating response...${NC}"
    local response
    response=$(generate_openai_text "$prompt")
    
    echo -e "${GREEN}Response:${NC}"
    echo "$response"
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r
}

menu_openai_coder() {
    echo -e "${CYAN}Enter code description:${NC}"
    read -r prompt
    
    echo -e "${CYAN}Programming language (default: javascript):${NC}"
    read -r language
    language="${language:-javascript}"
    
    echo -e "${CYAN}Generating code...${NC}"
    local response
    response=$(generate_openai_code "$prompt" "$language")
    
    echo -e "${GREEN}Generated Code:${NC}"
    echo "$response"
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r
}

menu_openai_image() {
    echo -e "${CYAN}Enter image description:${NC}"
    read -r prompt
    
    echo -e "${CYAN}Output filename (default: openai_output.png):${NC}"
    read -r output_file
    output_file="${output_file:-openai_output.png}"
    
    echo -e "${CYAN}Select model:${NC}"
    echo "1) gpt-image-2"
    echo "2) gpt-image-1.5"
    echo "3) dall-e-3"
    echo "4) dall-e-2"
    read -r model_choice
    
    case "$model_choice" in
        1) model="gpt-image-2" ;;
        2) model="gpt-image-1.5" ;;
        3) model="dall-e-3" ;;
        4) model="dall-e-2" ;;
        *) model="gpt-image-2" ;;
    esac
    
    echo -e "${CYAN}Generating image...${NC}"
    generate_openai_image "$prompt" "$output_file" "$model"
    
    echo -e "${GREEN}Image saved to: $output_file${NC}"
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r
}

menu_text_to_speech() {
    echo -e "${CYAN}Enter text to convert to speech:${NC}"
    read -r text
    
    echo -e "${CYAN}Output filename (default: speech.mp3):${NC}"
    read -r output_file
    output_file="${output_file:-speech.mp3}"
    
    echo -e "${CYAN}Select model:${NC}"
    echo "1) tts-1"
    echo "2) tts-1-hd"
    read -r model_choice
    
    case "$model_choice" in
        1) model="tts-1" ;;
        2) model="tts-1-hd" ;;
        *) model="tts-1" ;;
    esac
    
    echo -e "${CYAN}Generating speech...${NC}"
    generate_speech "$text" "$output_file" "$model"
    
    echo -e "${GREEN}Audio saved to: $output_file${NC}"
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r
}

menu_configure_models() {
    echo -e "${CYAN}Configure default models:${NC}"
    echo ""
    echo "Current Qwen model: $DEFAULT_QWEN_MODEL"
    echo "Current OpenAI model: $DEFAULT_OPENAI_MODEL"
    echo ""
    echo -e "${YELLOW}Available Qwen models:${NC}"
    echo "  - qwen/qwen3.7-max"
    echo "  - qwen/qwen3.6-max-preview"
    echo "  - qwen/qwen3.6-plus"
    echo "  - qwen/qwen3.6-flash"
    echo "  - qwen/qwen-image-2.0"
    echo ""
    echo -e "${YELLOW}Available OpenAI models:${NC}"
    echo "  - gpt-5.5-pro, gpt-5.5, gpt-5.4-nano"
    echo "  - gpt-5.3-chat, gpt-5.3-codex"
    echo "  - gpt-image-2, gpt-image-1.5"
    echo "  - dall-e-3, dall-e-2"
    echo "  - o1, o1-mini, o3-mini, o4-mini"
    echo "  - tts-1, tts-1-hd"
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r
}

#-------------------------------------------------------------------------------
# Główna funkcja menu
#-------------------------------------------------------------------------------

puter_menu() {
    while true; do
        show_puter_menu
        echo -n "Enter choice [1-9]: "
        read -r choice
        
        case "$choice" in
            1) menu_qwen_chat ;;
            2) menu_qwen_coder ;;
            3) menu_qwen_image ;;
            4) menu_openai_chat ;;
            5) menu_openai_coder ;;
            6) menu_openai_image ;;
            7) menu_text_to_speech ;;
            8) menu_configure_models ;;
            9|q|Q) break ;;
            *) echo -e "${RED}Invalid option${NC}" ;;
        esac
    done
}

# Eksport funkcji dla innych skryptów
export -f generate_qwen_text
export -f generate_openai_text
export -f generate_qwen_code
export -f generate_openai_code
export -f generate_qwen_image
export -f generate_openai_image
export -f generate_speech
export -f puter_menu

# Jeśli skrypt jest uruchomiony bezpośrednio
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    puter_menu
fi
