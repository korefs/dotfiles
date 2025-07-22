#!/bin/bash

set -e  # Stop script if any command fails

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Enhanced logging
log() {
    echo "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

warn() {
    echo "${YELLOW}[$(date +'%H:%M:%S')] ⚠️  $1${NC}"
}

error() {
    echo "${RED}[$(date +'%H:%M:%S')] ❌ $1${NC}"
}

success() {
    echo "${GREEN}[$(date +'%H:%M:%S')] ✅ $1${NC}"
}

info() {
    echo "${BLUE}[$(date +'%H:%M:%S')] ℹ️  $1${NC}"
}

show_header() {
echo "${PURPLE}"
cat << "EOF"
   ___       ___       ___   
  / _ \ __ _/ _ \ ___  / _ \  
 | | | |\ \ \ \/ _ \| | | | 
 | |_| |/_\ \\_\___/| |_| | 
  \___/    \___/     \___/  
                            
    macOS Setup Script
EOF
echo "${NC}"
}


# Progress bar function
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    
    printf "\r${CYAN}Progress: [${NC}"
    printf "%${completed}s" | tr ' ' '█'
    printf "%$((width - completed))s" | tr ' ' '░'
    printf "${CYAN}] ${percentage}%% (${current}/${total})${NC}\n"
    
    if [ $current -eq $total ]; then
        echo ""
    fi
}

show_header

# Pre-authenticate sudo to avoid multiple password prompts
log "Authenticating sudo to avoid multiple password prompts..."
sudo -v

# Keep sudo alive during the entire brew installation
# This runs a background process that refreshes sudo every 60 seconds
while true; do sudo -n true; sleep 60; kill -0 "$" || exit; done 2>/dev/null &

# System info
log "Detecting system information..."
MACOS_VERSION=$(sw_vers -productVersion)
ARCH=$(uname -m)
info "macOS $MACOS_VERSION ($ARCH)"

# Total steps for progress tracking
TOTAL_STEPS=16
CURRENT_STEP=0

# Function to wait for user input
wait_for_user() {
    echo "${YELLOW}Press Enter to continue...${NC}"
    read -r
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for internet connection
check_internet() {
    if ping -q -c 1 -W 1 google.com >/dev/null; then
        success "Internet connection verified"
    else
        error "No internet connection. Please check your connection."
        exit 1
    fi
}

# Update progress
update_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    show_progress $CURRENT_STEP $TOTAL_STEPS
    sleep 0.5
}

# Check internet first
check_internet
update_progress

# Create directories
log "Creating directory structure..."
mkdir -p ~/Development/{personal,work,learning}
mkdir -p ~/Development/tools
mkdir -p ~/.config
success "Development directories created"
update_progress

# Install Xcode Command Line Tools
log "Checking Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
    warn "Installing Xcode Command Line Tools..."
    xcode-select --install
    warn "A window will open to install Xcode Command Line Tools."
    warn "Click 'Install' and wait for the installation to complete."
    wait_for_user
else
    success "Xcode Command Line Tools already installed"
fi
update_progress

# Install Homebrew
if ! command_exists brew; then
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Check if Homebrew was installed correctly
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        # For Apple Silicon Macs
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        # For Intel Macs
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    # Check again if brew is available
    if ! command_exists brew; then
        error "Homebrew was not installed correctly"
        exit 1
    fi
    success "Homebrew installed"
else
    success "Homebrew already installed"
fi
update_progress

# Update Homebrew
log "Updating Homebrew..."
brew update
success "Homebrew updated"
update_progress

# Check if Brewfile exists
if [[ ! -f "Brewfile" ]]; then
    log "Creating optimized Brewfile..."
    cat > Brewfile << 'EOF'
# Taps
tap "hashicorp/tap"

# Essential CLI Tools
brew "git"
brew "wget"
brew "htop"
brew "tree"
brew "jq"
brew "fzf"
brew "ripgrep"
brew "zoxide"
brew "starship"
brew "neovim"
brew "bat"

# Development Tools
brew "pyenv"
brew "rustup-init"
brew "go"
brew "nvm"
brew "kubernetes-cli"
brew "helm"

# Media & Network Tools
brew "ffmpeg"
brew "yt-dlp"
brew "nmap"
brew "aircrack-ng"

# Security & Analysis
brew "sqlmap"
brew "binwalk"
brew "pngcheck"
brew "fcrackzip"
brew "imagemagick"
brew "exiftool"

# Database
brew "mongosh"
brew "postgresql@14"
brew "redis"
brew "mysql"

# .NET
brew "dotnet"

# Development Applications
cask "visual-studio-code"
cask "cursor"
cask "warp"
cask "docker"
cask "postman"
cask "microsoft-azure-storage-explorer"

# Browsers
cask "google-chrome"
cask "arc"
cask "zen"

# Communication
cask "whatsapp"
cask "discord"
cask "microsoft-teams"

# Productivity
cask "raycast"
cask "notion"
cask "obsidian"
cask "todoist"
cask "claude"

# Design
# cask "figma"
cask "sketch"

# Utilities
cask "the-unarchiver"
cask "appcleaner"
cask "motrix"
cask "keka"
# cask "bartender"
cask "rectangle"
cask "karabiner-elements"

# Cloud Storage
cask "google-drive"
cask "dropbox"

# Entertainment
cask "spotify"
cask "plex"

# Fonts
cask "font-fira-code"
cask "font-jetbrains-mono"
cask "font-sf-mono"
cask "font-cascadia-code"
cask "font-victor-mono"
cask "font-fira-code-nerd-font"
cask "font-jetbrains-mono-nerd-font"
cask "font-hack-nerd-font"
cask "font-source-code-pro-nerd-font"
cask "font-meslo-lg-nerd-font"
cask "font-inconsolata-nerd-font"
EOF
    success "Optimized Brewfile created"
fi

update_progress

log "Installing applications from Brewfile (this may take a while)..."
if brew bundle --file=Brewfile; then
    success "Apps installed successfully"
else
    warn "Some apps may have failed to install"
fi

update_progress

# Install oh-my-zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    # Install useful plugins
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
    
    success "Oh My Zsh and plugins installed"
else
    success "Oh My Zsh already installed"
fi
update_progress

# Configure .zshrc
log "Configuring .zshrc..."
cat > ~/.zshrc << 'EOF'
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(
    git
    docker
    docker-compose
    node
    npm
    yarn
    pnpm
    python
    rust
    golang
    kubectl
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
)

source $ZSH/oh-my-zsh.sh

# User configuration
export PATH="/opt/homebrew/bin:$PATH"
export EDITOR='code'

# Aliases
alias ll='exa -la'
alias ls='exa'
alias cat='bat'
alias cd='z'
alias vim='nvim'
alias python='python3'
alias pip='pip3'

# Initialize tools
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/bash_completion"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# rbenv
eval "$(rbenv init -)"

# Go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH

# Rust
source "$HOME/.cargo/env"

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Custom functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
EOF
update_progress

# Setup Git config
log "Configuring Git..."
# echo -e "${YELLOW}Enter your name for Git:${NC}"
# read -r git_name
# echo -e "${YELLOW}Enter your email for Git:${NC}"
# read -r git_email

git config --global --replace-all user.name "Gabriel A."
git config --global --replace-all user.email "kore.dv7@gmail.com"
git config --global init.defaultBranch main
git config --global pull.rebase false

# Global gitignore
cat > ~/.gitignore_global << 'EOF'
# macOS
.DS_Store
.AppleDouble
.LSOverride
._*

# IDEs
.vscode/
.idea/
*.swp
*.swo

# Node
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Python
__pycache__/
*.py[cod]
*$py.class
.env
.venv

# Logs
logs
*.log
EOF

git config --global core.excludesfile ~/.gitignore_global
success "Git configured"
update_progress

# Check if mas (Mac App Store CLI) is available
if ! command_exists mas; then
    log "Installing mas (Mac App Store CLI)..."
    brew install mas
fi

# Check if user is logged into Mac App Store
if ! mas account &>/dev/null; then
    warn "You need to be logged into the Mac App Store to install apps."
    warn "Please open the App Store, log in, and press Enter."
    wait_for_user
fi

# Install Mac App Store apps
log "Installing Mac App Store apps..."

# Dynamic wallpaper
mas install 1453504509 && success "Dynamic Wallpaper installed" || warn "Failed to install Dynamic Wallpaper"

# Bear notes
# mas install 1091189122 && success "Bear Notes installed" || warn "Failed to install Bear Notes"

# Xcode (if there's space)
# mas install 497799835 && success "Xcode installed" || warn "Failed to install Xcode"

update_progress

# Install nvm and Node
log "Setting up Node.js via NVM..."
if [[ ! -d "$HOME/.nvm" ]]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install latest LTS Node
    nvm install --lts
    nvm use --lts
    nvm alias default node
    
    # Install global packages
    npm install -g yarn pnpm typescript ts-node eslint prettier nodemon create-react-app @ionic/cli @angular/cli next
    
    success "NVM and Node.js configured"
else
    success "NVM already installed"
fi
update_progress

# Setup Python environment
log "Setting up Python environment..."
if command_exists pyenv; then

    # Install latest Python
    PYTHON_VERSION=$(pyenv install -l | grep -E '^\s*[0-9]+\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')
    
    # Check if $PYTHON_VERSION is already installed
    if pyenv versions | grep -q "$PYTHON_VERSION"; then
        success "Python $PYTHON_VERSION already installed"
    else
        log "Installing Python $PYTHON_VERSION..."
        pyenv install "$PYTHON_VERSION"
    fi
    
    pyenv global $PYTHON_VERSION
    
    success "Python environment configured"
fi
update_progress

# Advanced macOS Configurations
log "Applying advanced macOS configurations..."

###############################################################################
# Dock & Hot Corners                                                         #
###############################################################################

# Set dock size
defaults write com.apple.dock tilesize -int 40

# Enable magnification
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock largesize -int 64

# Position on left
#defaults write com.apple.dock orientation -string "left"

# Auto-hide dock
defaults write com.apple.dock autohide -bool false

# Remove auto-hiding delay
defaults write com.apple.dock autohide-delay -float 0

# Hot corners
# Top left screen corner → Mission Control
defaults write com.apple.dock wvous-tl-corner -int 2
defaults write com.apple.dock wvous-tl-modifier -int 0
# Top right screen corner → Desktop
defaults write com.apple.dock wvous-tr-corner -int 4
defaults write com.apple.dock wvous-tr-modifier -int 0

###############################################################################
# Finder                                                                      #
###############################################################################

# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Use list view by default
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Search current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable warning when changing file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Show the ~/Library folder
chflags nohidden ~/Library

###############################################################################
# Screen & Screenshots                                                        #
###############################################################################

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Save screenshots to Downloads folder
defaults write com.apple.screencapture location -string "${HOME}/Downloads"

# Save screenshots in PNG format
defaults write com.apple.screencapture type -string "png"

# Save screenshots to the clipboard instead of the desktop
defaults write com.apple.screencapture target clipboard

# Hide all desktop icons
defaults write com.apple.finder CreateDesktop -bool false

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# Enable subpixel font rendering on non-Apple LCDs
defaults write NSGlobalDomain AppleFontSmoothing -int 2

###############################################################################
# Keyboard & Input                                                           #
###############################################################################

# Disable natural scrolling
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Set a blazingly fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# Enable full keyboard access for all controls
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

###############################################################################
# Trackpad                                                                    #
###############################################################################

# Enable tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Enable three finger drag
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true

###############################################################################
# Menu Bar & Spotlight                                                       #
###############################################################################

# Show battery percentage
#defaults write com.apple.menuextra.battery ShowPercent -bool true

# Hide Spotlight icon
# defaults write com.apple.spotlight "NSStatusItem Visible Item-0" -bool false

###############################################################################
# Safari                                                                      #
###############################################################################

# Enable Web Inspector
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

success "Advanced configurations applied"
update_progress

# Install additional useful tools
log "Installing additional tools..."

# Install Starship prompt (if not already installed via brew)
if ! command_exists starship; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# Setup SSH
if [[ ! -f ~/.ssh/id_rsa ]]; then
    warn "Would you like to generate an SSH key? (y/n)"
    read -r generate_ssh
    if [[ $generate_ssh == "y" ]]; then
        ssh-keygen -t rsa -b 4096 -C "$git_email" -f ~/.ssh/id_rsa -N ""
        success "SSH key generated at ~/.ssh/id_rsa"
        info "Public key:"
        cat ~/.ssh/id_rsa.pub
    fi
fi

update_progress

# Restart affected services
log "Restarting services..."
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true
success "Services restarted"

# Final progress update
update_progress

echo ""
success "🎉 Setup completed successfully!"
echo ""
info "📝 Recommended next steps:"
echo ""
echo "1. 🔄 Restart your Mac to apply all configurations"
echo "2. 🔑 Add your SSH key to GitHub/GitLab if generated"
echo "3. 🎨 Configure themes and plugins in VS Code"
echo "4. ⚙️  Run 'brew services list' to see available services"
echo "5. 🐍 Set up Python virtual environments with 'pyenv virtualenv'"
echo "6. 🚀 Run 'nvm ls' to see installed Node versions"
echo ""
info "🛠️  Installed tools include:"
echo "   • Oh My Zsh with useful plugins"
echo "   • Node.js via NVM with global packages"
echo "   • Python via pyenv with development tools"
echo "   • Git configured with global .gitignore"
echo "   • Docker & Kubernetes CLI"
echo "   • Starship custom prompt"
echo "   • Many other development tools!"
echo ""
success "Environment setup completed!"