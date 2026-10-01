#Requires -Version 7
# sakura terminal for Windows - puts everything back
$ErrorActionPreference = 'Stop'

$dest         = Join-Path $HOME '.sakura'
$fragmentDir  = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\Sakura'
$profilePath  = $PROFILE.CurrentUserCurrentHost
$claudeConfig = Join-Path $HOME '.claude\settings.json'

# PowerShell profile
if (Test-Path $profilePath) {
    $text = "$(Get-Content $profilePath -Raw)"
    $clean = $text -replace '(?s)\r?\n?# >>> sakura >>>.*?# <<< sakura <<<\r?\n?', ''
    if ($clean -ne $text) { Set-Content $profilePath $clean -NoNewline -Encoding utf8; Write-Host "  * removed from your profile" }
}

# Windows Terminal
if (Test-Path $fragmentDir) { Remove-Item $fragmentDir -Recurse -Force; Write-Host "  * removed the Windows Terminal profile" }

# Claude Code status line
if (Test-Path $claudeConfig) {
    $settings = Get-Content $claudeConfig -Raw | ConvertFrom-Json -AsHashtable
    if ($settings -and $settings.Contains('statusLine') -and "$($settings.statusLine.command)" -match 'sakura') {
        $prev = Join-Path $dest 'previous-statusline.json'
        if (Test-Path $prev) { $settings['statusLine'] = Get-Content $prev -Raw | ConvertFrom-Json -AsHashtable; Write-Host "  * restored your old status line" }
        else { $settings.Remove('statusLine'); Write-Host "  * removed the status line" }
        $settings | ConvertTo-Json -Depth 50 | Set-Content $claudeConfig -Encoding utf8
    }
}

# scripts and your todo list
if (Test-Path $dest) {
    if ((Read-Host "  Also delete $dest (your todo list and settings)? (y/N)") -eq 'y') {
        Remove-Item $dest -Recurse -Force; Write-Host "  * deleted $dest"
    } else {
        Remove-Item (Join-Path $dest '*.ps1') -Force -ErrorAction SilentlyContinue
        Write-Host "  * kept your todo list and settings in $dest"
    }
}
Write-Host "`n  All back to normal. Reopen Windows Terminal to finish."
