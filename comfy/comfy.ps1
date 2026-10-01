# ✿ comfy terminal for Windows ✿
# Loaded from your PowerShell profile. Settings live in ~/.comfy/config.json

$ComfyHome       = Join-Path $HOME '.comfy'
$ComfyConfigPath = Join-Path $ComfyHome 'config.json'
$ComfyScratch    = Join-Path $ComfyHome 'scratch'   # where alt+w and `ask` run Claude, so they don't clutter your chat history

# The console defaults to an old code page, which turns ♡ and the moon emoji into ?
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)

# ---------- settings ----------

function Get-ComfyConfig {
    $cfg = @{ Name = $env:USERNAME; Greeting = $true; Prompt = $true; Model = 'haiku' }
    if (Test-Path $ComfyConfigPath) {
        try {
            $user = Get-Content $ComfyConfigPath -Raw | ConvertFrom-Json -AsHashtable
            foreach ($k in $user.Keys) { $cfg[$k] = $user[$k] }
        } catch { Write-Warning "comfy: couldn't read config.json ($_)" }
    }
    $cfg
}
$Comfy = Get-ComfyConfig

# ---------- colors ----------

function ConvertTo-ComfyRgb([string]$hex) {
    $h = $hex.TrimStart('#')
    '{0};{1};{2}' -f [Convert]::ToInt32($h.Substring(0, 2), 16), [Convert]::ToInt32($h.Substring(2, 2), 16), [Convert]::ToInt32($h.Substring(4, 2), 16)
}
function Get-ComfyFg([string]$hex) { "`e[38;2;$(ConvertTo-ComfyRgb $hex)m" }

$SkReset = "`e[0m"; $SkBold = "`e[1m"
$SkPink  = Get-ComfyFg '#F7B6CC'
$SkRose  = Get-ComfyFg '#F4A6C0'
$SkDim   = Get-ComfyFg '#9C7A8E'
$SkText  = Get-ComfyFg '#FCE4EE'
$SkMint  = Get-ComfyFg '#A8D8B9'
$SkGold  = Get-ComfyFg '#F6D38B'
$SkRed   = Get-ComfyFg '#F2798F'

$ComfyPixel = @{
    O = ConvertTo-ComfyRgb '#181926'; L = ConvertTo-ComfyRgb '#B8E6A0'; G = ConvertTo-ComfyRgb '#7CC77A'
    D = ConvertTo-ComfyRgb '#4E9A5B'; S = ConvertTo-ComfyRgb '#5E8C4A'; R = ConvertTo-ComfyRgb '#F2A98A'
    T = ConvertTo-ComfyRgb '#E08A6A'; K = ConvertTo-ComfyRgb '#181926'; W = ConvertTo-ComfyRgb '#FFFFFF'
    P = ConvertTo-ComfyRgb '#F7B6CC'
}

# ---------- small helpers ----------

function Format-ComfyShort([string]$s, [int]$n) {
    if ($s.Length -gt $n) { $s.Substring(0, $n - 1) + '…' } else { $s }
}
function Format-ComfyAgo([datetime]$t) {
    $d = (Get-Date) - $t
    if ($d.TotalMinutes -lt 1) { 'just now' }
    elseif ($d.TotalHours -lt 1) { '{0}m ago' -f [math]::Floor($d.TotalMinutes) }
    elseif ($d.TotalDays -lt 1) { '{0}h ago' -f [math]::Floor($d.TotalHours) }
    else { '{0}d ago' -f [math]::Floor($d.TotalDays) }
}
function Format-ComfyPath([string]$p) {
    if ($p.StartsWith($HOME, [StringComparison]::OrdinalIgnoreCase)) { '~' + $p.Substring($HOME.Length) } else { $p }
}
function Get-ComfyBranch([string]$dir = $PWD.Path) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { return $null }
    $b = git -C $dir branch --show-current 2>$null
    if ($LASTEXITCODE -eq 0 -and $b) { $b } else { $null }
}
function Test-ComfyInteractive {
    # VS Code's PowerShell extension starts pwsh with -NonInteractive -Command, so skip the argv check there
    # and VS Code's terminal starts it with -Command to load its shell integration
    if ($Host.Name -eq 'Visual Studio Code Host' -or $env:TERM_PROGRAM -eq 'vscode') { return $true }
    if ($Host.Name -ne 'ConsoleHost') { return $false }
    $argv = [Environment]::GetCommandLineArgs()
    -not ($argv | Where-Object { $_ -match '^-(c|command|f|file|noninteractive|encodedcommand|e|ec)$' })
}

# ---------- the plant ----------

$ComfyPlant = @(
    '..........OO..........'
    '.........OLGO.........'
    '..OOO...OLLGGO...OOO..'
    '.OLLGO..OLGGGO..OGLLO.'
    '.OLGGGO..OGGO..OGGGLO.'
    '..OGGGDO.OSSO.ODGGGO..'
    '...OODDDOOSSOODDDOO...'
    '.....OOOOOSSOOOOO.....'
    '..........SS..........'
    '..........SS..........'
    '...OOOOOOOOOOOOOOOO...'
    '...ORRRRRRRRRRRRRRO...'
    '...OOOOOOOOOOOOOOOO...'
    '....OTTTTTTTTTTTTO....'
    '....OTTKWTTTTKWTTO....'
    '....OPTKKTTTTKKTPO....'
    '....OTTTTKTTKTTTTO....'
    '.....OTTTTKKTTTTO.....'
    '.....OTTTTTTTTTTO.....'
    '......OOOOOOOOOO......'
)

# One animation frame: the top leaves lean by $sway columns, and $blink closes the eyes.
function Get-ComfyPlantFrame([int]$sway = 0, [switch]$blink) {
    $rows = $ComfyPlant.Clone()
    for ($y = 0; $y -lt 5; $y++) {
        if ($sway -lt 0) { $rows[$y] = $rows[$y].Substring(1) + '.' }
        elseif ($sway -gt 0) { $rows[$y] = '.' + $rows[$y].Substring(0, $rows[$y].Length - 1) }
    }
    if ($blink) { $rows[14] = '....OTTTTTTTTTTTTO....' }
    $rows
}

# Two pixels per character cell (upper/lower half blocks), so the pixels come out square.
function Get-ComfyArtLines([string[]]$art) {
    $w = ($art | Measure-Object -Property Length -Maximum).Maximum
    $rows = @($art | ForEach-Object { $_.PadRight($w, '.') })
    if ($rows.Count % 2) { $rows += ('.' * $w) }
    for ($y = 0; $y -lt $rows.Count; $y += 2) {
        $sb = [Text.StringBuilder]::new()
        for ($x = 0; $x -lt $w; $x++) {
            $t = $ComfyPixel["$($rows[$y][$x])"]; $b = $ComfyPixel["$($rows[$y + 1][$x])"]
            if (-not $t -and -not $b) { [void]$sb.Append(' ') }
            elseif ($t -and -not $b)  { [void]$sb.Append("`e[38;2;${t}m▀`e[0m") }
            elseif (-not $t -and $b)  { [void]$sb.Append("`e[38;2;${b}m▄`e[0m") }
            else                      { [void]$sb.Append("`e[38;2;${t};48;2;${b}m▀`e[0m") }
        }
        $sb.ToString()
    }
}

function Get-ComfyMoon {
    $synodic = 29.530588853
    $knownNew = [datetime]::new(2000, 1, 6, 18, 14, 0, [DateTimeKind]::Utc)
    $age = ((((Get-Date).ToUniversalTime() - $knownNew).TotalDays % $synodic) + $synodic) % $synodic
    $i = [int]([math]::Floor(($age / $synodic) * 8 + 0.5)) % 8
    $names = 'new moon', 'waxing crescent', 'first quarter', 'waxing gibbous', 'full moon', 'waning gibbous', 'last quarter', 'waning crescent'
    $icons = '🌑', '🌒', '🌓', '🌔', '🌕', '🌖', '🌗', '🌘'
    "$($icons[$i]) $($names[$i])"
}

# Most recent Claude Code chat, from the local chat logs (reads files only, no tokens).
function Get-ComfyLastChat {
    $projects = Join-Path $HOME '.claude/projects'
    if (-not (Test-Path $projects)) { return $null }
    $file = Get-ChildItem $projects -Directory -ErrorAction SilentlyContinue |
        Where-Object Name -notmatch 'comfy-scratch' |
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
    $row = { param($label, $value) "$SkRose{0,-8}$SkReset$SkText{1}$SkReset" -f $label, $value }

    $branch = Get-ComfyBranch
    $here = Format-ComfyShort (Format-ComfyPath $PWD.Path) 40
    if ($branch) { $here += "  $SkDim($branch)" }

    $chat = Get-ComfyLastChat
    $chatText = if ($chat) {
        $what = if ($chat.Summary) { "$($chat.Project): $($chat.Summary)" } else { $chat.Project }
        "$(Format-ComfyShort $what 40) $SkDim· $(Format-ComfyAgo $chat.When)"
    } else { 'no chats yet' }

    $info = @(
        "$SkBold${SkRose}good $part, $($Comfy.Name) $SkPink♡$SkReset"
        "$SkDim$($now.ToString('dddd, MMMM d', $inv).ToLower()) · $($now.ToString('h:mm tt', $inv).ToLower())$SkReset"
        "$SkRose$('─' * 34)$SkReset"
        (& $row 'here' $here)
        (& $row 'claude' $chatText)
        (& $row 'moon' (Get-ComfyMoon))
    )

    $draw = {
        param([string[]]$art, [bool]$redraw)
        $offset = [math]::Max(0, [math]::Floor(($art.Count - $info.Count) / 2))
        $sb = [Text.StringBuilder]::new()
        if ($redraw) { [void]$sb.Append("`e[$($art.Count)A") }
        for ($i = 0; $i -lt $art.Count; $i++) {
            $j = $i - $offset
            $right = if ($j -ge 0 -and $j -lt $info.Count) { $info[$j] } else { '' }
            [void]$sb.Append("`r`e[2K  $($art[$i])    $right`n")
        }
        [Console]::Out.Write($sb.ToString())
    }

    Write-Host ''
    & $draw @(Get-ComfyArtLines (Get-ComfyPlantFrame)) $false
    # A little wiggle and a blink, then it settles. ~1s total.
    if (-not [Console]::IsOutputRedirected) {
        foreach ($f in @(-1, 0, 1, 0, -1, 0, 'blink', 0)) {
            Start-Sleep -Milliseconds 120
            $frame = if ($f -eq 'blink') { Get-ComfyPlantFrame -blink } else { Get-ComfyPlantFrame $f }
            & $draw @(Get-ComfyArtLines $frame) $true
        }
    }
    Write-Host ''
    Write-Host "  $SkRose✿$SkDim who   $SkRose✿$SkDim ask   $SkRose✿$SkDim cl   $SkRose✿$SkDim alt+w explains your command   $SkRose✿$SkDim ctrl+/ menu$SkReset"
    Write-Host ''
}

# ---------- Claude helpers ----------

function Invoke-ComfyClaude([string]$prompt) {
    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        Write-Host "  ${SkRed}claude isn't on your PATH, so this needs Claude Code installed.$SkReset"
        return $null
    }
    New-Item -ItemType Directory -Force $ComfyScratch | Out-Null
    $prevOut = $OutputEncoding; $prevCon = [Console]::OutputEncoding
    $OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
    Write-Host -NoNewline "  $SkDim✿ thinking…$SkReset"
    Push-Location $ComfyScratch
    try { $out = $prompt | claude -p --model $Comfy.Model 2>$null }
    finally {
        Pop-Location
        $OutputEncoding = $prevOut; [Console]::OutputEncoding = $prevCon
        Write-Host -NoNewline "`r`e[2K"
    }
    (($out | ForEach-Object { "$_" }) -join "`n").Trim()
}

$ComfyRiskyPatterns = @(
    @{ P = '(?i)(iwr|irm|curl|wget|Invoke-WebRequest|Invoke-RestMethod)\b[^|]*\|\s*(iex|Invoke-Expression|sh|bash|pwsh|powershell)\b'; Why = 'downloads a script and runs it immediately' }
    @{ P = '(?i)\b(iex|Invoke-Expression)\b'; Why = 'runs text as code' }
    @{ P = '(?i)\b(rm|ri|Remove-Item|del|erase|rd|rmdir)\b.*(\s-r\w*|\s-Recurse|\s/s)\b'; Why = 'deletes folders and everything in them' }
    @{ P = '(?i)\bformat(-volume)?\b\s+[a-z]:|\bdiskpart\b|\bbcdedit\b|\bcipher\s+/w'; Why = 'low-level disk or boot changes' }
    @{ P = '(?i)\breg(\.exe)?\s+delete\b|\bRemove-ItemProperty\b'; Why = 'deletes registry settings' }
    @{ P = '(?i)\bSet-ExecutionPolicy\s+(Unrestricted|Bypass)'; Why = 'turns off script safety checks' }
    @{ P = '(?i)\bgit\s+(push\b.*(\s--force\b|\s-f\b)|reset\s+--hard|clean\s+-\w*f)'; Why = 'can throw away git work for good' }
    @{ P = '(?i)\bStop-Process\b.*-Force|\btaskkill\b.*\s/f\b'; Why = 'force-closes programs without saving' }
)

function Show-ComfyWhat([string]$cmd) {
    Write-Host ''
    Write-Host "  $SkRose✿$SkReset $SkText$cmd$SkReset"
    foreach ($r in $ComfyRiskyPatterns) {
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
    $answer = Invoke-ComfyClaude $prompt
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

# ---------- who's that pokémon? ----------

$ComfyPokemon = @'
Bulbasaur|A Grass/Poison starter with a plant bulb on its back that it was born with.
Ivysaur|The bulb on its back has become a bud, and it gets heavier just before it blooms.
Venusaur|A huge flower on its back gives off a soothing scent, strongest after a rainy day.
Charmander|A fire lizard starter. The flame on the tip of its tail shows how healthy it is.
Charmeleon|A hot-tempered red lizard with a horn on its head, the middle of a fire starter line.
Charizard|An orange Fire/Flying dragon whose flame burns hotter after a tough battle.
Squirtle|A tiny turtle starter that hides in its shell and sprays water from its mouth.
Wartortle|A turtle with furry ears and a fluffy tail that is said to be a sign of long life.
Blastoise|A big turtle with two water cannons sticking out of its shell.
Caterpie|A little green bug with a red antenna that gives off a stink to scare off birds.
Metapod|A green cocoon that can only harden its shell while it waits to evolve.
Butterfree|A white-winged butterfly that scatters sleep and paralysis powder.
Weedle|A hairy orange bug with a sharp poison stinger on its head.
Beedrill|A wasp-like Bug/Poison type with giant stingers on both forearms.
Pidgey|A small brown bird found in tall grass that kicks up sand to blind its foes.
Pidgeot|A large bird with a long red and yellow crest that can fly at Mach 2.
Rattata|A purple rat with long front teeth and a tail that curls at the tip.
Spearow|A small, short-tempered bird that has to flap its stubby wings fast to stay up.
Ekans|A purple snake that coils itself up. Its name is a word spelled backwards.
Arbok|A cobra with a scary face pattern on its hood.
Pikachu|An electric mouse with red cheeks and a lightning bolt tail. The series mascot.
Raichu|An orange electric mouse with a long thin tail that ends in a bolt shape.
Sandshrew|A yellow ground mouse that curls up into a ball to protect itself.
Clefairy|A pink fairy that dances under the full moon on Mt. Moon.
Vulpix|A red fox born with one white tail that splits into six as it grows.
Ninetales|A golden fox with nine tails, said to live for a thousand years.
Jigglypuff|A pink balloon that sings a lullaby, then gets angry when everyone falls asleep.
Zubat|A blue bat with no eyes that finds its way through caves with ultrasonic waves.
Oddish|A blue bulb with leaves on its head that wanders around at night.
Paras|A bug with two mushrooms growing on its back that slowly take control of it.
Venonat|A fuzzy purple bug with big red compound eyes.
Diglett|A little brown mole that pops out of the ground. No one has seen the rest of it.
Dugtrio|Three brown heads poking out of the ground together.
Meowth|A cat with a gold coin on its forehead that loves shiny things. One famously talks.
Psyduck|A yellow duck with constant headaches that set off its psychic powers.
Growlithe|A loyal orange puppy with black stripes, often used by the police.
Arcanine|A majestic orange and black striped dog said to run 6,200 miles in a single day.
Poliwag|A blue tadpole with a spiral on its belly, which is actually its insides showing.
Abra|A psychic that sleeps 18 hours a day and teleports away when it senses danger.
Alakazam|A mustached psychic holding two spoons, said to have an IQ of 5,000.
Machop|A small gray fighter that trains by lifting a different heavy thing every day.
Machamp|A four-armed fighting powerhouse that wears a champion's belt.
Bellsprout|A thin plant with a bell-shaped head and roots for feet.
Tentacool|A clear jellyfish with two red crystals, often drifting near the beach.
Geodude|A rock with two arms and no legs, easy to mistake for a stone on a mountain path.
Ponyta|A pony with a mane and tail made of flames.
Slowpoke|A pink, very slow, spaced-out creature that fishes with its tail.
Magnemite|A floating steel ball with one eye, a screw on top and a magnet on each side.
Farfetch'd|A brown duck that carries a leek stalk everywhere it goes.
Doduo|A two-headed bird that can't fly but runs incredibly fast.
Seel|A white sea lion with a horn on its head that loves icy water.
Grimer|A purple pile of sludge born from pollution.
Shellder|A purple clam shell with its long tongue always sticking out.
Gastly|A black ball with a grin, surrounded by a cloud of poison gas.
Haunter|A purple ghost with floating hands that licks its prey.
Gengar|A round purple ghost with a wide grin that hides in your shadow and makes the air go cold.
Onix|A giant snake made of a chain of boulders that tunnels underground.
Drowzee|A yellow tapir-like psychic that eats people's dreams.
Krabby|A small red crab with big pincers.
Voltorb|Looks exactly like a Poké Ball, but explodes when you touch it.
Exeggcute|Six pinkish eggs that move as a group, talking to each other by telepathy.
Cubone|A lonely little one that wears its mother's skull as a helmet.
Hitmonlee|A fighter with no neck that can stretch its legs out to kick from far away.
Hitmonchan|A fighter in boxing gloves whose punches are faster than a bullet train.
Lickitung|A pink creature whose tongue is twice as long as its body.
Koffing|A floating ball of toxic gas with a skull-and-crossbones mark.
Rhyhorn|A gray rock rhino that can only charge in a straight line.
Chansey|A pink nurse that carries an egg in its pouch and shares it with the hurt.
Tangela|A mass of blue vines with only its eyes and red feet showing.
Kangaskhan|A big brown parent that carries its baby in a pouch on its belly.
Horsea|A small blue seahorse that shoots ink at its enemies.
Goldeen|An elegant white and orange fish with a horn and a flowing tail fin.
Staryu|A brown starfish with a red gem core that can grow back lost limbs.
Mr. Mime|A mime that builds invisible walls with its fingertips.
Scyther|A green mantis with blades for arms.
Jynx|An Ice/Psychic type with long blonde hair that speaks in a strange language and dances.
Electabuzz|A yellow and black striped electric type that hangs around power plants.
Magmar|A fire creature born in volcanoes whose body looks like it's made of flames.
Pinsir|A brown beetle with two huge pincers on its head.
Tauros|A wild bull with three tails that it whips itself with to get fired up.
Magikarp|An orange fish that can only splash around, but evolves into something fearsome.
Gyarados|A furious blue sea serpent that evolves from the weakest fish there is.
Lapras|A gentle sea creature with a shell on its back that ferries people across the water.
Ditto|A pink blob with a simple face that can transform into anything it sees.
Eevee|A brown, fluffy creature with unstable genes that can evolve into many different types.
Vaporeon|A blue water evolution with fins and a mermaid-like tail that can melt into water.
Jolteon|An electric evolution with spiky yellow fur that it shoots like needles.
Flareon|A fire evolution with a big fluffy mane and tail, its body hotter than 1,500 degrees.
Porygon|A blocky pink and blue creature made entirely of computer code.
Omanyte|An ancient fossil with a spiral shell and tentacles.
Aerodactyl|A prehistoric flying dinosaur brought back to life from amber.
Snorlax|A huge, lazy sleeper that blocks roads and eats 900 pounds of food a day.
Articuno|A legendary blue bird of ice with a long flowing tail.
Zapdos|A legendary yellow bird crackling with electricity.
Moltres|A legendary bird whose wings are made of flames.
Dratini|A small blue serpent dragon that was long thought to be a myth.
Dragonite|A friendly, chubby orange dragon that can fly around the world in 16 hours.
Mewtwo|A powerful psychic created in a lab from the DNA of a mythical Pokémon.
Mew|A tiny pink mythical creature said to hold the DNA of every Pokémon.
Lucario|A blue jackal-like Fighting/Steel type that can sense and control aura.
'@ -split '\r?\n' | ForEach-Object { $n, $d = $_ -split '\|', 2; @{ Name = $n; Desc = $d } }

# Matches ignore case, spaces and punctuation, so "mr mime" and "farfetchd" count.
function who {
    $key = { param($s) $s.ToLower() -replace '[^a-z0-9]', '' }
    $score = 0; $rounds = 0
    foreach ($p in ($ComfyPokemon | Get-Random -Shuffle)) {
        $rounds++
        Write-Host ''
        Write-Host "  $SkBold$SkRose✿ who's that pokémon?$SkReset"
        Write-Host "  $SkText$($p.Desc)$SkReset"
        $won = $false
        for ($try = 1; $try -le 3 -and -not $won; $try++) {
            $guess = Read-Host "  guess $try/3 (enter gives up)"
            if (-not $guess) { break }
            if ((& $key $guess) -eq (& $key $p.Name)) { $won = $true }
            elseif ($try -lt 3) { Write-Host "  ${SkDim}nope, try again$SkReset" }
        }
        if ($won) { $score++; Write-Host "  $SkBold${SkMint}yes! it's $($p.Name)!$SkReset" }
        else { Write-Host "  ${SkGold}it's $($p.Name)!$SkReset" }
        Write-Host "  ${SkDim}score $score/$rounds$SkReset"
        if ((Read-Host '  again? (enter = yes, q = quit)') -eq 'q') { break }
    }
}

function ask {
    $q = if ($args.Count) { ($args | ForEach-Object { "$_" }) -join ' ' } else { Read-Host '  ask' }
    if (-not $q) { return }
    $a = Invoke-ComfyClaude "Answer in at most two short lines of plain text, no markdown. The user is on Windows using PowerShell 7.`n`nQuestion: $q"
    if ($a) { Write-Host "  $SkPink✿$SkReset $SkText$a$SkReset" }
}

function cl {
    # In Windows Terminal the plant stays pinned in this pane and Claude opens in a new pane below it
    # Elsewhere (VS Code's terminal) the new-tab greeting is already on screen, so just start Claude
    if (-not $env:WT_SESSION -or -not (Get-Command wt -ErrorAction SilentlyContinue)) { claude @args; return }
    $quoted = $args | ForEach-Object { "'" + ("$_" -replace "'", "''") + "'" }
    $cmd = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes("claude $($quoted -join ' ')"))
    # The greeting + prompt need ~18 rows; give Claude the rest. --size is a fraction, so convert.
    # ponytail: plant gets clipped in windows under ~36 rows, since Claude keeps at least half
    $size = [math]::Round([math]::Min(0.8, [math]::Max(0.5, 1 - 18 / $Host.UI.RawUI.WindowSize.Height)), 2)
    wt -w 0 split-pane -H --size $size -d "$PWD" pwsh -NoLogo -EncodedCommand $cmd
    # Draw after the pane shrinks; drawn before, the resize scrolls the plant off the top
    Start-Sleep -Milliseconds 300
    Clear-Host; bloom
}

function comfy-config {
    if (-not (Test-Path $ComfyConfigPath)) { $Comfy | ConvertTo-Json | Set-Content $ComfyConfigPath }
    Invoke-Item $ComfyConfigPath
    Write-Host "  $SkDim✿ open a new tab after saving to see your changes$SkReset"
}

# ---------- menu (ctrl+/ or `menu`) ----------

$ComfyMenuItems = @(
    @{ Name = 'who';           Desc = "mini game: who's that pokémon?";                 Text = 'who' }
    @{ Name = 'ask';           Desc = 'a quick one line answer from Claude';             Text = 'ask' }
    @{ Name = 'cl';            Desc = 'start Claude Code here';                          Text = 'cl' }
    @{ Name = 'cl -c';         Desc = 'pick up your last Claude chat in this folder';    Text = 'cl -c' }
    @{ Name = 'bloom';         Desc = 'show the plant greeting again';                   Text = 'bloom' }
    @{ Name = 'comfy-config'; Desc = 'change your name, greeting, prompt or model';    Text = 'comfy-config' }
)

function Show-ComfyMenu {
    $filter = ''; $sel = 0
    $bgSel = "`e[48;2;91;96;120m"
    [Console]::Out.Write("`e[?1049h`e[?25l")
    try {
        while ($true) {
            $items = @($ComfyMenuItems | Where-Object {
                -not $filter -or $_.Name.IndexOf($filter, [StringComparison]::OrdinalIgnoreCase) -ge 0 -or
                $_.Desc.IndexOf($filter, [StringComparison]::OrdinalIgnoreCase) -ge 0 })
            if ($sel -ge $items.Count) { $sel = [math]::Max(0, $items.Count - 1) }

            $sb = [Text.StringBuilder]::new("`e[H`e[2J`n")
            [void]$sb.Append("  $SkBold$SkRose✿ comfy menu$SkReset   $SkDim type to search · ↑ ↓ · enter · esc$SkReset`n`n")
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
    $pick = Show-ComfyMenu
    if ($pick) { & ([scriptblock]::Create($pick.Text)) }
}

# ---------- prompt ----------

if ($Comfy.Prompt) {
    function global:prompt {
        $ok = $?
        $leaf = if ($PWD.Path -eq $HOME) { '~' } else { Split-Path $PWD.Path -Leaf }
        $branch = Get-ComfyBranch
        $pill = "`e[48;2;244;166;192m`e[38;2;24;25;38m ✿ $leaf `e[0m"
        $git = if ($branch) { " $SkDim$branch$SkReset" } else { '' }
        $arrow = if ($ok) { $SkRose } else { $SkRed }
        "`n$pill$git`n$arrow❯$SkReset "
    }
}

# ---------- keys and colors ----------

if ((Test-ComfyInteractive) -and (Get-Module PSReadLine)) {
    Set-PSReadLineOption -ExtraPromptLineCount 1
    Set-PSReadLineOption -Colors @{
        Command          = "`e[38;2;244;166;192m"
        Parameter        = "`e[38;2;185;166;240m"
        String           = "`e[38;2;168;216;185m"
        Variable         = "`e[38;2;246;211;139m"
        Number           = "`e[38;2;246;211;139m"
        Operator         = "`e[38;2;247;182;204m"
        Comment          = "`e[38;2;156;122;142m"
        InlinePrediction = "`e[38;2;122;90;110m"
    }

    try {
        Set-PSReadLineKeyHandler -Chord 'Ctrl+/' -BriefDescription 'comfy menu' -ScriptBlock {
            $pick = Show-ComfyMenu
            if ($pick) {
                [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert($pick.Text)
                [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
            } else { [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt() }
        }
    } catch { }

    # Type a command, then press alt+w instead of enter to have it explained. The command stays on your line.
    Set-PSReadLineKeyHandler -Chord 'Alt+w' -BriefDescription 'comfy: explain this command' -ScriptBlock {
        $line = $null; $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if (-not $line.Trim()) { return }
        Write-Host ''
        Show-ComfyWhat $line
        [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
    }
}

# ---------- hello ✿ ----------

if ($Comfy.Greeting -and (Test-ComfyInteractive)) { bloom }
