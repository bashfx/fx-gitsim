################################################################################
# Git Simulation Functions
################################################################################

# Initialize git simulation structure
__create_git_structure() {
    local data_dir="$1"
    local ret=1
    
    if mkdir -p "$data_dir"; then
        touch "$data_dir"/{tags.txt,commits.txt,config,index,branches.txt,remotes.txt,HEAD}
        echo "main" > "$data_dir/branch.txt"
        echo "main" >> "$data_dir/branches.txt"
        ret=0
    fi
    
    return "$ret"
}

# Add .gitignore entry safely
__add_gitignore_entry() {
    local entry="$1"
    local gitignore_file=".gitignore"
    
    if ! grep -q "^${entry}$" "$gitignore_file" 2>/dev/null; then
        echo "$entry" >> "$gitignore_file"
    fi
    return 0
}

################################################################################
# Home Environment Setup - Proper Function Ordinality
################################################################################

# Mid-Ordinal: Home environment orchestrator (no literal operations)
_setup_home_env() {
    local home_dir="$1"
    
    # Orchestrate directory creation
    _create_home_directories "$home_dir" || return 1
    
    # Orchestrate dotfile generation
    _create_home_dotfiles "$home_dir" || return 1
    
    # Orchestrate sample file generation
    _create_sample_files "$home_dir" || return 1
    
    trace "Successfully set up home environment at $home_dir"
    return 0
}

# Mid-Ordinal: Directory structure creation
_create_home_directories() {
    local home_dir="$1"
    
    if mkdir -p "$home_dir"/{.config,.local/{bin,share,state},.cache,projects,Documents,Downloads}; then
        trace "Created home directory structure"
        return 0
    else
        error "Failed to create home directory structure"
        return 1
    fi
}

# Mid-Ordinal: Dotfiles generation orchestrator
_create_home_dotfiles() {
    local home_dir="$1"
    
    # Call low-ordinal print functions for each dotfile
    __print_bashrc "$home_dir/.bashrc" "$home_dir" || {
        error "Failed to create .bashrc"
        return 1
    }
    
    __print_profile "$home_dir/.profile" || {
        error "Failed to create .profile" 
        return 1
    }
    
    __print_gitconfig "$home_dir/.gitconfig" "$SIM_USER" "$SIM_EDITOR" || {
        error "Failed to create .gitconfig"
        return 1
    }
    
    trace "Created dotfiles in $home_dir"
    return 0
}

# Mid-Ordinal: Sample files creation orchestrator  
_create_sample_files() {
    local home_dir="$1"
    
    # Create configuration samples
    __print_sample_config "$home_dir/.config/testrc" || return 1
    __print_sample_data "$home_dir/.local/share/testdata" || return 1
    __print_sample_state "$home_dir/.local/state/teststate" || return 1
    __print_sample_cache "$home_dir/.cache/testcache" || return 1
    
    # Create document samples
    __print_sample_readme "$home_dir/Documents/README.md" || return 1
    __print_sample_download "$home_dir/Downloads/sample.txt" || return 1
    
    trace "Created sample files in $home_dir"
    return 0
}

################################################################################
# Low-Ordinal: Literal File Generation Functions
################################################################################

# Generate .bashrc content
__print_bashrc() {
    local file="$1"
    local home_path="$2"
    
    cat > "$file" << EOF
# Simulated .bashrc for testing
export USER="$SIM_USER"
export HOME="$home_path"
export SHELL="$SIM_SHELL"
export EDITOR="$SIM_EDITOR"
export LANG="$SIM_LANG"

export PATH="\$HOME/.local/bin:\$PATH"
export XDG_CONFIG_HOME="\$HOME/.config"
export XDG_DATA_HOME="\$HOME/.local/share"
export XDG_STATE_HOME="\$HOME/.local/state"
export XDG_CACHE_HOME="\$HOME/.cache"

# Common aliases for testing
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# Simulate common shell functions
cd() { builtin cd "\$@" && pwd; }
EOF
    return $?
}

# Generate .profile content
__print_profile() {
    local file="$1"
    
    cat > "$file" << 'EOF'
# Simulated .profile for testing
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# Source .bashrc if running bash
if [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi
EOF
    return $?
}

# Generate .gitconfig content
__print_gitconfig() {
    local file="$1"
    local user="$2"
    local editor="$3"
    
    cat > "$file" << EOF
[user]
    name = $user
    email = ${user}@example.com
[init]
    defaultBranch = main
[core]
    editor = $editor
[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    unstage = reset HEAD --
    last = log -1 HEAD
    visual = !gitk
EOF
    return $?
}

# Generate sample configuration file
__print_sample_config() {
    local file="$1"
    
    printf "# Test configuration for %s\n" "$SIM_USER" > "$file"
    return $?
}

# Generate sample data file
__print_sample_data() {
    local file="$1"
    
    printf "Sample data file for testing\n" > "$file"
    return $?
}

# Generate sample state file
__print_sample_state() {
    local file="$1"
    
    printf "state=initialized\n" > "$file"
    return $?
}

# Generate sample cache file (empty)
__print_sample_cache() {
    local file="$1"
    
    touch "$file"
    return $?
}

# Generate sample README
__print_sample_readme() {
    local file="$1"
    
    printf "# Sample README\n" > "$file"
    return $?
}

# Generate sample download file
__print_sample_download() {
    local file="$1"
    
    printf "Sample download content\n" > "$file"
    return $?
}