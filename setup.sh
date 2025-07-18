#!/bin/bash

echo "🚀 0x0 MacOS setup..."

# Instalar Xcode Command Line Tools
xcode-select --install

if ! command -v brew &> /dev/null; then
    echo "📦 Instalando Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Instalar apps essenciais
echo "Instalando aplicativos..."
brew bundle --file=Brewfile

# Install nvm
echo "Instalando NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm


mas install 1453504509 # Dynamic wallpaper

# Configurações do macOS
echo "Aplicando configurações..."
defaults write com.apple.dock autohide -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

echo "✅ Finalizado"