# GitSim - Git & Home Environment Simulator

![version](https://img.shields.io/badge/version-2.0.0-blue)
![architecture](https://img.shields.io/badge/architecture-BashFX_2.1-green)
![dependencies](https://img.shields.io/badge/dependencies-zero-brightgreen)

A BashFX 2.1 compliant tool for creating realistic git repositories and home environments for testing, demonstrations, and development workflows. GitSim provides safe, isolated environments that simulate real development scenarios without polluting your actual workspace.

## 🎯 Key Features

- **🔄 Git Simulation**: Full git operations (init, add, commit, status) with realistic repository structure
- **🏠 Home Environment**: Complete XDG-compliant simulated home directories with dotfiles
- **📋 Project Templates**: Professional scaffolding for Rust, Node.js, Python, and BashFX projects
- **🛡️ Safe Operations**: Zero risk to your real repositories and home directory
- **🧹 Rewindable**: Complete cleanup and uninstall capabilities
- **📦 Zero Dependencies**: Pure bash with only POSIX utilities
- **🏗️ Modular Architecture**: 18-part BashFX build system for maintainability

## 🚀 Quick Start

```bash
# Clone and test immediately
git clone <repository>
cd fx-gitsim

# Initialize git simulation in current directory
./gitsim.sh init

# Create files and commit them
echo "Hello World" > hello.txt
./gitsim.sh add hello.txt
./gitsim.sh commit -m "Add hello world"
./gitsim.sh status

# Create project with template
./gitsim.sh template rust myproject
cd myproject && ls -la

# Set up simulated home environment
./gitsim.sh home-init
HOME_PATH=$(./gitsim.sh home-path)
echo "Simulated home: $HOME_PATH"
```

## 📥 Installation

### Option 1: Standalone Usage (Recommended for Testing)
```bash
# Download and use immediately
wget <url>/gitsim.sh
chmod +x gitsim.sh
./gitsim.sh init
```

### Option 2: System Installation
```bash
# Install to XDG+ directories (~/.local)
./gitsim.sh install

# Add to PATH
export PATH="$HOME/.local/bin/fx:$PATH"

# Verify installation
gitsim version

# Generate configuration (optional)
gitsim rcgen
```

### Option 3: Development Setup
```bash
# For developers working on GitSim itself
git clone <repository>
cd fx-gitsim
./build.sh build    # Build from parts
./test_runner.sh    # Run test suite
```

## 📖 Complete API Reference

### Core Git Commands

#### `init [options]`
Initialize git simulation in current directory.

**Options:**
- `--template=TYPE` - Apply project template (rust, bash, node, python)

**Examples:**
```bash
./gitsim.sh init                    # Basic git simulation
./gitsim.sh init --template=rust    # With Rust project template
```

#### `init-in-home [project] [options]`
Create git simulation in simulated home environment.

**Arguments:**
- `project` - Project name (default: "testproject")

**Options:**
- `--template=TYPE` - Apply project template

**Examples:**
```bash
./gitsim.sh init-in-home                    # Default project
./gitsim.sh init-in-home webapp             # Named project
./gitsim.sh init-in-home api --template=rust # With template
```

#### `add <files...>`
Add files to staging area.

**Arguments:**
- `files` - One or more file paths to stage

**Examples:**
```bash
./gitsim.sh add file.txt
./gitsim.sh add src/*.rs
./gitsim.sh add .
```

#### `commit -m "message" [options]`
Create a commit with specified message.

**Options:**
- `-m "message"` - Commit message (required)
- `--allow-empty` - Allow commit with no changes

**Examples:**
```bash
./gitsim.sh commit -m "Initial commit"
./gitsim.sh commit -m "Add feature" --allow-empty
```

#### `status`
Show repository status (staged files, commits, etc.)

**Examples:**
```bash
./gitsim.sh status
```

### Home Environment Commands

#### `home-init [project] [options]`
Initialize simulated home environment with XDG directory structure.

**Arguments:**
- `project` - Project name for ~/projects/PROJECT (default: "testproject")

**Options:**
- `--template=TYPE` - Apply project template to the project directory

**Examples:**
```bash
./gitsim.sh home-init                    # Default setup
./gitsim.sh home-init myapp             # Named project
./gitsim.sh home-init api --template=rust # With Rust template
```

#### `home-path`
Get absolute path to simulated home directory.

**Examples:**
```bash
HOME_PATH=$(./gitsim.sh home-path)
cp config.toml "$HOME_PATH/.config/myapp/"
```

#### `home-env`
Show simulated environment variables for the current session.

**Examples:**
```bash
./gitsim.sh home-env
# Output: HOME=/path/to/.gitsim/.home USER=testuser ...
```

#### `home-ls [dir] [options]`
List contents of simulated home directory.

**Arguments:**
- `dir` - Subdirectory to list (default: home root)
- `options` - Standard ls options (-la, -lh, etc.)

**Examples:**
```bash
./gitsim.sh home-ls           # List home root
./gitsim.sh home-ls -la       # Detailed listing
./gitsim.sh home-ls projects  # List projects directory
```

#### `home-vars`
Show all SIM_ environment variables and their values.

**Examples:**
```bash
./gitsim.sh home-vars
# Output: SIM_HOME=/path SIM_USER=testuser ...
```

### Template System

#### `template <type> [project]`
Generate project template in specified or current directory.

**Arguments:**
- `type` - Template type (see template list below)
- `project` - Target directory name (optional)

**Examples:**
```bash
./gitsim.sh template rust           # In current directory
./gitsim.sh template rust myapp     # In ./myapp directory
./gitsim.sh template node frontend  # Node.js project
```

#### `template-list`
Show all available project templates.

**Output includes:**
- Template names and descriptions
- Available aliases

**Examples:**
```bash
./gitsim.sh template-list
```

#### `template-show <type>`
Preview template contents and structure.

**Arguments:**
- `type` - Template type to preview

**Examples:**
```bash
./gitsim.sh template-show rust
```

### Available Templates

| Template | Aliases | Description | Generated Structure |
|----------|---------|-------------|--------------------|
| **rust** | rs | Cargo project with modern Rust setup | Cargo.toml, src/main.rs, src/lib.rs, tests/, .gitignore |
| **bash** | sh, bashfx | BashFX-compliant script with build system | script.sh, parts/, build.map, test_runner.sh |
| **node** | js, npm, javascript | Node.js project with modern tooling | package.json, src/index.js, test/, .gitignore |
| **python** | py | Modern Python with pyproject.toml | pyproject.toml, src/project/, tests/, .gitignore |

### Test Data Generation

#### `noise [count]`
Generate random test files and stage them.

**Arguments:**
- `count` - Number of files to generate (default: 3)

**Examples:**
```bash
./gitsim.sh noise      # Generate 3 random files
./gitsim.sh noise 10   # Generate 10 random files
```

### Configuration Management

#### `rcgen [options]`
Generate GitSim configuration file.

**Options:**
- `--force` - Overwrite existing configuration

**Generated config location:** `~/.local/etc/gitsim/.gitsimrc`

**Examples:**
```bash
./gitsim.sh rcgen          # Generate default config
./gitsim.sh rcgen --force  # Overwrite existing
```

#### `cleanup [options]`
Clean up all GitSim artifacts from current directory.

**Options:**
- `--force` - Skip confirmation prompts

**Examples:**
```bash
./gitsim.sh cleanup         # Interactive cleanup
./gitsim.sh cleanup --force # Force cleanup
```

### System Management

#### `install`
Install GitSim to XDG+ system directories.

**Installs to:**
- Binary: `~/.local/bin/fx/gitsim`
- Library: `~/.local/lib/fx/gitsim/`
- Config: `~/.local/etc/gitsim/`

**Examples:**
```bash
./gitsim.sh install
```

#### `uninstall --force`
Remove GitSim installation completely.

**Options:**
- `--force` - Required flag for safety

**Examples:**
```bash
./gitsim.sh uninstall --force
```

#### `version`
Show version information.

**Examples:**
```bash
./gitsim.sh version
# Output: gitsim v2.0.0
```

## 🔧 Global Options

These options work with any command:

| Option | Description |
|--------|-------------|
| `-d, --debug` | Enable debug output |
| `-t, --trace` | Enable trace output (implies --debug) |
| `-q, --quiet` | Suppress all output except errors |
| `-f, --force` | Force operations, bypass safety checks |
| `-y, --yes` | Auto-confirm prompts |
| `-D, --dev` | Enable developer mode |
| `-h, --help` | Show command help |

**Examples:**
```bash
./gitsim.sh --debug init
./gitsim.sh --quiet --force cleanup
./gitsim.sh --trace template rust myapp
```

## 🌍 Environment Variables

GitSim respects and can override these environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `SIM_HOME` | `$XDG_HOME` or `$HOME` | Base simulated home directory |
| `SIM_USER` | `$USER` or "testuser" | Simulated username |
| `SIM_SHELL` | `$SHELL` or "/bin/bash" | Simulated shell |
| `SIM_EDITOR` | `$EDITOR` or "nano" | Simulated editor |
| `SIM_LANG` | `$LANG` or "en_US.UTF-8" | Simulated locale |

**XDG+ Variables (Advanced):**
- `XDG_HOME` - Base for all local files (default: `~/.local`)
- `XDG_LIB_HOME` - Library files (default: `$XDG_HOME/lib`)
- `XDG_BIN_HOME` - Binary files (default: `$XDG_HOME/bin`)
- `XDG_ETC_HOME` - Configuration files (default: `$XDG_HOME/etc`)

## 📝 Usage Examples

### Testing Deployment Scripts
```bash
# Create realistic Rust project for testing
./gitsim.sh home-init webapp --template=rust
PROJECT_DIR=$(./gitsim.sh home-path)/projects/webapp

# Test your deployment script
cd "$PROJECT_DIR"
your-deploy-script.sh  # Tests against real Cargo.toml, etc.

# Clean up when done
./gitsim.sh cleanup --force
```

### CI/CD Pipeline Testing
```bash
# Simulate a development workflow
./gitsim.sh init --template=node
echo 'console.log("Hello CI");' > src/app.js
./gitsim.sh add .
./gitsim.sh commit -m "Add app logic"

# Test your CI scripts
your-ci-script.sh

# Generate test data
./gitsim.sh noise 20
./gitsim.sh commit -m "Add test data"
```

### Dotfile Manager Testing
```bash
# Create simulated home environment
./gitsim.sh home-init
HOME_PATH=$(./gitsim.sh home-path)

# Test dotfile installation
HOME="$HOME_PATH" your-dotfile-installer.sh

# Verify results
./gitsim.sh home-ls -la .config
```

### Multi-Project Development Environment
```bash
# Set up multiple projects
./gitsim.sh template rust backend
./gitsim.sh template node frontend
./gitsim.sh template python ml-service

# Each has realistic project structure
ls backend/src/     # main.rs, lib.rs
ls frontend/src/    # index.js
ls ml-service/src/  # Python package structure
```

## 🏗️ Development & Architecture

GitSim is built using the BashFX 2.1 architecture for maintainability and scalability.

### Build System
```bash
# Build from modular parts
./build.sh build    # Concatenate parts into gitsim.sh
./build.sh clean    # Remove build artifacts

# Development workflow
./test_runner.sh    # Run full test suite
./build.sh build && ./test_runner.sh  # Test after build
```

### Project Structure
```
fx-gitsim/
├── gitsim.sh           # Built script (generated)
├── build.sh            # BashFX build system
├── test_runner.sh      # Test framework
├── parts/              # Modular source code
│   ├── build.map       # Build order specification
│   ├── part_01_header.sh
│   ├── part_02_config.sh
│   ├── ...
│   └── part_99_main.sh
└── docs/               # Documentation
    ├── gitsim_prd.md   # Product requirements
    ├── ref_template_system.md
    └── ...
```

### Function Ordinality (BashFX Pattern)
- **High-Ordinal**: `do_*` functions (dispatchable commands)
- **Mid-Ordinal**: `_*` functions (orchestration logic)
- **Low-Ordinal**: `__*` functions (literal operations)

### Contributing
1. Edit files in `parts/`, not `gitsim.sh` directly
2. Follow BashFX function ordinality patterns
3. Add tests for new functionality
4. Update documentation
5. Run `./build.sh build && ./test_runner.sh` before commits

## 🔒 Safety & Isolation

GitSim is designed to be completely safe:

- **No Pollution**: All artifacts contained in `.gitsim/` directories
- **Safe Defaults**: Confirms before destructive operations
- **XDG Compliance**: Respects user directory standards
- **Easy Cleanup**: `cleanup --force` removes everything
- **Isolated Environments**: No interference with real git repositories

## 🚨 Troubleshooting

### Common Issues

**"Not in a GitSim directory"**
```bash
# Initialize first
./gitsim.sh init
```

**"Template not found"**
```bash
# Check available templates
./gitsim.sh template-list
```

**Permission denied during install**
```bash
# Ensure ~/.local exists
mkdir -p ~/.local/{bin,lib,etc}
./gitsim.sh install
```

**Build fails**
```bash
# Clean and rebuild
./build.sh clean
./build.sh build
```

### Debug Mode
```bash
# Enable detailed logging
./gitsim.sh --trace --debug init
```

## 📄 License

MIT License - See repository for full details.