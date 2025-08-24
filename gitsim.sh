#!/usr/bin/env bash

# git_sim.sh - A simulator for git commands and home environments for testing

# --- Configuration Variables ---

# SIM_ variables that can inherit from live shell or be overridden
: ${SIM_HOME:=${XDG_HOME:-$HOME}}
: ${SIM_USER:=${USER:-testuser}}
: ${SIM_SHELL:=${SHELL:-/bin/bash}}
: ${SIM_EDITOR:=${EDITOR:-nano}}
: ${SIM_LANG:=${LANG:-en_US.UTF-8}}

# --- Helper Functions ---

# Find the root of the simulated repository by searching upwards for .gitsim
find_sim_root() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.gitsim" ]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}

# Get the simulated home directory
get_sim_home() {
    local sim_root="$1"
    echo "$sim_root/.gitsim/.home"
}

# Get the simulated project directory within home
get_sim_project_dir() {
    local home_dir="$1"
    local project_name="${2:-testproject}"
    echo "$home_dir/projects/$project_name"
}

# Create a fake home environment
setup_home_env() {
    local home_dir="$1"
    
    # Create standard home directories
    mkdir -p "$home_dir"/{.config,.local/{bin,share,state},.cache,projects,Documents,Downloads}
    
    # Create common dotfiles with SIM_ variables
    cat > "$home_dir/.bashrc" << EOF
# Simulated .bashrc for testing
export USER="$SIM_USER"
export HOME="$home_dir"
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
    
    cat > "$home_dir/.profile" << EOF
# Simulated .profile for testing
if [ -d "\$HOME/.local/bin" ] ; then
    PATH="\$HOME/.local/bin:\$PATH"
fi

# Source .bashrc if running bash
if [ -n "\$BASH_VERSION" ]; then
    if [ -f "\$HOME/.bashrc" ]; then
        . "\$HOME/.bashrc"
    fi
fi
EOF
    
    # Create .gitconfig with SIM_ variables
    cat > "$home_dir/.gitconfig" << EOF
[user]
    name = $SIM_USER
    email = ${SIM_USER}@example.com
[init]
    defaultBranch = main
[core]
    editor = $SIM_EDITOR
[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    unstage = reset HEAD --
    last = log -1 HEAD
    visual = !gitk
EOF
    
    # Create some sample files in common locations
    echo "# Test configuration for $SIM_USER" > "$home_dir/.config/testrc"
    echo "Sample data file for testing" > "$home_dir/.local/share/testdata"
    echo "state=initialized" > "$home_dir/.local/state/teststate"
    touch "$home_dir/.cache/testcache"
    
    # Create some sample documents
    echo "# Sample README" > "$home_dir/Documents/README.md"
    echo "Sample download content" > "$home_dir/Downloads/sample.txt"
    
    return 0
}

usage() {
    echo "usage: git_sim.sh <command> [<args>]"
    echo ""
    echo "Environment Variables:"
    echo "   SIM_HOME       Simulated home directory base (\$XDG_HOME or \$HOME)"
    echo "   SIM_USER       Simulated username (\$USER)"
    echo "   SIM_SHELL      Simulated shell (\$SHELL)"
    echo "   SIM_EDITOR     Simulated editor (\$EDITOR)"
    echo "   SIM_LANG       Simulated language (\$LANG)"
    echo ""
    echo "These are common Git commands used in various situations:"
    echo ""
    echo "start a working area"
    echo "   init           Create an empty Git repository or reinitialize an existing one"
    echo "   init-in-home   Create git repo in simulated home/projects directory"
    echo ""
    echo "work on the current change"
    echo "   add            Add file contents to the index"
    echo "   status         Show the working tree status"
    echo "   reset          Reset current HEAD to the specified state"
    echo ""
    echo "examine the history and state"
    echo "   log            Show commit logs"
    echo "   describe       Give an object a human readable name based on an available ref"
    echo "   diff           Show changes between commits, commit and working tree, etc"
    echo "   show           Show various types of objects"
    echo ""
    echo "grow, mark and tweak your common history"
    echo "   commit         Record changes to the repository"
    echo "   tag            Create, list, delete or verify a tag object signed with GPG"
    echo "   checkout       Switch branches or restore working tree files"
    echo "   branch         List, create, or delete branches"
    echo ""
    echo "collaborate"
    echo "   fetch          Download objects and refs from another repository"
    echo "   push           Update remote refs along with associated objects"
    echo "   remote         Manage set of tracked repositories"
    echo ""
    echo "home environment simulation"
    echo "   home-init      Initialize a simulated home environment"
    echo "   home-env       Show simulated environment variables"
    echo "   home-path      Get path to simulated home directory"
    echo "   home-ls        List contents of simulated home directory"
    echo "   home-vars      Show/set SIM_ environment variables"
    echo ""
    echo "custom simulator commands"
    echo "   noise          Create random files and stage them"
    echo "   branches       Create multiple branches with commits"
    echo "   history        Create a commit history with tags"
    echo "   help           Show this help message"
}

# --- Home Environment Commands ---

cmd_home_init() {
    local sim_root="$1"
    shift
    local project_name="${1:-testproject}"
    
    local home_dir
    home_dir=$(get_sim_home "$sim_root")
    
    if [ -d "$home_dir" ]; then
        echo "Reinitialized simulated home environment at $home_dir"
    else
        setup_home_env "$home_dir"
        echo "Initialized simulated home environment at $home_dir"
    fi
    
    # Create project directory
    local project_dir
    project_dir=$(get_sim_project_dir "$home_dir" "$project_name")
    mkdir -p "$project_dir"
    echo "Created project directory at $project_dir"
    
    return 0
}

cmd_init_in_home() {
    local sim_root="$1"
    shift
    local project_name="${1:-testproject}"
    
    local home_dir
    home_dir=$(get_sim_home "$sim_root")
    
    # Ensure home is initialized
    if [ ! -d "$home_dir" ]; then
        cmd_home_init "$sim_root" "$project_name"
    fi
    
    local project_dir
    project_dir=$(get_sim_project_dir "$home_dir" "$project_name")
    
    # Create git simulation in the project directory
    local project_sim_dir="$project_dir/.gitsim"
    local project_data_dir="$project_sim_dir/.data"
    
    if [ -d "$project_data_dir" ]; then
        echo "Reinitialized existing Git simulator repository in $project_dir/.gitsim/"
    else
        mkdir -p "$project_data_dir"
        touch "$project_data_dir/tags.txt"
        touch "$project_data_dir/commits.txt"
        touch "$project_data_dir/config"
        touch "$project_data_dir/index"
        touch "$project_data_dir/branches.txt"
        touch "$project_data_dir/remotes.txt"
        echo "main" > "$project_data_dir/branch.txt"
        echo "main" >> "$project_data_dir/branches.txt"
        touch "$project_data_dir/HEAD"
        echo "Initialized empty Git simulator repository in $project_dir/.gitsim/"
    fi
    
    # Create a .gitignore in the project
    if ! grep -q "^\.gitsim/$" "$project_dir/.gitignore" 2>/dev/null; then
        echo ".gitsim/" >> "$project_dir/.gitignore"
    fi
    
    # Create some sample project files
    echo "# $project_name" > "$project_dir/README.md"
    echo "node_modules/" > "$project_dir/.gitignore"
    echo ".gitsim/" >> "$project_dir/.gitignore"
    
    echo "Project path: $project_dir"
    echo "To work in this project: cd '$project_dir'"
    
    return 0
}

cmd_home_env() {
    local sim_root="$1"
    local home_dir
    home_dir=$(get_sim_home "$sim_root")
    
    if [ ! -d "$home_dir" ]; then
        echo "Simulated home not initialized. Run 'home-init' first." >&2
        return 1
    fi
    
    echo "# Simulated environment paths (do not override \$HOME)"
    echo "SIM_HOME='$home_dir'"
    echo "SIM_USER='$SIM_USER'"
    echo "SIM_SHELL='$SIM_SHELL'"
    echo "SIM_EDITOR='$SIM_EDITOR'"
    echo "SIM_LANG='$SIM_LANG'"
    echo ""
    echo "# XDG directories within simulated home"
    echo "SIM_XDG_CONFIG_HOME='$home_dir/.config'"
    echo "SIM_XDG_DATA_HOME='$home_dir/.local/share'"
    echo "SIM_XDG_STATE_HOME='$home_dir/.local/state'"
    echo "SIM_XDG_CACHE_HOME='$home_dir/.cache'"
    echo ""
    echo "# To use in scripts, reference these paths directly"
    echo "# Example: cp myfile \"\$SIM_XDG_CONFIG_HOME/\""
    
    return 0
}

cmd_home_path() {
    local sim_root="$1"
    get_sim_home "$sim_root"
    return 0
}

cmd_home_ls() {
    local sim_root="$1"
    shift
    local subdir="${1:-.}"
    local ls_args=()
    
    # Parse ls arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -l|-la|-al|-a)
                ls_args+=("$1")
                shift
                ;;
            *)
                subdir="$1"
                shift
                ;;
        esac
    done
    
    local home_dir
    home_dir=$(get_sim_home "$sim_root")
    
    if [ ! -d "$home_dir" ]; then
        echo "Simulated home not initialized. Run 'home-init' first." >&2
        return 1
    fi
    
    local target_dir="$home_dir/$subdir"
    if [ ! -d "$target_dir" ]; then
        echo "Directory not found: $target_dir" >&2
        return 1
    fi
    
    if [ ${#ls_args[@]} -eq 0 ]; then
        ls "$target_dir"
    else
        ls "${ls_args[@]}" "$target_dir"
    fi
    
    return 0
}

cmd_home_vars() {
    echo "Current SIM_ environment variables:"
    echo "SIM_HOME=${SIM_HOME}"
    echo "SIM_USER=${SIM_USER}"  
    echo "SIM_SHELL=${SIM_SHELL}"
    echo "SIM_EDITOR=${SIM_EDITOR}"
    echo "SIM_LANG=${SIM_LANG}"
    echo ""
    echo "To override, set before running script:"
    echo "SIM_USER=alice SIM_EDITOR=vim ./git_sim.sh home-init"
    return 0
}

# --- Enhanced Git Commands ---

# git init
cmd_init() {
    local SIM_DIR=".gitsim"
    local DATA_DIR="$SIM_DIR/.data"

    if [ -d "$DATA_DIR" ]; then
        echo "Reinitialized existing Git simulator repository in $(pwd)/$SIM_DIR/"
    else
        mkdir -p "$DATA_DIR"
        touch "$DATA_DIR/tags.txt"
        touch "$DATA_DIR/commits.txt"
        touch "$DATA_DIR/config"
        touch "$DATA_DIR/index"
        touch "$DATA_DIR/branches.txt"
        touch "$DATA_DIR/remotes.txt"
        echo "main" > "$DATA_DIR/branch.txt"
        echo "main" >> "$DATA_DIR/branches.txt"
        touch "$DATA_DIR/HEAD"
        echo "Initialized empty Git simulator repository in $(pwd)/$SIM_DIR/"
    fi

    if ! grep -q "^\.gitsim/$" .gitignore 2>/dev/null; then
        echo ".gitsim/" >> .gitignore
    fi
    return 0
}

# All other commands need the root path to be passed to them
cmd_config() {
    local STATE_FILE_CONFIG="$1"; shift
    local key="$1"
    local value="$2"
    if [ -n "$value" ]; then
        # Remove existing key if it exists
        if [ -f "$STATE_FILE_CONFIG" ]; then
            grep -v "^$key=" "$STATE_FILE_CONFIG" > "$STATE_FILE_CONFIG.tmp" && mv "$STATE_FILE_CONFIG.tmp" "$STATE_FILE_CONFIG"
        fi
        echo "$key=$value" >> "$STATE_FILE_CONFIG"
    else
        if [ -f "$STATE_FILE_CONFIG" ]; then
            grep "^$key=" "$STATE_FILE_CONFIG" | cut -d'=' -f2
        fi
    fi
    return 0
}

cmd_add() {
    local STATE_FILE_INDEX="$1"
    local SIM_ROOT="$2"
    shift 2

    # The directory where we store git's internal state
    local GIT_DIR="$SIM_ROOT/.gitsim"

    if [[ "$1" == "." ]] || [[ "$1" == "--all" ]]; then
        # For 'add .', we find all files in the repo root, excluding the .gitsim directory
        > "$STATE_FILE_INDEX"

        # We must change to the SIM_ROOT to get relative paths correctly.
        (cd "$SIM_ROOT" && find . -type f -not -path "./.gitsim/*" -not -path "./.git/*" | sed 's|^\./||') >> "$STATE_FILE_INDEX"

    else
        for file in "$@"; do
            echo "$file" >> "$STATE_FILE_INDEX"
        done
    fi
    sort -u "$STATE_FILE_INDEX" -o "$STATE_FILE_INDEX"
    return 0
}

cmd_reset() {
    local STATE_FILE_INDEX="$1"
    local STATE_FILE_HEAD="$2"
    shift 2
    
    local mode="mixed"  # default
    local commit_ref="HEAD"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --soft) mode="soft"; shift;;
            --mixed) mode="mixed"; shift;;
            --hard) mode="hard"; shift;;
            *) commit_ref="$1"; shift;;
        esac
    done
    
    case "$mode" in
        "soft")
            # Only move HEAD, keep index and working directory
            ;;
        "mixed")
            # Move HEAD and reset index, keep working directory
            > "$STATE_FILE_INDEX"
            ;;
        "hard")
            # Move HEAD, reset index, and reset working directory
            > "$STATE_FILE_INDEX"
            echo "WARNING: --hard reset simulated (working directory unchanged in simulation)"
            ;;
    esac
    
    return 0
}

cmd_commit() {
    local STATE_FILE_COMMITS="$1"
    local STATE_FILE_HEAD="$2"
    local STATE_FILE_INDEX="$3"
    shift 3
    local message=""
    local allow_empty=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m) message="$2"; shift 2;;
            --allow-empty) allow_empty=true; shift;;
            *) shift;;
        esac
    done
    if [ -z "$message" ]; then return 1; fi

    if [ "$allow_empty" = false ] && ! [ -s "$STATE_FILE_INDEX" ]; then
        echo "nothing to commit, working tree clean" >&2
        return 1
    fi

    local commit_hash
    commit_hash=$( (echo "$message" ; date +%s) | shasum | head -c 7)
    echo "$commit_hash $message" >> "$STATE_FILE_COMMITS"
    echo "$commit_hash" > "$STATE_FILE_HEAD"
    > "$STATE_FILE_INDEX"
    return 0
}

cmd_checkout() {
    local STATE_FILE_BRANCH="$1"
    local STATE_FILE_BRANCHES="$2"
    local STATE_FILE_INDEX="$3"
    shift 3
    
    local branch_name=""
    local create_branch=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -b) create_branch=true; branch_name="$2"; shift 2;;
            *) branch_name="$1"; shift;;
        esac
    done
    
    if [ -z "$branch_name" ]; then
        return 1
    fi
    
    if [ "$create_branch" = true ]; then
        if grep -q "^$branch_name$" "$STATE_FILE_BRANCHES"; then
            echo "fatal: A branch named '$branch_name' already exists." >&2
            return 128
        fi
        echo "$branch_name" >> "$STATE_FILE_BRANCHES"
        echo "Switched to a new branch '$branch_name'"
    else
        if ! grep -q "^$branch_name$" "$STATE_FILE_BRANCHES"; then
            echo "error: pathspec '$branch_name' did not match any file(s) known to git" >&2
            return 1
        fi
        echo "Switched to branch '$branch_name'"
    fi
    
    echo "$branch_name" > "$STATE_FILE_BRANCH"
    > "$STATE_FILE_INDEX"  # Clear staging area on branch switch
    return 0
}

cmd_branch() {
    local STATE_FILE_BRANCH="$1"
    local STATE_FILE_BRANCHES="$2"
    shift 2
    
    if [[ $# -eq 0 ]]; then
        # List branches, marking current one
        local current_branch
        current_branch=$(cat "$STATE_FILE_BRANCH")
        while IFS= read -r branch; do
            if [ "$branch" = "$current_branch" ]; then
                echo "* $branch"
            else
                echo "  $branch"
            fi
        done < "$STATE_FILE_BRANCHES"
        return 0
    fi
    
    local delete_branch=false
    local branch_name=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d) delete_branch=true; branch_name="$2"; shift 2;;
            *) branch_name="$1"; shift;;
        esac
    done
    
    if [ "$delete_branch" = true ]; then
        local current_branch
        current_branch=$(cat "$STATE_FILE_BRANCH")
        if [ "$branch_name" = "$current_branch" ]; then
            echo "error: Cannot delete branch '$branch_name' checked out at '$(pwd)'" >&2
            return 1
        fi
        if ! grep -q "^$branch_name$" "$STATE_FILE_BRANCHES"; then
            echo "error: branch '$branch_name' not found." >&2
            return 1
        fi
        sed -i "/^$branch_name$/d" "$STATE_FILE_BRANCHES"
        echo "Deleted branch $branch_name"
        return 0
    fi
    
    # Create new branch
    if grep -q "^$branch_name$" "$STATE_FILE_BRANCHES"; then
        echo "fatal: A branch named '$branch_name' already exists." >&2
        return 128
    fi
    echo "$branch_name" >> "$STATE_FILE_BRANCHES"
    return 0
}

cmd_remote() {
    local STATE_FILE_REMOTES="$1"
    shift
    
    case "$1" in
        "")
            # List remotes
            cut -d' ' -f1 "$STATE_FILE_REMOTES" 2>/dev/null | sort -u
            ;;
        "add")
            local name="$2"
            local url="$3"
            if [ -z "$name" ] || [ -z "$url" ]; then
                echo "usage: git remote add <name> <url>" >&2
                return 1
            fi
            echo "$name $url" >> "$STATE_FILE_REMOTES"
            ;;
        "remove"|"rm")
            local name="$2"
            if [ -z "$name" ]; then
                echo "usage: git remote remove <name>" >&2
                return 1
            fi
            sed -i "/^$name /d" "$STATE_FILE_REMOTES"
            ;;
        "show")
            local name="$2"
            if [ -z "$name" ]; then
                echo "usage: git remote show <name>" >&2
                return 1
            fi
            grep "^$name " "$STATE_FILE_REMOTES" | head -n 1 | cut -d' ' -f2-
            ;;
        *)
            echo "usage: git remote [-v | --verbose]" >&2
            echo "   or: git remote add <name> <url>" >&2
            echo "   or: git remote remove <name>" >&2
            return 1
            ;;
    esac
    
    return 0
}

cmd_tag() {
    local STATE_FILE_TAGS="$1"
    local STATE_FILE_HEAD="$2"
    shift 2
    if [[ $# -eq 0 ]]; then cat "$STATE_FILE_TAGS" | cut -d' ' -f1; return 0; fi
    local tag_name=""
    local message=""
    local delete_tag=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -a) tag_name="$2"; shift 2;;
            -m) message="$2"; shift 2;;
            -d) delete_tag=true; tag_name="$2"; shift 2;;
            --list) cat "$STATE_FILE_TAGS" | cut -d' ' -f1; return 0;;
            *) tag_name="$1"; shift;;
        esac
    done
    if [[ "$delete_tag" = true ]]; then
        # Use sed to delete the line in-place. This is more robust than the grep/mv pattern.
        sed -i "/^$tag_name /d" "$STATE_FILE_TAGS"
        return 0
    fi
    if [ -n "$tag_name" ]; then
        # Check if tag already exists
        if grep -q "^$tag_name " "$STATE_FILE_TAGS"; then
            echo "fatal: tag '$tag_name' already exists" >&2
            return 128
        fi
        local commit_hash
        commit_hash=$(cat "$STATE_FILE_HEAD" 2>/dev/null)
        if [ -z "$commit_hash" ]; then
            echo "fatal: Failed to create tag: HEAD does not point to a commit" >&2
            return 128
        fi
        echo "$tag_name $commit_hash $message" >> "$STATE_FILE_TAGS"
        return 0
    fi
}

cmd_log() {
    local STATE_FILE_COMMITS="$1"
    local STATE_FILE_TAGS="$2"
    shift 2

    # git log --pretty=format:"%s" "${tag}"..HEAD
    # This is a very specific implementation for semv's `since_last`
    if [[ "$1" == "--pretty=format:%s" ]]; then
        local range="$2"
        if [[ "$range" == *"..HEAD"* ]]; then
            local tag_name
            tag_name=$(echo "$range" | sed 's/\.\.HEAD//')

            local tag_commit_hash
            tag_commit_hash=$(grep "^$tag_name " "$STATE_FILE_TAGS" | head -n 1 | cut -d' ' -f2)

            if [ -n "$tag_commit_hash" ]; then
                # Find all commits after the tagged commit
                # The `sed` command prints all lines after the line with the matching hash
                sed -n "/$tag_commit_hash/,\$p" "$STATE_FILE_COMMITS" | tail -n +2 | awk '{$1=""; print $0}' | sed 's/^ //g'
                return 0
            fi
        fi
    fi

    # Handle --oneline format
    if [[ "$1" == "--oneline" ]]; then
        awk '{print substr($1,1,7) " " substr($0, index($0,$2))}' "$STATE_FILE_COMMITS" | tac
        return 0
    fi

    # Default behavior: print all commit messages (newest first)
    awk '{$1=""; print $0}' "$STATE_FILE_COMMITS" | sed 's/^ //g' | tac
    return 0
}

cmd_describe() {
    local STATE_FILE_TAGS="$1"; shift
    if [ ! -s "$STATE_FILE_TAGS" ]; then
        echo "fatal: No names found, cannot describe anything." >&2
        return 128
    fi
    cat "$STATE_FILE_TAGS" | cut -d' ' -f1 | sort -V | tail -n 1
    return 0
}

cmd_rev_parse() {
    local STATE_FILE_HEAD="$1"; shift
    case "$1" in
        --is-inside-work-tree) return 0;;
        --show-toplevel) find_sim_root; return 0;;
        HEAD) 
            if [ -s "$STATE_FILE_HEAD" ]; then
                cat "$STATE_FILE_HEAD"
            else
                echo "fatal: ambiguous argument 'HEAD': unknown revision or path not in the working tree." >&2
                return 128
            fi
            return 0
            ;;
        *) return 1;;
    esac
}

cmd_symbolic_ref() {
    local STATE_FILE_BRANCH="$1"; shift
    case "$1" in
        "HEAD")
            local branch
            branch=$(cat "$STATE_FILE_BRANCH" 2>/dev/null)
            if [ -n "$branch" ]; then
                echo "refs/heads/$branch"
            else
                return 1
            fi
            ;;
        "refs/remotes/origin/HEAD")
            echo "refs/remotes/origin/main"
            ;;
        *)
            return 1
            ;;
    esac
    return 0
}

cmd_show() {
    local STATE_FILE_HEAD="$1"; shift
    if [[ "$1" == "-s" ]] && [[ "$2" == "--format=%ct" ]] && [[ "$3" == "HEAD" ]]; then
        date +%s
        return 0
    fi
    return 1
}

cmd_show_ref() {
    local STATE_FILE_TAGS="$1"; shift
    if [[ "$1" == "--tags" ]]; then
        while IFS= read -r line; do
            local tag_name commit_hash
            tag_name=$(echo "$line" | cut -d' ' -f1)
            commit_hash=$(echo "$line" | cut -d' ' -f2)
            echo "$commit_hash refs/tags/$tag_name"
        done < "$STATE_FILE_TAGS"
        return 0
    fi
    return 1
}

cmd_rev_list() {
    local STATE_FILE_COMMITS="$1"; shift
    if [[ "$1" == "--count" ]]; then
        wc -l < "$STATE_FILE_COMMITS" | tr -d ' '
        return 0
    fi
    return 1
}

cmd_status() {
    local STATE_FILE_INDEX="$1"
    local STATE_FILE_BRANCH="$2"
    shift 2
    if [[ "$1" == "--porcelain" ]]; then
        if [ -s "$STATE_FILE_INDEX" ]; then
            sed 's/^/A  /' "$STATE_FILE_INDEX"
        fi
        return 0
    else
        # Human-readable output
        local branch
        branch=$(cat "$STATE_FILE_BRANCH" 2>/dev/null)
        echo "On branch ${branch:-main}"
        if [ -s "$STATE_FILE_INDEX" ]; then
            echo "Changes to be committed:"
            echo "  (use \"git restore --staged <file>...\" to unstage)"
            sed 's/^/\tnew file:   /' "$STATE_FILE_INDEX"
        else
            echo ""
            echo "nothing to commit, working tree clean"
        fi
        return 0
    fi
}

cmd_fetch() { 
    echo "Simulated fetch from origin"
    return 0
}

cmd_push() { 
    echo "Simulated push to origin"
    return 0
}

cmd_diff() {
    local STATE_FILE_INDEX="$1"; shift
    if [[ "$1" == "--exit-code" ]]; then
        if [ -s "$STATE_FILE_INDEX" ]; then return 1; else return 0; fi
    fi
    if [ -s "$STATE_FILE_INDEX" ]; then
        echo "Staged files:"
        sed 's/^/+++ /' "$STATE_FILE_INDEX"
    else
        echo "No staged changes"
    fi
    return 0
}

# --- Enhanced Simulation Commands ---

cmd_noise() {
    local SIM_ROOT="$1"
    local DATA_DIR="$2"
    shift 2
    local num_files=${1:-1}

    local names=("README" "script" "status" "main" "feature" "hotfix" "docs" "config" "utils" "test")
    local exts=(".md" ".fake" ".log" ".sh" ".txt" ".tmp" ".json" ".yml" ".xml" ".conf")

    for i in $(seq 1 "$num_files"); do
        local rand_name=${names[$RANDOM % ${#names[@]}]}
        local rand_ext=${exts[$RANDOM % ${#exts[@]}]}
        local filename="${rand_name}_${i}${rand_ext}"

        # Create the file in the simulated workspace root
        head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 > "$SIM_ROOT/$filename"
        echo "$filename" >> "$DATA_DIR/index"
    done

    sort -u "$DATA_DIR/index" -o "$DATA_DIR/index"
    echo "Created and staged ${num_files} noisy file(s)."
    return 0
}

cmd_branches() {
    local SIM_ROOT="$1"
    local DATA_DIR="$2"
    shift 2
    local num_branches=${1:-3}
    
    local branch_prefixes=("feature" "bugfix" "hotfix" "release" "develop" "experimental")
    local branch_suffixes=("auth" "ui" "api" "db" "test" "config" "docs" "refactor")
    
    for i in $(seq 1 "$num_branches"); do
        local prefix=${branch_prefixes[$RANDOM % ${#branch_prefixes[@]}]}
        local suffix=${branch_suffixes[$RANDOM % ${#branch_suffixes[@]}]}
        local branch_name="${prefix}/${suffix}-${i}"
        
        # Add branch to branches list
        echo "$branch_name" >> "$DATA_DIR/branches.txt"
        
        # Create a commit on this branch (simulate)
        local commit_hash
        commit_hash=$(echo "${branch_name}_commit_$(date +%s)" | shasum | head -c 7)
        echo "$commit_hash Implement $suffix for $prefix" >> "$DATA_DIR/commits.txt"
    done
    
    sort -u "$DATA_DIR/branches.txt" -o "$DATA_DIR/branches.txt"
    echo "Created $num_branches branch(es) with commits."
    return 0
}

cmd_history() {
    local SIM_ROOT="$1"
    local DATA_DIR="$2"
    shift 2
    local num_commits=${1:-5}
    local num_tags=${2:-2}
    
    local commit_messages=(
        "Initial commit"
        "Add core functionality"
        "Fix critical bug"
        "Update documentation"
        "Refactor codebase"
        "Add new feature"
        "Improve performance"
        "Fix security issue"
        "Update dependencies"
        "Add tests"
    )
    
    # Create commits
    > "$DATA_DIR/commits.txt"
    for i in $(seq 1 "$num_commits"); do
        local message=${commit_messages[$RANDOM % ${#commit_messages[@]}]}
        local commit_hash
        commit_hash=$(echo "${message}_${i}_$(date +%s)" | shasum | head -c 7)
        echo "$commit_hash $message" >> "$DATA_DIR/commits.txt"
        echo "$commit_hash" > "$DATA_DIR/HEAD"
    done
    
    # Create tags
    > "$DATA_DIR/tags.txt"
    local version_major=1
    local version_minor=0
    for i in $(seq 1 "$num_tags"); do
        local tag_name="v${version_major}.${version_minor}.0"
        local commit_hash
        commit_hash=$(sed -n "${i}p" "$DATA_DIR/commits.txt" | cut -d' ' -f1)
        echo "$tag_name $commit_hash Release $tag_name" >> "$DATA_DIR/tags.txt"
        version_minor=$((version_minor + 1))
        if [ $version_minor -gt 2 ]; then
            version_major=$((version_major + 1))
            version_minor=0
        fi
    done
    
    echo "Created $num_commits commit(s) and $num_tags tag(s)."
    return 0
}

# --- Main Dispatcher ---

main() {
    local cmd="$1"

    if [[ -z "$cmd" ]] || [[ "$cmd" == "help" ]] || [[ "$cmd" == "--help" ]]; then
        usage
        return 0
    fi

    shift

    if [ "$cmd" == "init" ]; then
        cmd_init
        return $?
    fi
    
    if [ "$cmd" == "init-in-home" ]; then
        # For init-in-home, we need to find or create a sim root first
        local SIM_ROOT
        SIM_ROOT=$(find_sim_root)
        if [[ -z "$SIM_ROOT" ]]; then
            # Create a temporary sim root in current directory
            mkdir -p .gitsim/.data
            SIM_ROOT="$PWD"
        fi
        cmd_init_in_home "$SIM_ROOT" "$@"
        return $?
    fi
    
    if [ "$cmd" == "home-vars" ]; then
        cmd_home_vars
        return $?
    fi

    local SIM_ROOT
    SIM_ROOT=$(find_sim_root)
    if [[ -z "$SIM_ROOT" ]]; then
        echo "fatal: not a git repository (or any of the parent directories): .gitsim" >&2
        return 128
    fi

    local SIM_DIR="$SIM_ROOT/.gitsim"
    local DATA_DIR="$SIM_DIR/.data"
    local STATE_FILE_CONFIG="$DATA_DIR/config"
    local STATE_FILE_TAGS="$DATA_DIR/tags.txt"
    local STATE_FILE_COMMITS="$DATA_DIR/commits.txt"
    local STATE_FILE_BRANCH="$DATA_DIR/branch.txt"
    local STATE_FILE_BRANCHES="$DATA_DIR/branches.txt"
    local STATE_FILE_REMOTES="$DATA_DIR/remotes.txt"
    local STATE_FILE_HEAD="$DATA_DIR/HEAD"
    local STATE_FILE_INDEX="$DATA_DIR/index"

    case "$cmd" in
        # Home environment commands
        home-init)      cmd_home_init "$SIM_ROOT" "$@";;
        home-env)       cmd_home_env "$SIM_ROOT" "$@";;
        home-path)      cmd_home_path "$SIM_ROOT" "$@";;
        home-ls)        cmd_home_ls "$SIM_ROOT" "$@";;
        
        # Git commands
        config)         cmd_config "$STATE_FILE_CONFIG" "$@";;
        add)            cmd_add "$STATE_FILE_INDEX" "$SIM_ROOT" "$@";;
        reset)          cmd_reset "$STATE_FILE_INDEX" "$STATE_FILE_HEAD" "$@";;
        commit)         cmd_commit "$STATE_FILE_COMMITS" "$STATE_FILE_HEAD" "$STATE_FILE_INDEX" "$@";;
        checkout)       cmd_checkout "$STATE_FILE_BRANCH" "$STATE_FILE_BRANCHES" "$STATE_FILE_INDEX" "$@";;
        branch)         cmd_branch "$STATE_FILE_BRANCH" "$STATE_FILE_BRANCHES" "$@";;
        remote)         cmd_remote "$STATE_FILE_REMOTES" "$@";;
        tag)            cmd_tag "$STATE_FILE_TAGS" "$STATE_FILE_HEAD" "$@";;
        log)            cmd_log "$STATE_FILE_COMMITS" "$STATE_FILE_TAGS" "$@";;
        describe)       cmd_describe "$STATE_FILE_TAGS" "$@";;
        rev-parse)      cmd_rev_parse "$STATE_FILE_HEAD" "$@";;
        symbolic-ref)   cmd_symbolic_ref "$STATE_FILE_BRANCH" "$@";;
        show)           cmd_show "$STATE_FILE_HEAD" "$@";;
        show-ref)       cmd_show_ref "$STATE_FILE_TAGS" "$@";;
        rev-list)       cmd_rev_list "$STATE_FILE_COMMITS" "$@";;
        status)         cmd_status "$STATE_FILE_INDEX" "$STATE_FILE_BRANCH" "$@";;
        fetch)          cmd_fetch "$@";;
        diff)           cmd_diff "$STATE_FILE_INDEX" "$@";;
        push)           cmd_push "$@";;
        
        # Simulation commands
        noise)          cmd_noise "$SIM_ROOT" "$DATA_DIR" "$@";;
        branches)       cmd_branches "$SIM_ROOT" "$DATA_DIR" "$@";;
        history)        cmd_history "$SIM_ROOT" "$DATA_DIR" "$@";;
        
        *)
            echo "git_simulator: unknown command '$cmd'" >&2
            usage
            return 1
            ;;
    esac
}

main "$@"
