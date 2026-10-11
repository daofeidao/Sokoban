# Verify every Sokoban level in Levels.swift by breadth-first search.
#
# Why: hand-tracing a level proves "there is a solution", it does NOT prove
# "the level is playable". A level can be solvable and still feel broken --
# e.g. the first instinct is a trap and the real solution needs two laps
# around the board. The step count printed here is the cheap signal for that.
#
# ASCII only on purpose: no Chinese literals, so no UTF-8 BOM needed.
# Chinese level names are read from Levels.swift (UTF-8) and are fine.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_levels.ps1
#   powershell ... -File .\scripts\verify_levels.ps1 -MaxMoves 40

param(
    [string]$LevelsFile = (Join-Path (Split-Path $PSScriptRoot -Parent) 'Sokoban\Data\Levels.swift'),
    # Levels above this many moves are technically solvable but not playable.
    [int]$MaxMoves = 25,
    # BFS gives up past this many distinct states and reports the level UNKNOWN.
    [int]$MaxStates = 400000,
    [switch]$ShowWalkthrough
)

$ErrorActionPreference = 'Stop'

# 0) up  1) down  2) left  3) right
$dirs = @(
    @{ dr = -1; dc = 0;  ch = 'U' },
    @{ dr = 1;  dc = 0;  ch = 'D' },
    @{ dr = 0;  dc = -1; ch = 'L' },
    @{ dr = 0;  dc = 1;  ch = 'R' }
)

# ---------------------------------------------------------------- parsing

if (-not (Test-Path $LevelsFile)) { throw "levels file not found: $LevelsFile" }
$text = [System.IO.File]::ReadAllText($LevelsFile, [System.Text.Encoding]::UTF8)

$levels = @()
# Match a level entry: (name: "...", <anything but a paren>, rows: [ ... ])
# The middle group swallows optional fields such as `par: 14`.
# [^)]*? is what keeps a match from spilling into the next entry.
$pattern = '\(name:\s*"([^"]*)"([^)]*?)rows:\s*\[(.*?)\]'
$rx = New-Object System.Text.RegularExpressions.Regex(
    $pattern,
    ([System.Text.RegularExpressions.RegexOptions]::Singleline -bor
     [System.Text.RegularExpressions.RegexOptions]::Compiled))
foreach ($m in $rx.Matches($text)) {
    $name = $m.Groups[1].Value
    $parMatch = [regex]::Match($m.Groups[2].Value, 'par:\s*(\d+)')
    $par = if ($parMatch.Success) { [int]$parMatch.Groups[1].Value } else { $null }
    $rows = @([regex]::Matches($m.Groups[3].Value, '"([^"]*)"') | ForEach-Object { $_.Groups[1].Value })
    if ($rows.Count -gt 0) { $levels += @{ name = $name; rows = $rows; par = $par } }
}

if ($levels.Count -eq 0) { throw 'no levels parsed out of Levels.swift' }
"parsed $($levels.Count) level(s) from $(Split-Path $LevelsFile -Leaf)"
""

# ---------------------------------------------------------------- solver

function Solve-Level {
    param($Walls, [string[]]$Boxes0, [string]$Player0, [string[]]$Targets, [int]$MaxStates)

    $startBoxes = ($Boxes0 | Sort-Object) -join ';'
    $start = "$Player0|$startBoxes"

    $parent = @{}
    $seen = @{}
    $seen[$start] = $true

    $q = New-Object System.Collections.Queue
    $q.Enqueue($start)
    $goal = $null
    $guard = 0
    $gaveUp = $false

    while ($q.Count -gt 0) {
        $guard++
        if ($guard -gt $MaxStates) { $gaveUp = $true; break }

        $cur = [string]$q.Dequeue()
        $bar = $cur.IndexOf('|')
        $player = $cur.Substring(0, $bar)
        $rest = $cur.Substring($bar + 1)
        $boxes = if ($rest) { @($rest -split ';') } else { @() }

        $bset = @{}
        foreach ($b in $boxes) { $bset[$b] = $true }

        # goal: every box sits on a target
        $done = ($boxes.Count -eq $Targets.Count)
        if ($done) {
            foreach ($t in $Targets) { if (-not $bset.ContainsKey($t)) { $done = $false; break } }
        }
        if ($done) { $goal = $cur; break }

        $pc = $player -split ','
        $pr = [int]$pc[0]; $pcol = [int]$pc[1]

        foreach ($d in $dirs) {
            $nr = $pr + $d.dr; $nc = $pcol + $d.dc
            $n = "$nr,$nc"
            if ($Walls.ContainsKey($n)) { continue }

            $newBoxes = $boxes
            if ($bset.ContainsKey($n)) {
                $br = $nr + $d.dr; $bc = $nc + $d.dc
                $bn = "$br,$bc"
                if ($Walls.ContainsKey($bn)) { continue }
                if ($bset.ContainsKey($bn)) { continue }
                $newBoxes = @($boxes | Where-Object { $_ -ne $n })
                $newBoxes += $bn
            }

            $key = "$n|$((($newBoxes | Sort-Object) -join ';'))"
            if ($seen.ContainsKey($key)) { continue }
            $seen[$key] = $true
            $parent[$key] = @{ prev = $cur; ch = $d.ch }
            $q.Enqueue($key)
        }
    }

    if ($gaveUp) {
        return @{ status = 'toobig'; states = $seen.Count }
    }
    if (-not $goal) {
        return @{ status = 'unsolved'; states = $seen.Count }
    }

    # walk back
    $path = ''
    $node = $goal
    while ($node -ne $start) {
        $step = $parent[$node]
        $path = $step.ch + $path
        $node = $step.prev
    }
    return @{ status = 'solved'; path = $path; length = $path.Length; states = $seen.Count }
}

# ---------------------------------------------------------------- run

$fail = 0
$warn = 0
$skip = 0
$badPar = 0
$i = 0

foreach ($lv in $levels) {
    $i++
    $width = ($lv.rows | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum
    $grid = @()
    foreach ($r in $lv.rows) { $grid += $r.PadRight($width) }

    $walls = @{}; $boxes = @(); $targets = @(); $player = $null
    for ($r = 0; $r -lt $grid.Count; $r++) {
        for ($c = 0; $c -lt $width; $c++) {
            $ch = $grid[$r][$c]
            switch ($ch) {
                '#' { $walls["$r,$c"] = $true }
                '$' { $boxes += "$r,$c" }
                '*' { $boxes += "$r,$c"; $targets += "$r,$c" }
                '.' { $targets += "$r,$c" }
                '@' { $player = "$r,$c" }
                '+' { $player = "$r,$c"; $targets += "$r,$c" }
            }
        }
    }

    $label = $lv.name

    if (-not $player) {
        Write-Output ("[{0,2}] FAIL  {1}  -- no player (@)" -f $i, $label); $fail++; continue
    }
    if ($boxes.Count -ne $targets.Count) {
        Write-Output ("[{0,2}] FAIL  {1}  -- {2} boxes vs {3} targets" -f $i, $label, $boxes.Count, $targets.Count)
        $fail++; continue
    }

    $res = Solve-Level -Walls $walls -Boxes0 $boxes -Player0 $player -Targets $targets -MaxStates $MaxStates

    if ($res.status -eq 'toobig') {
        Write-Output ("[{0,2}] SKIP  {1}  -- state space >{2}, not proven solvable" -f $i, $label, $MaxStates)
        $skip++
        continue
    }
    if ($res.status -eq 'unsolved') {
        Write-Output ("[{0,2}] FAIL  {1}  -- UNSOLVABLE ({2} states)" -f $i, $label, $res.states)
        $fail++
        continue
    }

    $flag = 'ok  '
    if ($res.length -gt $MaxMoves) { $flag = 'LONG'; $warn++ }

    # The hand-written par in Levels.swift must match what BFS found.
    $parNote = ''
    if ($null -eq $lv.par) {
        $parNote = '  <- no par declared'
    } elseif ($lv.par -ne $res.length) {
        $parNote = "  <- PAR WRONG (declared $($lv.par))"
        $badPar++
    }

    Write-Output ("[{0,2}] {1}  {2}  moves={3,-4} par={4,-4} states={5}{6}" -f $i, $flag, $label, $res.length, $lv.par, $res.states, $parNote)
    if ($ShowWalkthrough) { Write-Output ("        path: {0}" -f $res.path) }
}

""
if ($warn -gt 0) { Write-Output "$warn level(s) over $MaxMoves moves: solvable but likely unplayable." }
if ($skip -gt 0) { Write-Output "$skip level(s) skipped: state space too large to prove." }
if ($badPar -gt 0) {
    Write-Output "$badPar level(s) have a WRONG par value. Fix the number in Levels.swift."
    exit 1
}
if ($fail -gt 0) {
    Write-Output "$fail level(s) FAILED. Do not ship these."
    exit 1
}
Write-Output "all levels solvable, all par values correct."
exit 0