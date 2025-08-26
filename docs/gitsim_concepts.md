# GitSim User Concepts Guide

## What is GitSim?

GitSim is a testing simulator that creates **fake Git repositories** and **fake home directories** for safely testing your scripts and tools. Think of it as a sandbox where you can experiment without fear of breaking your real development environment.

## Core Concepts

### 🎭 Simulation, Not Reality

GitSim doesn't use real Git. Instead, it creates **realistic-looking files and directories** that mimic what Git would create:

```bash
your-project/
├── .gitsim/          # The simulation engine
│   ├── .data/        # Fake Git data (commits, branches, etc.)
│   └── .home/        # Fake home directory (optional)
├── .gitignore        # Real file (automatically created)
└── your-files...     # Your actual files
```

### 🏠 Two Types of Environments

**1. Git Repository Simulation**
- Creates a `.gitsim` directory in your current folder
- Simulates Git operations (add, commit, status)
- Perfect for testing deployment scripts

**2. Home Directory Simulation**  
- Creates a complete fake home directory with realistic structure
- Includes `.bashrc`, `.gitconfig`, XDG directories
- Perfect for testing dotfile managers or installation scripts

### 🛡️ Safety First

GitSim **never touches** your real:
- Git repositories
- Home directory files
- System configurations

Everything happens in isolated `.gitsim` directories that you can safely delete.

## Basic Commands

### Starting a Simulation

```bash
# Create a Git simulation in current directory
./gitsim.sh init

# Create a home environment simulation  
./gitsim.sh home-init

# Create a Git simulation inside a fake home directory
./gitsim.sh init-in-home myproject
```

### Basic Git Operations

```bash
# Add files (just like real Git)
./gitsim.sh add file.txt
./gitsim.sh add .

# Create commits (generates fake commit hashes)
./gitsim.sh commit -m "Add new feature"

# Check status
./gitsim.sh status
```

### Working with Home Environments

```bash
# Get the path to your fake home directory
HOME_PATH=$(./gitsim.sh home-path)
echo "Fake home is at: $HOME_PATH"

# List contents of fake home
./gitsim.sh home-ls
./gitsim.sh home-ls .config
./gitsim.sh home-ls -la Documents

# Show environment variables for your scripts
./gitsim.sh home-env
```

## Common Use Cases

### 1. Testing a Deployment Script

**Problem**: You have a script that deploys code based on Git history, but you don't want to risk your real repository.

```bash
# Set up simulation
./gitsim.sh init

# Create fake project history
./gitsim.sh noise 5  # Creates 5 random files
./gitsim.sh commit -m "Initial release"
./gitsim.sh noise 3  # Add more files
./gitsim.sh commit -m "Add new features"

# Now test your deployment script safely
./your-deploy-script.sh
```

### 2. Testing a Dotfile Manager

**Problem**: You want to test a tool that installs dotfiles and configurations without messing up your real home directory.

```bash
# Create fake home environment
./gitsim.sh home-init

# Get the fake home path for your script
FAKE_HOME=$(./gitsim.sh home-path)

# Test your dotfile manager
your-dotfile-tool --home="$FAKE_HOME"

# Check what it installed
./gitsim.sh home-ls -la
./gitsim.sh home-ls .config
```

### 3. Testing Installation Scripts

**Problem**: You need to test an installer that creates files and directories in standard locations.

```bash
# Create realistic environment
./gitsim.sh home-init

# Test installation to fake locations
CONFIG_DIR=$(./gitsim.sh home-path)/.config
BIN_DIR=$(./gitsim.sh home-path)/.local/bin

# Run your installer with fake paths
your-installer --config-dir="$CONFIG_DIR" --bin-dir="$BIN_DIR"

# Verify installation worked
./gitsim.sh home-ls .config
./gitsim.sh home-ls .local/bin
```

### 4. CI/CD Pipeline Testing

**Problem**: You want to test complex build/deploy logic locally before running in CI.

```bash
# Create project simulation with realistic structure
./gitsim.sh init-in-home webapp
PROJECT_DIR=$(./gitsim.sh home-path)/projects/webapp

cd "$PROJECT_DIR"

# Create realistic project files
echo '{"name": "webapp", "version": "1.0.0"}' > package.json
echo 'console.log("Hello World")' > app.js

# Add to simulation
../../../gitsim.sh add .
../../../gitsim.sh commit -m "Initial version"

# Test your CI/CD scripts
your-build-script.sh
your-test-script.sh
```

## Environment Variables

GitSim uses special `SIM_` prefixed variables that **inherit from your real environment** but can be overridden for testing:

```bash
# These inherit from your shell
SIM_USER=$USER        # Your username
SIM_HOME=$HOME        # Your home (safely overridden)
SIM_SHELL=$SHELL      # Your shell
SIM_EDITOR=$EDITOR    # Your editor

# Override for testing different scenarios
SIM_USER=testuser SIM_EDITOR=vim ./gitsim.sh home-init

# Or create a .simrc file to persist overrides
./gitsim.sh rcgen
# Edit .simrc to customize your test environment
```

## Advanced Features

### Test Data Generation

```bash
# Generate random files for testing
./gitsim.sh noise 10  # Creates 10 random files and stages them
```

### Custom Environments

```bash
# Create configuration file
./gitsim.sh rcgen

# Edit .simrc to customize your testing environment:
# SIM_USER="alice"
# SIM_EDITOR="vim"
# SIM_SHELL="/bin/zsh"
```

### Cleanup

```bash
# Remove all GitSim artifacts
./gitsim.sh cleanup

# Or just delete the .gitsim directory
rm -rf .gitsim
```

### Installation (Optional)

```bash
# Install GitSim to your system for global use
./gitsim.sh install

# Add to your PATH
export PATH="$HOME/.local/bin/fx:$PATH"

# Now use anywhere as 'gitsim'
gitsim init
```

## Real-World Example: Testing a Backup Script

Let's say you have a backup script that needs to:
1. Check Git status
2. Create a backup in `~/.local/backups/`
3. Update a log file in `~/.config/myapp/`

Here's how to test it safely:

```bash
# 1. Create complete test environment
./gitsim.sh init-in-home myproject
PROJECT_DIR=$(./gitsim.sh home-path)/projects/myproject

# 2. Set up realistic project state
cd "$PROJECT_DIR"
echo "Important data" > data.txt
../../../gitsim.sh add data.txt
../../../gitsim.sh commit -m "Add important data"

# 3. Get paths for your backup script
FAKE_HOME=$(../../../gitsim.sh home-path)
BACKUP_DIR="$FAKE_HOME/.local/backups"
CONFIG_DIR="$FAKE_HOME/.config/myapp"

# 4. Test your backup script with fake paths
your-backup-script --home="$FAKE_HOME" --project="$PROJECT_DIR"

# 5. Verify it worked
../../../gitsim.sh home-ls .local/backups
../../../gitsim.sh home-ls .config/myapp

# 6. Clean up when done
cd ../../..
./gitsim.sh cleanup
```

## Tips & Best Practices

### ✅ Do This
- Use GitSim for testing scripts that modify files or directories
- Always use the paths provided by `gitsim home-path` in your scripts
- Create `.simrc` files for consistent test environments
- Use `cleanup` when you're done testing

### ❌ Don't Do This
- Don't assume GitSim works exactly like real Git (it's a simulation)
- Don't use GitSim for actual version control (use real Git)
- Don't forget to clean up your test environments
- Don't test network operations (GitSim is local only)

## Getting Help

```bash
# Show all available commands
./gitsim.sh --help

# Show current environment variables
./gitsim.sh home-vars

# Check what paths are available
./gitsim.sh home-env
```

---

**Remember**: GitSim is your safety net for testing. It gives you the confidence to experiment, break things, and iterate quickly without any risk to your real development environment.