################################################################################
# Dispatchable Functions (System Management)
################################################################################

do_version() {
    printf "%s v%s\n" "$GITSIM_NAME" "$GITSIM_VERSION"
    return 0
}

do_install() {
    local ret=1

    info "Installing $GITSIM_NAME to XDG+ directories..."

    # Remove previous installation if it exists
    if [[ -f "$GITSIM_LIB_DIR/gitsim.sh" ]]; then
        info "Removing previous installation..."
        rm -f "$GITSIM_LIB_DIR/gitsim.sh"
        trace "Removed previous lib file"
    fi

    if [[ -L "$GITSIM_BIN_LINK" ]] || [[ -f "$GITSIM_BIN_LINK" ]]; then
        info "Removing previous symlink..."
        rm -f "$GITSIM_BIN_LINK"
        trace "Removed previous bin symlink"
    fi

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
    if ln -s "$GITSIM_LIB_DIR/gitsim.sh" "$GITSIM_BIN_LINK"; then
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
    local ret=1
    
    if [[ "$opt_force" == false ]]; then
        error "Uninstall requires --force flag for safety"
        info "Use: $GITSIM_NAME uninstall --force"
        return 1
    fi
    
    info "Uninstalling $GITSIM_NAME..."
    
    # Remove symlink
    if [ -L "$GITSIM_BIN_LINK" ]; then
        rm -f "$GITSIM_BIN_LINK"
        trace "Removed symlink $GITSIM_BIN_LINK"
    fi
    
    # Remove lib directory
    if [ -d "$GITSIM_LIB_DIR" ]; then
        rm -rf "$GITSIM_LIB_DIR"
        trace "Removed lib directory $GITSIM_LIB_DIR"
    fi
    
    okay "Uninstalled $GITSIM_NAME successfully"
    return 0
}