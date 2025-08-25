#!/usr/bin/env bash
#
# ┌─┐┬┌┬┐┌─┐┬┌┬┐
# │ ┬│ │ └─┐││││
# └─┘┴ ┴ └─┘┴┴ ┴
#
# name: gitsim
# version: 2.0.0
# desc: Git & Home Environment Simulator for Testing
#
# portable: find, mkdir, sed, awk, grep, shasum, wc, sort, tac, dirname, basename, mktemp
# builtins: printf, read, local, declare, case, if, for, while, shift, return

################################################################################
# Configuration & XDG+ Compliance
################################################################################

readonly GITSIM_VERSION="2.0.0"
readonly GITSIM_NAME="gitsim"

# XDG+ Base Configuration
: ${XDG_HOME:="$HOME/.local"}
: ${XDG_LIB_HOME:="$XDG_HOME/lib"}
: ${XDG_BIN_HOME:="$XDG_HOME/bin"}
: ${XDG_ETC_HOME:="$XDG_HOME/etc"}
: ${XDG_DATA_HOME:="$XDG_HOME/data"}
: ${XDG_CACHE_HOME:="$HOME/.cache"}

# BashFX FX-specific paths
readonly GITSIM_LIB_DIR="$XDG_LIB_HOME/fx/$GITSIM_NAME"
readonly GITSIM_BIN_LINK="$XDG_BIN_HOME/fx/$GITSIM_NAME"
readonly GITSIM_ETC_DIR="$XDG_ETC_HOME/$GITSIM_NAME"

# SIM_ variables that can inherit from live shell or be overridden
: ${SIM_HOME:=${XDG_HOME:-$HOME}}
: ${SIM_USER:=${USER:-testuser}}
: ${SIM_SHELL:=${SHELL:-/bin/bash}}
: ${SIM_EDITOR:=${EDITOR:-nano}}
: ${SIM_LANG:=${LANG:-en_US.UTF-8}}

# Standard option flags
opt_debug=false
opt_trace=false
opt_quiet=false
opt_force=false
opt_yes=false
opt_dev=false

################################################################################
# Simple stderr functions
################################################################################

stderr() { printf "%s\n" "$*" >&2; }
info() { [[ "$opt_quiet" == true ]] && return; stderr "[INFO] $*"; }
warn() { [[ "$opt_quiet" == true ]] && return; stderr "[WARN] $*"; }
error() { stderr "[ERROR] $*"; }
fatal() { stderr "[FATAL] $*"; exit 1; }
okay() { [[ "$opt_quiet" == true ]] && return; stderr "[OK] $*"; }
trace() { [[ "$opt_trace" == false ]] && return; stderr "[TRACE] $*"; }

################################################################################
# Helper Functions
################################################################################

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

# Get the simulated home directory
_get_sim_home() {
    local sim_root="$1"
    printf "%s" "$sim_root/.gitsim/.home"
}

# Get the simulated project directory within home
_get_sim_project_dir() {
    local home_dir="$1"
    local project_name="${2:-testproject}"
    printf "%s" "$home_dir/projects/$project_name"
}

# Create a fake home environment
_setup_home_env() {
    local home_dir="$1"
    local ret=1
    
    # Create standard home directories
    if mkdir -p "$home_dir"/{.config,.local/{bin,share,state},.cache,projects,Documents,Downloads}; then
        trace "Created home directory structure"
        ret=0
    else
        error "Failed to create home directory structure"
        return 1
    fi
    
    # Create common dotfiles with SIM_ variables
    __print_bashrc "$home_dir/.bashrc" "$home_dir" || return 1
    __print_profile "$home_dir/.profile" || return 1
    __print_gitconfig "$home_dir/.gitconfig" "$SIM_USER" "$SIM_EDITOR" || return 1
    
    # Create some sample files in common locations
    printf "# Test configuration for %s\n" "$SIM_USER" > "$home_dir/.config/testrc"
    printf "Sample data file for testing\n" > "$home_dir/.local/share/testdata"
    printf "state=initialized\n" > "$home_dir/.local/state/teststate"
    touch "$home_dir/.cache/testcache"
    
    # Create some sample documents
    printf "# Sample README\n" > "$home_dir/Documents/README.md"
    printf "Sample download content\n" > "$home_dir/Downloads/sample.txt"
    
    return "$ret"
}

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

################################################################################
# Git Simulation Functions
################################################################################

# Initialize git simulation structure
__create_git_structure() {
    local data_dir="$1"
    local ret=1
    
    if mkdir -p "$data_dir"; then
        touch "$data_dir"/{tags.txt,commits.txt,config,index,branches.txt,remotes.txt,HEAD}
        echo "main" > "$data_dir/branches.txt"
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
# Dispatchable Functions (High-Order)
################################################################################

do_init() {
    local sim_dir=".gitsim"
    local data_dir="$sim_dir/.data"
    local ret=1

    if [ -d "$data_dir" ]; then
        info "Reinitialized existing Git simulator repository in $(pwd)/$sim_dir/"
        ret=0
    else
        if __create_git_structure "$data_dir"; then
            okay "Initialized empty Git simulator repository in $(pwd)/$sim_dir/"
            ret=0
        else
            error "Failed to create Git simulator structure"
        fi
    fi

    __add_gitignore_entry ".gitsim/"
    return "$ret"
}

do_init_in_home() {
    local project_name="${1:-testproject}"
    local sim_root="$PWD"
    local home_dir
    local project_dir
    local ret=1

    # Always work from a .gitsim in the current directory
    if [ ! -d "$sim_root/.gitsim" ]; then
        __create_git_structure "$sim_root/.gitsim/.data" || return 1
    fi

    home_dir=$(_get_sim_home "$sim_root")

    # Ensure home is initialized
    if [ ! -d "$home_dir" ]; then
        do_home_init "$project_name" || return 1
    fi

    project_dir=$(_get_sim_project_dir "$home_dir" "$project_name")

    # Create git simulation in the project directory
    local project_data_dir="$project_dir/.gitsim/.data"

    if [ -d "$project_data_dir" ]; then
        info "Reinitialized existing Git simulator repository in $project_dir/.gitsim/"
        ret=0
    else
        if __create_git_structure "$project_data_dir"; then
            okay "Initialized empty Git simulator repository in $project_dir/.gitsim/"
            ret=0
        else
            error "Failed to create project Git simulator structure"
            return 1
        fi
    fi

    # Create project files
    printf "# %s\n" "$project_name" > "$project_dir/README.md"
    printf "node_modules/\n.gitsim/\n" > "$project_dir/.gitignore"

    info "Project path: $project_dir"
    info "To work in this project: cd '$project_dir'"

    return "$ret"
}

do_home_init() {
    local sim_root="$PWD"
    local home_dir
    local ret=1

    # Handle case where we don't have a sim_root yet
    if [ ! -d "$sim_root/.gitsim" ]; then
        if __create_git_structure "$sim_root/.gitsim/.data"; then
            trace "Created temporary sim structure"
        else
            error "Failed to create sim structure"
            return 1
        fi
    fi

    home_dir=$(_get_sim_home "$sim_root")

    if [ -d "$home_dir" ]; then
        info "Reinitialized simulated home environment at $home_dir"
        ret=0
    else
        if _setup_home_env "$home_dir"; then
            okay "Initialized simulated home environment at $home_dir"
            ret=0
        else
            error "Failed to setup home environment"
            return 1
        fi
    fi

    return "$ret"
}

do_home_env() {
    local sim_root
    local home_dir
    local ret=1
    
    sim_root=$(_find_sim_root) || {
        error "Not in a git simulator repository"
        return 1
    }
    
    home_dir=$(_get_sim_home "$sim_root")
    
    if [ ! -d "$home_dir" ]; then
        error "Simulated home not initialized. Run 'home-init' first."
        return 1
    fi
    
    printf "# Simulated environment paths (do not override \$HOME)\n"
    printf "SIM_HOME='%s'\n" "$home_dir"
    printf "SIM_USER='%s'\n" "$SIM_USER"
    printf "SIM_SHELL='%s'\n" "$SIM_SHELL"
    printf "SIM_EDITOR='%s'\n" "$SIM_EDITOR"
    printf "SIM_LANG='%s'\n" "$SIM_LANG"
    printf "\n"
    printf "# XDG directories within simulated home\n"
    printf "SIM_XDG_CONFIG_HOME='%s/.config'\n" "$home_dir"
    printf "SIM_XDG_DATA_HOME='%s/.local/share'\n" "$home_dir"
    printf "SIM_XDG_STATE_HOME='%s/.local/state'\n" "$home_dir"
    printf "SIM_XDG_CACHE_HOME='%s/.cache'\n" "$home_dir"
    printf "\n"
    printf "# To use in scripts, reference these paths directly\n"
    printf "# Example: cp myfile \"\$SIM_XDG_CONFIG_HOME/\"\n"
    
    return 0
}

do_home_path() {
    local sim_root
    local ret=1
    
    sim_root=$(_find_sim_root) || {
        error "Not in a git simulator repository"
        return 1
    }
    
    _get_sim_home "$sim_root"
    return 0
}

do_home_ls() {
    local sim_root
    local home_dir
    local subdir="${1:-.}"
    local ret=1
    
    sim_root=$(_find_sim_root) || {
        error "Not in a git simulator repository"
        return 1
    }
    
    home_dir=$(_get_sim_home "$sim_root")
    
    if [ ! -d "$home_dir" ]; then
        error "Simulated home not initialized. Run 'home-init' first."
        return 1
    fi
    
    local target_dir="$home_dir/$subdir"
    if [ ! -d "$target_dir" ]; then
        error "Directory not found: $target_dir"
        return 1
    fi
    
    shift
    if [ $# -eq 0 ]; then
        ls "$target_dir"
    else
        ls "$@" "$target_dir"
    fi
    ret=$?
    
    return "$ret"
}

do_home_vars() {
    printf "Current SIM_ environment variables:\n"
    printf "SIM_HOME=%s\n" "$SIM_HOME"
    printf "SIM_USER=%s\n" "$SIM_USER"
    printf "SIM_SHELL=%s\n" "$SIM_SHELL"
    printf "SIM_EDITOR=%s\n" "$SIM_EDITOR"  
    printf "SIM_LANG=%s\n" "$SIM_LANG"
    printf "\n"
    printf "To override, set before running script:\n"
    printf "SIM_USER=alice SIM_EDITOR=vim ./gitsim.sh home-init\n"
    return 0
}

do_version() {
    printf "%s v%s\n" "$GITSIM_NAME" "$GITSIM_VERSION"
    return 0
}

do_install() {
    local ret=1
    
    info "Installing $GITSIM_NAME to XDG+ directories..."
    
    # Create directories
    mkdir -p "$GITSIM_LIB_DIR" "$XDG_BIN_HOME/fx" || {
        error "Failed to create installation directories"
        return 1
    }
    
    # Copy script to lib directory
    if cp "$0" "$GITSIM_LIB_DIR/gitsim.sh"; then
        trace "Copied script to $GITSIM_LIB_DIR"
    else
        error "Failed to copy script to lib directory"
        return 1
    fi
    
    # Create symlink in bin directory (flattened, no .sh extension)
    if ln -sf "$GITSIM_LIB_DIR/gitsim.sh" "$GITSIM_BIN_LINK"; then
        trace "Created symlink at $GITSIM_BIN_LINK"
    else
        error "Failed to create symlink"
        return 1
    fi
    
    # Make sure it's executable
    chmod +x "$GITSIM_LIB_DIR/gitsim.sh"
    
    okay "Installed $GITSIM_NAME successfully"
    info "Add $XDG_BIN_HOME/fx to your PATH to use: export PATH=\"$XDG_BIN_HOME/fx:\$PATH\""
    
    return 0
}

do_uninstall() {
    if [[ "$opt_force" == false ]]; then
        error "Uninstall requires --force flag for safety"
        info "Use: $GITSIM_NAME uninstall --force"
        return 1
    fi

    info "Uninstalling $GITSIM_NAME..."

    # Create a temporary script to do the uninstallation
    local temp_script
    temp_script=$(mktemp)
    cat > "$temp_script" <<EOF
#!/usr/bin/env bash
rm -f "$GITSIM_BIN_LINK"
rm -rf "$GITSIM_LIB_DIR"
echo "[OK] Uninstalled $GITSIM_NAME successfully"
EOF
    chmod +x "$temp_script"

    # Execute the temporary script and exit
    exec "$temp_script"
}

# Git command implementations would go here - abbreviated for space
# (keeping the essential ones for the demo)

do_add() {
    local sim_root
    local state_file_index
    local ret=1
    
    sim_root=$(_find_sim_root) || {
        error "Not in a git repository (or any of the parent directories): .gitsim"
        return 128
    }
    
    state_file_index="$sim_root/.gitsim/.data/index"
    
    if [[ "$1" == "." ]] || [[ "$1" == "--all" ]]; then
        > "$state_file_index"
        (cd "$sim_root" && find . -type f -not -path "./.gitsim/*" -not -path "./.git/*" | sed 's|^\./||') >> "$state_file_index"
    else
        for file in "$@"; do
            echo "$file" >> "$state_file_index"
        done
    fi
    
    sort -u "$state_file_index" -o "$state_file_index"
    return 0
}

do_commit() {
    local sim_root
    local commits_file
    local head_file  
    local index_file
    local message=""
    local allow_empty=false
    local ret=1
    
    sim_root=$(_find_sim_root) || {
        error "Not in a git repository (or any of the parent directories): .gitsim"
        return 128
    }
    
    commits_file="$sim_root/.gitsim/.data/commits.txt"
    head_file="$sim_root/.gitsim/.data/HEAD"
    index_file="$sim_root/.gitsim/.data/index"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m) message="$2"; shift 2;;
            --allow-empty) allow_empty=true; shift;;
            *) shift;;
        esac
    done
    
    if [ -z "$message" ]; then
        error "No commit message provided"
        return 1
    fi

    if [ "$allow_empty" = false ] && ! [ -s "$index_file" ]; then
        error "nothing to commit, working tree clean"
        return 1
    fi

    local commit_hash
    commit_hash=$( (echo "$message" ; date +%s) | shasum | head -c 7)
    echo "$commit_hash $message" >> "$commits_file"
    echo "$commit_hash" > "$head_file"
    > "$index_file"
    
    okay "Committed: $message [$commit_hash]"
    return 0
}

do_status() {
    local sim_root
    local index_file
    local branches_file
    local ret=1
    
    sim_root=$(_find_sim_root) || {
        error "Not in a git repository (or any of the parent directories): .gitsim"
        return 128
    }
    
    index_file="$sim_root/.gitsim/.data/index"
    branches_file="$sim_root/.gitsim/.data/branches.txt"
    
    if [[ "$1" == "--porcelain" ]]; then
        if [ -s "$index_file" ]; then
            sed 's/^/A  /' "$index_file"
        fi
        return 0
    fi
    
    # Human-readable output
    local branch
    branch=$(tail -n 1 "$branches_file" 2>/dev/null)
    printf "On branch %s\n" "${branch:-main}"
    
    if [ -s "$index_file" ]; then
        printf "Changes to be committed:\n"
        printf "  (use \"git restore --staged <file>...\" to unstage)\n"
        sed 's/^/\tnew file:   /' "$index_file"
    else
        printf "\n"
        printf "nothing to commit, working tree clean\n"
    fi
    
    return 0
}

# Test data generation functions
do_noise() {
    local sim_root
    local data_dir
    local num_files="${1:-1}"
    local ret=1
    
    sim_root=$(_find_sim_root) || {
        error "Not in a git repository (or any of the parent directories): .gitsim"
        return 128
    }
    
    data_dir="$sim_root/.gitsim/.data"
    
    local names=("README" "script" "status" "main" "feature" "hotfix" "docs" "config" "utils" "test")
    local exts=(".md" ".fake" ".log" ".sh" ".txt" ".tmp" ".json" ".yml" ".xml" ".conf")

    for i in $(seq 1 "$num_files"); do
        local rand_name=${names[$RANDOM % ${#names[@]}]}
        local rand_ext=${exts[$RANDOM % ${#exts[@]}]}
        local filename="${rand_name}_${i}${rand_ext}"

        head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 > "$sim_root/$filename"
        echo "$filename" >> "$data_dir/index"
    done

    sort -u "$data_dir/index" -o "$data_dir/index"
    okay "Created and staged ${num_files} noisy file(s)"
    return 0
}

################################################################################
# Core System Functions
################################################################################

dispatch() {
    local cmd="$1"
    shift
    
    case "$cmd" in
        # Core git simulation
        init)           do_init "$@";;
        init-in-home)   do_init_in_home "$@";;
        add)            do_add "$@";;
        commit)         do_commit "$@";;
        status)         do_status "$@";;
        
        # Home environment
        home-init)      do_home_init "$@";;
        home-env)       do_home_env "$@";;
        home-path)      do_home_path "$@";;
        home-ls)        do_home_ls "$@";;
        home-vars)      do_home_vars "$@";;
        
        # Test data generation
        noise)          do_noise "$@";;
        
        # System management
        install)        do_install "$@";;
        uninstall)      do_uninstall "$@";;
        version)        do_version "$@";;
        
        *)
            error "Unknown command: $cmd"
            do_usage
            return 1
            ;;
    esac
}

usage() {
    cat << 'EOF'
gitsim - Git & Home Environment Simulator v2.0.0

USAGE:
    gitsim <command> [options] [args]

CORE COMMANDS:
    init                    Create git simulation in current directory
    init-in-home [project]  Create git simulation in simulated home project
    add <files>             Add files to staging area
    commit -m "message"     Create a commit with message
    status                  Show repository status

HOME ENVIRONMENT:
    home-init [project]     Initialize simulated home environment
    home-env               Show simulated environment variables
    home-path              Get path to simulated home directory  
    home-ls [dir] [opts]   List contents of simulated home
    home-vars              Show SIM_ environment variables

TEST DATA:
    noise [count]          Create random files and stage them

SYSTEM:
    install                Install to XDG+ directories
    uninstall --force      Remove installation
    version                Show version information

OPTIONS:
    -d, --debug            Enable debug output
    -t, --trace            Enable trace output (implies -d)
    -q, --quiet            Suppress all output except errors
    -f, --force            Force operations, bypass safety checks
    -D, --dev              Enable developer mode

ENVIRONMENT VARIABLES:
    SIM_HOME               Base simulated home [$SIM_HOME]
    SIM_USER               Simulated username [$SIM_USER]  
    SIM_SHELL              Simulated shell [$SIM_SHELL]
    SIM_EDITOR             Simulated editor [$SIM_EDITOR]

EXAMPLES:
    gitsim init
    gitsim home-init myproject
    gitsim noise 5
    gitsim commit -m "Test commit"
    
    # Use simulated environment in scripts:
    HOME_PATH=$(gitsim home-path)
    cp myfile "$HOME_PATH/.config/"

EOF
}

options() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--debug)
                opt_debug=true
                shift
                ;;
            -t|--trace)
                opt_trace=true
                opt_debug=true
                shift
                ;;
            -q|--quiet)
                opt_quiet=true
                shift
                ;;
            -f|--force)
                opt_force=true
                shift
                ;;
            -y|--yes)
                opt_yes=true
                shift
                ;;
            -D|--dev)
                opt_dev=true
                opt_debug=true
                opt_trace=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            --)
                shift
                break
                ;;
            -*)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                break
                ;;
        esac
    done
}

main() {
    # Parse options first
    options "$@"
    
    # Remove parsed options from arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--debug|-t|--trace|-q|--quiet|-f|--force|-y|--yes|-D|--dev|-h|--help)
                shift
                ;;
            --)
                shift
                break
                ;;
            -*)
                shift
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Show help if no command provided
    if [[ $# -eq 0 ]]; then
        usage
        exit 0
    fi
    
    # Dispatch to command
    dispatch "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
