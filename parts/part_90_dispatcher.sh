################################################################################
# Core System Functions
################################################################################

# NOTE: Main dispatch() function is defined in part_69_dispatcher.sh
# This part only contains the usage() function to avoid duplication

usage() {
    local version
    version=$(_get_version)

    cat << EOF
gitsim - Git & Home Environment Simulator v$version

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

TEMPLATES:
    template <type> [project]  Create project template (rust, bash, node, python)
    template-list              List available templates
    template-show <type>       Show template preview

TEST DATA:
    noise [count]          Create random files and stage them

CONFIGURATION:
    rcgen [--force]        Generate .simrc configuration file
    cleanup [--force]      Clean up all GitSim artifacts

SYSTEM:
    install                Install to XDG+ directories
    uninstall --force      Remove installation
    version                Show version information
    help                   Show this help message

OPTIONS:
    -d, --debug            Enable debug output
    -t, --trace            Enable trace output (implies -d)
    -q, --quiet            Suppress all output except errors
    -f, --force            Force operations, bypass safety checks
    -D, --dev              Enable developer mode
    -h, --help             Show this help message
    -v, --version          Show version information

ENVIRONMENT VARIABLES:
    SIM_HOME               Base simulated home [$SIM_HOME]
    SIM_USER               Simulated username [$SIM_USER]  
    SIM_SHELL              Simulated shell [$SIM_SHELL]
    SIM_EDITOR             Simulated editor [$SIM_EDITOR]

EXAMPLES:
    gitsim init
    gitsim home-init myproject
    gitsim template rust myproject
    gitsim template-list
    gitsim noise 5
    gitsim commit -m "Test commit"
    
    # Use simulated environment in scripts:
    HOME_PATH=$(gitsim home-path)
    cp myfile "$HOME_PATH/.config/"

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
                ;;
            -t|--trace)
                opt_trace=true
                opt_debug=true
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
            -v|--version)
                do_version
                exit 0
                ;;
            *)
                :
                ;;
        esac
    done
}