################################################################################
# Core System Functions
################################################################################

dispatch() {
    local cmd="$1"
    shift
    
    case "$cmd" in
        # Core git simulation
        init)           
            # Check for --template flag
            local template=""
            local other_args=()
            for arg in "$@"; do
                if [[ "$arg" =~ ^--template=(.+)$ ]]; then
                    template="${BASH_REMATCH[1]}"
                else
                    other_args+=("$arg")
                fi
            done
            
            if [[ -n "$template" ]]; then
                do_init_with_template "$template" "${other_args[@]}"
            else
                do_init "$@"
            fi
            ;;
        init-in-home)   
            # Check for --template flag
            local template=""
            local project_name="$1"
            for arg in "$@"; do
                if [[ "$arg" =~ ^--template=(.+)$ ]]; then
                    template="${BASH_REMATCH[1]}"
                    break
                fi
            done
            
            if [[ -n "$template" ]]; then
                do_init_in_home_with_template "$project_name" "$template"
            else
                do_init_in_home "$@"
            fi
            ;;
        add)            do_add "$@";;
        commit)         do_commit "$@";;
        status)         do_status "$@";;
        
        # Home environment
        home-init)      
            # Check for --template flag
            local template=""
            for arg in "$@"; do
                if [[ "$arg" =~ ^--template=(.+)$ ]]; then
                    template="${BASH_REMATCH[1]}"
                    break
                fi
            done
            
            if [[ -n "$template" ]]; then
                do_init_in_home_with_template "$1" "$template" 
            else
                do_home_init "$@"
            fi
            ;;
        home-env)       do_home_env "$@";;
        home-path)      do_home_path "$@";;
        home-ls)        do_home_ls "$@";;
        home-vars)      do_home_vars "$@";;
        
        # Template system
        template)       do_template "$@";;
        template-list)  do_template_list "$@";;
        template-show)  do_template_show "$@";;
        
        # Test data generation
        noise)          do_noise "$@";;
        
        # Configuration
        rcgen)          do_rcgen "$@";;
        cleanup)        do_cleanup "$@";;
        
        # System management
        install)        do_install "$@";;
        uninstall)      do_uninstall "$@";;
        version)        do_version "$@";;
        help)           usage;;

        *)
            error "Unknown command: $cmd"
            usage
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
    init [--template=TYPE]      Create git simulation in current directory
    init-in-home [project] [--template=TYPE]  Create git simulation in simulated home project
    add <files>                 Add files to staging area
    commit -m "message"         Create a commit with message
    status                      Show repository status

HOME ENVIRONMENT:
    home-init [project] [--template=TYPE]  Initialize simulated home environment
    home-env                   Show simulated environment variables
    home-path                  Get path to simulated home directory  
    home-ls [dir] [opts]       List contents of simulated home
    home-vars                  Show SIM_ environment variables

TEMPLATES:
    template <type> [project]  Create project template (rust, bash, node, python)
    template-list              List available templates
    template-show <type>       Show template preview

TEST DATA:
    noise [count]              Create random files and stage them

CONFIGURATION:
    rcgen [--force]            Generate .simrc configuration file
    cleanup [--force]          Clean up all GitSim artifacts

SYSTEM:
    install                    Install to XDG+ directories
    uninstall --force          Remove installation
    version                    Show version information

OPTIONS:
    -d, --debug                Enable debug output
    -t, --trace                Enable trace output (implies -d)
    -q, --quiet                Suppress all output except errors
    -f, --force                Force operations, bypass safety checks
    -y, --yes                  Automatically answer yes to prompts
    -D, --dev                  Enable developer mode

ENVIRONMENT VARIABLES:
    SIM_HOME                   Base simulated home [$SIM_HOME]
    SIM_USER                   Simulated username [$SIM_USER]  
    SIM_SHELL                  Simulated shell [$SIM_SHELL]
    SIM_EDITOR                 Simulated editor [$SIM_EDITOR]

EXAMPLES:
    gitsim init --template=rust
    gitsim init-in-home webapp --template=node
    gitsim template python backend
    gitsim home-init myproject
    gitsim noise 5
    gitsim commit -m "Test commit"
    
    # Use simulated environment in scripts:
    HOME_PATH=$(gitsim home-path)
    cp myfile "$HOME_PATH/.config/"

TEMPLATES AVAILABLE:
    rust (rs)      - Rust project with Cargo
    bash (sh)      - BashFX-compliant script project
    node (js)      - Node.js project with npm
    python (py)    - Python project with modern tooling

EOF
}

options() {
    local this next opts=("$@")
    for ((i=0; i<${#opts[@]}; i++)); do
        this=${opts[i]}
        next=${opts[i+1]}
        case "$this" in
            -d|--debug)
                opt_debug=true
                opt_quiet=false
                ;;
            -t|--trace)
                opt_trace=true
                opt_debug=true
                opt_quiet=false
                ;;
            -q|--quiet)
                opt_quiet=true
                ;;
            -f|--force)
                opt_force=true
                ;;
            -y|--yes)
                opt_yes=true
                ;;
            -D|--dev)
                opt_dev=true
                opt_debug=true
                opt_trace=true
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                :
                ;;
        esac
    done
}