################################################################################
# TESTSH Template Module
################################################################################

# Register this template with the core system
_register_template "testsh" "TESTSH-compliant comprehensive test suite" "testsh test-suite testing"

################################################################################
# TESTSH Template Implementation
################################################################################

# Main creation function (standard interface)
_create_testsh_template() {
    local target_dir="$1"
    local project_name="$2"

    # Create TESTSH project structure
    mkdir -p "$target_dir"
    mkdir -p "$target_dir"/{tests/{unit,sanity,smoke,integration,e2e,uat,chaos,bench,_adhoc},scripts}

    # Generate TESTSH project files
    __print_testsh_bootstrap_script "$target_dir/scripts/bootstrap-tests.sh" "$project_name"
    __print_testsh_main_runner "$target_dir/test.sh" "$project_name"
    __print_testsh_wrappers "$target_dir" "$project_name"
    __print_testsh_examples "$target_dir" "$project_name"
    __print_testsh_gitignore "$target_dir/.gitignore"
    __print_readme_md "$target_dir/README.md" "$project_name" "TESTSH"

    # Make scripts executable
    chmod +x "$target_dir/scripts/bootstrap-tests.sh"
    chmod +x "$target_dir/test.sh"
    chmod +x "$target_dir/tests/_adhoc"/*.sh 2>/dev/null || true

    trace "Created TESTSH project structure in $target_dir"
    return 0
}

# Template preview function
_show_testsh_template() {
    cat << 'EOF'
TESTSH project structure:
  test.sh                 - Main test runner with category support
  scripts/
    bootstrap-tests.sh    - Test structure generator
  tests/
    unit/                 - Unit test modules
    sanity/               - Sanity check tests
    smoke/                - Smoke test suite
    integration/          - Integration tests
    e2e/                  - End-to-end tests
    uat/                  - User acceptance tests
    chaos/                - Chaos engineering tests
    bench/                - Benchmark tests
    _adhoc/               - Ad-hoc test scripts
  README.md               - Test documentation

Features: Full TESTSH compliance, hierarchical test organization, multi-language support
EOF
}

################################################################################
# TESTSH File Generators
################################################################################

__print_testsh_bootstrap_script() {
    local file="$1"
    local name="$2"

    cat > "$file" << EOF
#!/usr/bin/env bash
# scripts/bootstrap-tests.sh - TESTSH Structure Generator
# Run from project root to initialize comprehensive test structure

set -euo pipefail

# Colors for output
readonly GREEN=\$'\\033[32m'
readonly BLUE=\$'\\033[34m'
readonly RESET=\$'\\033[0m'

info() { printf "%s[INFO]%s %s\\n" "\$BLUE" "\$RESET" "\$*"; }
okay() { printf "%s[OK]%s %s\\n" "\$GREEN" "\$RESET" "\$*"; }

cat_wrapper() {
    local name="\$1"; shift
    local lang="\${1:-rs}"

    case "\$lang" in
        rs|rust)
            cat > "tests/\${name}.rs" <<RUST_EOF
// Wrapper: \${name}.rs
fn main() {
    println!("placeholder for \${name}");
}
RUST_EOF
            ;;
        sh|bash)
            cat > "tests/\${name}.sh" <<BASH_EOF
#!/usr/bin/env bash
# Wrapper: \${name}.sh
echo "placeholder for \${name}"
BASH_EOF
            chmod +x "tests/\${name}.sh"
            ;;
        js|node)
            cat > "tests/\${name}.js" <<JS_EOF
// Wrapper: \${name}.js
console.log('placeholder for \${name}');
JS_EOF
            ;;
        py|python)
            cat > "tests/\${name}.py" <<PY_EOF
#!/usr/bin/env python3
# Wrapper: \${name}.py
print('placeholder for \${name}')
PY_EOF
            chmod +x "tests/\${name}.py"
            ;;
        *)
            cat > "tests/\${name}.txt" <<TXT_EOF
Placeholder for \${name}
TXT_EOF
            ;;
    esac
}

# Detect project language and set defaults
detect_language() {
    if [[ -f "Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "package.json" ]]; then
        echo "node"
    elif [[ -f "*.py" ]] || [[ -f "setup.py" ]] || [[ -f "requirements.txt" ]]; then
        echo "python"
    elif [[ -f "*.sh" ]] || [[ -f "build.sh" ]]; then
        echo "bash"
    else
        echo "generic"
    fi
}

main() {
    local lang="\${1:-\$(detect_language)}"

    info "Bootstrapping TESTSH structure for language: \$lang"

    # Ensure test directories exist
    mkdir -p tests/{unit,sanity,smoke,integration,e2e,uat,chaos,bench,_adhoc}

    # Create top-level wrappers
    info "Creating top-level test wrappers..."
    cat_wrapper "sanity" "\$lang"
    cat_wrapper "smoke" "\$lang"
    cat_wrapper "unit" "\$lang"
    cat_wrapper "integration" "\$lang"
    cat_wrapper "e2e" "\$lang"
    cat_wrapper "uat" "\$lang"
    cat_wrapper "chaos" "\$lang"
    cat_wrapper "bench" "\$lang"

    # Create category module examples
    info "Creating category examples..."
    case "\$lang" in
        rust)
            cat > tests/sanity/example.rs <<'RUST_EOF'
// sanity/example.rs
#[test]
fn sanity_example() {
    assert!(true);
}
RUST_EOF

            cat > tests/uat/example.rs <<'RUST_EOF'
// uat/example.rs
#[test]
fn uat_example() {
    assert!(true);
}
RUST_EOF
            ;;
        bash)
            cat > tests/sanity/example.sh <<'BASH_EOF'
#!/usr/bin/env bash
# sanity/example.sh
test_sanity_example() {
    return 0  # Pass
}
BASH_EOF
            chmod +x tests/sanity/example.sh

            cat > tests/uat/example.sh <<'BASH_EOF'
#!/usr/bin/env bash
# uat/example.sh
test_uat_example() {
    return 0  # Pass
}
BASH_EOF
            chmod +x tests/uat/example.sh
            ;;
        node)
            cat > tests/sanity/example.js <<'JS_EOF'
// sanity/example.js
describe('Sanity Tests', () => {
    it('should pass basic sanity check', () => {
        expect(true).toBe(true);
    });
});
JS_EOF

            cat > tests/uat/example.js <<'JS_EOF'
// uat/example.js
describe('UAT Tests', () => {
    it('should pass basic UAT check', () => {
        expect(true).toBe(true);
    });
});
JS_EOF
            ;;
        python)
            cat > tests/sanity/example.py <<'PY_EOF'
#!/usr/bin/env python3
# sanity/example.py
import unittest

class SanityTests(unittest.TestCase):
    def test_sanity_example(self):
        self.assertTrue(True)

if __name__ == '__main__':
    unittest.main()
PY_EOF
            chmod +x tests/sanity/example.py

            cat > tests/uat/example.py <<'PY_EOF'
#!/usr/bin/env python3
# uat/example.py
import unittest

class UATTests(unittest.TestCase):
    def test_uat_example(self):
        self.assertTrue(True)

if __name__ == '__main__':
    unittest.main()
PY_EOF
            chmod +x tests/uat/example.py
            ;;
    esac

    # Create adhoc skeleton
    info "Creating adhoc test skeleton..."
    cat > tests/_adhoc/demo.sh <<'ADHOC_EOF'
#!/usr/bin/env bash
# _adhoc/demo.sh - Example adhoc test
echo "adhoc demo test"
exit 0
ADHOC_EOF
    chmod +x tests/_adhoc/demo.sh

    okay "TESTSH structure bootstrapped successfully"
    info "Run '../test.sh list' to see available test categories"
}

main "\$@"
EOF
}

__print_testsh_main_runner() {
    local file="$1"
    local name="$2"

    cat > "$file" << EOF
#!/usr/bin/env bash
# test.sh - TESTSH-Compliant Test Runner for $name
#
# Supports hierarchical test execution across multiple categories
# Compatible with GitSim TESTSH architecture

set -e

# Configuration
readonly SCRIPT_NAME="test.sh"
readonly SCRIPT_VERSION="1.0.0"
readonly PROJECT_NAME="$name"

# Colors for output
readonly RED=\$'\\033[31m'
readonly GREEN=\$'\\033[32m'
readonly YELLOW=\$'\\033[33m'
readonly BLUE=\$'\\033[34m'
readonly RESET=\$'\\033[0m'

# Test categories in execution order
readonly TEST_CATEGORIES=(
    "sanity"
    "smoke"
    "unit"
    "integration"
    "e2e"
    "uat"
    "chaos"
    "bench"
)

# Logging functions
info() { printf "%s[INFO]%s %s\\n" "\$BLUE" "\$RESET" "\$*" >&2; }
okay() { printf "%s[OK]%s %s\\n" "\$GREEN" "\$RESET" "\$*" >&2; }
warn() { printf "%s[WARN]%s %s\\n" "\$YELLOW" "\$RESET" "\$*" >&2; }
error() { printf "%s[ERROR]%s %s\\n" "\$RED" "\$RESET" "\$*" >&2; }

# Test execution functions
run_category_tests() {
    local category="\$1"
    local test_dir="tests/\$category"
    local wrapper_file="tests/\$category"
    local tests_found=0
    local tests_passed=0

    info "Running \$category tests..."

    # Check for wrapper files (multiple extensions)
    local wrapper_found=false
    for ext in rs sh js py; do
        if [[ -f "\$wrapper_file.\$ext" ]]; then
            info "Executing wrapper: \$wrapper_file.\$ext"
            case "\$ext" in
                rs)
                    if command -v rustc >/dev/null; then
                        rustc "\$wrapper_file.\$ext" -o "/tmp/\$category" && "/tmp/\$category"
                        (( tests_found++ ))
                        [[ \$? -eq 0 ]] && (( tests_passed++ ))
                    else
                        warn "Rust compiler not found, skipping \$wrapper_file.\$ext"
                    fi
                    ;;
                sh)
                    bash "\$wrapper_file.\$ext"
                    (( tests_found++ ))
                    [[ \$? -eq 0 ]] && (( tests_passed++ ))
                    ;;
                js)
                    if command -v node >/dev/null; then
                        node "\$wrapper_file.\$ext"
                        (( tests_found++ ))
                        [[ \$? -eq 0 ]] && (( tests_passed++ ))
                    else
                        warn "Node.js not found, skipping \$wrapper_file.\$ext"
                    fi
                    ;;
                py)
                    if command -v python3 >/dev/null; then
                        python3 "\$wrapper_file.\$ext"
                        (( tests_found++ ))
                        [[ \$? -eq 0 ]] && (( tests_passed++ ))
                    else
                        warn "Python3 not found, skipping \$wrapper_file.\$ext"
                    fi
                    ;;
            esac
            wrapper_found=true
        fi
    done

    # Run individual test files in category directory
    if [[ -d "\$test_dir" ]]; then
        for test_file in "\$test_dir"/*; do
            [[ -f "\$test_file" ]] || continue
            [[ -x "\$test_file" ]] || continue

            info "Executing: \$(basename "\$test_file")"
            if "\$test_file"; then
                (( tests_passed++ ))
            fi
            (( tests_found++ ))
        done
    fi

    if [[ \$tests_found -eq 0 ]]; then
        warn "No tests found for category: \$category"
    else
        okay "\$category: \$tests_passed/\$tests_found tests passed"
    fi

    return \$(( tests_found - tests_passed ))
}

run_adhoc_tests() {
    local adhoc_dir="tests/_adhoc"
    local tests_found=0
    local tests_passed=0

    info "Running adhoc tests..."

    if [[ -d "\$adhoc_dir" ]]; then
        for test_file in "\$adhoc_dir"/*; do
            [[ -f "\$test_file" ]] || continue
            [[ -x "\$test_file" ]] || continue

            info "Executing adhoc: \$(basename "\$test_file")"
            if "\$test_file"; then
                (( tests_passed++ ))
            fi
            (( tests_found++ ))
        done
    fi

    if [[ \$tests_found -eq 0 ]]; then
        warn "No adhoc tests found"
    else
        okay "adhoc: \$tests_passed/\$tests_found tests passed"
    fi

    return \$(( tests_found - tests_passed ))
}

# Command implementations
cmd_list() {
    info "Available test categories:"
    for category in "\${TEST_CATEGORIES[@]}"; do
        local count=0
        local wrapper_exists=false

        # Check for wrapper files
        for ext in rs sh js py; do
            [[ -f "tests/\$category.\$ext" ]] && wrapper_exists=true
        done

        # Count individual test files
        if [[ -d "tests/\$category" ]]; then
            count=\$(find "tests/\$category" -type f -executable | wc -l)
        fi

        printf "  %-12s" "\$category"
        [[ "\$wrapper_exists" == true ]] && printf "[wrapper] "
        printf "(%d files)\\n" "\$count"
    done

    # Count adhoc tests
    local adhoc_count=0
    if [[ -d "tests/_adhoc" ]]; then
        adhoc_count=\$(find "tests/_adhoc" -type f -executable | wc -l)
    fi
    printf "  %-12s(%d files)\\n" "_adhoc" "\$adhoc_count"
}

cmd_run() {
    local category="\$1"

    if [[ -z "\$category" ]]; then
        # Run all categories
        local total_failures=0

        info "Running all test categories for \$PROJECT_NAME"

        for cat in "\${TEST_CATEGORIES[@]}"; do
            run_category_tests "\$cat" || (( total_failures++ ))
        done

        # Run adhoc tests
        run_adhoc_tests || (( total_failures++ ))

        if [[ \$total_failures -eq 0 ]]; then
            okay "All test categories passed!"
        else
            error "\$total_failures test categories had failures"
            return 1
        fi
    else
        # Run specific category
        if [[ " \${TEST_CATEGORIES[*]} " =~ " \$category " ]]; then
            run_category_tests "\$category"
        elif [[ "\$category" == "adhoc" ]]; then
            run_adhoc_tests
        else
            error "Unknown test category: \$category"
            info "Available categories: \${TEST_CATEGORIES[*]} adhoc"
            return 1
        fi
    fi
}

cmd_bootstrap() {
    local lang="\${1:-auto}"

    if [[ -f "scripts/bootstrap-tests.sh" ]]; then
        info "Running test structure bootstrap..."
        bash scripts/bootstrap-tests.sh "\$lang"
    else
        error "Bootstrap script not found: scripts/bootstrap-tests.sh"
        return 1
    fi
}

cmd_clean() {
    info "Cleaning test artifacts..."

    # Remove temporary files
    find tests/ -name "*.tmp" -delete 2>/dev/null || true
    rm -f /tmp/sanity /tmp/smoke /tmp/unit /tmp/integration /tmp/e2e /tmp/uat /tmp/chaos /tmp/bench

    okay "Test artifacts cleaned"
}

# Usage information
usage() {
    cat << USAGE_EOF
\$SCRIPT_NAME v\$SCRIPT_VERSION - TESTSH Test Runner for \$PROJECT_NAME

USAGE:
    \$SCRIPT_NAME <command> [args]

COMMANDS:
    list                   List all test categories and counts
    run [category]         Run tests (all categories if none specified)
    bootstrap [lang]       Initialize test structure (auto-detect language)
    clean                  Clean test artifacts and temporary files

TEST CATEGORIES:
    sanity, smoke, unit, integration, e2e, uat, chaos, bench, adhoc

EXAMPLES:
    \$SCRIPT_NAME list
    \$SCRIPT_NAME run
    \$SCRIPT_NAME run sanity
    \$SCRIPT_NAME bootstrap rust
    \$SCRIPT_NAME clean

USAGE_EOF
}

# Main execution
main() {
    case "\${1:-run}" in
        list|ls)
            cmd_list
            ;;
        run|test)
            shift
            cmd_run "\$@"
            ;;
        bootstrap|init)
            shift
            cmd_bootstrap "\$@"
            ;;
        clean)
            cmd_clean
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            error "Unknown command: \$1"
            usage
            return 1
            ;;
    esac
}

main "\$@"
EOF
}

__print_testsh_wrappers() {
    local target_dir="$1"
    local name="$2"

    # Create placeholder wrapper files for each category
    for category in sanity smoke unit integration e2e uat chaos bench; do
        cat > "$target_dir/tests/$category.sh" << EOF
#!/usr/bin/env bash
# tests/$category.sh - $category test wrapper for $name

echo "Running $category tests for $name"

# Add your $category test logic here
# This wrapper can coordinate multiple test files in tests/$category/

exit 0
EOF
        chmod +x "$target_dir/tests/$category.sh"
    done
}

__print_testsh_examples() {
    local target_dir="$1"
    local name="$2"

    # Create example test files
    cat > "$target_dir/tests/sanity/basic.sh" << EOF
#!/usr/bin/env bash
# tests/sanity/basic.sh - Basic sanity checks

test_project_structure() {
    [[ -f "README.md" ]] || { echo "README.md missing"; return 1; }
    [[ -d "tests" ]] || { echo "tests directory missing"; return 1; }
    echo "Project structure is sane"
    return 0
}

test_project_structure
EOF
    chmod +x "$target_dir/tests/sanity/basic.sh"

    cat > "$target_dir/tests/smoke/quick.sh" << EOF
#!/usr/bin/env bash
# tests/smoke/quick.sh - Quick smoke tests

test_basic_functionality() {
    echo "Running smoke test for $name"
    # Add basic functionality tests here
    return 0
}

test_basic_functionality
EOF
    chmod +x "$target_dir/tests/smoke/quick.sh"

    # Create adhoc demo
    cat > "$target_dir/tests/_adhoc/demo.sh" << EOF
#!/usr/bin/env bash
# tests/_adhoc/demo.sh - Demonstration adhoc test

echo "This is an adhoc test for $name"
echo "Adhoc tests are for one-off testing scenarios"
echo "They don't fit into standard test categories"

# Example: Test a specific bug fix or feature
exit 0
EOF
    chmod +x "$target_dir/tests/_adhoc/demo.sh"
}

__print_testsh_gitignore() {
    local file="$1"

    cat > "$file" << 'EOF'
# Test artifacts
tests/**/*.tmp
tests/**/*.log
/tmp/*test*

# Coverage reports
coverage/
*.coverage
.nyc_output/

# Test outputs
test-results/
junit.xml

# Language-specific test artifacts
target/debug/deps/*test*
node_modules/
__pycache__/
*.pyc
.pytest_cache/

EOF

    # Add common patterns
    __print_common_gitignore "$file"
}