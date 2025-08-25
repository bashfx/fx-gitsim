#!/usr/bin/env bash
# test_runner.sh - Basic and E2E tests for gitsim.sh

# Exit immediately if a command exits with a non-zero status.
set -e

: ${GITSIM_TEST_DIR:="$HOME/.cache/gitsim/test"}

# Helper function to create a temporary test directory
setup_test_dir() {
    mkdir -p "$GITSIM_TEST_DIR"
    local test_dir
    test_dir=$(mktemp -d "$GITSIM_TEST_DIR/gitsim-test.XXXXXX")
    echo "$test_dir"
}


echo "=== Running Basic GitSim Tests ==="
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

    # 1. Create a temporary directory
    local test_dir
    test_dir=$(setup_test_dir)
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
    "$original_dir/gitsim.sh" status > /dev/null
    echo "OK"

    # Return to original directory
    cd "$original_dir"

    # The trap will handle cleanup
}

run_home_environment_test() {
    echo
    echo "=== Running Home Environment Test ==="
    echo

    # 1. Create a temporary directory
    local test_dir
    test_dir=$(setup_test_dir)
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

    # 1. Create a temporary directory
    local test_dir
    test_dir=$(setup_test_dir)
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
    "$original_dir/gitsim.sh" init-in-home testproject > /dev/null
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

    # Return to original directory
    cd "$original_dir"

    # The trap will handle cleanup
}

run_noise_generation_test() {
    echo
    echo "=== Running Noise Generation Test ==="
    echo

    # 1. Create a temporary directory
    local test_dir
    test_dir=$(setup_test_dir)
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

    # 4. Generate noise files
    echo "--> Running 'gitsim noise 3'..."
    "$original_dir/gitsim.sh" noise 3 > /dev/null
    echo "OK"

    # 5. Check that noise generation worked
    echo "--> Verifying noise generation results..."
    local file_count
    file_count=$(wc -l < .gitsim/.data/index | tr -d ' ')
    if [ "$file_count" -ne 3 ]; then
        echo "ERROR: 'noise' did not create exactly 3 files (got $file_count)"
        exit 1
    fi
    # Check that actual files were created
    local actual_files
    actual_files=$(find . -maxdepth 1 -type f ! -name ".gitignore" | wc -l | tr -d ' ')
    if [ "$actual_files" -lt 3 ]; then
        echo "ERROR: 'noise' did not create actual files on filesystem"
        exit 1
    fi
    echo "OK"

    # Return to original directory
    cd "$original_dir"

    # The trap will handle cleanup
}

run_sim_variables_test() {
    echo
    echo "=== Running SIM Variables Test ==="
    echo

    # Test home-vars command
    echo "--> Testing 'gitsim home-vars'..."
    ./gitsim.sh home-vars > /dev/null
    echo "OK"

    # Test with custom SIM variables
    echo "--> Testing with custom SIM_USER..."
    local test_dir
    test_dir=$(setup_test_dir)
    # shellcheck disable=SC2064
    trap "rm -rf '$test_dir'" EXIT
    
    local original_dir
    original_dir=$(pwd)
    cd "$test_dir"

    # Initialize with custom variables
    SIM_USER=testuser SIM_EDITOR=vim "$original_dir/gitsim.sh" init > /dev/null
    SIM_USER=testuser SIM_EDITOR=vim "$original_dir/gitsim.sh" home-init > /dev/null
    
    # Check that custom variables were used
    if ! grep -q "testuser" .gitsim/.home/.gitconfig; then
        echo "ERROR: Custom SIM_USER was not applied to .gitconfig"
        exit 1
    fi
    if ! grep -q "vim" .gitsim/.home/.gitconfig; then
        echo "ERROR: Custom SIM_EDITOR was not applied to .gitconfig"
        exit 1
    fi
    echo "OK"

    cd "$original_dir"
}

run_install_tests() {
    echo
    echo "=== Running Install/Uninstall Tests ==="
    echo

    # Define paths for clarity (using temporary directories to avoid conflicts)
    local temp_xdg_home
    temp_xdg_home=$(setup_test_dir)
    local install_dir="$temp_xdg_home/lib/fx/gitsim"
    local link_path="$temp_xdg_home/bin/fx/gitsim"

    # Setup trap for cleanup
    # shellcheck disable=SC2064
    trap "echo '--> Cleaning up install test directories...'; rm -rf '$temp_xdg_home'" EXIT

    # Override XDG paths for testing
    export XDG_HOME="$temp_xdg_home"

    # 1. Test install
    echo "--> Testing 'gitsim install'..."
    ./gitsim.sh install > /dev/null
    if [ ! -f "$install_dir/gitsim.sh" ] || [ ! -L "$link_path" ]; then
        echo "ERROR: 'install' did not create script and symlink"
        echo "  Expected script: $install_dir/gitsim.sh"
        echo "  Expected link: $link_path"
        exit 1
    fi
    echo "OK"

    # 2. Test uninstall
    echo "--> Testing 'uninstall'..."
    local installed_gitsim="$install_dir/gitsim.sh"
    if ! "$installed_gitsim" uninstall > /dev/null 2>&1; then
        echo "OK: uninstall failed without --force, as expected"
    else
        echo "ERROR: 'uninstall' succeeded when it should have failed (safety check)."
        exit 1
    fi

    local uninstall_output
    uninstall_output=$("$installed_gitsim" --force uninstall)
    if [[ "$uninstall_output" == "[OK] Uninstalled gitsim successfully" ]]; then
        echo "OK: uninstall --force succeeded"
    else
        echo "ERROR: 'uninstall --force' failed with output: $uninstall_output"
        exit 1
    fi

    if [ ! -L "$link_path" ] && [ ! -d "$install_dir" ]; then
        echo "OK: uninstalled files are gone"
    else
        echo "ERROR: Forced 'uninstall' did not remove script files"
        exit 1
    fi

    # Restore environment
    unset XDG_HOME
}

run_error_conditions_test() {
    echo
    echo "=== Running Error Conditions Test ==="
    echo

    # 1. Create a temporary directory
    local test_dir
    test_dir=$(setup_test_dir)
    echo "--> Created temp directory for test: $test_dir"

    # 2. Setup a trap to clean up the directory on exit
    # shellcheck disable=SC2064
    trap "echo '--> Cleaning up temp directory...'; rm -rf '$test_dir'" EXIT

    # Store current directory and cd into test dir
    local original_dir
    original_dir=$(pwd)
    cd "$test_dir"

    # 3. Test commands without init (should fail)
    echo "--> Testing commands without init (should fail)..."
    if ! "$original_dir/gitsim.sh" status > /dev/null 2>&1; then
        echo "OK"
    else
        echo "ERROR: 'status' succeeded when it should have failed (no .gitsim)"
        exit 1
    fi
    if ! "$original_dir/gitsim.sh" add testfile > /dev/null 2>&1; then
        echo "OK"
    else
        echo "ERROR: 'add' succeeded when it should have failed (no .gitsim)"
        exit 1
    fi

    # 4. Test commit without staged files
    echo "--> Testing commit without staged files (should fail)..."
    "$original_dir/gitsim.sh" init > /dev/null
    if ! "$original_dir/gitsim.sh" commit -m "empty" > /dev/null 2>&1; then
        echo "OK"
    else
        echo "ERROR: 'commit' succeeded when it should have failed (nothing staged)"
        exit 1
    fi

    # 5. Test home commands without home-init
    echo "--> Testing home commands without home-init (should fail)..."
    if ! "$original_dir/gitsim.sh" home-ls > /dev/null 2>&1; then
        echo "OK"
    else
        echo "ERROR: 'home-ls' succeeded when it should have failed (no home)"
        exit 1
    fi

    # Return to original directory
    cd "$original_dir"

    # The trap will handle cleanup
}

run_clean_test() {

    echo
    echo "=== Running Clean Test ==="
    echo

    # 1. Create a temporary directory
    local test_dir
    test_dir=$(setup_test_dir)
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

    # 4. Generate noise files
    echo "--> Running 'gitsim noise 5'..."
    "$original_dir/gitsim.sh" noise 5 > /dev/null
    echo "OK"

    # 5. Check that noise generation worked
    echo "--> Verifying noise generation results..."
    local file_count
    file_count=$(wc -l < .gitsim/.data/index | tr -d ' ')
    if [ "$file_count" -ne 5 ]; then
        echo "ERROR: 'noise' did not create exactly 5 files (got $file_count)"
        exit 1
    fi
    echo "OK"

    # 6. Run clean command
    echo "--> Running 'gitsim clean'..."
    "$original_dir/gitsim.sh" clean > /dev/null
    echo "OK"

    # 7. Check that clean worked
    echo "--> Verifying clean results..."
    if [ -s ".gitsim/.data/index" ]; then
        echo "ERROR: 'clean' did not clear staging area"
        exit 1
    fi
    local actual_files
    actual_files=$(find . -maxdepth 1 -type f ! -name ".gitignore" | wc -l | tr -d ' ')
    if [ "$actual_files" -ne 0 ]; then
        echo "ERROR: 'clean' did not remove files from filesystem (found $actual_files files)"
        exit 1
    fi
    echo "OK"

    # Return to original directory
    cd "$original_dir"
}

run_branch_test() {
    echo
    echo "=== Running Branch Test ==="
    echo

    # 1. Create a temporary directory
    local test_dir
    test_dir=$(setup_test_dir)
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

    # 4. List branches
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
    expected_output="* main"$'\n'"  new-feature"
    if [[ "$branch_output" != "$expected_output" ]]; then
        echo "ERROR: 'branch' did not list new branch correctly"
        exit 1
    fi
    echo "OK"

    # 7. Delete a branch
    echo "--> Running 'gitsim branch -d new-feature'..."
    "$original_dir/gitsim.sh" branch -d new-feature > /dev/null
    echo "OK"

    # 8. List branches again
    echo "--> Running 'gitsim branch'..."
    branch_output=$("$original_dir/gitsim.sh" branch)
    if [[ "$branch_output" != "* main" ]]; then
        echo "ERROR: 'branch' did not delete branch correctly"
        exit 1
    fi
    echo "OK"

    # 9. Try to delete current branch (should fail)
    echo "--> Running 'gitsim branch -d main' (should fail)..."
    if ! "$original_dir/gitsim.sh" branch -d main > /dev/null 2>&1; then
        echo "OK"
    else
        echo "ERROR: 'branch -d main' succeeded when it should have failed"
        exit 1
    fi

    # Return to original directory
    cd "$original_dir"
}

run_checkout_test() {
    echo
    echo "=== Running Checkout Test ==="

    echo

    # 1. Create a temporary directory
    local test_dir
    test_dir=$(setup_test_dir)
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

    # 4. Create a new branch
    echo "--> Running 'gitsim branch new-feature'..."
    "$original_dir/gitsim.sh" branch new-feature > /dev/null
    echo "OK"

    # 5. Checkout the new branch
    echo "--> Running 'gitsim checkout new-feature'..."
    "$original_dir/gitsim.sh" checkout new-feature > /dev/null
    echo "OK"

    # 6. Check that the current branch is new-feature
    echo "--> Running 'gitsim branch'..."
    local branch_output
    branch_output=$("$original_dir/gitsim.sh" branch)
    if ! echo "$branch_output" | grep -q '^* new-feature$'; then
        echo "ERROR: 'checkout' did not switch to the new branch"
        exit 1
    fi
    echo "OK"

    # 7. Checkout back to main
    echo "--> Running 'gitsim checkout main'..."
    "$original_dir/gitsim.sh" checkout main > /dev/null
    echo "OK"

    # 8. Check that the current branch is main
    echo "--> Running 'gitsim branch'..."
    branch_output=$("$original_dir/gitsim.sh" branch)
    if ! echo "$branch_output" | grep -q '^* main$'; then
        echo "ERROR: 'checkout' did not switch back to main"
        exit 1
    fi
    echo "OK"

    # 9. Create and checkout a new branch with -b
    echo "--> Running 'gitsim checkout -b another-feature'..."
    "$original_dir/gitsim.sh" checkout -b another-feature > /dev/null
    echo "OK"

    # 10. Check that the current branch is another-feature
    echo "--> Running 'gitsim branch'..."
    branch_output=$("$original_dir/gitsim.sh" branch)
    if ! echo "$branch_output" | grep -q '^* another-feature$'; then
        echo "ERROR: 'checkout -b' did not switch to the new branch"

        exit 1
    fi
    echo "OK"

    # Return to original directory
    cd "$original_dir"
}

run_tag_test() {
    echo
    echo "=== Running Tag Test ==="
    echo

    # 1. Create a temporary directory
    local test_dir
    test_dir=$(setup_test_dir)
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

    # 4. Create a new tag
    echo "--> Running 'gitsim tag v1.0.0'..."
    "$original_dir/gitsim.sh" tag v1.0.0 > /dev/null
    echo "OK"

    # 5. List tags
    echo "--> Running 'gitsim tag'..."
    local tag_output
    tag_output=$("$original_dir/gitsim.sh" tag)
    if [[ "$tag_output" != "v1.0.0" ]]; then
        echo "ERROR: 'tag' did not list new tag correctly"
        exit 1
    fi
    echo "OK"

    # 6. Create another tag
    echo "--> Running 'gitsim tag v1.1.0'..."
    "$original_dir/gitsim.sh" tag v1.1.0 > /dev/null
    echo "OK"

    # 7. List tags again
    echo "--> Running 'gitsim tag'..."
    tag_output=$("$original_dir/gitsim.sh" tag)
    expected_output="v1.0.0"$'\n'"v1.1.0"
    if [[ "$tag_output" != "$expected_output" ]]; then
        echo "ERROR: 'tag' did not list new tag correctly"
        exit 1
    fi
    echo "OK"

    # 8. Delete a tag
    echo "--> Running 'gitsim tag -d v1.0.0'..."
    "$original_dir/gitsim.sh" tag -d v1.0.0 > /dev/null
    echo "OK"

    # 9. List tags again
    echo "--> Running 'gitsim tag'..."
    tag_output=$("$original_dir/gitsim.sh" tag)
    if [[ "$tag_output" != "v1.1.0" ]]; then
        echo "ERROR: 'tag' did not delete tag correctly"
        exit 1
    fi
    echo "OK"

    # Return to original directory
    cd "$original_dir"
}

run_reset_test() {
    echo
    echo "=== Running Reset Test ==="
    echo

    # 1. Create a temporary directory
    local test_dir
    test_dir=$(setup_test_dir)
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

    # 4. Generate noise files
    echo "--> Running 'gitsim noise 5'..."
    "$original_dir/gitsim.sh" noise 5 > /dev/null
    echo "OK"

    # 5. Run reset command
    echo "--> Running 'gitsim reset'..."
    "$original_dir/gitsim.sh" reset > /dev/null
    echo "OK"

    # 6. Check that reset worked
    echo "--> Verifying reset results..."
    if [ -s ".gitsim/.data/index" ]; then
        echo "ERROR: 'reset' did not clear staging area"

        exit 1
    fi
    local actual_files
    actual_files=$(find . -maxdepth 1 -type f ! -name ".gitignore" | wc -l | tr -d ' ')
    if [ "$actual_files" -ne 0 ]; then

        echo "ERROR: 'reset' did not remove files from filesystem (found $actual_files files)"
        exit 1
    fi
    echo "OK"

    # Return to original directory
    cd "$original_dir"
}

run_template_test() {
    echo
    echo "=== Running Template Test ==="
    echo

    # 1. Create a temporary directory
    local test_dir
    test_dir=$(setup_test_dir)
    echo "--> Created temp directory for test: $test_dir"

    # 2. Setup a trap to clean up the directory on exit
    # shellcheck disable=SC2064
    trap "echo '--> Cleaning up temp directory...'; rm -rf '$test_dir'" EXIT

    # Store current directory and cd into test dir
    local original_dir
    original_dir=$(pwd)
    cd "$test_dir"

    # 3. Initialize git simulation in home with node template
    echo "--> Running 'gitsim init-in-home my-node-app --template=node'..."
    "$original_dir/gitsim.sh" init-in-home my-node-app --template=node > /dev/null
    echo "OK"

    # 4. Check that the template was created correctly
    echo "--> Verifying template results..."
    local project_dir
    project_dir="$test_dir/.gitsim/.home/projects/my-node-app"
    if [ ! -f "$project_dir/package.json" ]; then
        echo "ERROR: 'init-in-home --template=node' did not create package.json"
        exit 1
    fi
    echo "OK"

    # 5. Initialize git simulation in home with rust template
    echo "--> Running 'gitsim init-in-home my-rust-app --template=rust'..."
    "$original_dir/gitsim.sh" init-in-home my-rust-app --template=rust > /dev/null
    echo "OK"

    # 6. Check that the template was created correctly
    echo "--> Verifying template results..."
    project_dir="$test_dir/.gitsim/.home/projects/my-rust-app"
    if [ ! -f "$project_dir/Cargo.toml" ] || [ ! -d "$project_dir/src" ] || [ ! -f "$project_dir/src/main.rs" ]; then
        echo "ERROR: 'init-in-home --template=rust' did not create rust project structure"
        exit 1
    fi
    echo "OK"

    # 7. Initialize git simulation in home with python template
    echo "--> Running 'gitsim init-in-home my-python-app --template=python'..."
    "$original_dir/gitsim.sh" init-in-home my-python-app --template=python > /dev/null
    echo "OK"

    # 8. Check that the template was created correctly
    echo "--> Verifying template results..."
    project_dir="$test_dir/.gitsim/.home/projects/my-python-app"
    if [ ! -f "$project_dir/requirements.txt" ] || [ ! -f "$project_dir/main.py" ]; then
        echo "ERROR: 'init-in-home --template=python' did not create python project structure"
        exit 1
    fi
    echo "OK"

    # Return to original directory
    cd "$original_dir"
}

run_noise_enhancement_test() {
    echo
    echo "=== Running Noise Enhancement Test ==="
    echo

    # 1. Create a temporary directory
    local test_dir
    test_dir=$(setup_test_dir)
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

    # 4. Generate js noise files
    echo "--> Running 'gitsim noise 3 --type=js'..."
    "$original_dir/gitsim.sh" noise 3 --type=js > /dev/null
    echo "OK"

    # 5. Check that js noise generation worked
    echo "--> Verifying js noise generation results..."
    if ! ls script_1.js > /dev/null 2>&1 || ! ls script_2.js > /dev/null 2>&1 || ! ls script_3.js > /dev/null 2>&1; then
        echo "ERROR: 'noise --type=js' did not create js files"
        exit 1
    fi
    if ! grep -q "console.log" script_1.js; then
        echo "ERROR: 'noise --type=js' did not create correct content"
        exit 1
    fi
    echo "OK"

    # 6. Clean the staging area
    "$original_dir/gitsim.sh" clean > /dev/null

    # 7. Generate py noise files
    echo "--> Running 'gitsim noise 2 --type=py'..."
    "$original_dir/gitsim.sh" noise 2 --type=py > /dev/null
    echo "OK"

    # 8. Check that py noise generation worked
    echo "--> Verifying py noise generation results..."
    if ! ls script_1.py > /dev/null 2>&1 || ! ls script_2.py > /dev/null 2>&1; then
        echo "ERROR: 'noise --type=py' did not create py files"
        exit 1
    fi
    if ! grep -q "print" script_1.py; then
        echo "ERROR: 'noise --type=py' did not create correct content"

        exit 1
    fi
    echo "OK"

    # Return to original directory
    cd "$original_dir"
}

# Run all tests
run_basic_workflow_test
run_home_environment_test
run_init_in_home_test
run_noise_generation_test
run_sim_variables_test
run_install_tests
run_error_conditions_test
run_clean_test
run_branch_test
run_checkout_test
run_tag_test
run_reset_test
run_template_test
run_noise_enhancement_test


echo
echo "================================"
echo "✅ All tests passed."
echo "================================"

exit 0
