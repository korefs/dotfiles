const { app, BrowserWindow, ipcMain, dialog, shell } = require('electron');
const path = require('path');
const fs = require('fs');
const { exec } = require('child_process');

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    },
    titleBarStyle: 'hiddenInset',
    trafficLightPosition: { x: 20, y: 20 }
  });

  mainWindow.loadFile('src/index.html');

  if (process.argv.includes('--dev')) {
    mainWindow.webContents.openDevTools();
  }
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});

ipcMain.handle('read-setup-script', async () => {
  try {
    const setupPath = path.join(__dirname, '..', 'setup.sh');
    const content = fs.readFileSync(setupPath, 'utf8');
    return { success: true, content };
  } catch (error) {
    return { success: false, error: error.message };
  }
});

ipcMain.handle('save-setup-script', async (event, content) => {
  try {
    const setupPath = path.join(__dirname, '..', 'setup.sh');
    fs.writeFileSync(setupPath, content, 'utf8');
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
});

ipcMain.handle('export-script', async (event, content) => {
  try {
    const result = await dialog.showSaveDialog(mainWindow, {
      title: 'Export Setup Script',
      defaultPath: 'setup.sh',
      filters: [
        { name: 'Shell Scripts', extensions: ['sh'] },
        { name: 'All Files', extensions: ['*'] }
      ]
    });

    if (!result.canceled && result.filePath) {
      fs.writeFileSync(result.filePath, content, 'utf8');
      return { success: true, path: result.filePath };
    }
    return { success: false, canceled: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
});

ipcMain.handle('check-homebrew', async () => {
  return new Promise((resolve) => {
    exec('which brew', (error) => {
      resolve({ installed: !error });
    });
  });
});

ipcMain.handle('open-external', async (event, url) => {
  try {
    await shell.openExternal(url);
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
});