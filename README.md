# GitSim - Git & Home Environment Simulator

A BashFX 2.1 compliant tool for creating realistic git repositories and home environments for testing, demonstrations, and development workflows.

## Features

- **Git Simulation**: Create realistic git repositories with commits, branches, and history
- **Home Environment**: Simulate complete user home directories with dotfiles and directory structures  
- **Project Templates**: Generate professional project scaffolding (Rust, Node.js, Python, BashFX)
- **XDG+ Compliance**: Follows XDG Base Directory specification with extensions
- **Modular Architecture**: 18-part BashFX build system for maintainability

## Quick Start

```bash
# Initialize git simulation in current directory
./gitsim.sh init

# Create files and commit them
echo "Hello World" > hello.txt
./gitsim.sh add hello.txt
./gitsim.sh commit -m "Add hello world"

# Create project with template
./gitsim.sh init --template=rust myproject

# Set up simulated home environment
./gitsim.sh home-init
./gitsim.sh home-path
```

## Installation

```bash
# Install to XDG+ directories
./gitsim.sh install

# Add to PATH
export PATH="$HOME/.local/bin/fx:$PATH"

# Generate configuration
gitsim rcgen
```

## Templates

- **rust** - Cargo project with src/, tests/, examples/
- **bash** - BashFX-compliant script project with build system  
- **node** - npm project with package.json and modern tooling
- **python** - Modern Python project with pyproject.toml

## Development

Built using BashFX 2.1 architecture:

```bash
# Build from parts
./build.sh build

# Run tests
./test_runner.sh

# Clean build
./build.sh clean
```

## Architecture

- **18-part modular system** for maintainability
- **Professional templates** with realistic project structures
- **Comprehensive testing** with automated validation
- **XDG+ compliance** for proper system integration

## License

MIT License - See project repository for details