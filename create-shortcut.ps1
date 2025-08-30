# Script to create Start Menu shortcut for Screenshot Service

# Get the path to the Start Menu Programs folder
$startMenuPath = [System.Environment]::GetFolderPath('StartMenu')
$programsPath = Join-Path $startMenuPath "Programs"

# Create shortcut file path
$shortcutPath = Join-Path $programsPath "Screenshot Service.lnk"

# Create WScript Shell object
$WshShell = New-Object -comObject WScript.Shell

# Create the shortcut
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\screenshot-service.ps1`""
$Shortcut.WorkingDirectory = $PSScriptRoot
$Shortcut.Description = "Screenshot Service - Global hotkey Ctrl+Shift+-"
$Shortcut.IconLocation = "shell32.dll,325"  # Camera icon from Windows

# Save the shortcut
$Shortcut.Save()

Write-Host "Start Menu shortcut created successfully!"
Write-Host ""
Write-Host "To pin to taskbar:"
Write-Host "1. Press Win key and search for 'Screenshot Service'"
Write-Host "2. Right-click on 'Screenshot Service'"
Write-Host "3. Select 'Pin to taskbar'"
Write-Host ""
Write-Host "You can now start the service from:"
Write-Host "   - Start Menu search"
Write-Host "   - Taskbar (after pinning)"
Write-Host ""

# Clean up COM object
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($WshShell) | Out-Null