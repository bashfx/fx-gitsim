################################################################################
# Simple stderr functions
################################################################################

stderr() { printf "%s\n" "$*" >&2; }
info() { [[ "$opt_quiet" == true ]] && return; stderr "[INFO] $*"; }
warn() { [[ "$opt_quiet" == true ]] && return; stderr "[WARN] $*"; }
error() { stderr "[ERROR] $*"; }
fatal() { stderr "[FATAL] $*"; exit 1; }
okay() { [[ "$opt_quiet" == true ]] && return; stderr "[OK] $*"; }
trace() { [[ "$opt_trace" == true ]] && stderr "[TRACE] $*"; }