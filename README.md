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

## Architektura aplikacji

```
qwen-tam/
├── qwen-tam.sh          # Główny skrypt aplikacji (TUI)
├── config.sh            # Moduł konfiguracji
├── github.sh            # Moduł integracji z GitHub
├── qwen-coder.sh        # Moduł komunikacji z Qwen Coder
├── qwen-agent.sh        # Moduł komunikacji z Qwen Agent
├── verifier.sh          # Moduł weryfikacji kodu
├── automation.sh        # Moduł automatyzacji procesów
├── logger.sh            # Moduł logowania i debugowania
├── events.sh            # Moduł obsługi zdarzeń
└── README.md            # Dokumentacja
```

## Tryby działania

### Tryb interaktywny (TUI)
- Menu tekstowe z nawigacją klawiszową
- Podgląd statusu zadań w czasie rzeczywistym
- Historia rozmów z AI

### Tryb tła (daemon)
- Praca w tle z pełnym logowaniem
- Obsługa zdarzeń czasowych (cron-like)
- Powiadomienia o zakończeniu zadań

### Tryb verbose/debug
- Szczegółowe logi wszystkich operacji
- Śledzenie wywołań API
- Dump zmiennych środowiskowych

## Bezpieczeństwo

- Token GitHub przechowywany jest w pliku z uprawnieniami `600`
- Możliwość szyfrowania konfiguracji (opcjonalnie)
- Walidacja wszystkich danych wejściowych
- Gentle code - bezpieczne usuwanie tymczasowych plików

## Instalacja

```bash
# Klonowanie repozytorium
git clone https://github.com/USER/qwen-tam.git
cd qwen-tam

# Konfiguracja
./qwen-tam.sh --config

# Uruchomienie
./qwen-tam.sh
```

## Konfiguracja modeli Qwen

Aplikacja wymaga lokalnie uruchomionych modeli:
- **Qwen Coder** - do generowania kodu (np. qwen-coder-7b)
- **Qwen Agent** - do planowania i automatyzacji (np. qwen-7b-chat)

Obsługiwane backendy:
- Ollama (`http://localhost:11434`)
- LM Studio (`http://localhost:1234`)
- Custom API endpoint

## Przykłady użycia

```bash
# Utworzenie nowego projektu
./qwen-tam.sh --create-repo "my-project"

# Generowanie dokumentacji
./qwen-tam.sh --generate-docs "opisz architekturę systemu"

# Automatyzacja zadania
./qwen-tam.sh --automate "stwórz skrypt backupu baz danych"

# Tryb debug
./qwen-tam.sh --debug --verbose
```

## Logi i diagnostyka

Logi zapisywane są w:
- `~/.qwen_tam/logs/app.log` - główne logi aplikacji
- `~/.qwen_tam/logs/debug.log` - szczegółowe logi debug
- `~/.qwen_tam/logs/events.log` - historia zdarzeń

## Rozwiązywanie problemów

### Częste błędy:
- **Brak połączenia z modelem AI** - sprawdź czy Ollama/LM Studio działa
- **Błąd autoryzacji GitHub** - wygeneruj nowy token w ustawieniach GitHub
- **Niewystarczająca pamięć** - zmniejsz rozmiar modelu lub zamknij inne aplikacje

## Licencja

MIT License - zobacz plik LICENSE

## Autor

Projekt stworzony dla Raspberry Pi 4 z myślą o lokalnej automatyzacji zadań programistycznych.
