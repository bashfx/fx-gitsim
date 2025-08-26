################################################################################
# Dispatchable Functions (Utilities)
################################################################################

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

do_rcgen() {
    local simrc_file=".simrc"
    local force_overwrite=false
    
    # Check for force flag
    if [[ "$1" == "--force" ]]; then
        force_overwrite=true
        shift
    fi
    
    # Check if file exists and we're not forcing
    if [ -f "$simrc_file" ] && [[ "$force_overwrite" == false ]]; then
        error "File $simrc_file already exists. Use --force to overwrite."
        return 1
    fi
    
    # Generate the .simrc file
    __print_simrc "$simrc_file"
    
    okay "Created $simrc_file configuration file"
    info "Edit this file to customize your SIM_ environment variables"
    info "The file will be automatically sourced when running gitsim commands"
    
    return 0
}

do_cleanup() {
    local force_cleanup="${1:-false}"
    local sim_root="$PWD"
    local simrc_file=".simrc"
    
    info "Starting cleanup of GitSim artifacts..."
    
    # Clean up .gitsim directory
    if [[ -d ".gitsim" ]]; then
        if [[ "$force_cleanup" == "true" ]] || [[ "$opt_yes" == "true" ]]; then
            rm -rf ".gitsim"
            okay "Removed .gitsim directory"
        else
            warn "Found .gitsim directory"
            read -p "Remove .gitsim directory? [y/N]: " -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf ".gitsim"
                okay "Removed .gitsim directory"
            fi
        fi
    fi
    
    # Clean up generated files from .simrc
    if [[ -f "$simrc_file" ]]; then
        # Source the .simrc to get GENERATED_FILES array
        local generated_files=()
        # Extract GENERATED_FILES array safely
        if grep -q "GENERATED_FILES=" "$simrc_file"; then
            # Use eval with proper safety checks
            local files_line
            files_line=$(grep "GENERATED_FILES=" "$simrc_file" | head -1)
            if [[ -n "$files_line" ]]; then
                eval "$files_line"
                generated_files=("${GENERATED_FILES[@]}")
            fi
        fi
        
        if [[ ${#generated_files[@]} -gt 0 ]]; then
            info "Found ${#generated_files[@]} tracked generated files"
            for file in "${generated_files[@]}"; do
                if [[ -f "$file" ]]; then
                    if [[ "$force_cleanup" == "true" ]] || [[ "$opt_yes" == "true" ]]; then
                        rm -f "$file"
                        okay "Removed generated file: $file"
                    else
                        read -p "Remove generated file '$file'? [y/N]: " -r
                        if [[ $REPLY =~ ^[Yy]$ ]]; then
                            rm -f "$file"
                            okay "Removed generated file: $file"
                        fi
                    fi
                fi
            done
        fi
        
        # Clean up .simrc itself
        if [[ "$force_cleanup" == "true" ]] || [[ "$opt_yes" == "true" ]]; then
            rm -f "$simrc_file"
            okay "Removed $simrc_file"
        else
            read -p "Remove $simrc_file? [y/N]: " -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -f "$simrc_file"
                okay "Removed $simrc_file"
            fi
        fi
    fi
    
    # Clean up .gitignore entries we added
    if [[ -f ".gitignore" ]] && grep -q "^\.gitsim/$" ".gitignore"; then
        grep -v "^\.gitsim/$" ".gitignore" > ".gitignore.tmp" && mv ".gitignore.tmp" ".gitignore"
        okay "Removed .gitsim/ from .gitignore"
    fi
    
    okay "Cleanup complete"
    return 0
}