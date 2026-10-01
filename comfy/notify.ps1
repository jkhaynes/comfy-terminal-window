# ✿ comfy notifier ✿
# Claude Code runs this when it finishes or needs you. It flashes the taskbar button of whatever
# window Claude is running in (Windows Terminal or VS Code) until you click back in.
# If that window is already in front, nothing happens.
$ErrorActionPreference = 'SilentlyContinue'
$null = [Console]::In.ReadToEnd()

# The hook runs a few processes below the terminal; walk up to the first one that owns a window
$p = Get-Process -Id $PID
while ($p -and $p.MainWindowHandle -eq 0) { $p = $p.Parent }
if (-not $p) { exit 0 }

Add-Type -Namespace Comfy -Name Flash -MemberDefinition @'
[StructLayout(LayoutKind.Sequential)]
public struct Info { public uint cbSize; public IntPtr hwnd; public uint dwFlags; public uint uCount; public uint dwTimeout; }
[DllImport("user32.dll")] public static extern bool FlashWindowEx(ref Info info);
'@
$info = [Comfy.Flash+Info]::new()
$info.cbSize = [Runtime.InteropServices.Marshal]::SizeOf($info)
$info.hwnd = $p.MainWindowHandle
$info.dwFlags = 3 -bor 12   # FLASHW_ALL, until the window comes to the front (FLASHW_TIMERNOFG)
[void][Comfy.Flash]::FlashWindowEx([ref]$info)
