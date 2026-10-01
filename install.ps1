#Requires -Version 7
# sakura terminal for Windows - installer
[CmdletBinding()]
param(
    [switch]$SkipStatusLine,   # leave Claude Code's status line alone
    [switch]$Yes               # don't ask before making changes
)
$ErrorActionPreference = 'Stop'

$src          = Join-Path $PSScriptRoot 'sakura'
$dest         = Join-Path $HOME '.sakura'
$fragmentDir  = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\Sakura'
$profilePath  = $PROFILE.CurrentUserCurrentHost
$claudeDir    = Join-Path $HOME '.claude'
$claudeConfig = Join-Path $claudeDir 'settings.json'
$markerStart  = '# >>> sakura >>>'
$markerEnd    = '# <<< sakura <<<'
$statusCmd    = 'pwsh -NoProfile -NoLogo -File "' + ((Join-Path $dest 'statusline.ps1') -replace '\\', '/') + '"'

$pink = "`e[38;2;236;135;168m"; $dim = "`e[38;2;156;122;142m"; $reset = "`e[0m"

Write-Host ""
Write-Host "  $pink* sakura terminal for Windows *$reset"
Write-Host ""
Write-Host "  This will:"
Write-Host "   1. copy the scripts to        $dim$dest$reset"
Write-Host "   2. add a Sakura profile + theme to Windows Terminal"
Write-Host "      $dim$fragmentDir$reset"
Write-Host "   3. add one line to your PowerShell profile"
Write-Host "      $dim$profilePath$reset"
if (-not $SkipStatusLine) {
    Write-Host "   4. set Claude Code's status line in $dim$claudeConfig$reset"
    Write-Host "      ${dim}(your current settings.json is backed up first)$reset"
}
Write-Host ""
if (-not $Yes) {
    if ((Read-Host "  Go ahead? (y/N)") -ne 'y') { Write-Host "  Nothing changed."; return }
}

# 1. scripts (never overwrites your config or todos)
New-Item -ItemType Directory -Force $dest | Out-Null
Copy-Item (Join-Path $src 'sakura.ps1'), (Join-Path $src 'statusline.ps1') $dest -Force
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
Copy-Item (Join-Path $PSScriptRoot 'terminal\sakura.json') $fragmentDir -Force
Write-Host "  $pink*$reset Windows Terminal profile added"

# 3. PowerShell profile
$block = @"
$markerStart
if (Test-Path "`$HOME\.sakura\sakura.ps1") { . "`$HOME\.sakura\sakura.ps1" }
$markerEnd
"@
if (-not (Test-Path $profilePath)) { New-Item -ItemType File -Force $profilePath | Out-Null }
$current = "$(Get-Content $profilePath -Raw)"
if ($current -notmatch [regex]::Escape($markerStart)) {
    Add-Content $profilePath "`n$block" -Encoding utf8
    Write-Host "  $pink*$reset profile updated"
} else {
    Write-Host "  $pink*$reset profile already set up"
}

# 4. Claude Code status line
if (-not $SkipStatusLine) {
    New-Item -ItemType Directory -Force $claudeDir | Out-Null
    $settings = [ordered]@{}
    if (Test-Path $claudeConfig) {
        Copy-Item $claudeConfig "$claudeConfig.sakura-backup" -Force
        $settings = Get-Content $claudeConfig -Raw | ConvertFrom-Json -AsHashtable
        if ($null -eq $settings) { $settings = [ordered]@{} }
        if ($settings.Contains('statusLine') -and "$($settings.statusLine.command)" -notmatch 'sakura') {
            $settings.statusLine | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $dest 'previous-statusline.json') -Encoding utf8
            Write-Host "  ${dim}(saved your old status line, uninstall puts it back)$reset"
        }
    }
    $settings['statusLine'] = [ordered]@{ type = 'command'; command = $statusCmd; padding = 0 }
    $settings | ConvertTo-Json -Depth 50 | Set-Content $claudeConfig -Encoding utf8
    Write-Host "  $pink*$reset Claude Code status line set"
}

Write-Host ""
Write-Host "  All done. Close Windows Terminal, reopen it, and pick the Sakura profile"
Write-Host "  from the dropdown next to the tabs. To make it your default:"
Write-Host "  ${dim}Settings > Startup > Default profile > Sakura$reset"
Write-Host ""
