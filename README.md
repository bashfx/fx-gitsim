# Git & Home Environment Simulator (BashFX Edition)

A BashFX-compliant testing simulator that creates isolated Git repositories and home directory environments for testing scripts and applications. Built following the BashFX architecture principles: self-contained, rewindable, XDG+ compliant, and respects your real environment.

## Features

- **Git Command Simulation**: Simulate common Git operations (commit, branch, tag, etc.)
- **Home Environment Simulation**: Create fake home directories with standard Unix/Linux directory structures
- **SIM_ Variable Management**: Use `SIM_` prefixed variables that inherit from your shell but can be overridden (never touches `$HOME`)
- **XDG+ Compliance**: Follows BashFX directory standards with clean installation/uninstallation
- **BashFX Architecture**: Proper function ordinality, stderr conventions, and rewindable operations
- **Flexible Initialization**: Create Git repos in current directory or within simulated home projects
- **Testing Utilities**: Generate sample commits, branches, tags, and files for comprehensive testing

## Installation

### Quick Use (No Installation)
```bash
# Download and make executable
curl -sL "https://raw.githubusercontent.com/bashfx/fx-gitsim/main/gitsim.sh" > gitsim.sh
chmod +x gitsim.sh
./gitsim.sh init
```

### BashFX Installation (Recommended)
```bash
# Install to XDG+ directories
./gitsim.sh install

# Add fx bin to PATH
export PATH="$HOME/.local/bin/fx:$PATH"

# Now use as 'gitsim' globally
gitsim init
```

## Commands Reference

### Git Repository Management

#### `init`
Create a Git simulation in the current directory.
```bash
./gitsim.sh init
```

#### `init-in-home [project-name]`
Create a Git simulation inside a fake project directory within simulated home.
```bash
./gitsim.sh init-in-home myproject
./gitsim.sh init-in-home  # defaults to "testproject"
```

### System Management

#### `install`
Install to BashFX XDG+ directories for system-wide use.
```bash
./gitsim.sh install
export PATH="$HOME/.local/bin/fx:$PATH"
gitsim --help  # Now available globally
```

#### `uninstall --force` 
Remove installation (requires --force for safety).
```bash
gitsim uninstall --force
```

#### `version`
Show version information.
```bash
gitsim version
```

### Home Environment Simulation

#### `home-init [project-name]`
Initialize a simulated home environment with standard directories and dotfiles.
```bash
./git_sim.sh home-init
./git_sim.sh home-init myproject
```

#### `home-env`
Show simulated environment variables (paths to use in your scripts).
```bash
./git_sim.sh home-env
# Output:
# SIM_HOME='/path/to/.gitsim/.home'
# SIM_XDG_CONFIG_HOME='/path/to/.gitsim/.home/.config'
# etc.
```

#### `home-path`
Get the path to the simulated home directory.
```bash
HOME_DIR=$(./git_sim.sh home-path)
echo "Simulated home: $HOME_DIR"
```

#### `home-ls [directory] [ls-options]`
List contents of simulated home directory.
```bash
./git_sim.sh home-ls          # List home root
./git_sim.sh home-ls -la      # List with details
./git_sim.sh home-ls projects # List projects directory
./git_sim.sh home-ls .config -l
```

#### `home-vars`
Show current SIM_ environment variables and how to override them.
```bash
./gitsim.sh home-vars
# Shows current values and override examples
```

### Git Commands

All standard Git commands are supported with realistic behavior:

```bash
# Working with files
./git_sim.sh add file.txt
./git_sim.sh add .
./git_sim.sh status
./git_sim.sh diff

# Commits and history
./git_sim.sh commit -m "Add new feature"
./git_sim.sh log
./git_sim.sh log --oneline

# Branches
./git_sim.sh branch feature/auth
./git_sim.sh checkout -b bugfix/login
./git_sim.sh branch -d old-feature

# Tags
./git_sim.sh tag v1.0.0
./git_sim.sh tag -a v1.1.0 -m "Release 1.1.0"
./git_sim.sh tag -d v0.9.0

# Remotes
./git_sim.sh remote add origin https://github.com/user/repo.git
./git_sim.sh remote show origin
./git_sim.sh fetch
./git_sim.sh push

# Advanced
./git_sim.sh reset --soft HEAD~1
./git_sim.sh describe
./git_sim.sh rev-parse HEAD
```

### Test Data Generation

#### `noise [count]`
Create random files and stage them.
```bash
./gitsim.sh noise      # 1 file
./gitsim.sh noise 10   # 10 files
```

## Environment Variables (SIM_ Variables)

The simulator uses `SIM_` prefixed variables that inherit from your environment but can be overridden. **Importantly, it never overrides your real `$HOME`**.

```bash
# Default inheritance (safe!)
SIM_HOME=${XDG_HOME:-$HOME}  # Uses XDG_HOME if set, fallback to HOME
SIM_USER=${USER}             # Inherits your username
SIM_SHELL=${SHELL}           # Inherits your shell
SIM_EDITOR=${EDITOR}         # Inherits your editor
SIM_LANG=${LANG}             # Inherits your locale

# Override for testing
SIM_USER=testuser SIM_EDITOR=vim ./gitsim.sh home-init
```

### XDG+ Directory Structure

When installed, follows BashFX XDG+ compliance:

```bash
~/.local/lib/fx/gitsim/     # Library files
~/.local/bin/fx/gitsim      # Executable symlink (flattened)
```

## Directory Structure

### Standard Git Simulation
```
your-project/
├── .gitsim/
│   └── .data/
│       ├── commits.txt
│       ├── tags.txt
│       ├── branches.txt
│       ├── index
│       └── HEAD
├── .gitignore
└── your-files...
```

### Home Environment Simulation
```
your-project/
└── .gitsim/
    ├── .data/           # Git simulation state
    └── .home/           # Simulated home directory
        ├── .bashrc      # Shell configuration (with SIM_ vars)
        ├── .profile     # Login profile
        ├── .gitconfig   # Git user config (uses SIM_USER)
        ├── .config/     # XDG config directory
        ├── .local/      # XDG local directory
        │   ├── bin/
        │   ├── share/
        │   └── state/
        ├── .cache/      # XDG cache directory
        ├── projects/    # Project workspace
        │   └── myproject/
        │       ├── .gitsim/
        │       ├── README.md
        │       └── .gitignore
        ├── Documents/
        └── Downloads/
```

## Use Cases

### 1. Testing Script Development Tools

Test tools like version bumpers, changelog generators, or release scripts:

```bash
# Set up a realistic project
./gitsim.sh init
./gitsim.sh noise 5
./gitsim.sh commit -m "Initial commit"
./gitsim.sh commit -m "feat: add new feature"

# Test your semver tool
your-semver-tool --check
your-semver-tool --bump patch

# Verify the simulation
./gitsim.sh status
```

### 2. Testing Home Directory Scripts

Test dotfile managers, configuration scripts, or installation tools:

```bash
# Create simulated environment
./gitsim.sh home-init

# Get paths for your script (never touches real $HOME!)
CONFIG_DIR=$(./gitsim.sh home-path)/.config
DATA_DIR=$(./gitsim.sh home-path)/.local/share

# Test your dotfile manager
your-dotfile-manager install --config-dir="$CONFIG_DIR"

# Verify installation
./gitsim.sh home-ls .config -la
```

### 3. CI/CD Pipeline Testing

Test deployment scripts or build tools locally:

```bash
# Simulate a project with release history
./git_sim.sh init-in-home webapp
PROJECT_DIR=$(./git_sim.sh home-path)/projects/webapp

cd "$PROJECT_DIR"
../../../git_sim.sh history 20 5
../../../git_sim.sh noise 15

# Test your deployment script
your-deploy-script --simulate --project-dir="$PROJECT_DIR"
```

### 4. Git Workflow Testing

Test complex Git workflows or hooks:

```bash
# Set up complex branch structure
./git_sim.sh init
./git_sim.sh branches 10

# Create realistic commit history
./git_sim.sh checkout feature/auth
./git_sim.sh noise 3
./git_sim.sh commit -m "Add authentication"

# Test your Git hooks or workflow tools
your-git-tool analyze-branches
your-git-tool suggest-merge
```

### 5. User Environment Testing

Test applications that depend on specific user environments:

```bash
# Test with different user configurations
SIM_USER=alice SIM_SHELL=/bin/zsh ./git_sim.sh home-init

# Test application behavior
HOME_PATH=$(./git_sim.sh home-path)
your-app --home="$HOME_PATH" --user=alice
```

### 6. Integration Testing

Test tools that work with both Git and filesystem:

```bash
#!/bin/bash
# Your test script

# Set up test environment
./gitsim.sh init-in-home testapp
PROJECT_DIR=$(./gitsim.sh home-path)/projects/testapp
CONFIG_DIR=$(./gitsim.sh home-path)/.config

cd "$PROJECT_DIR"
../../../gitsim.sh commit -m "Initial setup"

# Test your tool
your-tool --project="$PROJECT_DIR" --config="$CONFIG_DIR"

# Verify results
../../../gitsim.sh status
ls -la "$CONFIG_DIR"
```

## Testing the Simulator

Run the comprehensive test suite:

```bash
# Run all tests
./test_runner.sh

# Test specific scenarios
./gitsim.sh -D dev-test
```

The test runner covers:
- Basic workflow (init → add → commit → status)
- Home environment simulation
- Init-in-home projects  
- SIM_ variable inheritance
- Install/uninstall lifecycle
- Error conditions and validation

## Tips and Best Practices

1. **Isolation**: Each `.gitsim` directory is completely isolated - you can have multiple simulations
2. **Cleanup**: Remove `.gitsim` directories when done testing (`rm -rf .gitsim`)
3. **Scripting**: Use `$(./gitsim.sh home-path)` to get paths dynamically
4. **Environment**: Override `SIM_` variables to test different user scenarios
5. **Safety**: The simulator never touches your real `$HOME` or Git repositories
6. **Installation**: Use `install` for system-wide access, keeps everything in XDG+ directories
7. **Rewindability**: `uninstall --force` removes all traces cleanly

## Integration with Testing Frameworks

### Bash Tests (BATS)
```bash
setup() {
    ./git_sim.sh init
    ./git_sim.sh history 5 2
}

teardown() {
    rm -rf .gitsim
}

@test "tool handles git repo correctly" {
    run your-tool --check
    [ "$status" -eq 0 ]
}
```

### Make Targets
```make
test-setup:
	./gitsim.sh init-in-home testproject

test: test-setup
	cd $(./gitsim.sh home-path)/projects/testproject && \
	../../../your-tool test

test-clean:
	rm -rf .gitsim

install-dev:
	./gitsim.sh install

uninstall-dev:
	./gitsim.sh uninstall --force
```

## BashFX Architecture

This simulator follows BashFX principles:

- **Self-Contained**: Everything in XDG+ directories (`~/.local/`)
- **Rewindable**: Clean install/uninstall lifecycle  
- **Invisible**: No pollution of `$HOME`, respects existing environment
- **Function Ordinality**: Proper High-Order → Mid-Ordinal → Low-Ordinal structure
- **Standard Interface**: Consistent option flags, stderr conventions, return codes

## Contributing

The simulator follows BashFX architecture patterns. To add features:

1. **Follow Function Ordinality**: High-Order `do_*` → Mid-Ordinal `_helper` → Low-Ordinal `__literal`
2. **Use Standard Variables**: `ret`, `res`, `path`, `home_dir`, etc.
3. **Respect SIM_ Variables**: Never override real environment, use inheritance
4. **Add Tests**: Update `test_runner.sh` with new test scenarios
5. **XDG+ Compliance**: Keep everything in `~/.local/` hierarchy

## License

This tool is provided as-is for testing and development purposes. Built with love for the BashFX architecture! 🏗️
