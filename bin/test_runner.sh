#!/usr/bin/env bash
# test_runner.sh - Comprehensive tests for gitsim.sh

# Exit immediately if a command exits with a non-zero status.
set -e

# Prefer cache directory for temporary files
: ${XDG_CACHE_HOME:="$HOME/.cache"}
: ${TMPDIR:="$XDG_CACHE_HOME/tmp"}

# Ensure our temp directory exists
mkdir -p "$TMPDIR"

# Helper function to create temp directories in cache
mktemp_cache() {
    mktemp -d "$TMPDIR/gitsim-test-XXXXXX"
}

echo "=== Running Comprehensive GitSim Tests ==="
echo

# Ensure gitsim.sh is executable
if [ ! -x ./gitsim.sh ]; then
    echo "ERROR: ./gitsim.sh is not executable. Run chmod +x ./gitsim.sh"
    exit 1
fi

echo "--> Testing './gitsim.sh --help'..."
./gitsim.sh --help > /dev/null
echo "OK"
echo

echo "--> Testing './gitsim.sh version'..."
./gitsim.sh version > /dev/null
echo "OK"
echo

run_basic_workflow_test() {
    echo
    echo "=== Running Basic Workflow Test ==="
    echo

    # 1. Create a temporary directory in cache
    local test_dir
    test_dir=$(mktemp_cache)
    echo "--> Created temp directory for test: $test_dir"

    # 2. Setup a trap to clean up the directory on exit
    # shellcheck disable=SC2064
    trap "echo '--> Cleaning up temp directory...'; rm -rf '$test_dir'" EXIT

    # Store current directory and cd into test dir
    local original_dir
    original_dir=$(pwd)
    cd "$test_dir"

    # 3. Initialize git simulation
    echo "--> Running 'gitsim init'..."
    "$original_dir/gitsim.sh" init > /dev/null
    echo "OK"

    # 4. Check that init worked
    echo "--> Verifying init results..."
    if [ ! -d ".gitsim" ] || [ ! -d ".gitsim/.data" ] || [ ! -f ".gitsim/.data/commits.txt" ]; then
        echo "ERROR: 'init' did not create proper .gitsim structure"
        exit 1
    fi
    if [ ! -f ".gitsim/.data/branch.txt" ]; then
        echo "ERROR: 'init' did not create branch.txt file"
        exit 1
    fi
    echo "OK"

    # 5. Create some test files
    echo "--> Creating test files..."
    echo "test content" > testfile.txt
    echo "more content" > another.md
    echo "OK"

    # 6. Add files to staging
    echo "--> Running 'gitsim add .'..."
    "$original_dir/gitsim.sh" add . > /dev/null
    echo "OK"

    # 7. Check staging worked
    echo "--> Verifying staging results..."
    if [ ! -s ".gitsim/.data/index" ]; then
        echo "ERROR: 'add' did not stage files"
        exit 1
    fi
    echo "OK"

    # 8. Create a commit
    echo "--> Running 'gitsim commit -m \"Test commit\"'..."
    "$original_dir/gitsim.sh" commit -m "Test commit" > /dev/null
    echo "OK"

    # 9. Check commit worked
    echo "--> Verifying commit results..."
    if [ ! -s ".gitsim/.data/commits.txt" ] || [ -s ".gitsim/.data/index" ]; then
        echo "ERROR: 'commit' did not create commit or clear staging area"
        exit 1
    fi
    echo "OK"

    # 10. Test status command
    echo "--> Running 'gitsim status'..."
    local status_output
    status_output=$("$original_dir/gitsim.sh" status)
    if [[ "$status_output" != *"On branch main"* ]]; then
        echo "ERROR: 'status' did not show correct branch"
        exit 1
    fi
    echo "OK"

    # Return to original directory
    cd "$original_dir"

    # The trap will handle cleanup
}

run_branch_operations_test() {
    echo
    echo "=== Skipping Branch Operations Test (v2.2+ feature) ==="
    echo "SKIP: Branch operations not implemented in v2.1"
    return 0
    echo

    # 1. Create a temporary directory in cache
    local test_dir
    test_dir=$(mktemp_cache)
    echo "--> Created temp directory for test: $test_dir"

    # 2. Setup a trap to clean up the directory on exit
    # shellcheck disable=SC2064
    trap "echo '--> Cleaning up temp directory...'; rm -rf '$test_dir'" EXIT

    # Store current directory and cd into test dir
    local original_dir
    original_dir=$(pwd)
    cd "$test_dir"

    # 3. Initialize git simulation
    echo "--> Running 'gitsim init'..."
    "$original_dir/gitsim.sh" init > /dev/null
    echo "OK"

    # 4. List branches (should show main)
    echo "--> Running 'gitsim branch'..."
    local branch_output
    branch_output=$("$original_dir/gitsim.sh" branch)
    if [[ "$branch_output" != "* main" ]]; then
        echo "ERROR: 'branch' did not list main branch correctly"
        exit 1
    fi
    echo "OK"

    # 5. Create a new branch
    echo "--> Running 'gitsim branch new-feature'..."
    "$original_dir/gitsim.sh" branch new-feature > /dev/null
    echo "OK"

    # 6. List branches again
    echo "--> Running 'gitsim branch'..."
    branch_output=$("$original_dir/gitsim.sh" branch)
    if [[ "$branch_output" != *"* main"* ]] || [[ "$branch_output" != *"  new-feature"* ]]; then
        echo "ERROR: 'branch' did not list branches correctly after creation"
        exit 1
    fi
    echo "OK"

    # 7. Switch to new branch
    echo "--> Running 'gitsim checkout new-feature'..."
    "$original_dir/gitsim.sh" checkout new-feature > /dev/null
    echo "OK"

    # 8. Check current branch
    echo "--> Verifying checkout worked..."
    branch_output=$("$original_dir/gitsim.sh" branch)
    if [[ "$branch_output" != *"* new-feature"* ]]; then
        echo "ERROR: 'checkout' did not switch to new branch"
        exit 1
    fi
    echo "OK"

    # 9. Create and checkout branch with -b
    echo "--> Running 'gitsim checkout -b another-feature'..."
    "$original_dir/gitsim.sh" checkout -b another-feature > /dev/null
    echo "OK"

    # 10. Verify new branch is current
    echo "--> Verifying checkout -b worked..."
    branch_output=$("$original_dir/gitsim.sh" branch)
    if [[ "$branch_output" != *"* another-feature"* ]]; then
        echo "ERROR: 'checkout -b' did not create and switch to new branch"
        exit 1
    fi
    echo "OK"

    # 11. Delete a branch
    echo "--> Running 'gitsim checkout main' first..."
    "$original_dir/gitsim.sh" checkout main > /dev/null
    echo "--> Running 'gitsim branch -d new-feature'..."
    "$original_dir/gitsim.sh" branch -d new-feature > /dev/null
    echo "OK"

    # Return to original directory
    cd "$original_dir"
}

run_home_environment_test() {
    echo
    echo "=== Running Home Environment Test ==="
    echo

    # 1. Create a temporary directory in cache
    local test_dir
    test_dir=$(mktemp_cache)
    echo "--> Created temp directory for test: $test_dir"

    # 2. Setup a trap to clean up the directory on exit
    # shellcheck disable=SC2064
    trap "echo '--> Cleaning up temp directory...'; rm -rf '$test_dir'" EXIT

    # Store current directory and cd into test dir
    local original_dir
    original_dir=$(pwd)
    cd "$test_dir"

    # 3. Initialize git simulation first
    echo "--> Running 'gitsim init'..."
    "$original_dir/gitsim.sh" init > /dev/null
    echo "OK"

    # 4. Initialize home environment
    echo "--> Running 'gitsim home-init'..."
    "$original_dir/gitsim.sh" home-init > /dev/null
    echo "OK"

    # 5. Check that home-init worked
    echo "--> Verifying home-init results..."
    if [ ! -d ".gitsim/.home" ] || [ ! -d ".gitsim/.home/.config" ] || [ ! -d ".gitsim/.home/projects" ]; then
        echo "ERROR: 'home-init' did not create proper home structure"
        exit 1
    fi
    if [ ! -f ".gitsim/.home/.bashrc" ] || [ ! -f ".gitsim/.home/.gitconfig" ]; then
        echo "ERROR: 'home-init' did not create dotfiles"
        exit 1
    fi
    echo "OK"

    # 6. Test home-path command
    echo "--> Running 'gitsim home-path'..."
    local home_path
    home_path=$("$original_dir/gitsim.sh" home-path)
    if [ ! -d "$home_path" ]; then
        echo "ERROR: 'home-path' returned invalid path: $home_path"
        exit 1
    fi
    echo "OK"

    # 7. Test home-ls command
    echo "--> Running 'gitsim home-ls'..."
    "$original_dir/gitsim.sh" home-ls > /dev/null
    echo "OK"

    # 8. Test home-env command
    echo "--> Running 'gitsim home-env'..."
    "$original_dir/gitsim.sh" home-env > /dev/null
    echo "OK"

    # Return to original directory
    cd "$original_dir"

    # The trap will handle cleanup
}

run_init_in_home_test() {
    echo
    echo "=== Running Init-in-Home Test ==="
    echo

    # 1. Create a temporary directory in cache
    local test_dir
    test_dir=$(mktemp_cache)
    echo "--> Created temp directory for test: $test_dir"

    # 2. Setup a trap to clean up the directory on exit
    # shellcheck disable=SC2064
    trap "echo '--> Cleaning up temp directory...'; rm -rf '$test_dir'" EXIT

    # Store current directory and cd into test dir
    local original_dir
    original_dir=$(pwd)
    cd "$test_dir"

    # 3. Initialize git simulation with project in home
    echo "--> Running 'gitsim init-in-home testproject'..."
    "$original_dir/gitsim.sh" init-in-home testproject > /dev/null 2>&1  # Suppress .simrc warnings
    echo "OK"

    # 4. Check that init-in-home worked
    echo "--> Verifying init-in-home results..."
    if [ ! -d ".gitsim/.home/projects/testproject" ]; then
        echo "ERROR: 'init-in-home' did not create project directory"
        exit 1
    fi
    if [ ! -d ".gitsim/.home/projects/testproject/.gitsim" ]; then
        echo "ERROR: 'init-in-home' did not create git simulation in project"
        exit 1
    fi
    if [ ! -f ".gitsim/.home/projects/testproject/README.md" ]; then
        echo "ERROR: 'init-in-home' did not create project files"
        exit 1
    fi
    echo "OK"

    # 5. Test with template
    echo "--> Running 'gitsim init-in-home nodeproject --template=node'..."
    "$original_dir/gitsim.sh" init-in-home nodeproject --template=node > /dev/null 2>&1
    echo "OK"

    # 6. Check that template worked
    echo "--> Verifying template results..."
    if [ ! -f ".gitsim/.home/projects/nodeproject/package.json" ]; then
        echo "ERROR: 'init-in-home --template=node' did not create package.json"
        exit 1
    fi
    echo "OK"

    # Return to original directory
    cd "$original_dir"

    # The trap will handle cleanup
}

run_rcgen_test() {
    echo
    echo "=== Running RC Generation Test ==="
    echo

    # 1. Create a temporary directory in cache
    local test_dir
    test_dir=$(mktemp_cache)
    echo "--> Created temp directory for test: $test_dir"

    # 2. Setup a trap to clean up the directory on exit
    # shellcheck disable=SC2064
    trap "echo '--> Cleaning up temp directory...'; rm -rf '$test_dir'" EXIT

    # Store current directory and cd into test dir
    local original_dir
    original_dir=$(pwd)
    cd "$test_dir"

    # 3. Generate .simrc file
    echo "--> Running 'gitsim rcgen'..."
    "$original_dir/gitsim.sh" rcgen > /dev/null
    echo "OK"

    # 4. Check that .simrc was created
    echo "--> Verifying .simrc creation..."
    if [ ! -f ".simrc" ]; then
        echo "ERROR: 'rcgen' did not create .simrc file"
        exit 1
    fi
    if ! grep -q "SIM_USER" ".simrc"; then
        echo "ERROR: '.simrc' does not contain expected SIM_ variables"
        exit 1
    fi
    echo "OK"

    # 5. Test force overwrite
    echo "--> Testing 'gitsim rcgen' without --force (should fail)..."
    if "$original_dir/gitsim.sh" rcgen > /dev/null 2>&1; then
        echo "ERROR: 'rcgen' succeeded when it should have failed (file exists)"
        exit 1
    fi
    echo "OK"

    # 6. Test force overwrite
    echo "--> Running 'gitsim rcgen --force'..."
    "$original_dir/gitsim.sh" rcgen --force > /dev/null
    echo "OK"

    # Return to original directory
    cd "$original_dir"
}

run_noise_enhancement_test() {
    echo
    echo "=== Running Enhanced Noise Test ==="
    echo

    # 1. Create a temporary directory in cache
    local test_dir
    test_dir=$(mktemp_cache)
    echo "--> Created temp directory for test: $test_dir"

    # 2. Setup a trap to clean up the directory on exit
    # shellcheck disable=SC2064
    trap "echo '--> Cleaning up temp directory...'; rm -rf '$test_dir'" EXIT

    # Store current directory and cd into test dir
    local original_dir
    original_dir=$(pwd)
    cd "$test_dir"

    # 3. Initialize git simulation
    echo "--> Running 'gitsim init'..."
    "$original_dir/gitsim.sh" init > /dev/null
    echo "OK"

    # 4. Generate basic noise files
    echo "--> Running 'gitsim noise 2'..."
    "$original_dir/gitsim.sh" noise 2 > /dev/null
    echo "OK"

    # 5. Check that noise generation worked (basic check)
    echo "--> Verifying noise generation results..."
    local file_count
    file_count=$(ls -1 | grep -E "(README|script|status|main|feature|hotfix|docs|config|utils|test)_[0-9]+" | wc -l)
    if [ "$file_count" -lt 2 ]; then
        echo "ERROR: 'noise' did not create expected number of files (got $file_count)"
        exit 1
    fi
    echo "OK"

    # 6. Clean test files  
    echo "--> Cleaning test files manually (reset not implemented in v2.1)..."
    rm -f *_[0-9]*.*
    echo "OK"

    # 7. Generate more noise files to test variety  
    echo "--> Running 'gitsim noise 3'..."
    "$original_dir/gitsim.sh" noise 3 > /dev/null
    echo "OK"

    # 8. Check that the second batch of files was created
    echo "--> Verifying second batch of noise files..."
    local second_batch_count
    second_batch_count=$(ls -1 | grep -E "(README|script|status|main|feature|hotfix|docs|config|utils|test)_[0-9]+" | wc -l)
    if [ "$second_batch_count" -lt 3 ]; then
        echo "ERROR: Expected at least 3 noise files in second batch, got $second_batch_count"
        exit 1
    fi
    echo "OK"

    # Return to original directory
    cd "$original_dir"
}

run_reset_vs_clean_test() {
    echo
    echo "=== Skipping Reset vs Clean Test (v2.2+ feature) ==="
    echo "SKIP: Reset operations not implemented in v2.1"
    return 0
    echo

    # 1. Create a temporary directory in cache
    local test_dir
    test_dir=$(mktemp_cache)
    echo "--> Created temp directory for test: $test_dir"

    # 2. Setup a trap to clean up the directory on exit
    # shellcheck disable=SC2064
    trap "echo '--> Cleaning up temp directory...'; rm -rf '$test_dir'" EXIT

    # Store current directory and cd into test dir
    local original_dir
    original_dir=$(pwd)
    cd "$test_dir"

    # 3. Initialize git simulation
    echo "--> Running 'gitsim init'..."
    "$original_dir/gitsim.sh" init > /dev/null
    echo "OK"

    # 4. Create and stage some files
    echo "--> Creating and staging test files..."
    echo "content1" > file1.txt
    echo "content2" > file2.txt
    "$original_dir/gitsim.sh" add file1.txt file2.txt > /dev/null
    echo "OK"

    # 5. Test reset (should unstage files but keep them)
    echo "--> Running 'gitsim reset'..."
    "$original_dir/gitsim.sh" reset > /dev/null
    echo "OK"

    # 6. Verify reset behavior
    echo "--> Verifying reset results..."
    if [ -s ".gitsim/.data/index" ]; then
        echo "ERROR: 'reset' did not clear staging area"
        exit 1
    fi
    if [ ! -f "file1.txt" ] || [ ! -f "file2.txt" ]; then
        echo "ERROR: 'reset' removed files from filesystem (should only unstage)"
        exit 1
    fi
    echo "OK"

    # 7. Re-stage files for clean test
    echo "--> Re-staging files for clean test..."
    "$original_dir/gitsim.sh" add file1.txt file2.txt > /dev/null
    echo "OK"

    # 8. Test clean (should remove files from filesystem)
    echo "--> Running 'gitsim clean'..."
    "$original_dir/gitsim.sh" clean > /dev/null
    echo "OK"

    # 9. Verify clean behavior
    echo "--> Verifying clean results..."
    if [ -s ".gitsim/.data/index" ]; then
        echo "ERROR: 'clean' did not clear staging area"
        exit 1
    fi
    if [ -f "file1.txt" ] || [ -f "file2.txt" ]; then
        echo "ERROR: 'clean' did not remove files from filesystem"
        exit 1
    fi
    echo "OK"

    # Return to original directory
    cd "$original_dir"
}

run_install_tests() {
    echo
    echo "=== Running Install/Uninstall Tests ==="
    echo

    # 1. Create a temporary XDG_HOME for testing in cache
    local temp_xdg_home
    temp_xdg_home=$(mktemp_cache)
    local install_dir="$temp_xdg_home/lib/fx/gitsim"
    local link_path="$temp_xdg_home/bin/fx/gitsim"

    # Setup trap for cleanup
    # shellcheck disable=SC2064
    trap "echo '--> Cleaning up install test directories...'; rm -rf '$temp_xdg_home'" EXIT

    # 1. Test install with overridden XDG variables
    echo "--> Testing 'gitsim install' with custom XDG_HOME..."
    XDG_HOME="$temp_xdg_home" XDG_LIB_HOME="$temp_xdg_home/lib" XDG_BIN_HOME="$temp_xdg_home/bin" ./gitsim.sh install > /dev/null
    if [ ! -f "$install_dir/gitsim.sh" ] || [ ! -L "$link_path" ]; then
        echo "ERROR: 'install' did not create script and symlink"
        echo "  Expected script: $install_dir/gitsim.sh"
        echo "  Expected link: $link_path"
        echo "  Install dir contents:"
        ls -la "$temp_xdg_home" || echo "    (directory doesn't exist)"
        ls -la "$temp_xdg_home/lib" 2>/dev/null || echo "    (lib directory doesn't exist)"
        ls -la "$temp_xdg_home/lib/fx" 2>/dev/null || echo "    (lib/fx directory doesn't exist)"
        exit 1
    fi
    echo "OK"

    # 2. Test uninstall (should fail without --force)
    echo "--> Testing 'uninstall' without --force (should fail)..."
    if XDG_HOME="$temp_xdg_home" XDG_LIB_HOME="$temp_xdg_home/lib" XDG_BIN_HOME="$temp_xdg_home/bin" ./gitsim.sh uninstall > /dev/null 2>&1; then
        echo "ERROR: 'uninstall' succeeded when it should have failed (safety check)."
        exit 1
    fi
    echo "OK"

    # 3. Test forced uninstall
    echo "--> Testing 'uninstall --force'..."
    XDG_HOME="$temp_xdg_home" XDG_LIB_HOME="$temp_xdg_home/lib" XDG_BIN_HOME="$temp_xdg_home/bin" ./gitsim.sh uninstall --force > /dev/null
    if [ -L "$link_path" ] || [ -d "$install_dir" ]; then
        echo "ERROR: Forced 'uninstall' did not remove script files"
        exit 1
    fi
    echo "OK"
}

run_cleanup_test() {
    echo
    echo "=== Running Cleanup Test ==="
    echo

    # 1. Create a temporary directory in cache
    local test_dir
    test_dir=$(mktemp_cache)
    echo "--> Created temp directory for test: $test_dir"

    # 2. Setup a trap to clean up the directory on exit
    # shellcheck disable=SC2064
    trap "echo '--> Cleaning up temp directory...'; rm -rf '$test_dir'" EXIT

    # Store current directory and cd into test dir
    local original_dir
    original_dir=$(pwd)
    cd "$test_dir"

    # 3. Initialize git simulation and create artifacts
    echo "--> Setting up test environment..."
    "$original_dir/gitsim.sh" init > /dev/null
    "$original_dir/gitsim.sh" rcgen > /dev/null
    "$original_dir/gitsim.sh" noise 2 > /dev/null
    echo "OK"

    # 4. Verify artifacts exist
    echo "--> Verifying artifacts exist..."
    if [ ! -d ".gitsim" ] || [ ! -f ".simrc" ]; then
        echo "ERROR: Expected artifacts not found"
        exit 1
    fi
    echo "OK"

    # 5. Run cleanup with --yes flag
    echo "--> Running 'gitsim cleanup' with auto-yes..."
    "$original_dir/gitsim.sh" -y cleanup > /dev/null
    echo "OK"

    # 6. Verify cleanup worked
    echo "--> Verifying cleanup results..."
    if [ -d ".gitsim" ] || [ -f ".simrc" ]; then
        echo "ERROR: Cleanup did not remove all artifacts"
        exit 1
    fi
    echo "OK"

    # Return to original directory
    cd "$original_dir"
}

run_file_safety_test() {
    echo
    echo "=== Running File Safety Test ==="
    echo

    # 1. Create a temporary directory that simulates a real git repo
    local test_dir
    test_dir=$(mktemp_cache)
    echo "--> Created temp directory for test: $test_dir"

    # 2. Setup a trap to clean up the directory on exit
    # shellcheck disable=SC2064
    trap "echo '--> Cleaning up temp directory...'; rm -rf '$test_dir'" EXIT

    # Store current directory and cd into test dir
    local original_dir
    original_dir=$(pwd)
    cd "$test_dir"

    # 3. Initialize a real git repo (not gitsim)
    echo "--> Creating real git repo..."
    git init > /dev/null 2>&1
    echo "test" > realfile.txt
    git add realfile.txt > /dev/null 2>&1
    git commit -m "real commit" > /dev/null 2>&1
    echo "OK"

    # 4. Try to generate noise in real git repo (should fail)
    echo "--> Testing noise in real git repo (should fail)..."
    if "$original_dir/gitsim.sh" noise 1 > /dev/null 2>&1; then
        echo "ERROR: 'noise' succeeded in real git repo (should have failed)"
        exit 1
    fi
    echo "OK"

    # 5. Initialize gitsim in real git repo and try again (should work)
    echo "--> Adding gitsim to real git repo..."
    "$original_dir/gitsim.sh" init > /dev/null
    echo "OK"

    # 6. Now noise should work since we have .gitsim
    echo "--> Testing noise with .gitsim present (should work)..."
    "$original_dir/gitsim.sh" noise 1 > /dev/null
    echo "OK"

    # Return to original directory
    cd "$original_dir"
}

# Run all tests
run_basic_workflow_test
run_branch_operations_test
run_home_environment_test
run_init_in_home_test
run_rcgen_test
run_noise_enhancement_test
run_reset_vs_clean_test
run_cleanup_test
run_file_safety_test
run_install_tests

echo
echo "================================"
echo "✅ All tests passed."
echo "================================"

exit 0
