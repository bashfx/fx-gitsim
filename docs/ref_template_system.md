# GitSim Template System Implementation Plan

## Overview

Add project template generation to GitSim with integrated and standalone command support, following BashFX 2.0 architecture patterns.

## Command Interface Design

### Integrated Commands
```bash
# Enhanced existing commands with --template flag
gitsim init --template=rust
gitsim init-in-home myproject --template=node
gitsim home-init myproject --template=python
```

### Standalone Commands  
```bash
# Atomic template operations (for dev testing)
gitsim template rust                    # In current dir
gitsim template rust myproject          # In specific dir
gitsim template-list                    # Show available templates
gitsim template-show rust              # Preview template contents
```

## Template Priority & Structure

### 1. Rust (Highest Priority)
```
myproject/
├── Cargo.toml          # Basic package manifest
├── Cargo.lock          # Fake lock file
├── src/
│   ├── main.rs         # Hello world binary
│   └── lib.rs          # Basic library
├── tests/
│   └── integration_test.rs
├── .gitignore          # Rust-specific ignores
└── README.md           # Project description
```

### 2. Bash (BashFX-compliant)
```
myproject/
├── myproject.sh        # Main script (BashFX template)
├── parts/              # Build system ready
│   ├── build.map
│   └── 01_header.sh
├── .gitignore
├── README.md
└── test_runner.sh      # Basic test framework
```

### 3. JavaScript/Node.js
```
myproject/
├── package.json        # NPM manifest
├── package-lock.json   # Fake lock file  
├── src/
│   └── index.js        # Hello world
├── test/
│   └── index.test.js   # Basic test
├── .gitignore          # Node-specific ignores
└── README.md
```

### 4. Python  
```
myproject/
├── pyproject.toml      # Modern Python packaging
├── requirements.txt    # Dependencies
├── src/
│   └── myproject/
│       ├── __init__.py
│       └── main.py     # Hello world
├── tests/
│   └── test_main.py    # Basic test
├── .gitignore          # Python-specific ignores
└── README.md
```

## Architecture Implementation

### Build System Integration
Add new part: `13_template_system.sh`

Update build.map:
```
13 : 13_template_system.sh
```

### Function Ordinality Structure

#### High-Order Functions (Dispatchable)
```bash
do_template()           # Standalone template command
do_template_list()      # List available templates  
do_template_show()      # Preview template contents

# Enhanced existing functions
do_init()              # Add --template support
do_init_in_home()      # Add --template support  
do_home_init()         # Add --template support
```

#### Mid-Ordinal Functions (Orchestrators)
```bash
_create_template()     # Template creation orchestrator
_validate_template()   # Ensure template exists
_apply_template()      # Apply template to directory
_get_template_config() # Read from .gitsimrc
```

#### Low-Ordinal Functions (Literal Operations)  
```bash
# Rust templates
__print_cargo_toml()
__print_rust_main()
__print_rust_lib()
__print_rust_gitignore()

# Bash templates  
__print_bashfx_script()
__print_bashfx_buildmap()
__print_bash_gitignore()

# Node templates
__print_package_json()
__print_node_index()
__print_node_gitignore()

# Python templates
__print_pyproject_toml()
__print_python_main()
__print_python_init()
__print_python_gitignore()

# Common templates
__print_readme_md()
```

## Template Registry System

### Template Definition
```bash
# Template registry with metadata
declare -A TEMPLATES=(
    ["rust"]="Rust project with Cargo"
    ["bash"]="BashFX-compliant script project"  
    ["node"]="Node.js project with npm"
    ["python"]="Python project with modern tooling"
)

declare -A TEMPLATE_ALIASES=(
    ["js"]="node"
    ["javascript"]="node"
    ["py"]="python"
    ["rs"]="rust"
)
```

### Configuration Support
Global config file: `$XDG_ETC_HOME/gitsim/.gitsimrc`
```bash
# Global GitSim configuration
RUST_EDITION="2021"
NODE_VERSION="18"
PYTHON_VERSION="3.11"
BASH_TEMPLATE="full"  # or "minimal"

# Custom template paths (future extensibility)
CUSTOM_TEMPLATE_DIR="$XDG_DATA_HOME/gitsim/templates"
```

## Implementation Steps

### Phase 1: Core Template Infrastructure
1. **Add template registry system** (`_validate_template`, template constants)
2. **Implement core orchestration** (`_create_template`, `_apply_template`)
3. **Add standalone commands** (`do_template`, `do_template_list`)
4. **Update options parser** to handle `--template=name` flags

### Phase 2: Rust Template (Priority 1)
1. **Implement Rust print functions** (`__print_cargo_toml`, etc.)
2. **Add Rust template application** in `_apply_template`
3. **Test with realistic Cargo.toml** that build tools can parse
4. **Add integration tests** for Rust template generation

### Phase 3: Bash Template (Priority 2)  
1. **Create BashFX-compliant template** with proper ordinality
2. **Include modular build system structure** (parts/ directory)
3. **Generate working script template** that passes BashFX standards
4. **Test template with actual BashFX tools**

### Phase 4: JavaScript Template (Priority 3)
1. **Implement Node.js print functions** with realistic package.json
2. **Include common dev dependencies** (testing, linting)  
3. **Generate working Hello World** that `npm run` commands work with
4. **Test with actual npm/node tooling**

### Phase 5: Python Template (Priority 4)
1. **Use modern pyproject.toml** instead of setup.py
2. **Include src-layout structure** (best practices)
3. **Generate working package** that pip can install
4. **Test with Python tooling** (pytest, pip, etc.)

### Phase 6: Integration & Polish
1. **Integrate templates with existing commands** (`--template` flags)
2. **Add global configuration support** (`.gitsimrc` in XDG_ETC)
3. **Comprehensive testing** of all template combinations
4. **Documentation updates** (README, CONCEPTS, PRD)

## File Structure After Implementation

```
parts/
├── build.map           # Updated with template system
├── 01_header.sh
├── ...
├── 12_main.sh
└── 13_template_system.sh  # NEW: All template functionality

# Global config location
~/.local/etc/gitsim/.gitsimrc  # Optional global configuration
```

## Testing Strategy

### Unit Tests for Each Template
```bash
test_rust_template() {
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Test template generation
    gitsim template rust testproject
    
    # Validate structure
    [ -f "testproject/Cargo.toml" ] || fail "Missing Cargo.toml"
    [ -f "testproject/src/main.rs" ] || fail "Missing main.rs"
    
    # Test that Cargo can parse it
    cd testproject
    cargo check --quiet || fail "Invalid Cargo project"
    
    cleanup
}
```

### Integration Tests
```bash
test_init_with_template() {
    # Test --template flag integration
    gitsim init --template=rust
    [ -f "Cargo.toml" ] || fail "Template not applied"
    [ -d ".gitsim" ] || fail "Git simulation not created"
}
```

## Command Examples

### Development Workflow
```bash
# Create Rust project for testing deployment scripts
gitsim init-in-home webapp --template=rust
PROJECT_DIR=$(gitsim home-path)/projects/webapp

cd "$PROJECT_DIR"
# Now you have realistic Cargo.toml, src/main.rs, etc.
# Test your Rust deployment/build scripts safely

# Test different project types
gitsim template node frontend
gitsim template python backend  
gitsim template bash tooling
```

### Template Discovery
```bash
# See what's available
gitsim template-list
# Output:
# Available templates:
#   rust     - Rust project with Cargo
#   bash     - BashFX-compliant script project
#   node     - Node.js project with npm  
#   python   - Python project with modern tooling

# Preview before creating
gitsim template-show rust
# Shows the file structure and key file contents
```

## Benefits

1. **Realistic Testing**: Scripts can test against actual project structures
2. **Language Agnostic**: Support for major development ecosystems
3. **BashFX Compliant**: Templates follow proper architecture patterns
4. **Extensible**: Foundation for user-defined templates later
5. **Safe**: All generation happens in isolated environments

This implementation keeps GitSim focused on its core mission (safe testing environments) while adding the critical missing piece of realistic project structures that deployment and build tools actually expect to find.
