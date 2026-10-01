# ✿ sakura terminal for Windows ✿
# Loaded from your PowerShell profile. Settings live in ~/.sakura/config.json

$SakuraHome       = Join-Path $HOME '.sakura'
$SakuraConfigPath = Join-Path $SakuraHome 'config.json'
$SakuraTodoPath   = Join-Path $SakuraHome 'todo.txt'
$SakuraScratch    = Join-Path $SakuraHome 'scratch'   # where `what` and `ask` run Claude, so they don't clutter your chat history

# ---------- settings ----------

function Get-SakuraConfig {
    $cfg = @{ Name = $env:USERNAME; Greeting = $true; Prompt = $true; Model = 'haiku' }
    if (Test-Path $SakuraConfigPath) {
        try {
            $user = Get-Content $SakuraConfigPath -Raw | ConvertFrom-Json -AsHashtable
            foreach ($k in $user.Keys) { $cfg[$k] = $user[$k] }
        } catch { Write-Warning "sakura: couldn't read config.json ($_)" }
    }
    $cfg
}
$Sakura = Get-SakuraConfig

# ---------- colors ----------

function ConvertTo-SakuraRgb([string]$hex) {
    $h = $hex.TrimStart('#')
    '{0};{1};{2}' -f [Convert]::ToInt32($h.Substring(0, 2), 16), [Convert]::ToInt32($h.Substring(2, 2), 16), [Convert]::ToInt32($h.Substring(4, 2), 16)
}
function Get-SakuraFg([string]$hex) { "`e[38;2;$(ConvertTo-SakuraRgb $hex)m" }

$SkReset = "`e[0m"; $SkBold = "`e[1m"
$SkPink  = Get-SakuraFg '#F7B6CC'
$SkRose  = Get-SakuraFg '#EC87A8'
$SkDim   = Get-SakuraFg '#9C7A8E'
$SkText  = Get-SakuraFg '#F4DDE6'
$SkMint  = Get-SakuraFg '#A8D8B9'
$SkGold  = Get-SakuraFg '#F6D38B'
$SkRed   = Get-SakuraFg '#F2798F'

$SakuraPixel = @{
    W = ConvertTo-SakuraRgb '#FDE4EC'; L = ConvertTo-SakuraRgb '#F7B6CC'; P = ConvertTo-SakuraRgb '#EC87A8'
    D = ConvertTo-SakuraRgb '#C94F7C'; O = ConvertTo-SakuraRgb '#8F2D5A'; Y = ConvertTo-SakuraRgb '#F6D365'
    C = ConvertTo-SakuraRgb '#E0567F'
}

# ---------- small helpers ----------

function Format-SakuraShort([string]$s, [int]$n) {
    if ($s.Length -gt $n) { $s.Substring(0, $n - 1) + '…' } else { $s }
}
function Format-SakuraAgo([datetime]$t) {
    $d = (Get-Date) - $t
    if ($d.TotalMinutes -lt 1) { 'just now' }
    elseif ($d.TotalHours -lt 1) { '{0}m ago' -f [math]::Floor($d.TotalMinutes) }
    elseif ($d.TotalDays -lt 1) { '{0}h ago' -f [math]::Floor($d.TotalHours) }
    else { '{0}d ago' -f [math]::Floor($d.TotalDays) }
}
function Format-SakuraPath([string]$p) {
    if ($p.StartsWith($HOME, [StringComparison]::OrdinalIgnoreCase)) { '~' + $p.Substring($HOME.Length) } else { $p }
}
function Get-SakuraBranch([string]$dir = $PWD.Path) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { return $null }
    $b = git -C $dir branch --show-current 2>$null
    if ($LASTEXITCODE -eq 0 -and $b) { $b } else { $null }
}
function Test-SakuraInteractive {
    if ($Host.Name -ne 'ConsoleHost') { return $false }
    $argv = [Environment]::GetCommandLineArgs()
    -not ($argv | Where-Object { $_ -match '^-(c|command|f|file|noninteractive|encodedcommand|e|ec)$' })
}

# ---------- the blossom ----------

$SakuraBlossom = @(
    '........OO..OO........'
    '........OWOOWO........'
    '.......OWWWWWWO.......'
    '.......OWWWWWWO.......'
    '.......OLLLLLLO.......'
    '.OOOOOOOLLLLLLOOOOOOO.'
    '.OWWWLO.OPPPPO.OLWWWO.'
    '..OWLLLO.OPPO.OLLLWO..'
    '..OWLLLPOOYDOOPLLLWO..'
    'OOWWLLPPPDCCDPPPLLWWOO'
    'OWWWLLPPYCCCYDPPLLWWWO'
    '.OWWLOOODCCCCDOOOLWWO.'
    '..OOO..OPDYCYPO..OOO..'
    '....OOOPPPDDPPPOOO....'
    '...OLLLLPPOOPPLLLLO...'
    '...OWLLLLPOOPLLLLWO...'
    '...OWWLLLLOOLLLLWWO...'
    '...OWWWLLLOOLLLWWWO...'
    '...OOOWWWWOOWWWWOOO...'
    '......OWWO..OWWO......'
    '......OOO....OOO......'
)

# Two pixels per character cell (upper/lower half blocks), so the pixels come out square.
function Get-SakuraBlossomLines {
    $w = ($SakuraBlossom | Measure-Object -Property Length -Maximum).Maximum
    $rows = @($SakuraBlossom | ForEach-Object { $_.PadRight($w, '.') })
    if ($rows.Count % 2) { $rows += ('.' * $w) }
    for ($y = 0; $y -lt $rows.Count; $y += 2) {
        $sb = [Text.StringBuilder]::new()
        for ($x = 0; $x -lt $w; $x++) {
            $t = $SakuraPixel["$($rows[$y][$x])"]; $b = $SakuraPixel["$($rows[$y + 1][$x])"]
            if (-not $t -and -not $b) { [void]$sb.Append(' ') }
            elseif ($t -and -not $b)  { [void]$sb.Append("`e[38;2;${t}m▀`e[0m") }
            elseif (-not $t -and $b)  { [void]$sb.Append("`e[38;2;${b}m▄`e[0m") }
            else                      { [void]$sb.Append("`e[38;2;${t};48;2;${b}m▀`e[0m") }
        }
        $sb.ToString()
    }
}

function Get-SakuraMoon {
    $synodic = 29.530588853
    $knownNew = [datetime]::new(2000, 1, 6, 18, 14, 0, [DateTimeKind]::Utc)
    $age = ((((Get-Date).ToUniversalTime() - $knownNew).TotalDays % $synodic) + $synodic) % $synodic
    $i = [int]([math]::Floor(($age / $synodic) * 8 + 0.5)) % 8
    $names = 'new moon', 'waxing crescent', 'first quarter', 'waxing gibbous', 'full moon', 'waning gibbous', 'last quarter', 'waning crescent'
    $icons = '🌑', '🌒', '🌓', '🌔', '🌕', '🌖', '🌗', '🌘'
    "$($icons[$i]) $($names[$i])"
}

# Most recent Claude Code chat, from the local chat logs (reads files only, no tokens).
function Get-SakuraLastChat {
    $projects = Join-Path $HOME '.claude/projects'
    if (-not (Test-Path $projects)) { return $null }
    $file = Get-ChildItem $projects -Directory -ErrorAction SilentlyContinue |
        Where-Object Name -notmatch 'sakura-scratch' |
        Get-ChildItem -Filter *.jsonl -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $file) { return $null }

    $cwd = $null; $summary = $null
    foreach ($line in (Get-Content $file.FullName -TotalCount 5 -ErrorAction SilentlyContinue)) {
        if ($line -match '"type"\s*:\s*"summary"' -and $line -match '"summary"\s*:\s*"((?:[^"\\]|\\.)*)"') { $summary = $Matches[1] }
    }
    foreach ($line in (Get-Content $file.FullName -Tail 40 -ErrorAction SilentlyContinue)) {
        if ($line -match '"cwd"\s*:\s*"((?:[^"\\]|\\.)*)"') { $cwd = $Matches[1] -replace '\\\\', '\' }
    }
    $project = if ($cwd) { Split-Path $cwd -Leaf } else { $file.Directory.Name }
    [pscustomobject]@{ Project = $project; Summary = $summary; When = $file.LastWriteTime }
}

function bloom {
    $now = Get-Date
    $inv = [Globalization.CultureInfo]::InvariantCulture
    $part = if ($now.Hour -lt 5) { 'night' } elseif ($now.Hour -lt 12) { 'morning' } elseif ($now.Hour -lt 17) { 'afternoon' } else { 'evening' }
    $row = { param($label, $value) "$SkGold{0,-8}$SkReset$SkText{1}$SkReset" -f $label, $value }

    $todos = Get-SakuraTodos
    $todoText = if ($todos.Count) { "$($todos.Count) left $SkDim·$SkText next: $(Format-SakuraShort $todos[0] 38)" } else { 'all clear ✿' }

    $branch = Get-SakuraBranch
    $here = Format-SakuraShort (Format-SakuraPath $PWD.Path) 40
    if ($branch) { $here += "  $SkDim($branch)" }

    $chat = Get-SakuraLastChat
    $chatText = if ($chat) {
        $what = if ($chat.Summary) { "$($chat.Project): $($chat.Summary)" } else { $chat.Project }
        "$(Format-SakuraShort $what 40) $SkDim· $(Format-SakuraAgo $chat.When)"
    } else { 'no chats yet' }

    $info = @(
        "$SkBold${SkRose}good $part, $($Sakura.Name) $SkPink♡$SkReset"
        "$SkDim$($now.ToString('dddd, MMMM d', $inv).ToLower()) · $($now.ToString('h:mm tt', $inv).ToLower())$SkReset"
        "$SkRose$('─' * 34)$SkReset"
        (& $row 'todo' $todoText)
        (& $row 'here' $here)
        (& $row 'claude' $chatText)
        (& $row 'moon' (Get-SakuraMoon))
    )

    $art = @(Get-SakuraBlossomLines)
    $offset = [math]::Max(0, [math]::Floor(($art.Count - $info.Count) / 2))
    Write-Host ''
    for ($i = 0; $i -lt $art.Count; $i++) {
        $j = $i - $offset
        $right = if ($j -ge 0 -and $j -lt $info.Count) { $info[$j] } else { '' }
        Write-Host "  $($art[$i])    $right"
    }
    Write-Host ''
    Write-Host "  $SkRose✿$SkDim todo   $SkRose✿$SkDim what   $SkRose✿$SkDim ask   $SkRose✿$SkDim cl   $SkRose✿$SkDim alt+w explains your command   $SkRose✿$SkDim ctrl+/ menu$SkReset"
    Write-Host ''
}

# ---------- todo ----------

function Get-SakuraTodos {
    if (Test-Path $SakuraTodoPath) { @(Get-Content $SakuraTodoPath | Where-Object { $_.Trim() }) } else { @() }
}
function Save-SakuraTodos([string[]]$items) {
    New-Item -ItemType Directory -Force $SakuraHome | Out-Null
    [IO.File]::WriteAllLines($SakuraTodoPath, [string[]]@($items))
}

function todo {
    $all = @($args | ForEach-Object { "$_" })
    $items = [Collections.Generic.List[string]]::new([string[]]@(Get-SakuraTodos))
    $sub = if ($all.Count) { $all[0] } else { '' }
    $rest = if ($all.Count -gt 1) { $all[1..($all.Count - 1)] -join ' ' } else { '' }

    switch ($sub) {
        '' {
            if (-not $items.Count) { Write-Host "  $SkPink✿$SkReset nothing to do. add one with ${SkRose}todo add$SkReset"; return }
            Write-Host ''
            for ($i = 0; $i -lt $items.Count; $i++) { Write-Host ("  $SkRose{0,2}$SkReset  $SkText{1}$SkReset" -f ($i + 1), $items[$i]) }
            Write-Host "`n  $SkDim todo add <thing>  ·  todo done <number>  ·  todo edit$SkReset`n"
            return
        }
        { $_ -in 'add', 'a' } {
            if (-not $rest) { $rest = Read-Host '  new todo' }
            if (-not $rest) { return }
            $items.Add($rest); Save-SakuraTodos $items
            Write-Host "  $SkPink✿$SkReset added $SkDim· $($items.Count) left$SkReset"
            return
        }
        { $_ -in 'done', 'd', 'x' } {
            if (-not $rest) { todo; $rest = Read-Host '  which number is done' }
            $n = 0
            if (-not [int]::TryParse($rest, [ref]$n) -or $n -lt 1 -or $n -gt $items.Count) { Write-Host "  ${SkRed}no todo number $rest$SkReset"; return }
            $gone = $items[$n - 1]; $items.RemoveAt($n - 1); Save-SakuraTodos $items
            Write-Host "  $SkMint✓$SkReset $SkDim$gone$SkReset  $SkPink·$SkReset $($items.Count) left"
            return
        }
        'edit' { if (-not (Test-Path $SakuraTodoPath)) { Save-SakuraTodos @() }; Invoke-Item $SakuraTodoPath; return }
        'clear' {
            if ((Read-Host "  clear all $($items.Count) todos? (y/N)") -eq 'y') { Save-SakuraTodos @(); Write-Host "  $SkPink✿$SkReset cleared" }
            return
        }
        default {
            # `todo buy milk` works as a shortcut for `todo add buy milk`
            $items.Add(($all -join ' ')); Save-SakuraTodos $items
            Write-Host "  $SkPink✿$SkReset added $SkDim· $($items.Count) left$SkReset"
        }
    }
}

# ---------- Claude helpers ----------

function Invoke-SakuraClaude([string]$prompt) {
    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        Write-Host "  ${SkRed}claude isn't on your PATH, so this needs Claude Code installed.$SkReset"
        return $null
    }
    New-Item -ItemType Directory -Force $SakuraScratch | Out-Null
    $prevOut = $OutputEncoding; $prevCon = [Console]::OutputEncoding
    $OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
    Write-Host -NoNewline "  $SkDim✿ thinking…$SkReset"
    Push-Location $SakuraScratch
    try { $out = $prompt | claude -p --model $Sakura.Model 2>$null }
    finally {
        Pop-Location
        $OutputEncoding = $prevOut; [Console]::OutputEncoding = $prevCon
        Write-Host -NoNewline "`r`e[2K"
    }
    (($out | ForEach-Object { "$_" }) -join "`n").Trim()
}

$SakuraRiskyPatterns = @(
    @{ P = '(?i)(iwr|irm|curl|wget|Invoke-WebRequest|Invoke-RestMethod)\b[^|]*\|\s*(iex|Invoke-Expression|sh|bash|pwsh|powershell)\b'; Why = 'downloads a script and runs it immediately' }
    @{ P = '(?i)\b(iex|Invoke-Expression)\b'; Why = 'runs text as code' }
    @{ P = '(?i)\b(rm|ri|Remove-Item|del|erase|rd|rmdir)\b.*(\s-r\w*|\s-Recurse|\s/s)\b'; Why = 'deletes folders and everything in them' }
    @{ P = '(?i)\bformat(-volume)?\b\s+[a-z]:|\bdiskpart\b|\bbcdedit\b|\bcipher\s+/w'; Why = 'low-level disk or boot changes' }
    @{ P = '(?i)\breg(\.exe)?\s+delete\b|\bRemove-ItemProperty\b'; Why = 'deletes registry settings' }
    @{ P = '(?i)\bSet-ExecutionPolicy\s+(Unrestricted|Bypass)'; Why = 'turns off script safety checks' }
    @{ P = '(?i)\bgit\s+(push\b.*(\s--force\b|\s-f\b)|reset\s+--hard|clean\s+-\w*f)'; Why = 'can throw away git work for good' }
    @{ P = '(?i)\bStop-Process\b.*-Force|\btaskkill\b.*\s/f\b'; Why = 'force-closes programs without saving' }
)

function Show-SakuraWhat([string]$cmd) {
    Write-Host ''
    Write-Host "  $SkRose✿$SkReset $SkText$cmd$SkReset"
    foreach ($r in $SakuraRiskyPatterns) {
        if ($cmd -match $r.P) { Write-Host "  ${SkGold}heads up:$SkReset $($r.Why)" }
    }
    $prompt = @"
You are a careful Windows and PowerShell 7 expert. The user is about to run the command below in PowerShell on Windows. Do not run it.
Explain in 2 to 4 short plain-English sentences what it does and anything it changes or deletes. No markdown, no code blocks.
On the final line write exactly one of: VERDICT: SAFE, VERDICT: CAREFUL, VERDICT: RISKY
SAFE = only reads or shows things. CAREFUL = changes files or settings in a recoverable way. RISKY = deletes data, changes the system, or runs code from the internet.

Command:
$cmd
"@
    $answer = Invoke-SakuraClaude $prompt
    if (-not $answer) { Write-Host ''; return }
    $verdict = if ($answer -match 'VERDICT:\s*(SAFE|CAREFUL|RISKY)') { $Matches[1] } else { $null }
    $body = ($answer -split "`n" | Where-Object { $_ -notmatch 'VERDICT:' }) -join "`n"
    foreach ($l in ($body.Trim() -split "`n")) { Write-Host "  $SkText$l$SkReset" }
    switch ($verdict) {
        'SAFE'    { Write-Host "`n  $SkBold${SkMint}SAFE$SkReset" }
        'CAREFUL' { Write-Host "`n  $SkBold${SkGold}CAREFUL$SkReset" }
        'RISKY'   { Write-Host "`n  $SkBold${SkRed}RISKY$SkReset" }
    }
    Write-Host ''
}

# `what` with no arguments asks you to paste the command, which is the safe way:
# typing `what a | b` directly would let PowerShell run the `| b` part.
function what {
    $cmd = if ($args.Count) { ($args | ForEach-Object { "$_" }) -join ' ' } else { Read-Host '  paste the command' }
    if ($cmd) { Show-SakuraWhat $cmd }
}

function ask {
    $q = if ($args.Count) { ($args | ForEach-Object { "$_" }) -join ' ' } else { Read-Host '  ask' }
    if (-not $q) { return }
    $a = Invoke-SakuraClaude "Answer in at most two short lines of plain text, no markdown. The user is on Windows using PowerShell 7.`n`nQuestion: $q"
    if ($a) { Write-Host "  $SkPink✿$SkReset $SkText$a$SkReset" }
}

function cl { claude @args }

function sakura-config {
    if (-not (Test-Path $SakuraConfigPath)) { $Sakura | ConvertTo-Json | Set-Content $SakuraConfigPath }
    Invoke-Item $SakuraConfigPath
    Write-Host "  $SkDim✿ open a new tab after saving to see your changes$SkReset"
}

# ---------- menu (ctrl+/ or `menu`) ----------

$SakuraMenuItems = @(
    @{ Name = 'todo';          Desc = 'see your todo list';                              Text = 'todo' }
    @{ Name = 'todo add';      Desc = 'add something to your todo list';                 Text = 'todo add' }
    @{ Name = 'todo done';     Desc = 'check off a todo';                                Text = 'todo done' }
    @{ Name = 'what';          Desc = 'explain a command and how risky it is, first';    Text = 'what' }
    @{ Name = 'ask';           Desc = 'a quick one line answer from Claude';             Text = 'ask' }
    @{ Name = 'cl';            Desc = 'start Claude Code here';                          Text = 'cl' }
    @{ Name = 'cl -c';         Desc = 'pick up your last Claude chat in this folder';    Text = 'cl -c' }
    @{ Name = 'bloom';         Desc = 'show the blossom greeting again';                 Text = 'bloom' }
    @{ Name = 'sakura-config'; Desc = 'change your name, greeting, prompt or model';    Text = 'sakura-config' }
)

function Show-SakuraMenu {
    $filter = ''; $sel = 0
    $bgSel = "`e[48;2;92;52;80m"
    [Console]::Out.Write("`e[?1049h`e[?25l")
    try {
        while ($true) {
            $items = @($SakuraMenuItems | Where-Object {
                -not $filter -or $_.Name.IndexOf($filter, [StringComparison]::OrdinalIgnoreCase) -ge 0 -or
                $_.Desc.IndexOf($filter, [StringComparison]::OrdinalIgnoreCase) -ge 0 })
            if ($sel -ge $items.Count) { $sel = [math]::Max(0, $items.Count - 1) }

            $sb = [Text.StringBuilder]::new("`e[H`e[2J`n")
            [void]$sb.Append("  $SkBold$SkRose✿ sakura menu$SkReset   $SkDim type to search · ↑ ↓ · enter · esc$SkReset`n`n")
            [void]$sb.Append("  $SkPink❯$SkReset $SkText$filter$SkRose▏$SkReset`n`n")
            for ($i = 0; $i -lt $items.Count; $i++) {
                $it = $items[$i]
                if ($i -eq $sel) { [void]$sb.Append(("  $bgSel$SkPink ✿ {0,-14}$SkText{1} $SkReset`n" -f $it.Name, $it.Desc)) }
                else { [void]$sb.Append(("    $SkRose{0,-14}$SkReset$SkDim{1}$SkReset`n" -f $it.Name, $it.Desc)) }
            }
            if (-not $items.Count) { [void]$sb.Append("    ${SkDim}nothing matches$SkReset`n") }
            [Console]::Out.Write($sb.ToString())

            $k = [Console]::ReadKey($true)
            switch ($k.Key) {
                'Escape'    { return $null }
                'Enter'     { if ($items.Count) { return $items[$sel] } }
                'UpArrow'   { if ($sel -gt 0) { $sel-- } }
                'DownArrow' { if ($sel -lt $items.Count - 1) { $sel++ } }
                'Backspace' { if ($filter.Length) { $filter = $filter.Substring(0, $filter.Length - 1); $sel = 0 } }
                default     { if (-not [char]::IsControl($k.KeyChar)) { $filter += $k.KeyChar; $sel = 0 } }
            }
        }
    } finally { [Console]::Out.Write("`e[?25h`e[?1049l") }
}

function menu {
    $pick = Show-SakuraMenu
    if ($pick) { & ([scriptblock]::Create($pick.Text)) }
}

# ---------- prompt ----------

if ($Sakura.Prompt) {
    function global:prompt {
        $ok = $?
        $leaf = if ($PWD.Path -eq $HOME) { '~' } else { Split-Path $PWD.Path -Leaf }
        $branch = Get-SakuraBranch
        $pill = "`e[48;2;236;135;168m`e[38;2;42;27;43m ✿ $leaf `e[0m"
        $git = if ($branch) { " $SkDim$branch$SkReset" } else { '' }
        $arrow = if ($ok) { $SkRose } else { $SkRed }
        "`n$pill$git`n$arrow❯$SkReset "
    }
}

# ---------- keys and colors ----------

if ((Test-SakuraInteractive) -and (Get-Module PSReadLine)) {
    Set-PSReadLineOption -ExtraPromptLineCount 1
    Set-PSReadLineOption -Colors @{
        Command          = "`e[38;2;236;135;168m"
        Parameter        = "`e[38;2;185;166;240m"
        String           = "`e[38;2;168;216;185m"
        Variable         = "`e[38;2;246;211;139m"
        Number           = "`e[38;2;246;211;139m"
        Operator         = "`e[38;2;247;182;204m"
        Comment          = "`e[38;2;156;122;142m"
        InlinePrediction = "`e[38;2;122;90;110m"
    }

    try {
        Set-PSReadLineKeyHandler -Chord 'Ctrl+/' -BriefDescription 'sakura menu' -ScriptBlock {
            $pick = Show-SakuraMenu
            if ($pick) {
                [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert($pick.Text)
                [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
            } else { [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt() }
        }
    } catch { }

    # Type a command, then press alt+w instead of enter to have it explained. The command stays on your line.
    Set-PSReadLineKeyHandler -Chord 'Alt+w' -BriefDescription 'sakura: explain this command' -ScriptBlock {
        $line = $null; $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if (-not $line.Trim()) { return }
        Write-Host ''
        Show-SakuraWhat $line
        [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
    }
}

# ---------- hello ✿ ----------

if ($Sakura.Greeting -and (Test-SakuraInteractive) -and $env:TERM_PROGRAM -ne 'vscode') { bloom }
