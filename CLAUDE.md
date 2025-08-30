# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a complete PowerShell-based screenshot service for Windows featuring global hotkey support, system tray integration, multi-monitor capture, and Windows auto-start functionality. The service runs silently in the background and allows instant screenshot capture across all connected displays.

## Commands

### Running the Service
```powershell
.\screenshot-service.ps1
```

This is the main service that provides:
- Global hotkey registration (Ctrl+Shift+-)
- System tray icon with context menu
- Auto-start Windows integration
- Settings dialog for configuration
- Multi-monitor screenshot capture

### Running Screenshot Tool Directly
```powershell
.\screenshot.ps1
```

Direct screenshot tool (used internally by service):
- Creates semi-transparent overlay across all monitors
- Allows area selection with visual feedback
- Saves to configurable directory
- Copies file path to clipboard

### Creating Start Menu Shortcut
```powershell
.\create-shortcut.ps1
```

Creates a Windows Start Menu shortcut that can be pinned to taskbar.

## Architecture

### Core Components

**Screenshot Service (`screenshot-service.ps1`)**:
- **Global Hotkey System**: Uses Win32 API `RegisterHotKey` with custom `HotkeyForm` class to capture Ctrl+Shift+- system-wide
- **System Tray Integration**: Creates persistent tray icon with context menu for Settings and Exit
- **Configuration Management**: JSON-based config system with GUI settings dialog
- **Windows Integration**: Registry-based auto-start functionality
- **Process Management**: Launches screenshot tool silently using `ProcessStartInfo` with hidden windows

**Screenshot Capture Engine (`screenshot.ps1`)**:
- **Multi-Monitor Overlay**: Uses `SystemInformation.VirtualScreen` to span all displays including negative coordinates
- **Visual Selection System**: Semi-transparent overlay (30% opacity) with red selection borders
- **Coordinate Translation**: Converts between form-relative and absolute screen coordinates
- **Screen Capture**: Uses `Graphics.CopyFromScreen()` with precise coordinate mapping
- **File Management**: Timestamp-based naming with configurable folder and prefix

**Windows Integration (`create-shortcut.ps1`)**:
- **Start Menu Shortcut**: Creates .lnk file in Programs folder
- **Taskbar Pinning**: Enables right-click pin to taskbar functionality
- **Shell Integration**: Uses WScript.Shell COM object for shortcut creation

### Key Technical Details

- **Hotkey Implementation**: Win32 `RegisterHotKey` with custom WndProc message handling
- **Multi-Monitor Support**: Handles complex arrangements including negative coordinates and portrait displays
- **Process Architecture**: Service spawns hidden PowerShell processes for screenshot capture
- **Memory Management**: Proper disposal of COM objects, GDI+ resources, and Windows handles
- **Error Handling**: Graceful degradation with balloon tip notifications for conflicts
- **Configuration Persistence**: JSON serialization with fallback to defaults

### Configuration System

**JSON Configuration File (`screenshot-config.json`)**:
```json
{
    "screenshotFolder": "C:\\Screenshots",
    "filePrefix": "screenshot_"
}
```

**Settings Dialog Features**:
- Browse folder selection
- Auto-start checkbox (modifies Windows Registry)
- Real-time configuration updates
- Input validation

**Registry Integration**:
- Location: `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run`
- Key: `ScreenshotService`
- Value: Hidden PowerShell execution command

### File Structure

```
screenshot-service.ps1    # Main service with hotkey and tray
screenshot.ps1           # Core screenshot capture engine
create-shortcut.ps1     # Start Menu shortcut creator
screenshot-config.json  # Configuration file (auto-generated)
CLAUDE.md              # This documentation
claude_code_readme.md  # Development history/notes
```

### Dependencies

- **Windows PowerShell**: Required for Windows.Forms support (not PowerShell Core)
- **.NET Framework Assemblies**: `System.Windows.Forms`, `System.Drawing`
- **Windows APIs**: `user32.dll` for hotkey registration and window management
- **COM Objects**: `WScript.Shell` for shortcut creation
- **Registry Access**: For auto-start functionality
- **No External Modules**: Self-contained PowerShell solution

### User Experience Flow

1. **Service Start**: `screenshot-service.ps1` runs hidden, registers hotkey, shows tray icon
2. **Hotkey Trigger**: User presses Ctrl+Shift+- anywhere in Windows
3. **Screenshot Launch**: Service spawns hidden `screenshot.ps1` process
4. **Area Selection**: Semi-transparent overlay appears, user drags to select area
5. **Capture & Save**: Screenshot saved to configured folder, path copied to clipboard
6. **Cleanup**: Overlay closes, service remains active for next hotkey press

### Common Development Tasks

- **Modify Hotkey**: Change `VK_OEM_MINUS` constant in Win32 API definitions
- **Add Settings**: Extend JSON config and settings dialog form
- **Visual Feedback**: Modify Paint event handlers in screenshot.ps1
- **Error Handling**: Add balloon tip notifications in service
- **Testing**: Manual verification across multi-monitor setups