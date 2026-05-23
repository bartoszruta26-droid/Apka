# Qwen Time & Automation Manager

Aplikacja bash shell script do zarządzania czasem i automatyzacji procesów z wykorzystaniem lokalnych modeli AI Qwen Agent i Qwen Coder.

## Opis projektu

Aplikacja działa jako TUI (Text User Interface) w terminalu i służy do:
- Zarządzania zadaniami i czasem
- Automatyzacji procesów programistycznych
- Integracji z GitHub API
- Wykorzystania lokalnych modeli AI do generowania kodu i dokumentacji

## Wymagania sprzętowe

- Raspberry Pi 4 (zalecane minimum 4GB RAM)
- System: Raspberry Pi OS / Debian / Ubuntu
- Dostęp do internetu (do operacji GitHub)
- Lokalnie uruchomione modele Qwen (przez Ollama, LM Studio lub podobne)

## Główne funkcjonalności

### 0. Zarządzanie konfiguracją i autoryzacją GitHub
- Bezpieczne zapisywanie tokena GitHub w pliku konfiguracyjnym (`~/.qwen_tam_config`)
- Ładowanie danych logowania przy wymaganych operacjach
- Obsługa wielu profili użytkownika

### 1. Tworzenie repozytoriów GitHub
- Tworzenie nowych repozytoriów poprzez GitHub API
- Wsparcie dla repozytoriów publicznych i prywatnych
- Automatyczna inicjalizacja `.git` i pierwsze commity

### 2. Generowanie treści z Qwen Coder
- Pisanie plików Markdown (.md) - dokumentacja, README, specyfikacje
- Generowanie kodu źródłowego w różnych językach
- Wykonywanie poleceń systemowych na żądanie AI
- Kontekstowa pamięć rozmowy z modelem

### 3. Weryfikacja kodu
- Statyczna analiza wygenerowanego kodu
- Uruchamianie testów jednostkowych
- Walidacja składni
- Raportowanie błędów i sugestii poprawy

### 4. Automatyzacja z Qwen Agent
- Dyskusja AI z użytkownikiem w celu zrozumienia wymagań
- Planowanie i wykonywanie wieloetapowych zadań
- Obsługa zdarzeń (event handling)
- Praca w tle z trybem verbose
- Szczegółowe logowanie (debug mode)

---

## Struktura Aplikacji

Aplikacja składa się z następujących skryptów:

```
qwen-tam/
├── qwen-tam.sh           # Główny skrypt inicjujący i menu TUI
├── config/
│   ├── config.sh         # Konfiguracja i zmienne globalne
│   └── github.conf       # Dane logowania GitHub (szyfrowane)
├── scripts/
│   ├── auth.sh           # Autoryzacja i zarządzanie tokenem GitHub
│   ├── repo.sh           # Tworzenie i zarządzanie repozytoriami
│   ├── coder.sh          # Integracja z Qwen Coder
│   ├── agent.sh          # Integracja z Qwen Agent
│   ├── verify.sh         # Weryfikacja kodu
│   ├── automation.sh     # Automatyzacja procesów
│   ├── background.sh     # Obsługa trybu daemon/background
│   └── utils.sh          # Funkcje pomocnicze (logowanie, error handling)
├── logs/
│   ├── app.log           # Logi aplikacji
│   ├── debug.log         # Logi debugowe
│   └── events.log        # Logi zdarzeń
└── README.md
```

### Skrypt Główny: `qwen-tam.sh`

Główny punkt wejścia aplikacji, odpowiedzialny za:
- Inicjalizację środowiska i ładowanie konfiguracji
- Wyświetlanie głównego menu TUI
- Obsługę wyboru opcji menu i wywoływanie odpowiednich podskryptów
- Obsługę sygnałów systemowych (SIGINT, SIGTERM)
- Zarządzanie trybami pracy (interaktywny, daemon, debug)

---

## Interfejs Użytkownika (TUI)

### Główne Menu

```
╔══════════════════════════════════════════════════════════════╗
║           QWEN TIME & AUTOMATION MANAGER v1.0                ║
║                    Raspberry Pi 4 Edition                    ║
╠══════════════════════════════════════════════════════════════╣
║  MAIN MENU                                                   ║
╠══════════════════════════════════════════════════════════════╣
║  [1] 📁 GitHub Repository Management                         ║
║  [2] 🤖 Qwen Coder - Code Generation                         ║
║  [3] ✅ Code Verification                                    ║
║  [4] 🔄 Automation & AI Agent                                ║
║  [5] ⚙️  Configuration & Settings                            ║
║  [6] 📊 Logs & Monitoring                                    ║
║  [7] ℹ️  System Information                                  ║
║  [8] 🔄 Update Application                                   ║
║  [9] 🚪 Exit                                                 ║
╠══════════════════════════════════════════════════════════════╣
║  Status: ● Connected  |  Mode: Interactive  |  Debug: OFF   ║
║  Press 'D' for Debug mode | 'V' for Verbose | 'Q' to quit   ║
╚══════════════════════════════════════════════════════════════╝
```

### Podmenu 1: GitHub Repository Management

```
╔══════════════════════════════════════════════════════════════╗
║              GITHUB REPOSITORY MANAGEMENT                    ║
╠══════════════════════════════════════════════════════════════╣
║  [1.1] 🔐 Configure GitHub Credentials                       ║
║  [1.2] ➕ Create New Repository                              ║
║  [1.3] 📋 List My Repositories                               ║
║  [1.4] 🗑️  Delete Repository                                 ║
║  [1.5] 📥 Clone Repository                                   ║
║  [1.6] 🔄 Sync Local with Remote                             ║
║  [1.7] ⬅️  Back to Main Menu                                 ║
╚══════════════════════════════════════════════════════════════╝
```

### Podmenu 2: Qwen Coder - Code Generation

```
╔══════════════════════════════════════════════════════════════╗
║                QWEN CODER - CODE GENERATION                  ║
╠══════════════════════════════════════════════════════════════╣
║  [2.1] 📝 Generate Markdown Documentation                    ║
║  [2.2] 💻 Generate Source Code                               ║
║  [2.3] 📜 Generate Shell Scripts                             ║
║  [2.4] 🐍 Generate Python Scripts                            ║
║  [2.5] 🌐 Generate Web Files (HTML/CSS/JS)                   ║
║  [2.6] 📁 Create Project Structure                           ║
║  [2.7] ✏️  Edit Existing File with AI                        ║
║  [2.8] 📤 Execute Custom Command                             ║
║  [2.9] ⬅️  Back to Main Menu                                 ║
╚══════════════════════════════════════════════════════════════╝
```

### Podmenu 3: Code Verification

```
╔══════════════════════════════════════════════════════════════╗
║                   CODE VERIFICATION                          ║
╠══════════════════════════════════════════════════════════════╣
║  [3.1] 🔍 Syntax Check (Shell)                               ║
║  [3.2] 🔍 Syntax Check (Python)                              ║
║  [3.3] 🛡️  Security Scan                                     ║
║  [3.4] 📏 Code Style Check                                   ║
║  [3.5] 🧪 Run Unit Tests                                     ║
║  [3.6] 📊 Generate Verification Report                       ║
║  [3.7] ⬅️  Back to Main Menu                                 ║
╚══════════════════════════════════════════════════════════════╝
```

### Podmenu 4: Automation & AI Agent

```
╔══════════════════════════════════════════════════════════════╗
║               AUTOMATION & AI AGENT                          ║
╠══════════════════════════════════════════════════════════════╣
║  [4.1] 💬 Start AI Discussion Session                        ║
║  [4.2] 📋 Create Automation Workflow                         ║
║  [4.3] ▶️  Run Automation Task                               ║
║  [4.4] ⏸️  Pause/Resume Background Tasks                     ║
║  [4.5] 🛑 Stop Running Tasks                                 ║
║  [4.6] 📅 Schedule Automated Task                            ║
║  [4.7] 📜 View Task History                                  ║
║  [4.8] ⚡ Quick Automations                                  ║
║      ├─ [4.8.1] Auto-commit & Push                           ║
║      ├─ [4.8.2] Daily Backup                                 ║
║      ├─ [4.8.3] Code Review Loop                             ║
║      └─ [4.8.4] Custom Script Runner                         ║
║  [4.9] ⬅️  Back to Main Menu                                 ║
╚══════════════════════════════════════════════════════════════╝
```

### Podmenu 5: Configuration & Settings

```
╔══════════════════════════════════════════════════════════════╗
║               CONFIGURATION & SETTINGS                       ║
╠══════════════════════════════════════════════════════════════╣
║  [5.1] 🔑 Manage GitHub Token                                ║
║  [5.2] 🌐 Configure Qwen API Endpoint                        ║
║  [5.3] 📂 Set Working Directory                              ║
║  [5.4] 🎨 Theme & Display Options                            ║
║  [5.5] 🔔 Notification Settings                              ║
║  [5.6] 🗄️  Backup Configuration                              ║
║  [5.7] ♻️  Restore Configuration                             ║
║  [5.8] 🔄 Reset to Defaults                                  ║
║  [5.9] ⬅️  Back to Main Menu                                 ║
╚══════════════════════════════════════════════════════════════╝
```

### Podmenu 6: Logs & Monitoring

```
╔══════════════════════════════════════════════════════════════╗
║                  LOGS & MONITORING                           ║
╠══════════════════════════════════════════════════════════════╣
║  [6.1] 📄 View Application Log (app.log)                     ║
║  [6.2] 🐛 View Debug Log (debug.log)                         ║
║  [6.3] 📊 View Events Log (events.log)                       ║
║  [6.4] 🔍 Search Logs                                        ║
║  [6.5] 🧹 Clear Old Logs                                     ║
║  [6.6] 📥 Export Logs                                        ║
║  [6.7] 📈 Real-time Log Monitor                              ║
║  [6.8] ⬅️  Back to Main Menu                                 ║
╚══════════════════════════════════════════════════════════════╝
```

### Podmenu 7: System Information

```
╔══════════════════════════════════════════════════════════════╗
║                 SYSTEM INFORMATION                           ║
╠══════════════════════════════════════════════════════════════╣
║  [7.1] 💻 System Resources (CPU/RAM/Disk)                    ║
║  [7.2] 🌡️  Temperature & Health Status                       ║
║  [7.3] 📦 Installed Dependencies                             ║
║  [7.4] 🤖 Qwen Model Status                                  ║
║  [7.5] 🔗 Network Connectivity                               ║
║  [7.6] 📜 Version & Changelog                                ║
║  [7.7] ⬅️  Back to Main Menu                                 ║
╚══════════════════════════════════════════════════════════════╝
```

### Podmenu 8: Update Application

```
╔══════════════════════════════════════════════════════════════╗
║                  UPDATE APPLICATION                          ║
╠══════════════════════════════════════════════════════════════╣
║  [8.1] 🔄 Check for Updates                                  ║
║  [8.2] ⬇️  Download Latest Version                           ║
║  [8.3] 📦 Auto-Install Dependencies                          ║
║  [8.4] 🚀 Install Update (Rolling/Blue-Green)                ║
║  [8.5] 📋 View Changelog                                     ║
║  [8.6] ↩️  Rollback to Previous Version                      ║
║  [8.7] ⚙️  Configure Auto-Update Settings                    ║
║  [8.8] 📊 Update Cluster Nodes (Swarm)                       ║
║  [8.9] ⬅️  Back to Main Menu                                 ║
╚══════════════════════════════════════════════════════════════╝
```

**Opis funkcjonalności Podmenu 8 - Update Application:**

#### [8.1] Check for Updates
- Sprawdza dostępność nowej wersji w repozytorium GitHub
- Porównuje wersję lokalną z remotową (plik VERSION lub tag git)
- Wyświetla informacje o dostępnych aktualizacjach
- Pokazuje rozmiar aktualizacji i listę zmian

#### [8.2] Download Latest Version
- Pobiera najnowszą wersję aplikacji z GitHub
- Weryfikacja sumy kontrolnej (SHA256 checksum)
- Pobieranie z progresem i możliwością pauzy
- Zapis do tymczasowego katalogu staging

#### [8.3] Auto-Install Dependencies
- Automatyczna detekcja brakujących zależności
- Instalacja pakietów systemowych (apt, pip, npm)
- Konfiguracja środowiska uruchomieniowego
- Walidacja poprawności instalacji
- Obsługa zależności dla:
  - `git`, `curl`, `jq` (narzędzia systemowe)
  - `python3`, `pip3` (skrypty Python)
  - `nodejs`, `npm` (komponenty web)
  - `ollama` (lokalne modele AI)
  - `docker`, `docker-compose` ( Swarm cluster)

#### [8.4] Install Update
- **Rolling Update**: Aktualizacja po kolei z restartem usług
- **Blue-Green Deployment**: Równoległe wersje z przełączeniem ruchu
- Backup obecnej wersji przed instalacją
- Migracja konfiguracji i danych
- Restart usług w tle bez przerywania działania

#### [8.5] View Changelog
- Wyświetla historię zmian między wersjami
- Formatowanie Markdown z podziałem na kategorie:
  - ✨ New Features
  - 🐛 Bug Fixes
  - 🔒 Security Updates
  - ⚡ Performance Improvements
  - 📝 Documentation

#### [8.6] Rollback to Previous Version
- Przywracanie poprzedniej stabilnej wersji
- Automatyczny rollback w przypadku błędu aktualizacji
- Zachowanie danych i konfiguracji
- Logowanie przyczyn rollbacku

#### [8.7] Configure Auto-Update Settings
- Harmonogram automatycznych aktualizacji (cron)
- Powiadomienia o dostępnych aktualizacjach
- Wybór kanału aktualizacji (stable/beta/dev)
- Konfiguracja okna mantenimiento (maintenance window)

#### [8.8] Update Cluster Nodes (Swarm)
- Aktualizacja wszystkich węzłów klastra 4x RPi4
- Strategia rolling update z health checks
- Load balancing podczas aktualizacji
- Synchronizacja wersji między node'ami
- Raport statusu każdego węzła

---

## Tryby Pracy Aplikacji

### 1. Tryb Interaktywny (TUI)
- Domyślny tryb pracy
- Pełne menu tekstowe z nawigacją klawiszową
- Interakcja z użytkownikiem w czasie rzeczywistym
- Kolorowy interfejs z elementami graficznymi (ASCII art, boxy)

### 2. Tryb Daemon (Background)
```bash
./qwen-tam.sh --daemon [--verbose] [--config=/path/to/config]
```
- Uruchomienie w tle jako usługa
- Obsługa zadań zaplanowanych (cron-like)
- Logowanie wszystkich zdarzeń do plików
- Możliwość zdalnego zarządzania przez named pipe/socket

### 3. Tryb Debug
```bash
./qwen-tam.sh --debug [--verbose]
```
- Szczegółowe logowanie każdej operacji
- Wyświetlanie zmiennych środowiskowych
- Trace wykonania funkcji
- Zatrzymywanie przy błędach krytycznych

### 4. Tryb Verbose
```bash
./qwen-tam.sh --verbose
```
- Rozszerzone komunikaty o statusie
- Pokazywanie postępu operacji długotrwałych
- Dodatkowe informacje diagnostyczne

### 5. Tryb CLI (Command Line Interface)
```bash
# Bezpośrednie wywołanie funkcji bez TUI
./qwen-tam.sh --create-repo "my-project"
./qwen-tam.sh --generate-code "python" "script.py" "Write a hello world"
./qwen-tam.sh --verify "script.sh"
./qwen-tam.sh --automate "daily-backup"
```

---

## Funkcjonalności Szczegółowe

### 0. Zarządzanie Danymi Logowania GitHub

**Funkcje:**
- Bezpieczne zapisywanie tokena OAuth/personal access token
- Szyfrowanie danych przy użyciu `gpg` lub `openssl`
- Walidacja tokena przed zapisem (sprawdzenie uprawnień)
- Automatyczne ładowanie przy starcie aplikacji
- Możliwość przechowywania wielu profili (osobisty, firmowy)
- Rotacja tokena z powiadomieniem

**Bezpieczeństwo:**
- Plik `github.conf` z uprawnieniami `600` (tylko właściciel)
- Token nigdy nie jest wyświetlany w logach
- Automatyczne czyszczenie zmiennych środowiskowych po użyciu

---

### 1. Tworzenie Nowego Repozytorium GitHub

**Proces:**
1. Pobranie nazwy repozytorium od użytkownika
2. Opcjonalnie: opis, widoczność (public/private), inicjalizacja README
3. Walidacja nazwy (znaki dozwolone, długość)
4. Wysyłanie żądania API do GitHub
5. Obsługa odpowiedzi (sukces/błąd)
6. Opcjonalne: klonowanie lokalnie, inicjalizacja git
7. Logowanie zdarzenia

**Opcje dodatkowe:**
- Dodanie license (MIT, GPL, Apache)
- Dodanie `.gitignore` dla wybranego języka
- Dodanie domyślnej struktury katalogów
- Tagi/topics dla repozytorium

---

### 2. Generowanie Treści z Qwen Coder

**Typy generowanych treści:**
- **Markdown (.md):** dokumentacja, README, specyfikacje, raporty
- **Kod źródłowy:** Bash, Python, JavaScript, C/C++, itp.
- **Pliki konfiguracyjne:** YAML, JSON, TOML, INI
- **Skrypty automatyzujące:** sekwencje komend, workflow

**Proces generowania:**
1. Wybór typu pliku i języka
2. Wprowadzenie promptu/opisu wymagań
3. Opcjonalnie: kontekst (istniejące pliki, zależności)
4. Wysyłanie żądania do lokalnego endpointu Qwen Coder
5. Odbiór i parsowanie odpowiedzi
6. Zapis do pliku z potwierdzeniem
7. Opcjonalna weryfikacja poprawności

**Funkcje zaawansowane:**
- Iteracyjne dopracowywanie kodu (feedback loop)
- Generowanie na podstawie szablonów
- Batch generation (wiele plików naraz)
- Wersjonowanie wygenerowanego kodu

---

### 3. Weryfikacja Kodu

**Rodzaje weryfikacji:**

#### a) Sprawdzenie Składni
- **Shell:** `bash -n script.sh`, `shellcheck`
- **Python:** `python3 -m py_compile`, `flake8`, `pylint`
- **JavaScript:** `eslint`, `node --check`

#### b) Analiza Bezpieczeństwa
- Wykrywanie hard-coded credentials
- Sprawdzenie podatności (injection, path traversal)
- Analiza uprawnień plików
- Detekcja niebezpiecznych komend (`rm -rf`, `eval`, etc.)

#### c) Styl Kodu
- Przestrzeganie konwencji (PEP8, ShellCheck rules)
- Spójność formatowania
- Jakość komentarzy i dokumentacji

#### d) Testy
- Uruchamianie testów jednostkowych
- Coverage report
- Walidacja przypadków brzegowych

**Raport z weryfikacji:**
- Podsumowanie znalezionych problemów
- Sugestie poprawek
- Ocena jakości (score 0-100)
- Eksport do formatu Markdown/JSON

---

### 4. Automatyzacja z Qwen Agent

**Model interakcji:**
1. **Dyskusja AI-Użytkownik:**
   - Użytkownik opisuje cel automatyzacji
   - Agent zadaje pytania doprecyzowujące
   - Wspólne opracowanie workflow
   - Akceptacja planu działania

2. **Generowanie Workflow:**
   - Agent tworzy sekwencję kroków
   - Definicja warunków i wyjątków
   - Mapowanie na dostępne funkcje aplikacji

3. **Wykonanie Automatyzacji:**
   - Sekwencyjne lub równoległe wykonywanie kroków
   - Monitorowanie postępu
   - Obsługa błędów i retry logic
   - Powiadomienia o statusie

**Przykładowe scenariusze automatyzacji:**

#### a) Auto-commit & Push
```
1. Sprawdź zmiany w repozytorium (git status)
2. Jeśli są zmiany:
   - Stwórz commit z AI-generated message
   - Push do remote
   - Loguj sukces
3. Jeśli błędy:
   - Powiadom użytkownika
   - Zaproponuj rozwiązanie
```

#### b) Daily Backup
```
1. Harmonogram: codziennie o 02:00
2. Kroki:
   - Archive working directory
   - Compress with timestamp
   - Upload to GitHub Releases or external storage
   - Verify backup integrity
   - Send confirmation
```

#### c) Code Review Loop
```
1. Monitoruj nowe commity w branchu
2. Dla każdej zmiany:
   - Pobierz diff
   - Wyślij do Qwen Coder do analizy
   - Generuj raport z uwagami
   - Dodaj komentarz do PR (jeśli istnieje)
```

#### d) Custom Script Runner
```
1. Użytkownik definiuje listę komend
2. Agent optymalizuje kolejność
3. Wykonanie z walidacją każdego kroku
4. Rollback w przypadku błędu krytycznego
```

**Event Handling w Automatyzacji:**
- Rejestracja handlerów dla zdarzeń (start, complete, error, timeout)
- Możliwość podpięcia customowych akcji
- Logging wszystkich eventów do `events.log`
- Powiadomienia (terminal, email, webhook)

---

## Error Handling & Gentle Code

### Strategia Obsługi Błędów

**Poziomy błędów:**
1. **INFO:** Operacje rutynowe, expected behavior
2. **WARNING:** Problemy niekrytyczne, aplikacja działa dalej
3. **ERROR:** Błędy krytyczne dla danej operacji, rollback jeśli możliwe
4. **CRITICAL:** Błąd aplikacji, natychmiastowe zatrzymanie

**Zasady:**
- Każdy blok `try` (w bashu: `if ! command; then`) ma odpowiadający `catch`
- Komunikaty błędów są zrozumiałe dla użytkownika
- Logowanie stack trace w trybie debug
- Możliwość recovery bez utraty danych
- Gentle code: unikanie `set -e` na rzecz kontrolowanej obsługi

**Przykład implementacji:**
```bash
handle_error() {
    local exit_code=$?
    local function_name=$1
    local line_number=$2
    
    log_event "ERROR" "Function $function_name failed at line $line_number (exit code: $exit_code)"
    
    case $exit_code in
        1) echo "❌ Invalid argument provided" ;;
        2) echo "❌ Configuration file missing or invalid" ;;
        3) echo "❌ Network connection failed" ;;
        4) echo "❌ GitHub API error" ;;
        *) echo "❌ Unexpected error occurred" ;;
    esac
    
    if [[ "$DEBUG_MODE" == "true" ]]; then
        log_debug "Stack trace: $(get_stack_trace)"
    fi
    
    return $exit_code
}

trap 'handle_error "${FUNCNAME[1]}" "${LINENO}"' ERR
```

---

## Logowanie i Monitoring

### Rodzaje Logów

**1. `app.log` - Logi Aplikacji**
```
[2025-01-15 10:23:45] [INFO] Application started
[2025-01-15 10:23:46] [INFO] Configuration loaded successfully
[2025-01-15 10:23:47] [SUCCESS] GitHub token validated
[2025-01-15 10:24:01] [ACTION] Created repository 'my-project'
[2025-01-15 10:24:15] [WARNING] Rate limit approaching (45 requests remaining)
```

**2. `debug.log` - Logi Debugowe**
```
[2025-01-15 10:23:45.123] [DEBUG] Loading config from /home/pi/.config/qwen-tam/config.sh
[2025-01-15 10:23:45.145] [DEBUG] Variable GITHUB_TOKEN set (length: 40)
[2025-01-15 10:23:46.891] [DEBUG] API Request: POST https://api.github.com/user/repos
[2025-01-15 10:23:47.234] [DEBUG] API Response: {"id":12345,"name":"my-project",...}
```

**3. `events.log` - Logi Zdarzeń**
```
[2025-01-15 10:24:01] [EVENT] REPO_CREATED user=pi repo=my-project visibility=private
[2025-01-15 10:25:30] [EVENT] CODE_GENERATED type=python file=script.py tokens=245
[2025-01-15 10:26:45] [EVENT] AUTOMATION_STARTED workflow=daily-backup id=run_1737012405
[2025-01-15 10:27:00] [EVENT] AUTOMATION_COMPLETED workflow=daily-backup status=success duration=15s
```

### Rotacja Logów
- Automatyczna rotacja przy przekroczeniu 10MB
- Przechowywanie ostatnich 5 archiwów
- Kompresja starych logów (gzip)

---

## Wymagania Systemowe

### Minimalne:
- Raspberry Pi 4 (2GB RAM)
- Raspberry Pi OS (Bullseye lub nowszy)
- Bash 5.0+
- Git
- curl lub wget
- jq (do parsowania JSON)

### Zalecane:
- Raspberry Pi 4 (4GB lub 8GB RAM)
- Dodatkowe narzędzia:
  - `shellcheck` (walidacja bash)
  - `gpg` lub `openssl` (szyfrowanie)
  - `dialog` lub `whiptail` (ulepszone TUI)
  - `tmux` lub `screen` (dla trybu daemon)
  - `systemd` (zarządzanie usługą)

### Qwen Local Setup:
- Ollama lub llama.cpp z modelem Qwen
- Endpoint API dostępny na `localhost:11434` (domyślnie)
- Modele: `qwen-coder`, `qwen-agent` (lub odpowiedniki)

---

## Instalacja i Konfiguracja

### 1. Klonowanie i Przygotowanie
```bash
cd /home/pi
git clone <repo-url> qwen-tam
cd qwen-tam
chmod +x qwen-tam.sh
chmod +x scripts/*.sh
```

### 2. Instalacja Zależności
```bash
sudo apt update
sudo apt install -y git curl jq shellcheck openssl dialog
```

### 3. Konfiguracja Qwen Local
```bash
# Przykład z Ollama
ollama pull qwen-coder
ollama pull qwen-agent
ollama serve  # Domyślnie localhost:11434
```

### 4. Pierwsze Uruchomienie
```bash
./qwen-tam.sh
# Następnie wybierz opcję [5.1] aby skonfigurować GitHub token
```

### 5. (Opcjonalnie) Instalacja jako Usługa Systemd
```bash
sudo cp qwen-tam.service /etc/systemd/system/
sudo systemctl enable qwen-tam
sudo systemctl start qwen-tam
```

---

## Przykłady Użycia

### Przykład 1: Tworzenie Repozytorium i Generowanie Kodu
```bash
# Przez TUI:
# 1. Wybierz [1.2] Create New Repository
# 2. Wpisz nazwę: "automation-scripts"
# 3. Wybierz widoczność: private
# 4. Zatwierdź

# 5. Wróć do main menu, wybierz [2.3] Generate Shell Scripts
# 6. Prompt: "Create a backup script that archives /home/pi/data and uploads to GitHub"
# 7. Zatwierdź generowanie
# 8. Wybierz [3.1] Syntax Check aby zweryfikować
# 9. Wybierz [4.2] Create Automation Workflow aby zaplanować codzienne uruchomienie
```

### Przykład 2: Tryb CLI z Automatyzacją
```bash
# Jednorazowe utworzenie repo i wygenerowanie kodu
./qwen-tam.sh --create-repo "my-app" --private
./qwen-tam.sh --generate-code "bash" "backup.sh" "Backup script for /home/pi/projects"
./qwen-tam.sh --verify "backup.sh"
./qwen-tam.sh --automate "run-script" --script="backup.sh" --schedule="daily 02:00"
```

### Przykład 3: Tryb Daemon z Verbose
```bash
# Uruchomienie w tle z rozszerzonym logowaniem
./qwen-tam.sh --daemon --verbose --config=/home/pi/.config/qwen-tam/config.sh

# Monitorowanie logów w czasie rzeczywistym
tail -f logs/app.log
```

---

## Rozwiązywanie Problemów

### Częste Błędy

**Problem:** Token GitHub nieważny
```
Rozwiązanie: 
1. Wygeneruj nowy token na github.com/settings/tokens
2. Upewnij się, że ma uprawnienia: repo, workflow
3. Uruchom [5.1] i wprowadź nowy token
```

**Problem:** Qwen API nie odpowiada
```
Rozwiązanie:
1. Sprawdź czy usługa Qwen działa: curl http://localhost:11434/api/tags
2. Restartuj usługę: ollama serve
3. Sprawdź zasoby RAM (Qwen wymaga min. 2GB free)
```

**Problem:** Skrypt nie uruchamia się w tle
```
Rozwiązanie:
1. Sprawdź uprawnienia: chmod +x qwen-tam.sh
2. Uruchom z pełną ścieżką: /home/pi/qwen-tam/qwen-tam.sh --daemon
3. Sprawdź logi: tail -f logs/app.log
```

---

## Roadmapa Rozwoju

### Wersja 1.0 (Current)
- ✅ Podstawowe TUI
- ✅ Integracja z GitHub API
- ✅ Generowanie kodu z Qwen Coder
- ✅ Prosta automatyzacja

### Wersja 1.1 (Planned)
- [ ] Web interface (opcjonalny)
- [ ] Integracja z innymi VCS (GitLab, Bitbucket)
- [ ] Szablony projektów
- [ ] Plugin system

### Wersja 2.0 (Future)
- [ ] Multi-user support
- [ ] Distributed task execution
- [ ] Advanced AI workflows (multi-agent)
- [ ] Mobile notification app

---

## Technology Readiness Level (TRL)

Aplikacja przechodzi przez następujące poziomy gotowości technologicznej:

| TRL | Poziom | Opis | Status |
|-----|--------|------|--------|
| TRL 1 | Basic Principles Observed | Zdefiniowano koncepcję aplikacji TUI do automatyzacji z AI | ✅ Ukończone |
| TRL 2 | Technology Concept Formulated | Opracowano architekturę i wymagania funkcjonalne | ✅ Ukończone |
| TRL 3 | Experimental Proof of Concept | Prototypowe skrypty bash z podstawową funkcjonalnością | 🔄 W toku |
| TRL 4 | Component Validation in Lab Environment | Testy pojedynczych modułów na Raspberry Pi 4 | ⏳ Planowane |
| TRL 5 | System Validation in Relevant Environment | Integracja wszystkich komponentów, testy na jednym RPi4 | ⏳ Planowane |
| TRL 6 | System Demo in Relevant Environment | Działanie na 4x RPi4 Swarm Cluster | ⏳ Planowane |
| TRL 7 | System Prototype in Operational Environment | Testy obciążeniowe i długoterminowe | ⏳ Planowane |
| TRL 8 | Actual System Completed and Qualified | Produkcyjna wersja aplikacji z pełną dokumentacją | ⏳ Planowane |
| TRL 9 | Actual System Proven in Operational Environment | Certyfikacja i wdrożenie u końcowych użytkowników | ⏳ Planowane |

---

## Etapy Produkcji Aplikacji (Backend → Frontend)

### Backend (Warstwa Serwisowa)

**Etap B1: Core Infrastructure**
- [ ] Implementacja głównego skryptu `qwen-tam.sh`
- [ ] Moduł konfiguracji i zarządzania zmiennymi środowiskowymi
- [ ] System logowania (app.log, debug.log, events.log)
- [ ] Error handling i graceful shutdown

**Etap B2: GitHub Integration**
- [ ] Autoryzacja OAuth/Personal Access Token
- [ ] CRUD operacje na repozytoriach (Create, Read, Update, Delete)
- [ ] Zarządzanie webhookami
- [ ] Rate limiting i retry logic

**Etap B3: AI Integration Layer**
- [ ] Adapter dla Qwen Coder (API calls, prompt engineering)
- [ ] Adapter dla Qwen Agent (session management, context)
- [ ] Cache odpowiedzi AI
- [ ] Fallback mechanisms przy niedostępności modelu

**Etap B4: Automation Engine**
- [ ] Silnik workflow (sekwencje, warunki, pętle)
- [ ] Scheduler zadań (cron-like)
- [ ] Queue management dla zadań asynchronicznych
- [ ] Event bus dla komunikacji między-modułowej

**Etap B5: Verification & Testing**
- [ ] Static code analysis integration
- [ ] Unit test framework dla bash scripts
- [ ] Security scanning (credentials, injection)
- [ ] Performance benchmarking

### Frontend (Warstwa Prezentacji - TUI)

**Etap F1: Base TUI Framework**
- [ ] Renderowanie boxów i ramek ASCII/Unicode
- [ ] Nawigacja klawiszowa (arrow keys, Enter, Esc)
- [ ] Kolorowanie składni (ANSI escape codes)
- [ ] Dynamiczne odświeżanie ekranu

**Etap F2: Main Menu System**
- [ ] Główne menu z 8+ opcjami
- [ ] Podmenu z nawigacją hierarchiczną
- [ ] Status bar z informacjami o systemie
- [ ] Quick actions (skróty klawiszowe)

**Etap F3: Interactive Forms**
- [ ] Pola tekstowe z walidacją inputu
- [ ] Select lists z scrollowaniem
- [ ] Checkboxes i radio buttons
- [ ] Progress bars dla długich operacji

**Etap F4: Real-time Monitoring**
- [ ] Live tail logów z filtrowaniem
- [ ] Dashboard z metrykami systemu (CPU, RAM, temp)
- [ ] Visualizacja postępu automatyzacji
- [ ] Alert notifications

**Etap F5: Help & Documentation**
- [ ] Context-sensitive help (F1)
- [ ] Searchable command reference
- [ ] Tutorial mode dla nowych użytkowników
- [ ] Changelog viewer

---

## Key Phases of the SDLC (Software Development Life Cycle)

| Phase | Description | Current Status | Deliverables |
|-------|-------------|----------------|--------------|
| **1. Planning** | Define the project scope, goals, and requirements. Establish a roadmap for the development process. | ✅ Complete | Project Charter, Roadmap, Resource Plan |
| **2. Requirements Analysis** | Gather and analyze user requirements to ensure the software meets stakeholder needs. | ✅ Complete | SRS Document, Use Cases, User Stories |
| **3. Design** | Create a detailed software design document that outlines the architecture and user interface. | ✅ Complete | Architecture Diagram, API Specs, UI Mockups |
| **4. Coding** | Write the actual code based on the design specifications. | 🔄 In Progress | Source Code, Unit Tests, Code Documentation |
| **5. Testing** | Conduct various tests to identify and fix bugs, ensuring the software functions as intended. | ⏳ Planned | Test Plans, Test Reports, Bug Tracker |
| **6. Deployment** | Release the software to the production environment for end users. | ⏳ Planned | Release Packages, Installation Guides, CI/CD Pipeline |
| **7. Maintenance** | Provide ongoing support, updates, and improvements to the software post-deployment. | ⏳ Planned | Patch Releases, Feature Updates, Support Documentation |

---

## 4x Raspberry Pi 4 Swarm Cluster Configuration

Aplikacja została zaprojektowana do działania w klastrze 4x Raspberry Pi 4, zapewniając skalowalność i wysoką dostępność.

### Architektura Klastra

```
┌─────────────────────────────────────────────────────────────────┐
│                    SWARM MANAGER (RPi4 #1)                      │
│  - Orchestrator zadań                                           │
│  - Load Balancer                                                │
│  - Central Configuration Store                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
         ┌────────────────────┼────────────────────┐
         │                    │                    │
         ▼                    ▼                    ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│   WORKER #1     │ │   WORKER #2     │ │   WORKER #3     │
│   (RPi4 #2)     │ │   (RPi4 #3)     │ │   (RPi4 #4)     │
│ - Task Executor │ │ - Task Executor │ │ - Task Executor │
│ - AI Inference  │ │ - AI Inference  │ │ - Backup Node   │
└─────────────────┘ └─────────────────┘ └─────────────────┘
```

### Plik Konfiguracyjny Klastra (`swarm.conf`)

```yaml
# swarm.conf - Konfiguracja 4x RPi4 Swarm Cluster
# Umieszczony w: /etc/qwen-tam/swarm.conf lub ~/.config/qwen-tam/swarm.conf

cluster:
  name: "qwen-tam-swarm"
  version: "1.0"
  
manager:
  host: "rpi4-manager.local"
  ip: "192.168.1.100"
  port: 8080
  api_endpoint: "http://rpi4-manager.local:8080/api/v1"
  
workers:
  - id: "worker-1"
    host: "rpi4-worker1.local"
    ip: "192.168.1.101"
    port: 8081
    role: ["executor", "ai-inference"]
    weight: 1.0
    
  - id: "worker-2"
    host: "rpi4-worker2.local"
    ip: "192.168.1.102"
    port: 8082
    role: ["executor", "ai-inference"]
    weight: 1.0
    
  - id: "worker-3"
    host: "rpi4-worker3.local"
    ip: "192.168.1.103"
    port: 8083
    role: ["executor", "backup"]
    weight: 0.5

communication:
  protocol: "mqtt"  # mqtt, http, grpc, nats
  broker_host: "rpi4-manager.local"
  broker_port: 1883
  topic_prefix: "qwen-tam/"
  qos: 1
  retain: false
  
  # Alternatywne protokoły
  http:
    timeout: 30
    retries: 3
    ssl_enabled: false
    
  grpc:
    max_message_size: 4194304  # 4MB
    keepalive_time: 30
    
  nats:
    servers: ["nats://rpi4-manager.local:4222"]
    cluster_id: "qwen-tam-cluster"

security:
  tls_enabled: false
  cert_path: "/etc/qwen-tam/certs/"
  auth_method: "token"  # token, mtls, oauth2
  shared_secret: "${SWARM_SHARED_SECRET}"
  
load_balancing:
  algorithm: "round-robin"  # round-robin, least-connections, weighted
  health_check_interval: 10
  health_check_timeout: 5
  failover_enabled: true
  
task_distribution:
  strategy: "broadcast"  # broadcast, unicast, multicast
  replication_factor: 2
  priority_queues: ["high", "normal", "low"]
  
logging:
  central_logging: true
  log_level: "INFO"
  remote_syslog: "rpi4-manager.local:514"
  
monitoring:
  prometheus_enabled: true
  prometheus_port: 9090
  grafana_dashboard: true
  alert_manager: "alertmanager.local:9093"
```

### Aktualizacja Aplikacji z Repozytorium GitHub

**Skrypt aktualizacji rozproszonej (`update-cluster.sh`):**

```bash
#!/bin/bash
# update-cluster.sh - Rozproszona aktualizacja 4x RPi4 Swarm

set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-/etc/qwen-tam/swarm.conf}"
GITHUB_REPO="https://github.com/username/qwen-tam.git"
BRANCH="main"
BACKUP_DIR="/var/backups/qwen-tam"

# Funkcja logowania
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a /var/log/qwen-tam/update.log
}

# Pobranie konfiguracji klastra
load_cluster_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "ERROR: Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    MANAGER_HOST=$(yq eval '.manager.host' "$CONFIG_FILE")
    WORKER_HOSTS=$(yq eval '.workers[].host' "$CONFIG_FILE")
}

# Sprawdzenie dostępności node'ów
health_check() {
    local host=$1
    if ping -c 1 -W 2 "$host" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Aktualizacja pojedynczego node'a
update_node() {
    local host=$1
    local role=$2
    
    log "Updating node: $host (role: $role)"
    
    # SSH connection with key-based auth
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
        admin@"$host" << 'EOF'
        set -e
        
        # Stop services
        sudo systemctl stop qwen-tam || true
        
        # Backup current version
        BACKUP_NAME="qwen-tam-backup-$(date +%Y%m%d-%H%M%S)"
        sudo tar -czf /var/backups/qwen-tam/$BACKUP_NAME.tar.gz \
            /opt/qwen-tam/
        
        # Pull latest changes
        cd /opt/qwen-tam
        sudo git fetch origin
        sudo git checkout main
        sudo git pull origin main
        
        # Run migrations if exist
        if [[ -f "./scripts/migrate.sh" ]]; then
            sudo ./scripts/migrate.sh
        fi
        
        # Restart services
        sudo systemctl daemon-reload
        sudo systemctl start qwen-tam
        
        # Verify startup
        sleep 5
        if systemctl is-active --quiet qwen-tam; then
            echo "SUCCESS: Node updated successfully"
        else
            echo "ERROR: Service failed to start, rolling back..."
            # Rollback logic here
            exit 1
        fi
EOF
    
    if [[ $? -eq 0 ]]; then
        log "✓ Node $host updated successfully"
    else
        log "✗ Failed to update node $host"
        return 1
    fi
}

# Strategia aktualizacji: Rolling Update
rolling_update() {
    log "Starting rolling update..."
    
    # Update workers first (parallel)
    for worker in $WORKER_HOSTS; do
        if health_check "$worker"; then
            update_node "$worker" "worker" &
        else
            log "WARNING: Worker $worker is unreachable, skipping..."
        fi
    done
    
    # Wait for workers
    wait
    
    # Update manager last
    if health_check "$MANAGER_HOST"; then
        update_node "$MANAGER_HOST" "manager"
    else
        log "ERROR: Manager $MANAGER_HOST is unreachable!"
        exit 1
    fi
    
    log "Rolling update completed successfully!"
}

# Main execution
main() {
    log "=========================================="
    log "Qwen TAM Cluster Update Started"
    log "=========================================="
    
    load_cluster_config
    
    case "${UPDATE_STRATEGY:-rolling}" in
        rolling)
            rolling_update
            ;;
        parallel)
            # Update all nodes simultaneously
            log "Parallel update strategy selected"
            # Implementation...
            ;;
        manual)
            # Manual node selection
            log "Manual update mode - select nodes interactively"
            # Implementation...
            ;;
    esac
}

main "$@"
```

### Protokoły Komunikacji Między Aplikacjami

#### 1. MQTT (Message Queuing Telemetry Transport)

**Domyślny protokół dla IoT/Swarm:**

```python
# Przykład publikacji zadania (Python/Mosquitto)
import paho.mqtt.client as mqtt
import json

client = mqtt.Client("qwen-tam-manager")
client.connect("rpi4-manager.local", 1883, 60)

task_payload = {
    "task_id": "task_12345",
    "type": "code_generation",
    "priority": "high",
    "payload": {
        "language": "python",
        "prompt": "Create a backup script",
        "output_file": "backup.py"
    },
    "timestamp": "2025-01-15T10:30:00Z"
}

client.publish("qwen-tam/tasks/code_generation", 
               json.dumps(task_payload), 
               qos=1)
```

**Tematy MQTT:**
| Topic | Direction | Description |
|-------|-----------|-------------|
| `qwen-tam/tasks/+` | Manager → Workers | Dystrybucja zadań |
| `qwen-tam/results/+` | Workers → Manager | Wyniki wykonania |
| `qwen-tam/health/+` | Workers → Manager | Heartbeat/Health status |
| `qwen-tam/config/update` | Manager → All | Aktualizacje konfiguracji |
| `qwen-tam/events/+` | All → Logger | Logi zdarzeń |

#### 2. HTTP/REST API

**Alternatywa dla komunikacji synchronicznej:**

```yaml
# Endpoints API
/api/v1/cluster/status      # GET - Status całego klastra
/api/v1/tasks               # POST - Nowe zadanie
/api/v1/tasks/{id}          # GET - Status zadania
/api/v1/workers             # GET - Lista workerów
/api/v1/workers/{id}/health # GET - Health check workera
/api/v1/config              # GET/PUT - Konfiguracja
```

#### 3. gRPC (High-Performance RPC)

**Dla niskich opóźnień i dużego throughput:**

```protobuf
// proto/task.proto
syntax = "proto3";

package qwentam;

service TaskService {
  rpc SubmitTask(TaskRequest) returns (TaskResponse);
  rpc GetTaskStatus(TaskStatusRequest) returns (TaskStatusResponse);
  rpc StreamTaskResults(StreamRequest) returns (stream TaskResult);
}

message TaskRequest {
  string task_id = 1;
  TaskType type = 2;
  bytes payload = 3;
  int32 priority = 4;
}

enum TaskType {
  CODE_GENERATION = 0;
  CODE_VERIFICATION = 1;
  AUTOMATION = 2;
  REPO_MANAGEMENT = 3;
}
```

#### 4. NATS (Lightweight Pub/Sub)

**Dla event-driven architektury:**

```bash
# Przykład użycia NATS CLI
nats pub "qwen-tam.tasks.code" --file task.json
nats sub "qwen-tam.results.>" --queue workers
```

### Tabela Porównawcza Protokołów

| Protokół | Opóźnienie | Throughput | QoS | Use Case |
|----------|------------|------------|-----|----------|
| MQTT | ~10ms | Średni | 0,1,2 | IoT, sensor data, commands |
| HTTP/REST | ~50ms | Niski | N/A | Sync requests, admin API |
| gRPC | ~5ms | Wysoki | N/A | Internal microservices |
| NATS | ~2ms | Bardzo wysoki | At-most-once | Event streaming, logs |

---

## 🛠️ Technologie i Języki Programowania

### Zasada Nadrzędna: **NO PYTHON**
> ⚠️ **STROGA ZABRONIENIE**: W całym projekcie **nigdy nie używamy języka Python**. 
> Wszystkie komponenty muszą być zaimplementowane w dozwolonych technologiach poniżej.

### 1. 🐍 Bash Shell Script (Linux)
*   **Zastosowanie**: Skrypty systemowe, automatyzacja zadań administracyjnych, skrypty startowe dla kontenerów, narzędzia CLI, TUI (Text User Interface).
*   **Środowisko**: Linux (Debian/Raspbian, Ubuntu, Alpine).
*   **Przykłady użycia w projekcie**:
    *   `install.sh` - instalacja zależności i konfiguracja systemu.
    *   `update-cluster.sh` - zarządzanie aktualizacjami na klastrze Swarm.
    *   Entry-pointy dla kontenerów Docker.
    *   Skrypty TUI menu aplikacji.
    *   Automatyzacja procesów z wykorzystaniem lokalnych modeli AI.
*   **Standardy**: POSIX sh lub Bash 4.0+, rygorystyczne sprawdzanie błędów (`set -euo pipefail`).

### 2. 💻 C / C# / C++ (Cross-Platform GUI)
*   **Zastosowanie**: Wydajne aplikacje desktopowe, moduły obliczeniowe, sterowniki sprzętowe, zaawansowane TUI/GUI.
*   **Kompatybilność**: Linux, Windows, macOS.
*   **Frameworki i Narzędzia**:
    *   **C/C++**: Qt (GUI), ncurses/imlib2 (TUI), CMake (budowa), GTK.
    *   **C#**: .NET MAUI lub Avalonia UI (cross-platform GUI), Entity Framework Core, WinForms/WPF (Windows native).
*   **Przykłady użycia w projekcie**:
    *   Rdzeń silnika harmonogramowania (C++ dla wydajności).
    *   Zaawansowany klient desktopowy do wizualizacji danych.
    *   Moduły komunikacji niskopoziomowej.
    *   Aplikacje mobilne cross-platform (C#/.NET MAUI).
    *   Native aplikacje na każdą platformę desktopową.

### 3. 🌐 WebUI (Apache2 + Linux)
*   **Zastosowanie**: Interfejs użytkownika dostępny przez przeglądarkę, dashboardy, zdalne zarządzanie, REST API.
*   **Stack Technologiczny**:
    *   **Serwer WWW**: Apache2 (mod_proxy, mod_ssl, mod_rewrite, mod_security).
    *   **Backend**: Go, Node.js, C# (.NET Core), lub C++ (CGI/FastCGI) działające jako usługa systemowa lub kontener.
    *   **Frontend**: HTML5, CSS3, JavaScript (Vanilla lub lekkie frameworki jak Alpine.js/Vue.js/React).
*   **Architektura**: Reverse Proxy (Apache2) kierujący ruch do backendu API.
*   **Przykłady użycia w projekcie**:
    *   Główny panel sterowania aplikacją.
    *   Widoki raportów i wykresów czasu pracy.
    *   Konfigurator reguł automatyzacji.
    *   Dashboard monitoringu systemu.

### 4. 📱 Android App
*   **Zastosowanie**: Mobilny dostęp do systemu, powiadomienia push, skanowanie kodów, praca terenowa, rejestracja czasu pracy.
*   **Technologie**:
    *   **Język**: Kotlin lub Java (Native Android).
    *   **Alternatywa Cross-platform**: Flutter (Dart) lub .NET MAUI (C#) - zgodne z zakazem Pythona.
*   **Komunikacja**: REST API / gRPC z backendem.
*   **Przykłady użycia w projekcie**:
    *   Rejestracja czasu pracy w terenie.
    *   Odbieranie alertów z systemu monitoringu.
    *   Skaner kodów QR/ISBN do inwentaryzacji.
    *   Powiadomienia o zdarzeniach systemowych.
    *   Tryb offline z synchronizacją.

---

## Licencja

MIT License - zobacz plik LICENSE dla szczegółów.

---

## Autor i Kontakt

Qwen Time & Automation Manager został stworzony z myślą o developerach pracujących na Raspberry Pi 4.

W razie pytań lub sugestii, proszę o kontakt poprzez GitHub Issues.

---

**© 2025 Qwen TAM Contributors**
