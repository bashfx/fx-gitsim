#!/usr/bin/env bash

# test_git_sim.sh - Test suite for the git simulator
# Because we need to test the tester! 😅

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test setup
TEST_DIR="$(mktemp -d)"
ORIGINAL_DIR="$PWD"
GITSIM="$ORIGINAL_DIR/git_sim.sh"

cleanup() {
    cd "$ORIGINAL_DIR"
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

log_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
    TESTS_RUN=$((TESTS_RUN + 1))
}

assert_success() {
    if [[ $? -eq 0 ]]; then
        echo -e "  ${GREEN}✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "  ${RED}✗ FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_failure() {
    if [[ $? -ne 0 ]]; then
        echo -e "  ${GREEN}✓ PASS${NC} (expected failure)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "  ${RED}✗ FAIL${NC} (should have failed)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_file_exists() {
    if [[ -f "$1" ]]; then
        echo -e "  ${GREEN}✓ PASS${NC} File exists: $1"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "  ${RED}✗ FAIL${NC} File missing: $1"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_dir_exists() {
    if [[ -d "$1" ]]; then
        echo -e "  ${GREEN}✓ PASS${NC} Directory exists: $1"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "  ${RED}✗ FAIL${NC} Directory missing: $1"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_contains() {
    local content="$1"
    local expected="$2"
    if [[ "$content" == *"$expected"* ]]; then
        echo -e "  ${GREEN}✓ PASS${NC} Contains: '$expected'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "  ${RED}✗ FAIL${NC} Missing: '$expected'"
        echo "    Got: '$content'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test functions

test_basic_init() {
    log_test "Basic git init"
    cd "$TEST_DIR"
    mkdir basic_init && cd basic_init
    
    "$GITSIM" init > /dev/null
    assert_success
    
    TESTS_RUN=$((TESTS_RUN + 4))  # We'll check 4 things
    assert_dir_exists ".gitsim"
    assert_dir_exists ".gitsim/.data"
    assert_file_exists ".gitsim/.data/commits.txt"
    assert_file_exists ".gitsim/.data/HEAD"
}

test_home_init() {
    log_test "Home environment initialization"
    cd "$TEST_DIR"
    mkdir home_init && cd home_init
    
    "$GITSIM" init > /dev/null
    "$GITSIM" home-init > /dev/null
    assert_success
    
    TESTS_RUN=$((TESTS_RUN + 6))
    assert_dir_exists ".gitsim/.home"
    assert_dir_exists ".gitsim/.home/.config"
    assert_dir_exists ".gitsim/.home/.local"
    assert_dir_exists ".gitsim/.home/projects"
    assert_file_exists ".gitsim/.home/.bashrc"
    assert_file_exists ".gitsim/.home/.gitconfig"
}

test_init_in_home() {
    log_test "Init in home with project"
    cd "$TEST_DIR"
    mkdir init_in_home && cd init_in_home
    
    "$GITSIM" init > /dev/null
    "$GITSIM" init-in-home testproject > /dev/null
    assert_success
    
    TESTS_RUN=$((TESTS_RUN + 4))
    assert_dir_exists ".gitsim/.home/projects/testproject"
    assert_dir_exists ".gitsim/.home/projects/testproject/.gitsim"
    assert_file_exists ".gitsim/.home/projects/testproject/README.md"
    assert_file_exists ".gitsim/.home/projects/testproject/.gitignore"
}

test_commit_workflow() {
    log_test "Basic commit workflow"
    cd "$TEST_DIR"
    mkdir commit_test && cd commit_test
    
    "$GITSIM" init > /dev/null
    
    # Should fail with no staged files
    "$GITSIM" commit -m "Empty commit" 2>/dev/null
    assert_failure
    TESTS_RUN=$((TESTS_RUN - 1))  # Don't double count this test
    
    # Add some files
    echo "test content" > testfile.txt
    "$GITSIM" add testfile.txt
    "$GITSIM" commit -m "Initial commit" > /dev/null
    assert_success
    
    # Check commit was recorded
    TESTS_RUN=$((TESTS_RUN + 1))
    local commits_content
    commits_content=$(cat .gitsim/.data/commits.txt)
    assert_contains "$commits_content" "Initial commit"
}

test_branch_operations() {
    log_test "Branch operations"
    cd "$TEST_DIR"
    mkdir branch_test && cd branch_test
    
    "$GITSIM" init > /dev/null
    
    # Create a branch
    "$GITSIM" branch feature/test
    assert_success
    
    # List branches
    TESTS_RUN=$((TESTS_RUN + 1))
    local branches_output
    branches_output=$("$GITSIM" branch)
    assert_contains "$branches_output" "feature/test"
    
    # Switch to branch
    "$GITSIM" checkout feature/test > /dev/null
    assert_success
    
    # Check current branch
    TESTS_RUN=$((TESTS_RUN + 1))
    local current_branch
    current_branch=$(cat .gitsim/.data/branch.txt)
    assert_contains "$current_branch" "feature/test"
}

test_tag_operations() {
    log_test "Tag operations"
    cd "$TEST_DIR"
    mkdir tag_test && cd tag_test
    
    "$GITSIM" init > /dev/null
    
    # Create a commit first
    echo "content" > file.txt
    "$GITSIM" add file.txt
    "$GITSIM" commit -m "Test commit" > /dev/null
    
    # Create a tag
    "$GITSIM" tag v1.0.0
    assert_success
    
    # List tags
    TESTS_RUN=$((TESTS_RUN + 1))
    local tags_output
    tags_output=$("$GITSIM" tag)
    assert_contains "$tags_output" "v1.0.0"
}

test_noise_generation() {
    log_test "Noise file generation"
    cd "$TEST_DIR"
    mkdir noise_test && cd noise_test
    
    "$GITSIM" init > /dev/null
    "$GITSIM" noise 3 > /dev/null
    assert_success
    
    # Check files were created and staged
    TESTS_RUN=$((TESTS_RUN + 1))
    local index_content
    index_content=$(cat .gitsim/.data/index)
    local file_count
    file_count=$(echo "$index_content" | wc -l | tr -d ' ')
    
    if [[ "$file_count" -eq 3 ]]; then
        echo -e "  ${GREEN}✓ PASS${NC} Created 3 files"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "  ${RED}✗ FAIL${NC} Expected 3 files, got $file_count"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

test_history_generation() {
    log_test "History generation"
    cd "$TEST_DIR"
    mkdir history_test && cd history_test
    
    "$GITSIM" init > /dev/null
    "$GITSIM" history 5 2 > /dev/null
    assert_success
    
    # Check commits were created
    TESTS_RUN=$((TESTS_RUN + 1))
    local commit_count
    commit_count=$(wc -l < .gitsim/.data/commits.txt | tr -d ' ')
    
    if [[ "$commit_count" -eq 5 ]]; then
        echo -e "  ${GREEN}✓ PASS${NC} Created 5 commits"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "  ${RED}✗ FAIL${NC} Expected 5 commits, got $commit_count"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    # Check tags were created
    TESTS_RUN=$((TESTS_RUN + 1))
    local tag_count
    tag_count=$(wc -l < .gitsim/.data/tags.txt | tr -d ' ')
    
    if [[ "$tag_count" -eq 2 ]]; then
        echo -e "  ${GREEN}✓ PASS${NC} Created 2 tags"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "  ${RED}✗ FAIL${NC} Expected 2 tags, got $tag_count"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

test_home_paths() {
    log_test "Home path operations"
    cd "$TEST_DIR"
    mkdir home_paths && cd home_paths
    
    "$GITSIM" init > /dev/null
    "$GITSIM" home-init > /dev/null
    
    local home_path
    home_path=$("$GITSIM" home-path)
    assert_success
    
    # Verify path exists
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ -d "$home_path" ]]; then
        echo -e "  ${GREEN}✓ PASS${NC} Home path exists: $home_path"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "  ${RED}✗ FAIL${NC} Home path missing: $home_path"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    # Test home-ls
    "$GITSIM" home-ls > /dev/null
    assert_success
}

test_git_log_formats() {
    log_test "Git log formats"
    cd "$TEST_DIR"
    mkdir log_test && cd log_test
    
    "$GITSIM" init > /dev/null
    "$GITSIM" history 3 1 > /dev/null
    
    # Test regular log
    "$GITSIM" log > /dev/null
    assert_success
    
    # Test oneline log
    "$GITSIM" log --oneline > /dev/null
    assert_success
}

test_sim_variables() {
    log_test "SIM_ environment variables"
    
    # Test with custom variables
    cd "$TEST_DIR"
    mkdir sim_vars && cd sim_vars
    
    SIM_USER=testuser SIM_EDITOR=vim "$GITSIM" init > /dev/null
    SIM_USER=testuser SIM_EDITOR=vim "$GITSIM" home-init > /dev/null
    assert_success
    
    # Check .gitconfig has custom user
    TESTS_RUN=$((TESTS_RUN + 1))
    local gitconfig_content
    gitconfig_content=$(cat .gitsim/.home/.gitconfig)
    assert_contains "$gitconfig_content" "testuser"
}

test_error_conditions() {
    log_test "Error conditions"
    cd "$TEST_DIR"
    mkdir error_test && cd error_test
    
    # Should fail without init
    "$GITSIM" status 2>/dev/null
    assert_failure
    TESTS_RUN=$((TESTS_RUN - 1))  # Don't double count
    
    "$GITSIM" init > /dev/null
    
    # Should fail with duplicate tag
    echo "content" > file.txt
    "$GITSIM" add file.txt
    "$GITSIM" commit -m "Test" > /dev/null
    "$GITSIM" tag v1.0.0 > /dev/null
    "$GITSIM" tag v1.0.0 2>/dev/null
    assert_failure
    TESTS_RUN=$((TESTS_RUN - 1))
}

# Main execution
main() {
    echo "🧪 Testing the Git Simulator"
    echo "Test directory: $TEST_DIR"
    echo "Git simulator: $GITSIM"
    echo ""
    
    if [[ ! -f "$GITSIM" ]]; then
        echo -e "${RED}Error: git_sim.sh not found at $GITSIM${NC}"
        exit 1
    fi
    
    # Make it executable
    chmod +x "$GITSIM"
    
    # Run all tests
    test_basic_init
    test_home_init
    test_init_in_home
    test_commit_workflow
    test_branch_operations
    test_tag_operations
    test_noise_generation
    test_history_generation
    test_home_paths
    test_git_log_formats
    test_sim_variables
    test_error_conditions
    
    # Summary
    echo ""
    echo "📊 Test Summary"
    echo "==============="
    echo -e "Tests run:    ${YELLOW}$TESTS_RUN${NC}"
    echo -e "Passed:       ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed:       ${RED}$TESTS_FAILED${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n🎉 ${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "\n💥 ${RED}Some tests failed!${NC}"
        exit 1
    fi
}

main "$@"
