#!/usr/bin/env bash
#
# build.sh - GitSim Modular Build System
# BashFX Build Pattern v1
#

# Configuration - paths relative to script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_FILE="$PROJECT_ROOT/gitsim.sh"
PARTS_DIR="$PROJECT_ROOT/parts"
BUILD_MAP="$PARTS_DIR/build.map"
BACKUP_SUFFIX=".bak"

# Colors for output
readonly RED=$'\033[31m'
readonly GREEN=$'\033[32m' 
readonly YELLOW=$'\033[33m'
readonly BLUE=$'\033[34m'
readonly RESET=$'\033[0m'

# Logging functions
info() { printf "%s[INFO]%s %s\n" "$BLUE" "$RESET" "$*" >&2; }
okay() { printf "%s[OK]%s %s\n" "$GREEN" "$RESET" "$*" >&2; }
warn() { printf "%s[WARN]%s %s\n" "$YELLOW" "$RESET" "$*" >&2; }
error() { printf "%s[ERROR]%s %s\n" "$RED" "$RESET" "$*" >&2; }
fatal() { error "$*"; exit 1; }

# Validate build environment
check_environment() {
    [[ -d "$PARTS_DIR" ]] || fatal "Parts directory '$PARTS_DIR' not found"
    [[ -f "$BUILD_MAP" ]] || fatal "Build map '$BUILD_MAP' not found"
    info "Environment validated"
}

# Smart sync - update part files from loose files
smart_sync() {
    local synced=0
    
    info "Performing smart sync..."
    
    # Find loose files with numeric prefixes
    while IFS= read -r -d '' loose_file; do
        local filename=$(basename "$loose_file")
        local prefix="${filename%%_*}"
        
        # Check if prefix is numeric
        if [[ "$prefix" =~ ^[0-9]+$ ]]; then
            # Find matching official part file
            local official_part=$(grep "^${prefix}[[:space:]]*:" "$BUILD_MAP" | cut -d':' -f2 | sed 's/^[[:space:]]*//')
            
            if [[ -n "$official_part" ]]; then
                local official_path="$PARTS_DIR/$official_part"
                
                if [[ "$loose_file" -nt "$official_path" ]] || [[ ! -f "$official_path" ]]; then
                    info "Syncing $filename -> $official_part"
                    cp "$loose_file" "$official_path"
                    ((synced++))
                fi
            fi
        fi
    done < <(find "$PARTS_DIR" -name "[0-9]*" -type f -print0 2>/dev/null)
    
    if [[ $synced -gt 0 ]]; then
        okay "Smart sync complete - $synced files updated"
    else
        info "Smart sync complete - no updates needed"
    fi
}

# Remove stale output file to prevent stale builds
cleanup_stale() {
    if [[ -f "$OUTPUT_FILE" ]]; then
        info "Removing stale output file: $OUTPUT_FILE"
        rm -f "$OUTPUT_FILE" || warn "Could not remove stale output file"
    fi
}

# Build the output file from parts
build_script() {
    local temp_file="${OUTPUT_FILE}.tmp"
    local parts_used=0
    local parts_missing=0
    
    info "Building $OUTPUT_FILE from parts... (expecting 18 parts)"
    
    # Create temporary file
    > "$temp_file"
    
    # Process build map line by line
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        # Parse map entry: "NN : filename.sh"
        if [[ "$line" =~ ^([0-9]+)[[:space:]]*:[[:space:]]*(.+)$ ]]; then
            local part_num="${BASH_REMATCH[1]}"
            local part_file="${BASH_REMATCH[2]// /}" # Remove spaces
            local part_path="$PARTS_DIR/$part_file"
            
            if [[ -f "$part_path" ]]; then
                info "Adding part $part_num: $part_file"
                
                # Add part header comment
                cat >> "$temp_file" << EOF

################################################################################
# Part $part_num: $part_file
################################################################################

EOF
                
                # Add the actual part content
                cat "$part_path" >> "$temp_file"
                echo >> "$temp_file"  # Add newline between parts
                ((parts_used++))
            else
                warn "Part file not found: $part_path"
                ((parts_missing++))
            fi
        else
            warn "Invalid build map line: $line"
        fi
    done < "$BUILD_MAP"
    
    # Check results
    if [[ $parts_used -eq 0 ]]; then
        fatal "No parts were processed"
    fi
    
    if [[ $parts_missing -gt 0 ]]; then
        warn "$parts_missing part files were missing"
    fi
    
    # Backup existing file if it exists
    if [[ -f "$OUTPUT_FILE" ]]; then
        cp "$OUTPUT_FILE" "${OUTPUT_FILE}${BACKUP_SUFFIX}"
        info "Backed up existing file to ${OUTPUT_FILE}${BACKUP_SUFFIX}"
    fi
    
    # Move temp file to final location
    mv "$temp_file" "$OUTPUT_FILE"
    chmod +x "$OUTPUT_FILE"
    
    okay "Built $OUTPUT_FILE from $parts_used parts"
    
    # Show file size info
    local file_size=$(wc -l < "$OUTPUT_FILE")
    info "Generated script: $file_size lines"
    
    if [[ $file_size -gt 4000 ]]; then
        warn "Script size ($file_size lines) approaching AI comprehension limit (4000 lines)"
    fi
}

# Validate the built script
validate_script() {
    info "Validating built script..."
    
    if [[ ! -f "$OUTPUT_FILE" ]]; then
        fatal "Output file $OUTPUT_FILE not found"
    fi
    
    # Check for basic syntax errors
    if bash -n "$OUTPUT_FILE"; then
        okay "Script syntax validation passed"
    else
        fatal "Script has syntax errors"
    fi
    
    # Check for required components
    local missing_components=0
    
    # Check for main function
    if ! grep -q "^main()" "$OUTPUT_FILE"; then
        error "Missing main() function"
        ((missing_components++))
    fi
    
    # Check for dispatch function
    if ! grep -q "^dispatch()" "$OUTPUT_FILE"; then
        error "Missing dispatch() function"
        ((missing_components++))
    fi
    
    # Check for template system
    if ! grep -q "_register_template" "$OUTPUT_FILE"; then
        warn "Template system not found"
    fi
    
    # Check for BashFX execution pattern
    if ! grep -q 'orig_args=("$@")' "$OUTPUT_FILE"; then
        warn "BashFX execution pattern not found"
    fi
    
    if [[ $missing_components -eq 0 ]]; then
        okay "Script validation passed"
        return 0
    else
        error "Script validation failed - $missing_components missing components"
        return 1
    fi
}

# Test the built script
test_script() {
    info "Testing built script..."
    
    if [[ ! -f "$OUTPUT_FILE" ]]; then
        fatal "Output file $OUTPUT_FILE not found"
    fi
    
    # Test basic commands
    local test_commands=(
        "version"
        "template-list"
        "--help"
    )
    
    for cmd in "${test_commands[@]}"; do
        info "Testing command: $cmd"
        if "./$OUTPUT_FILE" $cmd >/dev/null 2>&1; then
            okay "Command '$cmd' executed successfully"
        else
            warn "Command '$cmd' failed or had issues"
        fi
    done
    
    okay "Basic script testing completed"
}

# Clean build artifacts
clean_build() {
    info "Cleaning build artifacts..."
    
    local cleaned=0
    
    # Remove temporary files
    for pattern in "${OUTPUT_FILE}.tmp" "${OUTPUT_FILE}${BACKUP_SUFFIX}" "${OUTPUT_FILE}.test"; do
        if [[ -f "$pattern" ]]; then
            rm -f "$pattern"
            info "Removed $pattern"
            ((cleaned++))
        fi
    done
    
    if [[ $cleaned -gt 0 ]]; then
        okay "Cleaned $cleaned build artifacts"
    else
        info "No build artifacts to clean"
    fi
}

# Show build statistics
show_stats() {
    if [[ ! -f "$OUTPUT_FILE" ]]; then
        warn "No output file to analyze"
        return 1
    fi
    
    info "Build Statistics:"
    printf "  Output file: %s\n" "$OUTPUT_FILE"
    printf "  File size: %s bytes\n" "$(wc -c < "$OUTPUT_FILE")"
    printf "  Line count: %s lines\n" "$(wc -l < "$OUTPUT_FILE")"
    printf "  Parts directory: %s\n" "$PARTS_DIR"
    printf "  Build map: %s\n" "$BUILD_MAP"
    
    # Count available parts
    local available_parts=$(find "$PARTS_DIR" -name "part_*.sh" | wc -l)
    printf "  Available parts: %s\n" "$available_parts"
    
    # Count parts in build map
    local mapped_parts=$(grep -c "^[0-9]" "$BUILD_MAP" 2>/dev/null || echo "0")
    printf "  Mapped parts: %s\n" "$mapped_parts"
    
    echo
}

# List available parts
list_parts() {
    info "Available parts in $PARTS_DIR:"
    
    if [[ -f "$BUILD_MAP" ]]; then
        echo "Parts in build map:"
        while IFS= read -r line; do
            if [[ "$line" =~ ^([0-9]+)[[:space:]]*:[[:space:]]*(.+)$ ]]; then
                local part_num="${BASH_REMATCH[1]}"
                local part_file="${BASH_REMATCH[2]// /}"
                local part_path="$PARTS_DIR/$part_file"
                
                if [[ -f "$part_path" ]]; then
                    printf "  %s: %s ✓\n" "$part_num" "$part_file"
                else
                    printf "  %s: %s ✗ (missing)\n" "$part_num" "$part_file"
                fi
            fi
        done < "$BUILD_MAP"
    fi
    
    echo
    echo "All part files:"
    for part_file in "$PARTS_DIR"/part_*.sh; do
        if [[ -f "$part_file" ]]; then
            local basename_file=$(basename "$part_file")
            local file_size=$(wc -l < "$part_file")
            printf "  %s (%s lines)\n" "$basename_file" "$file_size"
        fi
    done
}

# Show usage information
usage() {
    cat << 'EOF'
build.sh - GitSim Modular Build System

USAGE:
    build.sh [command]

COMMANDS:
    build       Build the output script (default)
    clean       Clean build artifacts  
    validate    Validate built script
    test        Test built script basic functionality
    sync        Perform smart sync of loose files
    stats       Show build statistics
    list        List available parts
    help        Show this help message

EXAMPLES:
    ./build.sh                # Build the script
    ./build.sh clean          # Clean artifacts
    ./build.sh validate       # Check script validity
    ./build.sh sync build     # Sync then build

EOF
}

# Main execution
main() {
    local command="${1:-build}"
    
    case "$command" in
        build)
            check_environment
            cleanup_stale
            smart_sync
            build_script
            validate_script
            show_stats
            ;;
        clean)
            clean_build
            ;;
        validate)
            check_environment
            validate_script
            ;;
        test)
            check_environment
            validate_script
            test_script
            ;;
        sync)
            check_environment
            smart_sync
            ;;
        stats)
            show_stats
            ;;
        list)
            check_environment
            list_parts
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

main "$@"
