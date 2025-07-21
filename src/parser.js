class SetupParser {
  static parseBrewPackages(content) {
    const packages = {
      taps: [],
      brews: [],
      casks: [],
      masApps: []
    };

    const lines = content.split('\n');
    let inBrewfile = false;

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();

      if (line.includes('cat > Brewfile')) {
        inBrewfile = true;
        continue;
      }

      if (inBrewfile && line === 'EOF') {
        inBrewfile = false;
        continue;
      }

      if (inBrewfile) {
        if (line.startsWith('tap ')) {
          const match = line.match(/tap\s+"([^"]+)"/);
          if (match) packages.taps.push(match[1]);
        } else if (line.startsWith('brew ')) {
          const match = line.match(/brew\s+"([^"]+)"/);
          if (match) packages.brews.push(match[1]);
        } else if (line.startsWith('cask ')) {
          const match = line.match(/cask\s+"([^"]+)"/);
          if (match) packages.casks.push(match[1]);
        }
      }

      if (line.includes('mas install')) {
        const match = line.match(/mas install\s+(\d+)/);
        if (match) {
          const appId = match[1];
          let appName = 'Unknown App';
          
          if (i > 0) {
            const prevLine = lines[i-1].trim();
            if (prevLine.startsWith('#')) {
              appName = prevLine.replace('#', '').trim();
            }
          }
          
          packages.masApps.push({ id: appId, name: appName });
        }
      }
    }

    return packages;
  }

  static parseSystemConfigs(content) {
    const configs = [];
    const lines = content.split('\n');

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();

      if (line.startsWith('defaults write')) {
        const match = line.match(/defaults write\s+([^\s]+)\s+([^\s]+)\s+(.+)/);
        if (match) {
          const [, domain, key, value] = match;
          let description = '';
          
          if (i > 0) {
            const prevLine = lines[i-1].trim();
            if (prevLine.startsWith('#')) {
              description = prevLine.replace('#', '').trim();
            }
          }

          configs.push({
            domain,
            key,
            value,
            description,
            enabled: true,
            originalLine: line
          });
        }
      }
    }

    return configs;
  }

  static generateBrewfile(packages) {
    let brewfile = '';
    
    if (packages.taps.length > 0) {
      brewfile += '# Taps\n';
      packages.taps.forEach(tap => {
        brewfile += `tap "${tap}"\n`;
      });
      brewfile += '\n';
    }

    if (packages.brews.length > 0) {
      brewfile += '# Tools\n';
      packages.brews.forEach(brew => {
        brewfile += `brew "${brew}"\n`;
      });
      brewfile += '\n';
    }

    if (packages.casks.length > 0) {
      brewfile += '# Casks\n';
      packages.casks.forEach(cask => {
        brewfile += `cask "${cask}"\n`;
      });
      brewfile += '\n';
    }

    return brewfile;
  }

  static generateSetupScript(packages, configs) {
    let script = `#!/bin/bash

set -e

echo "🚀 0x0 MacOS setup..."

wait_for_user() {
    echo "Pressione Enter para continuar..."
    read -r
}

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
    
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    if ! command_exists brew; then
        echo "❌ Erro: Homebrew não foi instalado corretamente"
        exit 1
    fi
else
    echo "✅ Homebrew já instalado"
fi

# Criar Brewfile
cat > Brewfile << 'EOF'
${SetupParser.generateBrewfile(packages)}EOF

# Instalar apps do Brewfile
echo "📦 Instalando aplicativos do Brewfile..."
if brew bundle --file=Brewfile; then
    echo "✅ Apps instalados com sucesso"
else
    echo "⚠️  Alguns apps podem ter falhado na instalação"
fi
`;

    if (packages.masApps && packages.masApps.length > 0) {
      script += `
# Verificar se mas está disponível
if ! command_exists mas; then
    echo "📱 Instalando mas (Mac App Store CLI)..."
    brew install mas
fi

if ! mas account &>/dev/null; then
    echo "⚠️  Você precisa estar logado na Mac App Store para instalar apps."
    echo "   Por favor, abra a App Store, faça login e tente novamente."
    wait_for_user
fi

echo "📱 Instalando apps da Mac App Store..."
`;

      packages.masApps.forEach(app => {
        script += `
# ${app.name}
if mas install ${app.id}; then
    echo "✅ ${app.name} instalado"
else
    echo "⚠️  Falha ao instalar ${app.name}"
fi
`;
      });
    }

    if (configs && configs.length > 0) {
      script += `
# Configurações do macOS
echo "⚙️  Aplicando configurações do macOS..."

`;
      configs.forEach(config => {
        if (config.enabled) {
          if (config.description) {
            script += `# ${config.description}\n`;
          }
          script += `${config.originalLine}\n\n`;
        }
      });

      script += `echo "🔄 Reiniciando serviços afetados..."

killall Finder
killall Dock
killall SystemUIServer
`;
    }

    script += `
echo ""
echo "✅ Setup concluído!"
`;

    return script;
  }
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = SetupParser;
}