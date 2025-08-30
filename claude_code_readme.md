# PowerShell Screenshot Tool

A simple multi-monitor screenshot tool for Windows that captures selected screen areas and copies the file path to clipboard.

## Current Features

- ✅ Multi-monitor support - works across all connected displays
- ✅ Area selection with visual overlay
- ✅ Auto-saves to predefined folder with timestamp
- ✅ Copies full file path to clipboard automatically
- ✅ Minimizes terminal window during capture
- ✅ Semi-transparent overlay with selection borders

## Current Implementation

The tool is implemented as a PowerShell script (`screenshot.ps1`) that:

1. **Minimizes the PowerShell window** when launched to avoid blocking the screen
2. **Creates a semi-transparent overlay** across all monitors using `SystemInformation.VirtualScreen`
3. **Allows area selection** by clicking and dragging with visual feedback
4. **Captures the selected area** using `Graphics.CopyFromScreen()`
5. **Saves to C:\Screenshots** with timestamp filename format
6. **Copies full path to clipboard** for easy pasting into terminals

## Technical Details

### Dependencies
- `System.Windows.Forms` - For UI overlay and screen detection
- `System.Drawing` - For graphics operations and bitmap handling
- Win32 API calls for window management (minimize/restore console)

### Key Components
- **Multi-monitor detection**: Uses `[System.Windows.Forms.Screen]::AllScreens` and `SystemInformation.VirtualScreen`
- **Overlay form**: Spans entire virtual screen area with semi-transparent background
- **Coordinate translation**: Converts form-relative coordinates to absolute screen coordinates
- **Visual feedback**: Red border (4px thick) with white inner border (1px) for selection visibility

### File Structure
```
screenshot.ps1          # Main PowerShell script
C:\Screenshots\         # Default output directory
  └── screenshot_YYYYMMDD_HHMMSS.png
```

## Current Issues & Improvement Areas

### Visual Feedback
- Selection area visibility could be improved
- Current approach uses borders on semi-transparent overlay
- Could benefit from clearer selection indication (transparent selection area with darker surroundings)

### User Experience
- No configuration UI - hardcoded paths and settings
- No preview or confirmation before saving
- Limited file format options (PNG only)

### Code Organization
- Single monolithic script
- Could benefit from modularization
- Error handling could be improved

## Configuration Options (Currently Hardcoded)

```powershell
$screenshotFolder = "C:\Screenshots"    # Output directory
$filePrefix = "screenshot_"             # Filename prefix
```

## Usage

1. Run the script: `.\screenshot.ps1`
2. Terminal minimizes automatically
3. Semi-transparent overlay appears across all monitors
4. Click and drag to select area
5. Release to capture
6. Press ESC to cancel
7. File path is automatically copied to clipboard

## Next Development Goals

1. **Improve visual feedback** - make selection area completely transparent
2. **Add configuration options** - customizable paths, formats, etc.
3. **Better error handling** - graceful failures and user feedback
4. **Code refactoring** - modular functions for better maintainability
5. **Additional features** - different file formats, preview, hotkey support

## Technical Notes for Claude Code

- This is a PowerShell-based Windows Forms application
- Uses .NET Framework classes through PowerShell
- Requires Windows PowerShell (not PowerShell Core) for full Windows.Forms support
- Can be converted to C# for better performance and distribution
- Current coordinate system handles negative coordinates for multi-monitor setups (monitors to the left of primary)

## Evolution Summary

### Phase 1: Basic Screenshot Tool
- Initial PowerShell script with area selection
- Basic Windows Forms overlay with selection rectangle
- File saving with timestamp naming

### Phase 2: Multi-Monitor Enhancement  
- Added support for spanning multiple displays using VirtualScreen
- Fixed coordinate translation for complex monitor arrangements
- Enhanced visual feedback with red borders and semi-transparent overlay
- Improved selection area visibility vs screen darkening

### Phase 3: Global Hotkey Integration
- Implemented Win32 API hotkey registration (Ctrl+Shift+-)
- Created background service architecture
- Added silent PowerShell process launching
- Fixed coordinate mapping for accurate capture across monitors

### Phase 4: System Integration & Polish
- **System Tray Service**: Persistent background service with context menu
- **Settings Dialog**: GUI configuration for screenshot folder and auto-start
- **Windows Integration**: Registry-based auto-start and Start Menu shortcuts
- **Configuration System**: JSON-based settings persistence
- **Error Handling**: Balloon tip notifications for hotkey conflicts
- **Process Architecture**: Clean separation of service and capture components
- **Multi-Monitor Fix**: Resolved primary-monitor-only limitation

## Final Implementation

The tool evolved from a basic screenshot script into a complete Windows service featuring:
- Global hotkey activation (Ctrl+Shift+-)  
- Multi-monitor screenshot capture across all displays
- System tray integration with settings
- Auto-start with Windows
- Configurable screenshot location
- Start Menu shortcut with taskbar pinning support

## Technical Achievements

- **Zero Dependencies**: Pure PowerShell + .NET Framework solution
- **Silent Operation**: No visible windows during normal use  
- **Robust Coordinate Handling**: Supports complex multi-monitor setups including negative coordinates
- **Memory Management**: Proper disposal of all Windows resources
- **Registry Integration**: Professional Windows service behavior
- **Configuration Management**: Persistent user preferences

This represents a complete, production-ready screenshot service built entirely in PowerShell.