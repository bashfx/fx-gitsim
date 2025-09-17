main() {
    # Show logo for interactive commands only
    case "$1" in
        home-path|version)
            # Skip logo for commands that return data for scripting
            ;;
        *)
            _logo
            ;;
    esac
    
    # Try to source .simrc for environment customization
    _source_simrc
    
    # Show help if no command provided
    if [[ ${#@} -eq 0 ]]; then
        usage
        exit 0
    fi
    
    # For home/project commands, suggest .simrc if not found
    case "$1" in
        home-init|init-in-home|home-vars|template)
            _check_simrc || true  # Don't fail on missing .simrc
            ;;
    esac
    
    # Dispatch to command
    dispatch "$@"
    return $?
}

# Script execution using BashFX pattern
if [ "$0" = "-bash" ]; then
    :
else
    # direct call
    orig_args=("$@")
    options "${orig_args[@]}"
    # Filter out global options but preserve command-specific flags
    args=()
    skip_next=false
    for arg in "${orig_args[@]}"; do
        if [ "$skip_next" = true ]; then
            skip_next=false
            continue
        fi
        
        case "$arg" in
            # Global options that should be filtered
            -d|--debug|-t|--trace|-q|--quiet|-f|-y|--yes|-D|--dev|-h|--help|-v|--version)
                ;;
            # Command-specific flags that should be preserved
            -m|--allow-empty|--template=*|--porcelain|--force|--testsh)
                args+=("$arg")
                # If -m, also preserve the next argument (the message)
                if [[ "$arg" == "-m" ]]; then
                    skip_next=false  # We'll add the next arg in the next iteration
                fi
                ;;
            # Non-option arguments
            *)
                args+=("$arg")
                ;;
        esac
    done
    main "${args[@]}"
    ret=$?
    exit $ret
fi