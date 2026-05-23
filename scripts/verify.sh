#!/bin/bash

#===============================================================================
# QWEN TIME & AUTOMATION MANAGER - Code Verification Module
# Plik: scripts/verify.sh
# Opis: Weryfikacja kodu - analiza statyczna, testy jednostkowe, raporty
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# Konfiguracja modułu verify
#-------------------------------------------------------------------------------
readonly VERIFY_VERSION="1.0"
readonly VERIFY_LOG_DIR="${SCRIPT_DIR:-$(dirname "$(dirname "${BASH_SOURCE[0]}")")}/logs"
readonly VERIFY_LOG="${VERIFY_LOG_DIR}/verify.log"
readonly REPORTS_DIR="${VERIFY_LOG_DIR}/reports"

# Narzędzia do weryfikacji
SHELL_CHECK_AVAILABLE=false
CPPCHECK_AVAILABLE=false
SHELLFMT_AVAILABLE=false
CLANG_FORMAT_AVAILABLE=false
UNIT_TEST_TOOLS_AVAILABLE=false

#-------------------------------------------------------------------------------
# Funkcje pomocnicze modułu verify
#-------------------------------------------------------------------------------

log_verify_info() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[VERIFY INFO]${NC} $timestamp - $*"
    [[ -d "$VERIFY_LOG_DIR" ]] && echo "[INFO] $timestamp - $*" >> "$VERIFY_LOG"
}

log_verify_debug() {
    if [[ "$DEBUG_MODE" == true ]]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo -e "${CYAN}[VERIFY DEBUG]${NC} $timestamp - $*" >&2
        [[ -d "$VERIFY_LOG_DIR" ]] && echo "[DEBUG] $timestamp - $*" >> "$VERIFY_LOG"
    fi
}

log_verify_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[VERIFY ERROR]${NC} $timestamp - $*" >&2
    [[ -d "$VERIFY_LOG_DIR" ]] && echo "[ERROR] $timestamp - $*" >> "$VERIFY_LOG"
}

log_verify_success() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[VERIFY SUCCESS]${NC} $timestamp - $*"
    [[ -d "$VERIFY_LOG_DIR" ]] && echo "[SUCCESS] $timestamp - $*" >> "$VERIFY_LOG"
}

log_verify_warning() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[VERIFY WARNING]${NC} $timestamp - $*"
    [[ -d "$VERIFY_LOG_DIR" ]] && echo "[WARNING] $timestamp - $*" >> "$VERIFY_LOG"
}

#-------------------------------------------------------------------------------
# Detekcja dostępnych narzędzi
#-------------------------------------------------------------------------------

detect_verification_tools() {
    log_verify_debug "Detecting verification tools..."
    
    # ShellCheck
    if command -v shellcheck &>/dev/null; then
        SHELL_CHECK_AVAILABLE=true
        log_verify_debug "ShellCheck found: $(shellcheck --version | head -1)"
    else
        log_verify_warning "ShellCheck not installed - shell syntax check will be limited"
    fi
    
    # cppcheck dla C/C++
    if command -v cppcheck &>/dev/null; then
        CPPCHECK_AVAILABLE=true
        log_verify_debug "cppcheck found: $(cppcheck --version | head -1)"
    else
        log_verify_debug "cppcheck not installed - C/C++ security scan will be limited"
    fi
    
    # shellfmt
    if command -v shellfmt &>/dev/null; then
        SHELLFMT_AVAILABLE=true
        log_verify_debug "shellfmt found"
    else
        log_verify_debug "shellfmt not installed"
    fi
    
    # clang-format
    if command -v clang-format &>/dev/null; then
        CLANG_FORMAT_AVAILABLE=true
        log_verify_debug "clang-format found"
    else
        log_verify_debug "clang-format not installed"
    fi
    
    # Narzędzia testowe (bashunit, shunit2, etc.)
    if command -v bashunit &>/dev/null || command -v shunit2 &>/dev/null || [[ -f "/usr/bin/python3" ]] && python3 -m pytest --version &>/dev/null; then
        UNIT_TEST_TOOLS_AVAILABLE=true
        log_verify_debug "Unit test tools found"
    else
        log_verify_debug "Unit test tools not found - will use basic test execution"
    fi
}

#-------------------------------------------------------------------------------
# [3.1] Syntax Check - Shell Scripts
#-------------------------------------------------------------------------------

verify_syntax_shell() {
    clear_screen
    show_header
    echo -e "${CYAN}║  🔍 SYNTAX CHECK - SHELL SCRIPTS                          ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"
    echo ""
    
    local target_file=""
    local target_dir=""
    
    echo -n "  Enter path to shell script or directory: "
    read -r target_path
    
    if [[ ! -e "$target_path" ]]; then
        log_verify_error "Path does not exist: $target_path"
        return 1
    fi
    
    # Jeśli podano katalog, znajdź wszystkie pliki .sh
    if [[ -d "$target_path" ]]; then
        target_dir="$target_path"
        log_verify_info "Scanning directory: $target_dir"
        local files_found=0
        local errors_found=0
        
        while IFS= read -r -d '' file; do
            ((files_found++))
            echo ""
            echo -e "${CYAN}─────────────────────────────────────────────────────────────${NC}"
            echo -e "${CYAN}Checking:${NC} $file"
            
            if ! verify_single_shell_file "$file"; then
                ((errors_found++))
            fi
        done < <(find "$target_dir" -name "*.sh" -type f -print0)
        
        echo ""
        echo -e "${CYAN}─────────────────────────────────────────────────────────────${NC}"
        echo -e "${GREEN}Summary:${NC} Checked $files_found files, $errors_found with errors"
        
        if [[ $errors_found -eq 0 ]]; then
            log_verify_success "All shell scripts passed syntax check"
        else
            log_verify_warning "$errors_found scripts have syntax issues"
        fi
        
    elif [[ -f "$target_path" ]]; then
        target_file="$target_path"
        log_verify_info "Checking single file: $target_file"
        
        if verify_single_shell_file "$target_file"; then
            log_verify_success "Syntax check passed for $target_file"
        else
            log_verify_error "Syntax check failed for $target_file"
            return 1
        fi
    fi
    
    return 0
}

verify_single_shell_file() {
    local file="$1"
    local has_errors=0
    
    # 1. Sprawdzenie składni bash (wbudowane)
    echo -e "  ${BLUE}[1/3]${NC} Bash syntax check..."
    if bash -n "$file" 2>&1; then
        echo -e "    ✅ Bash syntax: OK"
    else
        echo -e "    ❌ Bash syntax: FAILED"
        has_errors=1
    fi
    
    # 2. ShellCheck (jeśli dostępny)
    if [[ "$SHELL_CHECK_AVAILABLE" == true ]]; then
        echo -e "  ${BLUE}[2/3]${NC} ShellCheck analysis..."
        local shellcheck_output
        shellcheck_output=$(shellcheck -f gcc "$file" 2>&1) || true
        
        if [[ -z "$shellcheck_output" ]]; then
            echo -e "    ✅ ShellCheck: No issues found"
        else
            echo -e "    ⚠️  ShellCheck warnings/errors:"
            echo "$shellcheck_output" | head -20 | sed 's/^/       /'
            local issue_count=$(echo "$shellcheck_output" | wc -l)
            if [[ $issue_count -gt 20 ]]; then
                echo "       ... and $((issue_count - 20)) more issues"
            fi
            # ShellCheck zwraca błędy ale nie oznacza to że składnia jest zła
        fi
    else
        echo -e "  ${YELLOW}[2/3]${NC} ShellCheck: Not available (install with: apt install shellcheck)"
    fi
    
    # 3. Sprawdzenie uprawnień wykonywalności
    echo -e "  ${BLUE}[3/3]${NC} Executable permission check..."
    if [[ -x "$file" ]]; then
        echo -e "    ✅ File is executable"
    else
        echo -e "    ⚠️  File is not executable (chmod +x $file)"
    fi
    
    return $has_errors
}

#-------------------------------------------------------------------------------
# [3.2] Syntax Check - C/C++ Code
#-------------------------------------------------------------------------------

verify_syntax_cpp() {
    clear_screen
    show_header
    echo -e "${CYAN}║  🔍 SYNTAX CHECK - C/C++ CODE                             ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"
    echo ""
    
    local target_path=""
    echo -n "  Enter path to C/C++ file or directory: "
    read -r target_path
    
    if [[ ! -e "$target_path" ]]; then
        log_verify_error "Path does not exist: $target_path"
        return 1
    fi
    
    local files_checked=0
    local errors_found=0
    
    # Funkcja do sprawdzania pojedynczego pliku
    check_cpp_file() {
        local file="$1"
        local ext="${file##*.}"
        local compiler_cmd=""
        
        ((files_checked++))
        echo ""
        echo -e "${CYAN}─────────────────────────────────────────────────────────────${NC}"
        echo -e "${CYAN}Checking:${NC} $file"
        
        # Wybór kompilatora na podstawie rozszerzenia
        case "$ext" in
            c|C)
                compiler_cmd="gcc -fsyntax-only -Wall -Wextra -std=c11"
                ;;
            cpp|cxx|cc|C++)
                compiler_cmd="g++ -fsyntax-only -Wall -Wextra -std=c++17"
                ;;
            h|hpp|hxx)
                # Pliki nagłówkowe wymagają specjalnego traktowania
                compiler_cmd="g++ -fsyntax-only -Wall -Wextra -std=c++17 -c"
                ;;
            *)
                echo -e "  ${YELLOW}⚠️  Unknown extension: $ext - skipping${NC}"
                return 0
                ;;
        esac
        
        echo -e "  ${BLUE}[1/2]${NC} Compiler syntax check ($compiler_cmd)..."
        if $compiler_cmd "$file" 2>&1; then
            echo -e "    ✅ Compiler syntax: OK"
        else
            echo -e "    ❌ Compiler syntax: FAILED"
            ((errors_found++))
        fi
        
        # cppcheck jeśli dostępny
        if [[ "$CPPCHECK_AVAILABLE" == true ]]; then
            echo -e "  ${BLUE}[2/2]${NC} cppcheck static analysis..."
            local cppcheck_output
            cppcheck_output=$(cppcheck --quiet --enable=all --inconclusive "$file" 2>&1) || true
            
            if [[ -z "$cppcheck_output" || "$cppcheck_output" == *"0 errors"* ]]; then
                echo -e "    ✅ cppcheck: No issues found"
            else
                echo -e "    ⚠️  cppcheck warnings:"
                echo "$cppcheck_output" | head -15 | sed 's/^/       /'
            fi
        else
            echo -e "  ${YELLOW}[2/2]${NC} cppcheck: Not available (install with: apt install cppcheck)"
        fi
    }
    
    # Przetwarzanie plików
    if [[ -d "$target_path" ]]; then
        log_verify_info "Scanning directory: $target_path"
        while IFS= read -r -d '' file; do
            check_cpp_file "$file"
        done < <(find "$target_path" -type f \( -name "*.c" -o -name "*.cpp" -o -name "*.cxx" -o -name "*.cc" -o -name "*.h" -o -name "*.hpp" -o -name "*.hxx" \) -print0)
    elif [[ -f "$target_path" ]]; then
        check_cpp_file "$target_path"
    fi
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Summary:${NC} Checked $files_checked files, $errors_found with errors"
    
    if [[ $errors_found -eq 0 ]]; then
        log_verify_success "All C/C++ files passed syntax check"
    else
        log_verify_error "$errors_found files have syntax errors"
        return 1
    fi
    
    return 0
}

#-------------------------------------------------------------------------------
# [3.3] Security Scan
#-------------------------------------------------------------------------------

verify_security_scan() {
    clear_screen
    show_header
    echo -e "${CYAN}║  🛡️  SECURITY SCAN                                        ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"
    echo ""
    
    local target_path=""
    echo -n "  Enter path to scan (file or directory): "
    read -r target_path
    
    if [[ ! -e "$target_path" ]]; then
        log_verify_error "Path does not exist: $target_path"
        return 1
    fi
    
    log_verify_info "Starting security scan: $target_path"
    echo ""
    
    local security_issues=0
    
    # 1. Skanowanie pod kątem hardcoded secrets
    echo -e "${BLUE}[1/5]${NC} Scanning for hardcoded secrets..."
    local secrets_pattern='(password|passwd|pwd|secret|api_key|apikey|token|auth|credential)[[:space:]]*[=:][[:space:]]*["\047]?[^"\047[:space:]]+["\047]?'
    local secrets_found
    secrets_found=$(grep -riE "$secrets_pattern" "$target_path" 2>/dev/null | grep -v ".git" | head -20) || true
    
    if [[ -n "$secrets_found" ]]; then
        echo -e "  ${RED}⚠️  Potential secrets found:${NC}"
        echo "$secrets_found" | sed 's/^/     /'
        ((security_issues++))
    else
        echo -e "  ${GREEN}✅${NC} No hardcoded secrets detected"
    fi
    
    # 2. Skanowanie pod kątem eval/exec injection
    echo -e "${BLUE}[2/5]${NC} Scanning for dangerous eval/exec usage..."
    local eval_pattern='(eval|exec|source)[[:space:]]+\$'
    local eval_found
    eval_found=$(grep -rE "$eval_pattern" "$target_path" 2>/dev/null | grep -v ".git" | head -10) || true
    
    if [[ -n "$eval_found" ]]; then
        echo -e "  ${YELLOW}⚠️  Dynamic code execution detected (review manually):${NC}"
        echo "$eval_found" | sed 's/^/     /'
        # To nie zawsze jest błąd, więc tylko ostrzegamy
    else
        echo -e "  ${GREEN}✅${NC} No dangerous eval/exec patterns"
    fi
    
    # 3. Sprawdzenie uprawnień plików
    echo -e "${BLUE}[3/5]${NC} Checking file permissions..."
    local world_writable
    world_writable=$(find "$target_path" -type f -perm -002 2>/dev/null | head -10) || true
    
    if [[ -n "$world_writable" ]]; then
        echo -e "  ${RED}⚠️  World-writable files found:${NC}"
        echo "$world_writable" | sed 's/^/     /'
        ((security_issues++))
    else
        echo -e "  ${GREEN}✅${NC} No world-writable files"
    fi
    
    # 4. Sprawdzenie shebangów
    echo -e "${BLUE}[4/5]${NC} Validating shebangs in scripts..."
    local bad_shebangs
    bad_shebangs=$(find "$target_path" -type f -name "*.sh" -exec head -1 {} \; 2>/dev/null | grep -v "^#!/" | grep -v "^$" | head -5) || true
    
    if [[ -n "$bad_shebangs" ]]; then
        echo -e "  ${YELLOW}⚠️  Some scripts may have missing/invalid shebangs${NC}"
    else
        echo -e "  ${GREEN}✅${NC} Shebangs look correct"
    fi
    
    # 5. cppcheck security scan dla C/C++
    if [[ "$CPPCHECK_AVAILABLE" == true ]]; then
        echo -e "${BLUE}[5/5]${NC} Running cppcheck security analysis..."
        local cppcheck_sec
        cppcheck_sec=$(cppcheck --quiet --enable=security,warning "$target_path" 2>&1) || true
        
        if [[ -z "$cppcheck_sec" || "$cppcheck_sec" == *"0 errors"* ]]; then
            echo -e "  ${GREEN}✅${NC} cppcheck security: No issues"
        else
            echo -e "  ${YELLOW}⚠️  cppcheck security warnings:${NC}"
            echo "$cppcheck_sec" | head -15 | sed 's/^/     /'
        fi
    fi
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    if [[ $security_issues -eq 0 ]]; then
        log_verify_success "Security scan completed - no critical issues found"
    else
        log_verify_warning "Security scan completed - $security_issues potential issues require review"
    fi
    
    return 0
}

#-------------------------------------------------------------------------------
# [3.4] Code Style Check
#-------------------------------------------------------------------------------

verify_code_style() {
    clear_screen
    show_header
    echo -e "${CYAN}║  📏 CODE STYLE CHECK                                      ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"
    echo ""
    
    local target_path=""
    echo -n "  Enter path to check (file or directory): "
    read -r target_path
    
    if [[ ! -e "$target_path" ]]; then
        log_verify_error "Path does not exist: $target_path"
        return 1
    fi
    
    log_verify_info "Starting code style check: $target_path"
    echo ""
    
    # Sprawdź typ plików w katalogu
    local has_shell=false
    local has_cpp=false
    
    if [[ -d "$target_path" ]]; then
        [[ $(find "$target_path" -name "*.sh" -type f | head -1) ]] && has_shell=true
        [[ $(find "$target_path" -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" | head -1) ]] && has_cpp=true
    else
        case "$target_path" in
            *.sh) has_shell=true ;;
            *.c|*.cpp|*.h|*.hpp) has_cpp=true ;;
        esac
    fi
    
    # Style check dla Shell
    if [[ "$has_shell" == true ]]; then
        echo -e "${BLUE}━━━ Shell Script Style ━━━${NC}"
        
        if [[ "$SHELLFMT_AVAILABLE" == true ]]; then
            echo -e "  ${BLUE}▶${NC} Running shellfmt..."
            local shellfmt_issues
            shellfmt_issues=$(shellfmt -l "$target_path" 2>&1) || true
            
            if [[ -z "$shellfmt_issues" ]]; then
                echo -e "    ${GREEN}✅${NC} shellfmt: Code is properly formatted"
            else
                echo -e "    ${YELLOW}⚠️  Formatting issues found:${NC}"
                echo "$shellfmt_issues" | head -10 | sed 's/^/       /'
            fi
        else
            echo -e "  ${YELLOW}ℹ️${NC} shellfmt not installed - using basic checks"
            
            # Basic style checks
            echo -e "  ${BLUE}▶${NC} Checking for common style issues..."
            
            # Sprawdzanie wcięć (mieszanie tab i spaces)
            local mixed_indent
            mixed_indent=$(grep -rP "^[ ]*\t" "$target_path" 2>/dev/null | head -5) || true
            if [[ -n "$mixed_indent" ]]; then
                echo -e "    ${YELLOW}⚠️  Mixed tabs/spaces indentation detected${NC}"
            else
                echo -e "    ${GREEN}✅${NC} Consistent indentation"
            fi
            
            # Sprawdzanie długości linii
            local long_lines
            long_lines=$(find "$target_path" -name "*.sh" -exec awk 'length > 120 {print FILENAME":"NR": "length" chars"}' {} \; 2>/dev/null | head -5) || true
            if [[ -n "$long_lines" ]]; then
                echo -e "    ${YELLOW}⚠️  Lines over 120 characters:${NC}"
                echo "$long_lines" | sed 's/^/       /'
            else
                echo -e "    ${GREEN}✅${NC} Line lengths acceptable"
            fi
        fi
        echo ""
    fi
    
    # Style check dla C/C++
    if [[ "$has_cpp" == true ]]; then
        echo -e "${BLUE}━━━ C/C++ Style ━━━${NC}"
        
        if [[ "$CLANG_FORMAT_AVAILABLE" == true ]]; then
            echo -e "  ${BLUE}▶${NC} Running clang-format check..."
            local clang_format_issues
            clang_format_issues=$(clang-format --style=file --dry-run --Werror "$target_path" 2>&1) || true
            
            if [[ -z "$clang_format_issues" ]]; then
                echo -e "    ${GREEN}✅${NC} clang-format: Code follows style guide"
            else
                echo -e "    ${YELLOW}⚠️  Formatting issues found:${NC}"
                echo "$clang_format_issues" | head -10 | sed 's/^/       /'
            fi
        else
            echo -e "  ${YELLOW}ℹ️${NC} clang-format not installed - using basic checks"
            
            # Basic style checks dla C/C++
            echo -e "  ${BLUE}▶${NC} Checking for common style issues..."
            
            # Sprawdzanie wcięć
            local mixed_indent
            mixed_indent=$(grep -rP "^[ ]*\t" "$target_path" 2>/dev/null | head -5) || true
            if [[ -n "$mixed_indent" ]]; then
                echo -e "    ${YELLOW}⚠️  Mixed tabs/spaces indentation detected${NC}"
            else
                echo -e "    ${GREEN}✅${NC} Consistent indentation"
            fi
        fi
        echo ""
    fi
    
    # Ogólne zasady stylu
    echo -e "${BLUE}━━━ General Style Rules ━━━${NC}"
    
    # Sprawdzanie komentarzy
    echo -e "  ${BLUE}▶${NC} Checking documentation coverage..."
    local comment_ratio
    if [[ -d "$target_path" ]]; then
        local total_lines=$(find "$target_path" -type f \( -name "*.sh" -o -name "*.c" -o -name "*.cpp" -o -name "*.h" \) -exec cat {} \; 2>/dev/null | wc -l)
        local comment_lines=$(find "$target_path" -type f \( -name "*.sh" -o -name "*.c" -o -name "*.cpp" -o -name "*.h" \) -exec grep -c "^[[:space:]]*#\|^[[:space:]]*//\|^[[:space:]]*/\*" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum}')
        
        if [[ $total_lines -gt 0 ]]; then
            comment_ratio=$((comment_lines * 100 / total_lines))
            if [[ $comment_ratio -ge 10 ]]; then
                echo -e "    ${GREEN}✅${NC} Documentation coverage: ${comment_ratio}% (good)"
            else
                echo -e "    ${YELLOW}⚠️  Documentation coverage: ${comment_ratio}% (consider adding more comments)${NC}"
            fi
        fi
    else
        echo -e "    ${BLUE}ℹ️${NC} Single file - skipping ratio analysis"
    fi
    
    log_verify_success "Code style check completed"
    return 0
}

#-------------------------------------------------------------------------------
# [3.5] Run Unit Tests
#-------------------------------------------------------------------------------

verify_run_unit_tests() {
    clear_screen
    show_header
    echo -e "${CYAN}║  🧪 RUN UNIT TESTS                                        ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"
    echo ""
    
    local test_dir=""
    echo -n "  Enter path to test directory or project root: "
    read -r test_dir
    
    if [[ ! -d "$test_dir" ]]; then
        log_verify_error "Directory does not exist: $test_dir"
        return 1
    fi
    
    log_verify_info "Searching for tests in: $test_dir"
    echo ""
    
    local tests_found=0
    local tests_passed=0
    local tests_failed=0
    
    # 1. Szukanie testów bash (bashunit, shunit2)
    echo -e "${BLUE}[1/3]${NC} Looking for Bash unit tests..."
    
    # bashunit
    local bashunit_tests=$(find "$test_dir" -name "*_test.sh" -o -name "test_*.sh" 2>/dev/null | head -20)
    if [[ -n "$bashunit_tests" ]]; then
        echo -e "  Found bash test files"
        while IFS= read -r test_file; do
            ((tests_found++))
            echo -e "  ${CYAN}▶${NC} Running: $test_file"
            
            if [[ -x "$test_file" ]]; then
                if "$test_file" 2>&1; then
                    ((tests_passed++))
                    echo -e "    ${GREEN}✅ PASSED${NC}"
                else
                    ((tests_failed++))
                    echo -e "    ${RED}❌ FAILED${NC}"
                fi
            else
                echo -e "    ${YELLOW}⚠️  Not executable - skipping${NC}"
            fi
        done <<< "$bashunit_tests"
    else
        echo -e "  ${YELLOW}ℹ️${NC} No bash test files found (*_test.sh, test_*.sh)"
    fi
    
    # 2. Szukanie testów C/C++ (Google Test, Catch2)
    echo -e "${BLUE}[2/3]${NC} Looking for C/C++ unit tests..."
    
    local cpp_test_bins=$(find "$test_dir" -name "*_test" -type f -executable 2>/dev/null | head -10)
    if [[ -n "$cpp_test_bins" ]]; then
        echo -e "  Found C++ test executables"
        while IFS= read -r test_bin; do
            ((tests_found++))
            echo -e "  ${CYAN}▶${NC} Running: $test_bin"
            
            if "$test_bin" 2>&1; then
                ((tests_passed++))
                echo -e "    ${GREEN}✅ PASSED${NC}"
            else
                ((tests_failed++))
                echo -e "    ${RED}❌ FAILED${NC}"
            fi
        done <<< "$cpp_test_bins"
    else
        echo -e "  ${YELLOW}ℹ️${NC} No C++ test executables found"
    fi
    
    # 3. Uruchomienie Makefile test target jeśli istnieje
    echo -e "${BLUE}[3/3]${NC} Checking for Makefile test target..."
    
    if [[ -f "$test_dir/Makefile" ]]; then
        if grep -q "^[[:space:]]*test[[:space:]]*:" "$test_dir/Makefile"; then
            echo -e "  ${CYAN}▶${NC} Running 'make test'..."
            cd "$test_dir"
            if make test 2>&1; then
                echo -e "    ${GREEN}✅ Makefile tests passed${NC}"
                ((tests_passed++))
            else
                echo -e "    ${RED}❌ Makefile tests failed${NC}"
                ((tests_failed++))
            fi
            cd - > /dev/null
        else
            echo -e "  ${YELLOW}ℹ️${NC} No 'test' target in Makefile"
        fi
    else
        echo -e "  ${YELLOW}ℹ️${NC} No Makefile found"
    fi
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Test Summary:${NC}"
    echo -e "  Total tests found:  $tests_found"
    echo -e "  Tests passed:       ${GREEN}$tests_passed${NC}"
    echo -e "  Tests failed:       ${RED}$tests_failed${NC}"
    
    if [[ $tests_found -eq 0 ]]; then
        log_verify_warning "No tests found to run"
    elif [[ $tests_failed -eq 0 ]]; then
        log_verify_success "All $tests_passed tests passed!"
    else
        log_verify_error "$tests_failed out of $tests_found tests failed"
        return 1
    fi
    
    return 0
}

#-------------------------------------------------------------------------------
# [3.6] Generate Verification Report
#-------------------------------------------------------------------------------

verify_generate_report() {
    clear_screen
    show_header
    echo -e "${CYAN}║  📊 GENERATE VERIFICATION REPORT                          ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"
    echo ""
    
    mkdir -p "$REPORTS_DIR"
    
    local target_path=""
    local report_name=""
    
    echo -n "  Enter path to project/file: "
    read -r target_path
    
    if [[ ! -e "$target_path" ]]; then
        log_verify_error "Path does not exist: $target_path"
        return 1
    fi
    
    echo -n "  Enter report name (or press Enter for auto): "
    read -r report_name
    
    if [[ -z "$report_name" ]]; then
        report_name="verify_report_$(date +%Y%m%d_%H%M%S)"
    fi
    
    local report_file="${REPORTS_DIR}/${report_name}.md"
    
    log_verify_info "Generating verification report: $report_file"
    echo ""
    echo -e "  ${CYAN}Generating...${NC}"
    
    # Nagłówek raportu
    cat > "$report_file" << EOF
# Verification Report

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')
**Target:** $target_path
**Version:** $VERIFY_VERSION

---

## Executive Summary

EOF
    
    # 1. Informacje o plikach
    echo -e "  ${BLUE}[1/6]${NC} Analyzing file structure..."
    cat >> "$report_file" << EOF
### File Structure

EOF
    
    if [[ -d "$target_path" ]]; then
        local file_count=$(find "$target_path" -type f | wc -l)
        local sh_count=$(find "$target_path" -name "*.sh" -type f | wc -l)
        local c_count=$(find "$target_path" -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" | wc -l)
        local total_lines=$(find "$target_path" -type f \( -name "*.sh" -o -name "*.c" -o -name "*.cpp" -o -name "*.h" \) -exec cat {} \; 2>/dev/null | wc -l)
        
        cat >> "$report_file" << EOF
- **Total files:** $file_count
- **Shell scripts:** $sh_count
- **C/C++ files:** $c_count
- **Total lines of code:** $total_lines

EOF
    else
        local lines=$(wc -l < "$target_path")
        cat >> "$report_file" << EOF
- **File:** $(basename "$target_path")
- **Lines:** $lines

EOF
    fi
    
    # 2. Wyniki Syntax Check
    echo -e "  ${BLUE}[2/6]${NC} Running syntax validation..."
    cat >> "$report_file" << EOF
### Syntax Validation

#### Shell Scripts
EOF
    
    if [[ -d "$target_path" ]]; then
        local syntax_errors=0
        while IFS= read -r -d '' file; do
            if bash -n "$file" 2>/dev/null; then
                echo "- ✅ $(basename "$file")" >> "$report_file"
            else
                echo "- ❌ $(basename "$file") - SYNTAX ERROR" >> "$report_file"
                ((syntax_errors++))
            fi
        done < <(find "$target_path" -name "*.sh" -type f -print0 2>/dev/null)
        
        if [[ $syntax_errors -eq 0 ]]; then
            echo -e "\n**Status:** All shell scripts passed syntax check ✅" >> "$report_file"
        else
            echo -e "\n**Status:** $syntax_errors files with syntax errors ❌" >> "$report_file"
        fi
    else
        if bash -n "$target_path" 2>/dev/null; then
            echo -e "\n**Status:** Passed ✅" >> "$report_file"
        else
            echo -e "\n**Status:** Failed ❌" >> "$report_file"
        fi
    fi
    
    # 3. Security Scan Results
    echo -e "  ${BLUE}[3/6]${NC} Running security scan..."
    cat >> "$report_file" << EOF

### Security Analysis

EOF
    
    local secrets_found=$(grep -riE '(password|secret|api_key|token)[[:space:]]*[=:][[:space:]]*[^[:space:]]+' "$target_path" 2>/dev/null | wc -l)
    local world_writable=$(find "$target_path" -type f -perm -002 2>/dev/null | wc -l)
    
    cat >> "$report_file" << EOF
- **Potential secrets:** $secrets_found occurrences
- **World-writable files:** $world_writable files
- **Security status:** $([ $secrets_found -eq 0 ] && [ $world_writable -eq 0 ] && echo "✅ Clean" || echo "⚠️ Review needed")

EOF
    
    # 4. Code Style
    echo -e "  ${BLUE}[4/6]${NC} Analyzing code style..."
    cat >> "$report_file" << EOF
### Code Style

EOF
    
    if [[ -d "$target_path" ]]; then
        local total_lines=$(find "$target_path" -type f \( -name "*.sh" -o -name "*.c" -o -name "*.cpp" \) -exec cat {} \; 2>/dev/null | wc -l)
        local comment_lines=$(find "$target_path" -type f \( -name "*.sh" -o -name "*.c" -o -name "*.cpp" \) -exec grep -c "^[[:space:]]*#\|^[[:space:]]*//\|^[[:space:]]*/\*" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum}')
        
        if [[ $total_lines -gt 0 ]]; then
            local ratio=$((comment_lines * 100 / total_lines))
            echo "- **Documentation coverage:** ${ratio}%" >> "$report_file"
            echo "- **Comment lines:** $comment_lines / $total_lines" >> "$report_file"
        fi
    fi
    
    # 5. Test Coverage
    echo -e "  ${BLUE}[5/6]${NC} Checking test coverage..."
    cat >> "$report_file" << EOF

### Test Coverage

EOF
    
    local test_files=$(find "$target_path" -name "*_test.sh" -o -name "test_*.sh" 2>/dev/null | wc -l)
    local test_bins=$(find "$target_path" -name "*_test" -type f -executable 2>/dev/null | wc -l)
    
    cat >> "$report_file" << EOF
- **Bash test files:** $test_files
- **C++ test executables:** $test_bins
- **Test status:** $([ $test_files -gt 0 ] || [ $test_bins -gt 0 ] && echo "✅ Tests present" || echo "⚠️ No tests found")

EOF
    
    # 6. Recommendations
    echo -e "  ${BLUE}[6/6]${NC} Generating recommendations..."
    cat >> "$report_file" << EOF
### Recommendations

EOF
    
    local recommendations=0
    
    if [[ $secrets_found -gt 0 ]]; then
        echo "1. 🔒 **Security:** Review and remove any hardcoded secrets" >> "$report_file"
        ((recommendations++))
    fi
    
    if [[ $world_writable -gt 0 ]]; then
        echo "$((recommendations + 1)). 🔐 **Permissions:** Fix world-writable file permissions" >> "$report_file"
        ((recommendations++))
    fi
    
    if [[ $test_files -eq 0 ]] && [[ $test_bins -eq 0 ]]; then
        echo "$((recommendations + 1)). 🧪 **Testing:** Consider adding unit tests" >> "$report_file"
        ((recommendations++))
    fi
    
    if [[ $total_lines -gt 0 ]] && [[ $ratio -lt 10 ]]; then
        echo "$((recommendations + 1)). 📝 **Documentation:** Add more code comments" >> "$report_file"
        ((recommendations++))
    fi
    
    if [[ $recommendations -eq 0 ]]; then
        echo "✅ No critical recommendations - code quality looks good!" >> "$report_file"
    fi
    
    # Footer
    cat >> "$report_file" << EOF

---

*Report generated by Qwen TAM Verification Module v${VERIFY_VERSION}*
EOF
    
    echo ""
    echo -e "${GREEN}Report generated successfully!${NC}"
    echo -e "  Location: ${CYAN}$report_file${NC}"
    echo ""
    
    # Czy wyświetlić raport?
    read -rp "  Display report now? [y/N]: " show_now
    if [[ "$show_now" =~ ^[Yy]$ ]]; then
        echo ""
        cat "$report_file"
    fi
    
    log_verify_success "Verification report saved to $report_file"
    return 0
}

#-------------------------------------------------------------------------------
# Menu główne modułu verify
#-------------------------------------------------------------------------------

verify_menu() {
    detect_verification_tools
    
    while true; do
        clear_screen
        show_header
        echo -e "${CYAN}║                   CODE VERIFICATION MENU                 ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║  [1] 🔍 Syntax Check (Shell)                             ║${NC}"
        echo -e "${GREEN}║  [2] 🔍 Syntax Check (C/C++)                             ║${NC}"
        echo -e "${GREEN}║  [3] 🛡️  Security Scan                                   ║${NC}"
        echo -e "${GREEN}║  [4] 📏 Code Style Check                                 ║${NC}"
        echo -e "${GREEN}║  [5] 🧪 Run Unit Tests                                   ║${NC}"
        echo -e "${GREEN}║  [6] 📊 Generate Verification Report                     ║${NC}"
        echo -e "${GREEN}║  [7] ℹ️  Available Tools Status                          ║${NC}"
        echo -e "${YELLOW}║  [8] ⬅️  Back to Main Menu                               ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        read -rp "  Enter choice [1-8]: " choice
        
        case $choice in
            1) verify_syntax_shell ;;
            2) verify_syntax_cpp ;;
            3) verify_security_scan ;;
            4) verify_code_style ;;
            5) verify_run_unit_tests ;;
            6) verify_generate_report ;;
            7) 
                clear_screen
                show_header
                echo -e "${CYAN}║  AVAILABLE VERIFICATION TOOLS                         ║${NC}"
                echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${NC}"
                echo -e "  ShellCheck:      $([ "$SHELL_CHECK_AVAILABLE" == true ] && echo -e "${GREEN}✅ Installed${NC}" || echo -e "${YELLOW}❌ Not installed${NC}")"
                echo -e "  cppcheck:        $([ "$CPPCHECK_AVAILABLE" == true ] && echo -e "${GREEN}✅ Installed${NC}" || echo -e "${YELLOW}❌ Not installed${NC}")"
                echo -e "  shellfmt:        $([ "$SHELLFMT_AVAILABLE" == true ] && echo -e "${GREEN}✅ Installed${NC}" || echo -e "${YELLOW}❌ Not installed${NC}")"
                echo -e "  clang-format:    $([ "$CLANG_FORMAT_AVAILABLE" == true ] && echo -e "${GREEN}✅ Installed${NC}" || echo -e "${YELLOW}❌ Not installed${NC}")"
                echo -e "  Unit Test Tools: $([ "$UNIT_TEST_TOOLS_AVAILABLE" == true ] && echo -e "${GREEN}✅ Installed${NC}" || echo -e "${YELLOW}❌ Not installed${NC}")"
                echo ""
                echo -e "${YELLOW}Install missing tools:${NC}"
                echo "  apt install shellcheck cppcheck clang-format"
                echo "  go install github.com/mvdan/sh/v3/cmd/shfmt@latest"
                echo ""
                read -rp "  Press Enter to continue..."
                ;;
            8|q|Q) break ;;
            *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
        esac
    done
}

# Exportuj funkcję verify_menu dla głównego skryptu
export -f verify_menu 2>/dev/null || true
export -f verify_syntax_shell 2>/dev/null || true
export -f verify_syntax_cpp 2>/dev/null || true
export -f verify_security_scan 2>/dev/null || true
export -f verify_code_style 2>/dev/null || true
export -f verify_run_unit_tests 2>/dev/null || true
export -f verify_generate_report 2>/dev/null || true
