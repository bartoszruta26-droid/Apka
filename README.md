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
║  [8] 🚪 Exit                                                 ║
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

## Licencja

MIT License - zobacz plik LICENSE dla szczegółów.

---

## Autor i Kontakt

Qwen Time & Automation Manager został stworzony z myślą o developerach pracujących na Raspberry Pi 4.

W razie pytań lub sugestii, proszę o kontakt poprzez GitHub Issues.

---

**© 2025 Qwen TAM Contributors**
