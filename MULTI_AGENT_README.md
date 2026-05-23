# Multi-Agent AI Workflows - Instrukcja Obsługi

## Opis Funkcjonalności

Moduł **Multi-Agent AI Workflows** umożliwia tworzenie zaawansowanych workflow z wykorzystaniem wielu lokalnych modeli LLM uruchomionych na różnych Raspberry Pi 4. System pozwala na:

- **Zarządzanie klastrem węzłów** - dodawanie, usuwanie i monitorowanie Raspberry Pi 4 z uruchomionymi modelami AI
- **Definiowanie agentów** - tworzenie agentów o różnych rolach (coordinator, worker, validator, specialist)
- **Tworzenie workflow** - definiowanie wieloetapowych procesów przetwarzania
- **Load balancing** - automatyczne wybieranie najlepszych węzłów do zadań
- **Health monitoring** - sprawdzanie dostępności i zdrowia węzłów
- **Komunikacja międzywęzłowa** - wysyłanie żądań do pojedynczych węzłów lub broadcast do wszystkich

## Wymagania

### Sprzętowe
- Minimum 2x Raspberry Pi 4 (zalecane 4GB RAM lub więcej)
- Sieć LAN (przewodowa zalecana dla lepszej wydajności)

### Programowe
- System: Raspberry Pi OS / Debian / Ubuntu na każdym RPi4
- Uruchomiony serwis Ollama lub LM Studio na każdym węźle
- Dostępne modele Qwen (np. qwen2.5:7b, qwen2.5-coder:7b)
- Bash 4.0+
- curl, netcat

### Konfiguracja każdego węzła

Na **każdym Raspberry Pi 4** uruchom serwis Ollama:

```bash
# Instalacja Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Pobranie modelu
ollama pull qwen2.5:7b

# Uruchomienie serwisu (domyślnie port 11434)
systemctl start ollama
systemctl enable ollama

# Konfiguracja dostępu sieciowego (jeśli potrzebna)
# Edytuj /etc/systemd/system/ollama.service.d/override.conf
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
```

## Szybki Start

### 1. Uruchomienie menu Multi-Agent

Z poziomu głównego menu aplikacji `qwen-tam`:
```
[4] 🔄 Automation & AI Agent
  → [4.9] 🤖 Multi-Agent Workflows (Cluster RPi4)
```

Lub bezpośrednio z linii poleceń:
```bash
./scripts/multi_agent.sh --menu
```

### 2. Dodanie pierwszego węzła

W menu wybierz opcję **2. Dodaj nowy węzeł (RPi4)** i podaj:
- **Node ID**: unikalny identyfikator (np. `node1`, `rpi4-master`)
- **Hostname**: nazwa hosta (np. `rpi4-01`)
- **IP Address**: adres IP w sieci LAN (np. `192.168.1.100`)
- **Port**: domyślnie `11434` (Ollama API)
- **Model**: nazwa modelu (np. `qwen2.5:7b`)
- **Role**: rola węzła (`coordinator`, `worker`, `validator`)

### 3. Skanowanie sieci (opcjonalne)

Wybierz opcję **4. Skanuj sieć w poszukiwaniu węzłów** aby automatycznie wykryć aktywne instancje Ollama w sieci.

### 4. Sprawdzenie statusu klastra

Wybierz opcję **1. Pokaż status klastra** aby zobaczyć wszystkie skonfigurowane węzły.

### 5. Definiowanie agentów

Wybierz opcję **6. Zdefiniuj nowego agenta**:
- **Agent ID**: unikalny identyfikator agenta (np. `coordinator_01`)
- **Agent type**: typ agenta (`coordinator`, `worker`, `validator`, `specialist`)
- **Node ID**: ID węzła na którym agent będzie działał
- **Capabilities**: opis umiejętności agenta

### 6. Tworzenie workflow

#### Opcja A: Użycie gotowego workflow

Wybierz opcję **9. Uruchom przykładowe workflow (collaborative coding)**:
1. Podaj nazwę projektu
2. Podaj opis projektu
3. System automatycznie utworzy i wykona workflow z krokami:
   - Analiza wymagań (coordinator)
   - Generowanie kodu (worker)
   - Code review (validator)
   - Agregacja wyników (coordinator)

#### Opcja B: Własne workflow

Wybierz opcję **8. Utwórz nowe workflow**:
1. Podaj Workflow ID i nazwę
2. Dodaj kroki używając funkcji `add_workflow_step`:

```bash
# Przykład dodania kroków
add_workflow_step "my_workflow" 1 "generate" "worker_01" \
    "Wygeneruj funkcję sortującą w Pythonie" \
    "" "/workspace/output/sort.py"

add_workflow_step "my_workflow" 2 "validate" "validator_01" \
    "Sprawdź bezpieczeństwo i jakość kodu" \
    "/workspace/output/sort.py" "/workspace/output/review.json"
```

3. Wykonaj workflow funkcją `execute_workflow "my_workflow"`

## Tryby Pracy Węzłów

### Role węzłów

| Rola | Opis | Przykład użycia |
|------|------|-----------------|
| `coordinator` | Koordynuje pracę innych agentów, podejmuje decyzje | Analiza wymagań, planowanie |
| `worker` | Wykonuje zadania (generowanie kodu, analiza) | Generowanie kodu, tłumaczenie tekstu |
| `validator` | Sprawdza jakość, bezpieczeństwo, poprawność | Code review, weryfikacja faktów |
| `specialist` | Wąska specjalizacja (security, optimization) | Analiza bezpieczeństwa, optymalizacja |

### Typy kroków workflow

| Typ | Opis |
|-----|------|
| `analyze` | Analiza danych wejściowych |
| `generate` | Generowanie nowej treści/kodu |
| `validate` | Walidacja i sprawdzenie jakości |
| `transform` | Transformacja danych |
| `aggregate` | Agregacja wyników z wielu źródeł |
| `process` | Przetwarzanie danych |

## Przykłady Użycia

### Przykład 1: Distributed Text Processing

Przetwarzanie dużego dokumentu z podziałem na części:

```bash
#!/bin/bash
source ./scripts/multi_agent.sh

# Utwórz workflow
create_workflow "doc_process_001" "Distributed Document Processing"

# Dodaj kroki dla każdego worker node
step=1
for worker in $(get_active_nodes "worker" | cut -d'|' -f1); do
    add_workflow_step "doc_process_001" $step "process" "worker_${worker}" \
        "Przetwórz fragment dokumentu #${step}" \
        "/input/document_part_${step}.txt" \
        "/output/processed_${step}.json"
    ((step++))
done

# Agregacja
add_workflow_step "doc_process_001" $step "aggregate" "coordinator_01" \
    "Połącz wszystkie przetworzone fragmenty" \
    "" \
    "/output/final_document.md"

# Wykonaj
execute_workflow "doc_process_001"
```

### Przykład 2: Collaborative Code Generation

Generowanie kodu z code review:

```bash
#!/bin/bash
source ./scripts/multi_agent.sh

# Definicja agentów
define_agent "architect_01" "coordinator" "node1" \
    "Architektura systemu, planowanie komponentów"
    
define_agent "coder_01" "worker" "node2" \
    "Generowanie kodu Python, JavaScript"
    
define_agent "reviewer_01" "validator" "node3" \
    "Code review, security scan, best practices"

# Workflow
create_workflow "code_gen_001" "Collaborative Code Generation"

add_workflow_step "code_gen_001" 1 "analyze" "architect_01" \
    "Zaprojektuj architekturę aplikacji TODO list" \
    "" "/design/architecture.json"

add_workflow_step "code_gen_001" 2 "generate" "coder_01" \
    "Zaimplementuj aplikację zgodnie z architekturą" \
    "/design/architecture.json" "/code/app.tar.gz"

add_workflow_step "code_gen_001" 3 "validate" "reviewer_01" \
    "Przeprowadź code review i security scan" \
    "/code/app.tar.gz" "/review/report.json"

execute_workflow "code_gen_001"
```

### Przykład 3: Load Balancing

Automatyczne wybieranie najlepszego węzła:

```bash
#!/bin/bash
source ./scripts/multi_agent.sh

# Wybierz najlepszy dostępny węzeł worker
best_node=$(select_best_node "" "worker")
echo "Wybrano węzeł: $best_node"

# Wyślij żądanie do wybranego węzła
payload='{"model": "qwen2.5:7b", "prompt": "Hello!", "stream": false}'
response=$(send_to_node "$best_node" "$payload")
echo "$response"
```

### Przykład 4: Health Check i Failover

```bash
#!/bin/bash
source ./scripts/multi_agent.sh

# Sprawdź zdrowie wszystkich węzłów
health_check_all_nodes

# Jeśli węzeł jest nieaktywny, system automatycznie go wyłączy
# i można wybrać inny do zadań
```

## Komenda Linii Poleceń

Skrypt obsługuje tryb interaktywny oraz parametry:

```bash
# Menu interaktywne (domyślne)
./scripts/multi_agent.sh

# Lub z parametrem
./scripts/multi_agent.sh --menu

# Pokaż status klastra
./scripts/multi_agent.sh --status

# Check health wszystkich węzłów
./scripts/multi_agent.sh --health

# Lista agentów
./scripts/multi_agent.sh --list-agents
```

## Pliki Konfiguracyjne

### `~/.qwen_tam_cluster`

Główny plik konfiguracji klastra:

```
# Format: NODE_ID|HOSTNAME|IP_ADDRESS|PORT|MODEL|ROLE|STATUS
node1|rpi4-master|192.168.1.100|11434|qwen2.5-coder:7b|coordinator|active
node2|rpi4-worker1|192.168.1.101|11434|qwen2.5:7b|worker|active
node3|rpi4-worker2|192.168.1.102|11434|qwen2.5:7b|worker|active
node4|rpi4-validator|192.168.1.103|11434|qwen2.5-coder:7b|validator|active
```

### `~/.qwen_tam_logs/agents/*.agent`

Pliki stanu agentów:

```
AGENT_ID=coordinator_01
AGENT_TYPE=coordinator
NODE_ID=node1
CAPABILITIES=Architektura systemu, planowanie komponentów
CREATED_AT=2025-01-15T10:30:00+01:00
STATUS=idle
TASKS_COMPLETED=5
LAST_ACTIVE=2025-01-15T12:45:00+01:00
```

### `~/.qwen_tam_logs/agents/*.workflow`

Pliki definicji workflow:

```
WORKFLOW_ID=coding_1234567890
WORKFLOW_NAME=Collaborative Coding: MyProject
CREATED_AT=2025-01-15T10:30:00+01:00
STATUS=completed
STEPS_COUNT=4
CURRENT_STEP=4
```

## Logi

Logi systemu znajdują się w `~/.qwen_tam_logs/`:
- `multi_agent.log` - główne logi operacji
- `agents/` - stany agentów i workflow

## Rozwiązywanie Problemów

### Problem: Nie można połączyć się z węzłem

**Rozwiązanie:**
1. Sprawdź czy Ollama działa: `systemctl status ollama`
2. Sprawdź czy port jest otwarty: `nc -zv <IP> 11434`
3. Sprawdź firewall: `sudo ufw allow 11434/tcp`
4. Upewnij się że Ollama nasłuchuje na wszystkich interfejsach:
   ```bash
   sudo systemctl edit ollama
   # Dodaj: Environment="OLLAMA_HOST=0.0.0.0"
   sudo systemctl restart ollama
   ```

### Problem: Workflow nie wykonuje się poprawnie

**Rozwiązanie:**
1. Sprawdź logi: `cat ~/.qwen_tam_logs/multi_agent.log`
2. Sprawdź status workflow: `cat ~/.qwen_tam_logs/agents/<workflow_id>.workflow`
3. Uruchom w trybie debug: `DEBUG_MODE=true ./scripts/multi_agent.sh`

### Problem: Brak dostępnych worker nodes

**Rozwiązanie:**
1. Sprawdź status klastra: opcja 1 w menu
2. Uruchom health check: opcja 5 w menu
3. Dodaj więcej węzłów: opcja 2 w menu
4. Sprawdź czy węzły mają status `active`

## Best Practices

1. **Sieć przewodowa** - Używaj połączenia Ethernet zamiast WiFi dla lepszej stabilności
2. **Chłodzenie** - Zapewnij odpowiednie chłodzenie dla RPi4 przy długotrwałym obciążeniu
3. **Modele lekkie** - Na RPi4 używaj modeli 7B lub mniejszych (qwen2.5:7b, qwen2.5-coder:7b)
4. **Monitorowanie** - Regularnie sprawdzaj health węzłów
5. **Backup konfiguracji** - Kopiuj plik `~/.qwen_tam_cluster` na bezpiecznym nośniku

## Zaawansowane Funkcje

### Broadcast do wszystkich węzłów

```bash
# Wyślij to samo żądanie do wszystkich aktywnych węzłów
payload='{"model": "qwen2.5:7b", "prompt": "Cześć!", "stream": false}'
broadcast_to_all "$payload" "/api/generate"
```

### Filtrowanie węzłów po roli

```bash
# Pobierz tylko węzły worker
get_active_nodes "worker"

# Pobierz tylko coordinators
get_active_nodes "coordinator"
```

### Ręczna aktualizacja statusu węzła

```bash
# Ustaw węzeł w stan maintenance
update_node_status "node1" "maintenance"

# Przywróć do aktywnych
update_node_status "node1" "active"
```

## Integracja z Qwen TAM

Moduł Multi-Agent jest zintegrowany z główną aplikacją Qwen TAM i może być używany w połączeniu z innymi funkcjami:
- Generowanie kodu z Qwen Coder na zdalnych węzłach
- Weryfikacja kodu z wykorzystaniem validator nodes
- Automatyzacja zadań z rozdziałem na wiele węzłów

---

**Autor**: Qwen TAM Team  
**Wersja**: 1.0  
**Licencja**: MIT
