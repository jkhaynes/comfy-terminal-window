#Requires -Version 7
# comfy terminal for Windows - installer
[CmdletBinding()]
param(
    [switch]$SkipStatusLine,   # leave Claude Code's status line alone
    [switch]$Yes               # don't ask before making changes
)
$ErrorActionPreference = 'Stop'

$src          = Join-Path $PSScriptRoot 'comfy'
$dest         = Join-Path $HOME '.comfy'
$fragmentDir  = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\Comfy'
$profilePath  = $PROFILE.CurrentUserAllHosts   # all hosts, so VS Code's PowerShell extension loads it too
$claudeDir    = Join-Path $HOME '.claude'
$claudeConfig = Join-Path $claudeDir 'settings.json'
$markerStart  = '# >>> comfy >>>'
$markerEnd    = '# <<< comfy <<<'
$notifyCmd    = 'pwsh -NoProfile -NoLogo -File "' + ((Join-Path $dest 'notify.ps1') -replace '\\', '/') + '"'
$statusCmd    = 'pwsh -NoProfile -NoLogo -File "' + ((Join-Path $dest 'statusline.ps1') -replace '\\', '/') + '"'

$pink = "`e[38;2;244;166;192m"; $dim = "`e[38;2;156;122;142m"; $reset = "`e[0m"

Write-Host ""
Write-Host "  $pink* comfy terminal for Windows *$reset"
Write-Host ""
Write-Host "  This will:"
Write-Host "   1. copy the scripts to        $dim$dest$reset"
Write-Host "   2. add a Comfy profile + theme to Windows Terminal"
Write-Host "      $dim$fragmentDir$reset"
Write-Host "   3. add one line to your PowerShell profile"
Write-Host "      $dim$profilePath$reset"
$what = if ($SkipStatusLine) { 'theme' } else { 'theme and status line' }
Write-Host "   4. set Claude Code's pink $what in $dim$claudeConfig$reset"
Write-Host "      and flash the taskbar when Claude finishes or needs you"
Write-Host "      ${dim}(your current settings.json is backed up first)$reset"
Write-Host ""
if (-not $Yes) {
    if ((Read-Host "  Go ahead? (y/N)") -ne 'y') { Write-Host "  Nothing changed."; return }
}

# 0. this project used to be called sakura; carry an old install over
$oldDest = Join-Path $HOME '.sakura'
if ((Test-Path $oldDest) -and -not (Test-Path $dest)) {
    Move-Item $oldDest $dest
    Remove-Item (Join-Path $dest 'sakura.ps1') -ErrorAction SilentlyContinue
    Write-Host "  $pink*$reset moved your settings from $oldDest"
}
Remove-Item (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\Sakura') -Recurse -Force -ErrorAction SilentlyContinue
foreach ($p in $PROFILE.CurrentUserAllHosts, $PROFILE.CurrentUserCurrentHost) {
    if (-not (Test-Path $p)) { continue }
    $text = "$(Get-Content $p -Raw)"
    $clean = $text -replace '(?s)\r?\n?# >>> sakura >>>.*?# <<< sakura <<<\r?\n?', ''
    if ($clean -ne $text) { Set-Content $p $clean -NoNewline -Encoding utf8 }
}

# 1. scripts (never overwrites your config)
New-Item -ItemType Directory -Force $dest | Out-Null
Copy-Item (Join-Path $src 'comfy.ps1'), (Join-Path $src 'statusline.ps1'), (Join-Path $src 'notify.ps1') $dest -Force
if ($IsWindows) { Get-ChildItem $dest -Filter *.ps1 | Unblock-File }
$configPath = Join-Path $dest 'config.json'
if (-not (Test-Path $configPath)) {
    $name = Read-Host "  What should the greeting call you? (enter for $env:USERNAME)"
    if (-not $name) { $name = $env:USERNAME }
    [ordered]@{ Name = $name; Greeting = $true; Prompt = $true; Model = 'haiku' } |
        ConvertTo-Json | Set-Content $configPath -Encoding utf8
}
Write-Host "  $pink*$reset scripts copied"

# 2. Windows Terminal fragment
New-Item -ItemType Directory -Force $fragmentDir | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'terminal\comfy.json') $fragmentDir -Force
Write-Host "  $pink*$reset Windows Terminal profile added"

# 3. PowerShell profile
$block = @"
$markerStart
if (Test-Path "`$HOME\.comfy\comfy.ps1") { . "`$HOME\.comfy\comfy.ps1" }
$markerEnd
"@
# older installs used the console-only profile; move the line so it doesn't load twice
$oldProfile = $PROFILE.CurrentUserCurrentHost
if (Test-Path $oldProfile) {
    $text = "$(Get-Content $oldProfile -Raw)"
    $clean = $text -replace '(?s)\r?\n?# >>> comfy >>>.*?# <<< comfy <<<\r?\n?', ''
    if ($clean -ne $text) { Set-Content $oldProfile $clean -NoNewline -Encoding utf8 }
}
if (-not (Test-Path $profilePath)) { New-Item -ItemType File -Force $profilePath | Out-Null }
$current = "$(Get-Content $profilePath -Raw)"
if ($current -notmatch [regex]::Escape($markerStart)) {
    Add-Content $profilePath "`n$block" -Encoding utf8
    Write-Host "  $pink*$reset profile updated"
} else {
    Write-Host "  $pink*$reset profile already set up"
}

# 4. Claude Code pink theme + status line
New-Item -ItemType Directory -Force (Join-Path $claudeDir 'themes') | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'claude\comfy.json') (Join-Path $claudeDir 'themes') -Force
$settings = [ordered]@{}
if (Test-Path $claudeConfig) {
    Copy-Item $claudeConfig "$claudeConfig.comfy-backup" -Force
    $settings = Get-Content $claudeConfig -Raw | ConvertFrom-Json -AsHashtable
    if ($null -eq $settings) { $settings = [ordered]@{} }
}
if ($settings.Contains('theme') -and $settings.theme -ne 'custom:comfy') {
    Set-Content (Join-Path $dest 'previous-theme.txt') $settings.theme -Encoding utf8
}
$settings['theme'] = 'custom:comfy'
Write-Host "  $pink*$reset Claude Code pink theme set"
if (-not $SkipStatusLine) {
    if ($settings.Contains('statusLine') -and "$($settings.statusLine.command)" -notmatch 'comfy') {
        $settings.statusLine | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $dest 'previous-statusline.json') -Encoding utf8
        Write-Host "  ${dim}(saved your old status line, uninstall puts it back)$reset"
    }
    $settings['statusLine'] = [ordered]@{ type = 'command'; command = $statusCmd; padding = 0 }
    Write-Host "  $pink*$reset Claude Code status line set"
}
if (-not $settings.Contains('hooks')) { $settings['hooks'] = [ordered]@{} }
foreach ($event in 'Stop', 'Notification') {
    # drop an older comfy entry first so reinstalling doesn't add it twice
    $groups = @($settings.hooks[$event] | Where-Object { $_ -and "$($_.hooks.command)" -notmatch 'comfy[\\/]notify' })
    $settings.hooks[$event] = $groups + @([ordered]@{ hooks = @([ordered]@{ type = 'command'; command = $notifyCmd }) })
}
Write-Host "  $pink*$reset taskbar flash set"
$settings | ConvertTo-Json -Depth 50 | Set-Content $claudeConfig -Encoding utf8

Write-Host ""
Write-Host "  All done. Close Windows Terminal, reopen it, and pick the Comfy profile"
Write-Host "  from the dropdown next to the tabs. To make it your default:"
Write-Host "  ${dim}Settings > Startup > Default profile > Comfy$reset"
Write-Host ""
