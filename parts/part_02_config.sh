################################################################################
# Configuration & XDG+ Compliance
################################################################################

readonly GITSIM_VERSION="2.1.0"
readonly GITSIM_NAME="gitsim"

# XDG+ Base Configuration
: ${XDG_HOME:="$HOME/.local"}
: ${XDG_LIB_HOME:="$XDG_HOME/lib"}
: ${XDG_BIN_HOME:="$XDG_HOME/bin"}
: ${XDG_ETC_HOME:="$XDG_HOME/etc"}
: ${XDG_DATA_HOME:="$XDG_HOME/data"}
: ${XDG_CACHE_HOME:="$HOME/.cache"}

# Temp directory preference (respects user's cache preference)
: ${TMPDIR:="$XDG_CACHE_HOME/tmp"}

# BashFX FX-specific paths
readonly GITSIM_LIB_DIR="$XDG_LIB_HOME/fx/$GITSIM_NAME"
readonly GITSIM_BIN_LINK="$XDG_BIN_HOME/fx/$GITSIM_NAME"
readonly GITSIM_ETC_DIR="$XDG_ETC_HOME/$GITSIM_NAME"

# SIM_ variables that can inherit from live shell or be overridden
: ${SIM_HOME:=${XDG_HOME:-$HOME}}
: ${SIM_USER:=${USER:-testuser}}
: ${SIM_SHELL:=${SHELL:-/bin/bash}}
: ${SIM_EDITOR:=${EDITOR:-nano}}
: ${SIM_LANG:=${LANG:-en_US.UTF-8}}

# Standard option flags
opt_debug=false
opt_trace=false
opt_quiet=false
opt_force=false
opt_yes=false
opt_dev=false