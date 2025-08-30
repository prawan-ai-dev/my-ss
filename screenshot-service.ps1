Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Configuration file path
$configFile = Join-Path $PSScriptRoot "screenshot-config.json"

# Load or create configuration
function Get-Config {
    if (Test-Path $configFile) {
        try {
            $config = Get-Content $configFile -Raw | ConvertFrom-Json
            return $config
        } catch {
            # If config is corrupted, return defaults
        }
    }
    
    # Default configuration
    return @{
        screenshotFolder = "C:\Screenshots"
        filePrefix = "screenshot_"
    }
}

function Save-Config($config) {
    try {
        $config | ConvertTo-Json | Set-Content $configFile -Encoding UTF8
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to save configuration: $_", "Error", 'OK', 'Error')
    }
}

# Load initial config
$script:config = Get-Config

# Global hotkey registration using Win32 API
Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    public class GlobalHotkey {
        [DllImport("user32.dll")]
        public static extern bool RegisterHotKey(IntPtr hWnd, int id, int fsModifiers, int vk);
        [DllImport("user32.dll")]
        public static extern bool UnregisterHotKey(IntPtr hWnd, int id);
        
        public const int MOD_CONTROL = 0x0002;
        public const int MOD_SHIFT = 0x0004;
        public const int VK_OEM_MINUS = 0xBD;  // - key
        public const int WM_HOTKEY = 0x0312;
    }
"@ -ReferencedAssemblies System.Windows.Forms

# Function to add to Windows startup
function Add-ToStartup {
    try {
        $scriptPath = $PSCommandPath
        $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        Set-ItemProperty -Path $registryPath -Name "ScreenshotService" -Value "powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        return $true
    } catch {
        return $false
    }
}

# Function to remove from Windows startup
function Remove-FromStartup {
    try {
        $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        Remove-ItemProperty -Path $registryPath -Name "ScreenshotService" -ErrorAction SilentlyContinue
        return $true
    } catch {
        return $false
    }
}

# Function to check if already in startup
function Test-InStartup {
    try {
        $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        $value = Get-ItemProperty -Path $registryPath -Name "ScreenshotService" -ErrorAction SilentlyContinue
        return $value -ne $null
    } catch {
        return $false
    }
}

# Function to launch screenshot tool silently and directly
function Launch-ScreenshotTool {
    try {
        # Create screenshot folder if it doesn't exist
        if (-not (Test-Path $script:config.screenshotFolder)) {
            New-Item -ItemType Directory -Path $script:config.screenshotFolder -Force | Out-Null
        }
        
        # Launch PowerShell completely hidden with current config
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -Command `"& { `$screenshotFolder = '$($script:config.screenshotFolder)'; `$filePrefix = '$($script:config.filePrefix)'; . '$PSScriptRoot\screenshot.ps1' }`""
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $psi.CreateNoWindow = $true
        $psi.UseShellExecute = $false
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    } catch {
        Show-TrayNotification "Screenshot Error" "Failed to launch screenshot tool: $_"
    }
}

# Function to show tray notifications
function Show-TrayNotification($title, $message) {
    $notifyIcon.BalloonTipTitle = $title
    $notifyIcon.BalloonTipText = $message
    $notifyIcon.BalloonTipIcon = 'Info'
    $notifyIcon.ShowBalloonTip(3000)
}

# Handle hotkey activation
Add-Type -TypeDefinition @"
    using System;
    using System.Windows.Forms;
    using System.Runtime.InteropServices;
    
    public class HotkeyForm : Form {
        private System.Action onHotkey;
        
        public HotkeyForm(System.Action hotkeyAction) {
            onHotkey = hotkeyAction;
            this.WindowState = FormWindowState.Minimized;
            this.ShowInTaskbar = false;
            this.Visible = false;
        }
        
        protected override void WndProc(ref Message m) {
            const int WM_HOTKEY = 0x0312;
            if (m.Msg == WM_HOTKEY) {
                if (onHotkey != null) onHotkey();
            }
            base.WndProc(ref m);
        }
    }
"@ -ReferencedAssemblies System.Windows.Forms

# Create system tray icon
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Text = "Screenshot Tool (Ctrl+Shift+-)"
$notifyIcon.Visible = $true

# Create simple icon (16x16 camera-like icon)
$iconBitmap = New-Object System.Drawing.Bitmap(16, 16)
$graphics = [System.Drawing.Graphics]::FromImage($iconBitmap)
$graphics.Clear([System.Drawing.Color]::Transparent)
# Draw simple camera icon
$pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Black, 1)
$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Gray)
$graphics.FillRectangle($brush, 2, 4, 12, 8)
$graphics.DrawRectangle($pen, 2, 4, 12, 8)
$graphics.FillEllipse($brush, 5, 6, 6, 4)
$graphics.DrawEllipse($pen, 5, 6, 6, 4)
$graphics.FillRectangle($brush, 1, 2, 4, 2)
$graphics.DrawRectangle($pen, 1, 2, 4, 2)
$pen.Dispose()
$brush.Dispose()
$graphics.Dispose()
$notifyIcon.Icon = [System.Drawing.Icon]::FromHandle($iconBitmap.GetHicon())

# Create context menu
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip

# Settings menu item
$settingsItem = New-Object System.Windows.Forms.ToolStripMenuItem
$settingsItem.Text = "Settings..."
$settingsItem.Add_Click({
    Show-SettingsDialog
})
$contextMenu.Items.Add($settingsItem)

# Separator
$contextMenu.Items.Add("-")

# Close menu item
$closeItem = New-Object System.Windows.Forms.ToolStripMenuItem
$closeItem.Text = "Exit"
$closeItem.Add_Click({
    $script:shouldExit = $true
    $notifyIcon.Dispose()
    $hotkeyForm.Close()
})
$contextMenu.Items.Add($closeItem)

$notifyIcon.ContextMenuStrip = $contextMenu

# Settings dialog
function Show-SettingsDialog {
    $settingsForm = New-Object System.Windows.Forms.Form
    $settingsForm.Text = "Screenshot Settings"
    $settingsForm.Size = New-Object System.Drawing.Size(450, 200)
    $settingsForm.StartPosition = "CenterScreen"
    $settingsForm.FormBorderStyle = "FixedDialog"
    $settingsForm.MaximizeBox = $false
    $settingsForm.MinimizeBox = $false
    $settingsForm.TopMost = $true
    
    # Screenshot folder label
    $folderLabel = New-Object System.Windows.Forms.Label
    $folderLabel.Text = "Screenshot Folder:"
    $folderLabel.Location = New-Object System.Drawing.Point(10, 20)
    $folderLabel.Size = New-Object System.Drawing.Size(100, 20)
    $settingsForm.Controls.Add($folderLabel)
    
    # Screenshot folder textbox
    $folderTextBox = New-Object System.Windows.Forms.TextBox
    $folderTextBox.Text = $script:config.screenshotFolder
    $folderTextBox.Location = New-Object System.Drawing.Point(10, 45)
    $folderTextBox.Size = New-Object System.Drawing.Size(300, 20)
    $settingsForm.Controls.Add($folderTextBox)
    
    # Browse button
    $browseButton = New-Object System.Windows.Forms.Button
    $browseButton.Text = "Browse..."
    $browseButton.Location = New-Object System.Drawing.Point(320, 43)
    $browseButton.Size = New-Object System.Drawing.Size(80, 25)
    $browseButton.Add_Click({
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderDialog.SelectedPath = $folderTextBox.Text
        $folderDialog.Description = "Select screenshot folder"
        if ($folderDialog.ShowDialog() -eq 'OK') {
            $folderTextBox.Text = $folderDialog.SelectedPath
        }
    })
    $settingsForm.Controls.Add($browseButton)
    
    # Auto-start checkbox
    $autoStartCheckBox = New-Object System.Windows.Forms.CheckBox
    $autoStartCheckBox.Text = "Start with Windows"
    $autoStartCheckBox.Location = New-Object System.Drawing.Point(10, 85)
    $autoStartCheckBox.Size = New-Object System.Drawing.Size(150, 20)
    $autoStartCheckBox.Checked = Test-InStartup
    $settingsForm.Controls.Add($autoStartCheckBox)
    
    # OK button
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Location = New-Object System.Drawing.Point(250, 120)
    $okButton.Size = New-Object System.Drawing.Size(75, 25)
    $okButton.Add_Click({
        # Save configuration
        $script:config.screenshotFolder = $folderTextBox.Text
        Save-Config $script:config
        
        # Handle auto-start setting
        if ($autoStartCheckBox.Checked) {
            Add-ToStartup | Out-Null
        } else {
            Remove-FromStartup | Out-Null
        }
        
        $settingsForm.Close()
    })
    $settingsForm.Controls.Add($okButton)
    
    # Cancel button
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Location = New-Object System.Drawing.Point(335, 120)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 25)
    $cancelButton.Add_Click({
        $settingsForm.Close()
    })
    $settingsForm.Controls.Add($cancelButton)
    
    $settingsForm.ShowDialog()
}

# Create the hotkey handler form  
$action = { Launch-ScreenshotTool }
$hotkeyForm = New-Object HotkeyForm -ArgumentList $action

# Register the hotkey
$hotkeyId = 1
$registered = [GlobalHotkey]::RegisterHotKey($hotkeyForm.Handle, $hotkeyId, ([GlobalHotkey]::MOD_CONTROL -bor [GlobalHotkey]::MOD_SHIFT), [GlobalHotkey]::VK_OEM_MINUS)

if (-not $registered) {
    Show-TrayNotification "Hotkey Error" "Failed to register Ctrl+Shift+- hotkey. It may be in use by another program."
}

# Set up cleanup on exit
$script:shouldExit = $false
$cleanup = {
    try {
        if ($hotkeyForm -and $hotkeyForm.Handle -ne [IntPtr]::Zero) {
            [GlobalHotkey]::UnregisterHotKey($hotkeyForm.Handle, $hotkeyId)
        }
        if ($notifyIcon) { $notifyIcon.Dispose() }
        if ($hotkeyForm) { $hotkeyForm.Dispose() }
    } catch {
        # Ignore cleanup errors
    }
}

# Handle form closing
$hotkeyForm.Add_FormClosed({
    if (-not $script:shouldExit) {
        # If form closed unexpectedly, cleanup and exit
        & $cleanup
        [System.Windows.Forms.Application]::Exit()
    }
})

# Automatically add to startup if not already there
if (-not (Test-InStartup)) {
    Add-ToStartup | Out-Null
}

# Keep the script running
try {
    [System.Windows.Forms.Application]::Run($hotkeyForm)
} finally {
    & $cleanup
}