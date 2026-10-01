#Requires -Version 7
# comfy terminal for Windows - puts everything back
$ErrorActionPreference = 'Stop'

$dest         = Join-Path $HOME '.comfy'
$fragmentDir  = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\Comfy'
$claudeConfig = Join-Path $HOME '.claude\settings.json'

# PowerShell profile
foreach ($profilePath in $PROFILE.CurrentUserAllHosts, $PROFILE.CurrentUserCurrentHost) {
    if (-not (Test-Path $profilePath)) { continue }
    $text = "$(Get-Content $profilePath -Raw)"
    $clean = $text -replace '(?s)\r?\n?# >>> comfy >>>.*?# <<< comfy <<<\r?\n?', ''
    if ($clean -ne $text) { Set-Content $profilePath $clean -NoNewline -Encoding utf8; Write-Host "  * removed from your profile" }
}

# Windows Terminal
if (Test-Path $fragmentDir) { Remove-Item $fragmentDir -Recurse -Force; Write-Host "  * removed the Windows Terminal profile" }

# Claude Code status line
if (Test-Path $claudeConfig) {
    $settings = Get-Content $claudeConfig -Raw | ConvertFrom-Json -AsHashtable
    if ($settings -and $settings.Contains('statusLine') -and "$($settings.statusLine.command)" -match 'comfy') {
        $prev = Join-Path $dest 'previous-statusline.json'
        if (Test-Path $prev) { $settings['statusLine'] = Get-Content $prev -Raw | ConvertFrom-Json -AsHashtable; Write-Host "  * restored your old status line" }
        else { $settings.Remove('statusLine'); Write-Host "  * removed the status line" }
    }
    if ($settings -and $settings['theme'] -eq 'custom:comfy') {
        $prev = Join-Path $dest 'previous-theme.txt'
        $settings['theme'] = if (Test-Path $prev) { (Get-Content $prev -Raw).Trim() } else { 'dark' }
        Write-Host "  * restored your Claude Code theme"
    }
    if ($settings -and $settings.hooks) {
        foreach ($event in 'Stop', 'Notification') {
            if (-not $settings.hooks.Contains($event)) { continue }
            $groups = @($settings.hooks[$event] | Where-Object { "$($_.hooks.command)" -notmatch 'comfy[\\/]notify' })
            if ($groups.Count) { $settings.hooks[$event] = $groups } else { $settings.hooks.Remove($event) }
        }
        Write-Host "  * removed the taskbar flash"
    }
    if ($settings) { $settings | ConvertTo-Json -Depth 50 | Set-Content $claudeConfig -Encoding utf8 }
}
Remove-Item (Join-Path $HOME '.claude\themes\comfy.json') -ErrorAction SilentlyContinue

# scripts and your settings
if (Test-Path $dest) {
    if ((Read-Host "  Also delete $dest (your settings)? (y/N)") -eq 'y') {
        Remove-Item $dest -Recurse -Force; Write-Host "  * deleted $dest"
    } else {
        Remove-Item (Join-Path $dest '*.ps1') -Force -ErrorAction SilentlyContinue
        Write-Host "  * kept your settings in $dest"
    }
}
Write-Host "`n  All back to normal. Reopen Windows Terminal to finish."
