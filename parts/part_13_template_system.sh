################################################################################
# Template System - Core Infrastructure
################################################################################

# Template registry - populated dynamically by language modules
declare -A TEMPLATES=()
declare -A TEMPLATE_ALIASES=()

################################################################################
# Template Registration System
################################################################################

# Registration function for language modules to call
_register_template() {
    local name="$1"
    local description="$2"
    local aliases="$3"  # Optional: space-separated aliases
    
    TEMPLATES["$name"]="$description"
    
    # Register aliases if provided
    if [[ -n "$aliases" ]]; then
        for alias in $aliases; do
            TEMPLATE_ALIASES["$alias"]="$name"
        done
    fi
    
    trace "Registered template: $name ($description)"
}

################################################################################
# Mid-Ordinal Template Functions
################################################################################

# Validate template exists and resolve aliases
_validate_template() {
    local template="$1"
    local resolved="$template"
    
    # Check if it's an alias
    if [[ -n "${TEMPLATE_ALIASES[$template]}" ]]; then
        resolved="${TEMPLATE_ALIASES[$template]}"
    fi
    
    # Check if template exists
    if [[ -z "${TEMPLATES[$resolved]}" ]]; then
        error "Unknown template: $template"
        info "Available templates: ${!TEMPLATES[*]}"
        return 1
    fi
    
    printf "%s" "$resolved"
    return 0
}

# Template dispatcher - dynamically calls language-specific functions
_dispatch_template() {
    local template="$1"
    local target_dir="$2"
    local project_name="$3"
    local testsh_flag="${4:-false}"

    # Dynamic function call: _create_rust_template, _create_node_template, etc.
    local create_func="_create_${template}_template"

    if declare -f "$create_func" >/dev/null 2>&1; then
        "$create_func" "$target_dir" "$project_name" "$testsh_flag"
    else
        error "Template implementation not found: $template"
        info "Function $create_func is not defined"
        return 1
    fi
}

# Apply template to specified directory
_apply_template() {
    local template="$1"
    local target_dir="$2"
    local project_name="$3"
    local testsh_flag="${4:-false}"
    local validated_template

    # Validate and resolve template name
    validated_template=$(_validate_template "$template") || return 1

    # Ensure target directory exists
    mkdir -p "$target_dir"

    # Dispatch to language-specific implementation
    _dispatch_template "$validated_template" "$target_dir" "$project_name" "$testsh_flag"
}

# Enhanced init functions with template support
_init_with_template() {
    local template="$1"
    local project_name="$2"
    local target_dir="$3"
    
    # First create the git simulation
    if __create_git_structure "$target_dir/.gitsim/.data"; then
        trace "Created git simulation structure"
    else
        error "Failed to create git simulation structure"
        return 1
    fi
    
    # Then apply the template
    if _apply_template "$template" "$target_dir" "$project_name"; then
        okay "Applied $template template to $target_dir"
        __add_gitignore_entry ".gitsim/"
        return 0
    else
        error "Failed to apply template: $template"
        return 1
    fi
}

################################################################################
# Dispatchable Functions (High-Order)
################################################################################

do_template() {
    local template=""
    local project_name=""
    local target_dir="$PWD"
    local testsh_flag=false

    # Parse arguments and flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --testsh)
                testsh_flag=true
                shift
                ;;
            --template=*)
                template="${1#--template=}"
                shift
                ;;
            *)
                if [[ -z "$template" ]]; then
                    template="$1"
                elif [[ -z "$project_name" ]]; then
                    project_name="$1"
                else
                    error "Unexpected argument: $1"
                    return 1
                fi
                shift
                ;;
        esac
    done

    # Set defaults
    [[ -z "$project_name" ]] && project_name="$(basename "$PWD")"

    if [[ -z "$template" ]]; then
        error "Template name required"
        info "Usage: gitsim template <template-name> [project-name] [--testsh]"
        do_template_list
        return 1
    fi

    # If project name provided, create subdirectory
    if [[ "$project_name" != "$(basename "$PWD")" ]]; then
        target_dir="$PWD/$project_name"
    fi

    info "Creating $template template in $target_dir"
    if [[ "$testsh_flag" == true ]]; then
        info "Including TESTSH comprehensive test suite"
    fi

    _apply_template "$template" "$target_dir" "$project_name" "$testsh_flag"
}

do_template_list() {
    if [[ ${#TEMPLATES[@]} -eq 0 ]]; then
        warn "No templates available"
        return 1
    fi
    
    printf "Available templates:\n"
    for template in "${!TEMPLATES[@]}"; do
        printf "  %-10s - %s\n" "$template" "${TEMPLATES[$template]}"
    done
    
    # Show aliases if any exist
    if [[ ${#TEMPLATE_ALIASES[@]} -gt 0 ]]; then
        printf "\nAliases:\n"
        for alias in "${!TEMPLATE_ALIASES[@]}"; do
            printf "  %-10s -> %s\n" "$alias" "${TEMPLATE_ALIASES[$alias]}"
        done
    fi
}

do_template_show() {
    local template="$1"
    local validated_template
    
    if [[ -z "$template" ]]; then
        error "Template name required"
        info "Usage: gitsim template-show <template-name>"
        return 1
    fi
    
    validated_template=$(_validate_template "$template") || return 1
    
    printf "Template: %s\n" "$validated_template"
    printf "Description: %s\n" "${TEMPLATES[$validated_template]}"
    printf "\nThis template creates:\n"
    
    # Call template-specific show function if it exists
    local show_func="_show_${validated_template}_template"
    if declare -f "$show_func" >/dev/null 2>&1; then
        "$show_func"
    else
        info "No detailed preview available for $validated_template template"
    fi
}

################################################################################
# Enhanced Existing Commands
################################################################################

# Enhanced do_init with template support
do_init_with_template() {
    local template="$1"
    local project_name="${2:-$(basename "$PWD")}"
    
    if _init_with_template "$template" "$project_name" "$PWD"; then
        okay "Initialized Git simulator repository with $template template"
        return 0
    else
        error "Failed to initialize with template: $template"
        return 1
    fi
}

# Enhanced do_init_in_home with template support  
do_init_in_home_with_template() {
    local project_name="$1"
    local template="$2"
    local sim_root
    local home_dir
    local project_dir
    
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
    
    # Apply template to project directory
    if _init_with_template "$template" "$project_name" "$project_dir"; then
        okay "Initialized Git simulator repository with $template template in $project_dir"
        info "Project path: $project_dir"
        info "To work in this project: cd '$project_dir'"
        return 0
    else
        error "Failed to initialize project with template: $template"
        return 1
    fi
}

################################################################################
# Common Template Utilities
################################################################################

# Generate README.md - shared across all templates
__print_readme_md() {
    local file="$1"
    local project_name="$2"
    local language="$3"
    
    cat > "$file" << EOF
# $project_name

A sample $language project generated by GitSim for testing purposes.

## Description

This project was automatically generated to provide a realistic structure for testing deployment scripts, build tools, and other development workflows in a safe, isolated environment.

## Generated by GitSim

This project structure is simulated and intended for testing only. It includes:
- Realistic project files and structure
- Fake package/dependency files for build tool compatibility
- Standard configuration files
- Basic example code

## Usage

This project can be used to test:
- Build and deployment scripts
- Package managers and dependency resolution
- Development tooling and workflows
- CI/CD pipeline configurations

Generated on: $(date)
Generated by: GitSim v$GITSIM_VERSION
EOF
}

# Generate common .gitignore patterns
__print_common_gitignore() {
    local file="$1"
    
    cat >> "$file" << 'EOF'

# GitSim
.gitsim/
.simrc

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
EOF
}