# ✿ comfy status line for Claude Code ✿
# Claude Code pipes session info in as JSON; we print one pink line back.
$ErrorActionPreference = 'SilentlyContinue'
[Console]::InputEncoding = [Text.Encoding]::UTF8
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)

function fg([string]$hex) { $h = $hex.TrimStart('#'); "`e[38;2;$([Convert]::ToInt32($h.Substring(0,2),16));$([Convert]::ToInt32($h.Substring(2,2),16));$([Convert]::ToInt32($h.Substring(4,2),16))m" }
$reset = "`e[0m"; $rose = fg '#F4A6C0'; $pink = fg '#F7B6CC'; $dim = fg '#9C7A8E'
$text = fg '#FCE4EE'; $mint = fg '#A8D8B9'; $gold = fg '#F6D38B'; $red = fg '#F2798F'
$sep = " $dim·$reset "

try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { $j = $null }
if (-not $j) { [Console]::Out.Write("🪴 comfy"); exit 0 }

$parts = [Collections.Generic.List[string]]::new()

# model
$model = if ($j.model.display_name) { $j.model.display_name } else { 'Claude' }
$parts.Add("🪴 $text$model$reset")

# how full the chat is
$pct = $null
if ($null -ne $j.context_window.used_percentage) {
    $pct = [double]$j.context_window.used_percentage
} elseif ($j.transcript_path -and (Test-Path $j.transcript_path)) {
    $size = 200000
    if ($j.context_window.context_window_size) { $size = [double]$j.context_window.context_window_size }
    elseif ("$($j.model.id)" -match '1m') { $size = 1000000 }
    $lines = @(Get-Content $j.transcript_path -Tail 300)
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        if ($lines[$i] -notmatch '"usage"') { continue }
        try { $e = $lines[$i] | ConvertFrom-Json } catch { continue }
        if ($e.isSidechain) { continue }   # helper agents have their own context
        $u = $e.message.usage
        if ($u) {
            $used = [double]$u.input_tokens + [double]$u.cache_read_input_tokens + [double]$u.cache_creation_input_tokens
            $pct = 100 * $used / $size
            break
        }
    }
}
if ($null -ne $pct) {
    $pct = [math]::Min(100, [math]::Max(0, $pct))
    $filled = [int][math]::Round($pct / 10)
    # plenty of room 🌸, halfway 🍵, time to wrap up 🌙
    $color, $mood = if ($pct -lt 50) { $mint, '🌸' } elseif ($pct -lt 70) { $gold, '🍵' } else { $red, '🌙' }
    $bar = ('▰' * $filled) + ('▱' * (10 - $filled))
    $parts.Add("$color$bar$reset $text$([int][math]::Round($pct))%$reset $mood")
}

# time
if ($j.cost.total_duration_ms) {
    $mins = [math]::Floor([double]$j.cost.total_duration_ms / 60000)
    $dur = if ($mins -ge 60) { '{0}h {1}m' -f [math]::Floor($mins / 60), ($mins % 60) } else { "${mins}m" }
    $parts.Add("$dim$dur$reset")
}

# lines changed
$add = [int]$j.cost.total_lines_added; $del = [int]$j.cost.total_lines_removed
if ($add -or $del) { $parts.Add("$mint+$add$reset $red-$del$reset") }

# folder and branch
$dir = if ($j.workspace.current_dir) { $j.workspace.current_dir } else { $j.cwd }
if ($dir) {
    $where = "$pink$(Split-Path $dir -Leaf)$reset"
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $branch = git -C $dir branch --show-current 2>$null
        if ($branch) { $where += " $dim($branch)$reset" }
    }
    $parts.Add($where)
}

[Console]::Out.Write(($parts -join $sep))
