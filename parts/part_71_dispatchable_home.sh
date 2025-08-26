################################################################################
# Dispatchable Functions (Home Environment)
################################################################################

do_init_in_home() {
    local project_name="${1:-testproject}"
    local sim_root
    local home_dir
    local project_dir
    local ret=1
    
    sim_root=$(_find_sim_root) || {
        # Create a temporary sim root in current directory
        if __create_git_structure ".gitsim/.data"; then
            sim_root="$PWD"
        else
            error "Failed to create temporary sim root"
            return 1
        fi
    }
    
    home_dir=$(_get_sim_home "$sim_root")
    
    # Ensure home is initialized
    if [ ! -d "$home_dir" ]; then
        do_home_init "$sim_root" "$project_name" || return 1
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
    local sim_root="${1:-$PWD}"
    local project_name="${2:-testproject}"
    local home_dir
    local project_dir
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
    
    # Create project directory
    project_dir=$(_get_sim_project_dir "$home_dir" "$project_name")
    mkdir -p "$project_dir"
    okay "Created project directory at $project_dir"
    
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
    printf "Or create a .simrc file: gitsim rcgen\n"
    return 0
}