################################################################################
# RC System & Configuration Management
################################################################################

# Source .simrc file if it exists
_source_simrc() {
    local simrc_file=".simrc"
    
    if [ -f "$simrc_file" ]; then
        trace "Sourcing $simrc_file"
        # shellcheck disable=SC1090
        source "$simrc_file"
        return 0
    fi
    
    return 1
}

# Check if we should offer to create .simrc
_check_simrc() {
    local simrc_file=".simrc"
    
    if [ ! -f "$simrc_file" ]; then
        warn "No .simrc file found in current directory"
        info "Run 'gitsim rcgen' to create a configuration file for SIM_ variables"
        return 1
    fi
    
    return 0
}

# Track generated files for cleanup
_track_generated_file() {
    local file="$1"
    local simrc_file=".simrc"
    
    # Ensure .simrc exists
    if [[ ! -f "$simrc_file" ]]; then
        warn "No .simrc file found to track generated files"
        return 1
    fi
    
    # Add to GENERATED_FILES array if not already present
    if ! grep -q "GENERATED_FILES.*$file" "$simrc_file"; then
        # Check if GENERATED_FILES array exists
        if grep -q "GENERATED_FILES=" "$simrc_file"; then
            # Array exists, append to it
            sed -i "s/GENERATED_FILES=(/GENERATED_FILES=(\"$file\" /" "$simrc_file"
        else
            # Array doesn't exist, create it
            echo "GENERATED_FILES=(\"$file\")" >> "$simrc_file"
        fi
    fi
}

# Generate .simrc content
__print_simrc() {
    local file="$1"
    
    cat > "$file" << EOF
#!/usr/bin/env bash
# .simrc - GitSim environment configuration
# This file is automatically sourced by gitsim commands

# SIM_ variables that can be overridden for testing
# These inherit from your shell environment but can be customized here

# Base simulated home (inherits from XDG_HOME or HOME)
SIM_HOME=\${XDG_HOME:-\$HOME}

# Simulated user identity
SIM_USER=\${USER:-testuser}

# Simulated shell environment  
SIM_SHELL=\${SHELL:-/bin/bash}

# Simulated default editor
SIM_EDITOR=\${EDITOR:-nano}

# Simulated locale
SIM_LANG=\${LANG:-en_US.UTF-8}

# Generated files tracking (for cleanup)
GENERATED_FILES=()

# Example custom overrides:
# SIM_USER="alice"
# SIM_EDITOR="vim"
# SIM_HOME="/tmp/custom-sim-home"

# Export variables so they're available to subshells
export SIM_HOME SIM_USER SIM_SHELL SIM_EDITOR SIM_LANG
EOF
    
    return $?
}