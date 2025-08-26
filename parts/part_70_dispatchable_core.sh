################################################################################
# Dispatchable Functions (Core Git Commands)
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
    local branch_file
    local ret=1
    
    sim_root=$(_find_sim_root) || {
        error "Not in a git repository (or any of the parent directories): .gitsim"
        return 128
    }
    
    index_file="$sim_root/.gitsim/.data/index"
    branch_file="$sim_root/.gitsim/.data/branch.txt"
    
    if [[ "$1" == "--porcelain" ]]; then
        if [ -s "$index_file" ]; then
            sed 's/^/A  /' "$index_file"
        fi
        return 0
    fi
    
    # Human-readable output
    local branch
    branch=$(cat "$branch_file" 2>/dev/null)
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