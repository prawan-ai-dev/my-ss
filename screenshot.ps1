Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Configuration - can be overridden by calling script
if (-not $screenshotFolder) { $screenshotFolder = "C:\Screenshots" }
if (-not $filePrefix) { $filePrefix = "screenshot_" }

# Create folder if it doesn't exist
if (-not (Test-Path $screenshotFolder)) {
    New-Item -ItemType Directory -Path $screenshotFolder -Force
}

# Minimize the PowerShell window and add DPI awareness
Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    public class Win32 {
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        [DllImport("user32.dll")]
        public static extern bool GetCursorPos(out POINT lpPoint);
        [DllImport("user32.dll")]
        public static extern bool SetProcessDPIAware();
        public const int SW_MINIMIZE = 6;
        public const int SW_RESTORE = 9;
    }
    
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT {
        public int X;
        public int Y;
    }
"@

# Set DPI awareness to ensure consistent coordinate systems
[Win32]::SetProcessDPIAware()

$consolePtr = [Win32]::GetConsoleWindow()
# Only minimize if console is visible (not when launched via hotkey)
if ([Win32]::GetConsoleWindow() -ne [IntPtr]::Zero) {
    try {
        [Win32]::ShowWindow($consolePtr, [Win32]::SW_MINIMIZE)
    } catch {
        # Ignore if console manipulation fails
    }
}

Write-Host "Screenshot Tool Started"
Write-Host "Instructions:"
Write-Host "1. Press and drag to select area"
Write-Host "2. Release mouse to capture"
Write-Host "3. Press ESC to cancel"
Write-Host ""

# Get the bounds of all monitors combined
$allScreensBounds = [System.Windows.Forms.SystemInformation]::VirtualScreen

# Create form for screen capture that spans all monitors
$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::Black
$form.Opacity = 0.3  # Semi-transparent so you can see through
$form.Cursor = [System.Windows.Forms.Cursors]::Cross
$form.ShowInTaskbar = $false

# Set the form to cover ALL monitors (not just primary) - this is key for multi-monitor support
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
$form.Location = New-Object System.Drawing.Point($allScreensBounds.X, $allScreensBounds.Y)
$form.Size = New-Object System.Drawing.Size($allScreensBounds.Width, $allScreensBounds.Height)
$form.WindowState = [System.Windows.Forms.FormWindowState]::Normal  # Don't use Maximized

Write-Host "Multi-monitor setup detected:"
Write-Host "  Virtual Screen: $($allScreensBounds.Width)x$($allScreensBounds.Height) at ($($allScreensBounds.X),$($allScreensBounds.Y))"
foreach ($screen in [System.Windows.Forms.Screen]::AllScreens) {
    $bounds = $screen.Bounds
    $isPrimary = if ($screen.Primary) { " (Primary)" } else { "" }
    Write-Host "  Monitor: $($bounds.Width)x$($bounds.Height) at ($($bounds.X),$($bounds.Y))$isPrimary"
}
Write-Host "  Form will cover: $($form.Location.X),$($form.Location.Y) to $($form.Location.X + $form.Size.Width),$($form.Location.Y + $form.Size.Height)"

# Selection variables
$startPoint = New-Object System.Drawing.Point
$endPoint = New-Object System.Drawing.Point
$isSelecting = $false

# Mouse down event
$form.Add_MouseDown({
    # Use DPI-aware cursor position
    $cursorPos = New-Object POINT
    [Win32]::GetCursorPos([ref]$cursorPos)
    $script:startPoint = New-Object System.Drawing.Point($cursorPos.X, $cursorPos.Y)
    $script:endPoint = $script:startPoint
    $script:isSelecting = $true
    $form.Invalidate()
})

# Mouse move event
$form.Add_MouseMove({
    if ($script:isSelecting) {
        # Use DPI-aware cursor position
        $cursorPos = New-Object POINT
        [Win32]::GetCursorPos([ref]$cursorPos)
        $script:endPoint = New-Object System.Drawing.Point($cursorPos.X, $cursorPos.Y)
        $form.Invalidate()
    }
})

# Paint event - draw selection rectangle
$form.Add_Paint({
    if ($script:isSelecting) {
        # Convert screen coordinates to form coordinates for drawing
        $startFormPoint = $form.PointToClient($script:startPoint)
        $endFormPoint = $form.PointToClient($script:endPoint)
        
        $selectionRect = New-Object System.Drawing.Rectangle
        $selectionRect.X = [Math]::Min($startFormPoint.X, $endFormPoint.X)
        $selectionRect.Y = [Math]::Min($startFormPoint.Y, $endFormPoint.Y)
        $selectionRect.Width = [Math]::Abs($endFormPoint.X - $startFormPoint.X)
        $selectionRect.Height = [Math]::Abs($endFormPoint.Y - $startFormPoint.Y)
        
        if ($selectionRect.Width -gt 0 -and $selectionRect.Height -gt 0) {
            # Draw red border around selection
            $redPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 3)
            $_.Graphics.DrawRectangle($redPen, $selectionRect)
            $redPen.Dispose()
            
            # Draw white inner border for better visibility
            if ($selectionRect.Width -gt 6 -and $selectionRect.Height -gt 6) {
                $whitePen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 1)
                $innerRect = New-Object System.Drawing.Rectangle(($selectionRect.X + 2), ($selectionRect.Y + 2), ($selectionRect.Width - 4), ($selectionRect.Height - 4))
                $_.Graphics.DrawRectangle($whitePen, $innerRect)
                $whitePen.Dispose()
            }
        }
    }
})

# Mouse up event - capture screenshot
$form.Add_MouseUp({
    # Use DPI-aware cursor position
    $cursorPos = New-Object POINT
    [Win32]::GetCursorPos([ref]$cursorPos)
    $script:endPoint = New-Object System.Drawing.Point($cursorPos.X, $cursorPos.Y)
    
    if ($script:isSelecting) {
        $script:isSelecting = $false
        $form.Hide()
        
        # Calculate capture rectangle using screen coordinates (already correct now)
        $rect = New-Object System.Drawing.Rectangle
        $rect.X = [Math]::Min($script:startPoint.X, $script:endPoint.X)
        $rect.Y = [Math]::Min($script:startPoint.Y, $script:endPoint.Y)
        $rect.Width = [Math]::Abs($script:endPoint.X - $script:startPoint.X)
        $rect.Height = [Math]::Abs($script:endPoint.Y - $script:startPoint.Y)
        
        if ($rect.Width -gt 0 -and $rect.Height -gt 0) {
            # Capture screenshot from the actual screen coordinates
            $bitmap = New-Object System.Drawing.Bitmap($rect.Width, $rect.Height)
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            $graphics.CopyFromScreen($rect.Location, [System.Drawing.Point]::Empty, $rect.Size)
            
            # Generate filename with timestamp
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $filename = "$filePrefix$timestamp.png"
            $fullPath = Join-Path $screenshotFolder $filename
            
            # Save image
            $bitmap.Save($fullPath, [System.Drawing.Imaging.ImageFormat]::Png)
            
            # Copy full path to clipboard
            Set-Clipboard -Value $fullPath
            
            # Cleanup
            $graphics.Dispose()
            $bitmap.Dispose()
            
            Write-Host "Screenshot saved: $fullPath"
            Write-Host "Path copied to clipboard!"
            Write-Host "Captured area: $($rect.Width)x$($rect.Height) at ($($rect.X),$($rect.Y))"
            
            # Only restore console if it was minimized initially
            try {
                [Win32]::ShowWindow($consolePtr, [Win32]::SW_RESTORE)
            } catch {
                # Ignore if console manipulation fails (when launched via hotkey)
            }
        }
        
        $form.Close()
    }
})

# Key press event - ESC to cancel
$form.Add_KeyDown({
    if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
        $form.Close()
        try {
            [Win32]::ShowWindow($consolePtr, [Win32]::SW_RESTORE)
        } catch {
            # Ignore if console manipulation fails (when launched via hotkey)
        }
    }
})

# Show form and start capture
$form.Add_Shown({ $form.Activate() })
$form.ShowDialog()

Write-Host "Screenshot tool closed."