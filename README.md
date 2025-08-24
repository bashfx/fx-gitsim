# Git & Home Environment Simulator

A comprehensive testing simulator that creates isolated Git repositories and home directory environments for testing scripts and applications without affecting your real filesystem or Git repositories.

## Features

- **Git Command Simulation**: Simulate common Git operations (commit, branch, tag, etc.)
- **Home Environment Simulation**: Create fake home directories with standard Unix/Linux directory structures
- **Environment Variable Management**: Use `SIM_` prefixed variables that inherit from your shell but can be overridden
- **Flexible Initialization**: Create Git repos in current directory or within simulated home projects
- **Testing Utilities**: Generate sample commits, branches, tags, and files for comprehensive testing

## Quick Start

```bash
# Make executable
chmod +x git_sim.sh

# Initialize a basic Git simulation
./git_sim.sh init

# Or initialize with simulated home environment
./git_sim.sh init-in-home myproject

# Create test data
./git_sim.sh noise 5
./git_sim.sh history 10 3
./git_sim.sh branches 4
```

## Commands Reference

### Git Repository Management

#### `init`
Create a Git simulation in the current directory.
```bash
./git_sim.sh init
```

#### `init-in-home [project-name]`
Create a Git simulation inside a fake project directory within simulated home.
```bash
./git_sim.sh init-in-home myproject
./git_sim.sh init-in-home  # defaults to "testproject"
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
./git_sim.sh home-vars
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
./git_sim.sh noise      # 1 file
./git_sim.sh noise 10   # 10 files
```

#### `branches [count]`
Create multiple realistic branches with commits.
```bash
./git_sim.sh branches 5
```

#### `history [commits] [tags]`
Generate a commit history with version tags.
```bash
./git_sim.sh history 10 3  # 10 commits, 3 tags
./git_sim.sh history 20    # 20 commits, 2 tags (default)
```

## Environment Variables

The simulator uses `SIM_` prefixed variables that inherit from your environment but can be overridden:

```bash
# Default inheritance
SIM_HOME=${XDG_HOME:-$HOME}
SIM_USER=${USER}
SIM_SHELL=${SHELL}
SIM_EDITOR=${EDITOR}
SIM_LANG=${LANG}

# Override for testing
SIM_USER=testuser SIM_EDITOR=vim ./git_sim.sh home-init
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
        ├── .bashrc      # Shell configuration
        ├── .profile     # Login profile
        ├── .gitconfig   # Git user config
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
./git_sim.sh init
./git_sim.sh history 15 4
./git_sim.sh branches 6

# Test your semver tool
your-semver-tool --check
your-semver-tool --bump patch

# Verify the simulation
./git_sim.sh tag
./git_sim.sh log --oneline
```

### 2. Testing Home Directory Scripts

Test dotfile managers, configuration scripts, or installation tools:

```bash
# Create simulated environment
./git_sim.sh home-init

# Get paths for your script
CONFIG_DIR=$(./git_sim.sh home-path)/.config
DATA_DIR=$(./git_sim.sh home-path)/.local/share

# Test your dotfile manager
your-dotfile-manager install --config-dir="$CONFIG_DIR"

# Verify installation
./git_sim.sh home-ls .config -la
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
./git_sim.sh init-in-home testapp
PROJECT_DIR=$(./git_sim.sh home-path)/projects/testapp
CONFIG_DIR=$(./git_sim.sh home-path)/.config

cd "$PROJECT_DIR"
../../../git_sim.sh history 10 2

# Test your tool
your-tool --project="$PROJECT_DIR" --config="$CONFIG_DIR"

# Verify results
../../../git_sim.sh status
ls -la "$CONFIG_DIR"
```

## Tips and Best Practices

1. **Isolation**: Each `.gitsim` directory is completely isolated - you can have multiple simulations
2. **Cleanup**: Remove `.gitsim` directories when done testing
3. **Scripting**: Use `$(./git_sim.sh home-path)` to get paths dynamically
4. **Environment**: Override `SIM_` variables to test different user scenarios
5. **Realistic Data**: Use `history` and `branches` commands to create realistic test scenarios

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
	./git_sim.sh init-in-home testproject
	./git_sim.sh history 10 3

test: test-setup
	cd $$(./git_sim.sh home-path)/projects/testproject && \
	../../../your-tool test

test-clean:
	rm -rf .gitsim
```

## Contributing

The simulator is designed to be easily extensible. To add new Git commands or home directory features:

1. Add the command to the `usage()` function
2. Implement `cmd_your_command()` function
3. Add the case statement in the main dispatcher
4. Test with realistic scenarios

## License

This tool is provided as-is for testing and development purposes.
