################################################################################
# Helper Functions
################################################################################

# Print logo from figlet block
_logo() {
    local show_logo="${1:-true}"
    
    if [[ "$show_logo" == "false" ]]; then
        return 0
    fi
    
    cat << 'EOF'
┌─┐┬┌┬┐┌─┐┬┌┬┐
│ ┬│ │ └─┐││││
└─┘┴ ┴ └─┘┴┴ ┴
EOF
}

# Create a temporary directory in user's cache instead of /tmp
_mktemp_dir() {
    local temp_base="${XDG_CACHE_HOME}/gitsim-tmp"
    mkdir -p "$temp_base"
    mktemp -d "$temp_base/XXXXXX"
}

# Find the root of the simulated repository by searching upwards for .gitsim
_find_sim_root() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.gitsim" ]; then
            printf "%s" "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}

# Get the simulated home directory path
_get_sim_home() {
    local sim_root="$1"
    printf "%s" "$sim_root/.gitsim/.home"
}

# Get the simulated project directory
_get_sim_project_dir() {
    local home_dir="$1"
    local project_name="${2:-testproject}"
    printf "%s" "$home_dir/projects/$project_name"
}

# Safety check: ensure we're in a safe location for file generation
_is_safe_for_generation() {
    local current_dir="$PWD"
    
    # Safe if we're in a .gitsim directory structure
    if [[ "$current_dir" == *"/.gitsim/"* ]] || [[ "$current_dir" == *"/.gitsim" ]]; then
        return 0
    fi
    
    # Safe if we have a .gitsim directory (our simulation root)
    if [[ -d ".gitsim" ]]; then
        return 0
    fi
    
    # Unsafe if we're in a real git repo without .gitsim
    if [[ -d ".git" ]] && [[ ! -d ".gitsim" ]]; then
        return 1
    fi
    
    # Default to safe for other cases
    return 0
}