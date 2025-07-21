#!/bin/bash

set -e  # Para o script se algum comando falhar

echo "🚀 0x0 MacOS setup..."

# Função para aguardar input do usuário
wait_for_user() {
    echo "Pressione Enter para continuar..."
    read -r
}

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Instalar Xcode Command Line Tools
echo "📱 Verificando Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
    echo "Instalando Xcode Command Line Tools..."
    xcode-select --install
    echo "⚠️  Uma janela será aberta para instalar o Xcode Command Line Tools."
    echo "   Clique em 'Install' e aguarde a conclusão da instalação."
    wait_for_user
else
    echo "✅ Xcode Command Line Tools já instalado"
fi

# Instalar Homebrew
if ! command_exists brew; then
    echo "📦 Instalando Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Verificar se o Homebrew foi instalado corretamente
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        # Para Macs com Apple Silicon
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        # Para Macs com Intel
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    # Verificar novamente se brew está disponível
    if ! command_exists brew; then
        echo "❌ Erro: Homebrew não foi instalado corretamente"
        exit 1
    fi
else
    echo "✅ Homebrew já instalado"
fi

# Verificar se Brewfile existe
if [[ ! -f "Brewfile" ]]; then
    echo "⚠️  Brewfile não encontrado. Criando um exemplo..."
    cat > Brewfile << 'EOF'
# Taps
tap "homebrew/cask-fonts"

# Tools
brew "pyenv"
brew "rustup-init"
brew "git"
brew "ffmpeg"
brew "fprobe"
brew "mongosh"
brew "yt-dlp"
brew "wget"
brew "nvm"
brew "aircrack-ng"
brew "nmap"
brew "sqlmap"
brew "pngcheck"
brew "binwalk"
brew "fcrackzip"
brew "netpbm"
brew "imagemagick"
brew "gs"

brew "dotnet"
brew "dotnet@8"
brew "dotnet@6"

# Casks
cask "visual-studio-code"
cask "the-unarchiver"
cask "appcleaner"
cask "raycast"
cask "visual-studio-code"
cask "iterm2"
cask "docker"
cask "google-chrome"
cask "postman-agent"    
cask "zen"
cask "claude"
cask "motrix"
caks "whatsapp"
cask "discord"
cask "spotify"
cask "obsidian"
cask "notion"
cask "microsoft-azure-storage-explorer"
cask "warp"

# Fonts
cask "font-fira-code"
# Jetbrains mono
cask "font-jetbrains-mono"
EOF
    echo "✅ Brewfile de exemplo criado. Edite conforme necessário."
fi

# Instalar apps do Brewfile
echo "📦 Instalando aplicativos do Brewfile..."
if brew bundle --file=Brewfile; then
    echo "✅ Apps instalados com sucesso"
else
    echo "⚠️  Alguns apps podem ter falhado na instalação"
fi

# Verificar se mas (Mac App Store CLI) está disponível
if ! command_exists mas; then
    echo "📱 Instalando mas (Mac App Store CLI)..."
    brew install mas
fi

# Verificar se o usuário está logado na Mac App Store
if ! mas account &>/dev/null; then
    echo "⚠️  Você precisa estar logado na Mac App Store para instalar apps."
    echo "   Por favor, abra a App Store, faça login e tente novamente."
    wait_for_user
fi

# Instalar apps da Mac App Store
echo "📱 Instalando apps da Mac App Store..."

# Dynamic wallpaper
if mas install 1453504509; then
    echo "✅ Dynamic Wallpaper instalado"
else
    echo "⚠️  Falha ao instalar Dynamic Wallpaper"
fi

# Bear notes
if mas install 1091189122; then
    echo "✅ Bear Notes instalado"
else
    echo "⚠️  Falha ao instalar Bear Notes"
fi

# Install nvm
echo "🔧 Instalando NVM..."
if [[ ! -d "$HOME/.nvm" ]]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    
    # Carregar NVM para a sessão atual
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if command_exists nvm; then
        echo "✅ NVM instalado com sucesso"
        # Instalar a versão LTS mais recente do Node
        nvm install --lts
        nvm use --lts
    else
        echo "⚠️  NVM instalado, mas será necessário reiniciar o terminal"
    fi
else
    echo "✅ NVM já instalado"
fi

# Configurações do macOS
echo "⚙️  Aplicando configurações do macOS..."

###############################################################################
# Screen                                                                      #
###############################################################################

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Enable show desktop gesture
defaults write com.apple.dock show-desktop-gesture-enabled -bool true

# Save screenshots to the desktop
defaults write com.apple.screencapture location -string "${HOME}/Desktop"

# Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
defaults write com.apple.screencapture type -string "png"

# Save screenshots to the clipboard instead of the desktop
defaults write com.apple.screencapture target clipboard

# Hide all desktop icons
defaults write com.apple.finder CreateDesktop -bool false

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool false

# Enable subpixel font rendering on non-Apple LCDs
defaults write NSGlobalDomain AppleFontSmoothing -int 2

# Disable natural scrolling
defaults write -g com.apple.swipescrolldirection -bool false

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Set a fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

echo "🔄 Reiniciando serviços afetados..."

# Reiniciar Finder para aplicar mudanças
killall Finder

# Reiniciar Dock para aplicar mudanças
killall Dock

# Reiniciar SystemUIServer para aplicar mudanças de screenshot
killall SystemUIServer

echo ""
echo "✅ Setup concluído!"