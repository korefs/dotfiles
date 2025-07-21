const { ipcRenderer } = require('electron');

class AppManager {
    constructor() {
        this.packages = {
            taps: [],
            brews: [],
            casks: [],
            masApps: []
        };
        this.configs = [];
        this.init();
    }

    init() {
        this.setupTabs();
        this.setupEventListeners();
        this.loadScript();
    }

    setupTabs() {
        const tabs = document.querySelectorAll('.tab');
        const tabContents = document.querySelectorAll('.tab-content');

        tabs.forEach(tab => {
            tab.addEventListener('click', () => {
                const tabName = tab.getAttribute('data-tab');
                
                tabs.forEach(t => t.classList.remove('active'));
                tabContents.forEach(tc => tc.classList.remove('active'));
                
                tab.classList.add('active');
                document.getElementById(tabName).classList.add('active');

                if (tabName === 'preview') {
                    this.updatePreview();
                }
            });
        });
    }

    setupEventListeners() {
        document.getElementById('loadScript').addEventListener('click', () => this.loadScript());
        document.getElementById('exportScript').addEventListener('click', () => this.exportScript());
        document.getElementById('generateScript').addEventListener('click', () => this.updatePreview());
        document.getElementById('saveManualScript').addEventListener('click', () => this.saveManualScript());

        document.getElementById('addTap').addEventListener('click', () => this.addTap());
        document.getElementById('addBrew').addEventListener('click', () => this.addBrew());
        document.getElementById('addCask').addEventListener('click', () => this.addCask());
        document.getElementById('addMasApp').addEventListener('click', () => this.addMasApp());

        document.getElementById('browseFormulae').addEventListener('click', () => this.openBrewFormulae());
        document.getElementById('browseCasks').addEventListener('click', () => this.openBrewCasks());
        document.getElementById('browseSearch').addEventListener('click', () => this.openBrewSearch());

        document.getElementById('newTap').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.addTap();
        });
        document.getElementById('newBrew').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.addBrew();
        });
        document.getElementById('newCask').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.addCask();
        });
    }

    async loadScript() {
        try {
            const result = await ipcRenderer.invoke('read-setup-script');
            if (result.success) {
                this.packages = SetupParser.parseBrewPackages(result.content);
                this.configs = SetupParser.parseSystemConfigs(result.content);
                this.renderPackages();
                this.renderConfigs();
                console.log('Script loaded successfully');
            } else {
                console.error('Failed to load script:', result.error);
            }
        } catch (error) {
            console.error('Error loading script:', error);
        }
    }

    async exportScript() {
        try {
            const scriptContent = document.getElementById('scriptPreview').value;
            const script = scriptContent || SetupParser.generateSetupScript(this.packages, this.configs);
            const result = await ipcRenderer.invoke('export-script', script);
            
            if (result.success && !result.canceled) {
                console.log('Script exported to:', result.path);
            }
        } catch (error) {
            console.error('Error exporting script:', error);
        }
    }

    async saveManualScript() {
        try {
            const scriptContent = document.getElementById('scriptPreview').value;
            if (scriptContent.trim()) {
                const result = await ipcRenderer.invoke('save-setup-script', scriptContent);
                if (result.success) {
                    console.log('Script saved successfully');
                    alert('Script salvo com sucesso!');
                } else {
                    console.error('Failed to save script:', result.error);
                    alert('Erro ao salvar script: ' + result.error);
                }
            } else {
                alert('Script está vazio!');
            }
        } catch (error) {
            console.error('Error saving script:', error);
            alert('Erro ao salvar script: ' + error.message);
        }
    }

    addTap() {
        const input = document.getElementById('newTap');
        const tapName = input.value.trim();
        if (tapName && !this.packages.taps.includes(tapName)) {
            this.packages.taps.push(tapName);
            input.value = '';
            this.renderPackages();
        }
    }

    addBrew() {
        const input = document.getElementById('newBrew');
        const brewName = input.value.trim();
        if (brewName && !this.packages.brews.includes(brewName)) {
            this.packages.brews.push(brewName);
            input.value = '';
            this.renderPackages();
        }
    }

    addCask() {
        const input = document.getElementById('newCask');
        const caskName = input.value.trim();
        if (caskName && !this.packages.casks.includes(caskName)) {
            this.packages.casks.push(caskName);
            input.value = '';
            this.renderPackages();
        }
    }

    addMasApp() {
        const idInput = document.getElementById('newMasId');
        const nameInput = document.getElementById('newMasName');
        const appId = idInput.value.trim();
        const appName = nameInput.value.trim();
        
        if (appId && appName) {
            const exists = this.packages.masApps.some(app => app.id === appId);
            if (!exists) {
                this.packages.masApps.push({ id: appId, name: appName });
                idInput.value = '';
                nameInput.value = '';
                this.renderPackages();
            }
        }
    }

    removePackage(type, index) {
        this.packages[type].splice(index, 1);
        this.renderPackages();
    }

    toggleConfig(index) {
        this.configs[index].enabled = !this.configs[index].enabled;
        this.renderConfigs();
    }

    renderPackages() {
        this.renderPackageList('tapsList', this.packages.taps, 'taps');
        this.renderPackageList('brewsList', this.packages.brews, 'brews');
        this.renderPackageList('casksList', this.packages.casks, 'casks');
        this.renderMasAppsList();
    }

    renderPackageList(containerId, packages, type) {
        const container = document.getElementById(containerId);
        
        if (packages.length === 0) {
            container.innerHTML = '<div class="empty-state">Nenhum item adicionado</div>';
            return;
        }

        container.innerHTML = packages.map((pkg, index) => `
            <div class="package-item">
                <span class="package-name">${pkg}</span>
                <div class="package-actions">
                    <button class="btn btn-danger" onclick="app.removePackage('${type}', ${index})">
                        Remover
                    </button>
                </div>
            </div>
        `).join('');
    }

    renderMasAppsList() {
        const container = document.getElementById('masAppsList');
        
        if (this.packages.masApps.length === 0) {
            container.innerHTML = '<div class="empty-state">Nenhum app adicionado</div>';
            return;
        }

        container.innerHTML = this.packages.masApps.map((app, index) => `
            <div class="package-item">
                <div>
                    <span class="package-name">${app.name}</span>
                    <div class="package-id">ID: ${app.id}</div>
                </div>
                <div class="package-actions">
                    <button class="btn btn-danger" onclick="app.removePackage('masApps', ${index})">
                        Remover
                    </button>
                </div>
            </div>
        `).join('');
    }

    renderConfigs() {
        const container = document.getElementById('configsList');
        
        if (this.configs.length === 0) {
            container.innerHTML = '<div class="empty-state">Nenhuma configuração encontrada</div>';
            return;
        }

        container.innerHTML = this.configs.map((config, index) => `
            <div class="config-item">
                <div class="config-header">
                    <div>
                        <div class="config-description">${config.description || 'Configuração'}</div>
                        <div class="config-domain">${config.domain} → ${config.key}</div>
                    </div>
                    <label class="config-toggle">
                        <input type="checkbox" ${config.enabled ? 'checked' : ''} 
                               onchange="app.toggleConfig(${index})">
                        <span class="slider"></span>
                    </label>
                </div>
            </div>
        `).join('');
    }

    updatePreview() {
        const script = SetupParser.generateSetupScript(this.packages, this.configs);
        document.getElementById('scriptPreview').value = script;
    }

    async openBrewFormulae() {
        try {
            await ipcRenderer.invoke('open-external', 'https://formulae.brew.sh/formula/');
        } catch (error) {
            console.error('Error opening Homebrew formulae:', error);
        }
    }

    async openBrewCasks() {
        try {
            await ipcRenderer.invoke('open-external', 'https://formulae.brew.sh/cask/');
        } catch (error) {
            console.error('Error opening Homebrew casks:', error);
        }
    }

    async openBrewSearch() {
        try {
            await ipcRenderer.invoke('open-external', 'https://brew.sh/');
        } catch (error) {
            console.error('Error opening Homebrew search:', error);
        }
    }
}

const app = new AppManager();