# Invoke-StructuralValidator.ps1
# Scans a C++ Unreal Engine project for doctrine violations.
# Detects: empty functions, placeholder patterns, unbound systems, unapproved placeholders.
#
# Usage:
#   .\Invoke-StructuralValidator.ps1 -ProjectRoot "E:\the system"
#   .\Invoke-StructuralValidator.ps1 -ProjectRoot "E:\the system" -Scope "Source\the system\World"
#   .\Invoke-StructuralValidator.ps1 -ProjectRoot "E:\the system" -RegistryPath "E:\MasterCopy\enforcement\PLACEHOLDER_REGISTRY.md"

#Requires -Version 7.0

param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,

    [Parameter()]
    [string]$Scope = "Source",

    [Parameter()]
    [string]$RegistryPath = (Join-Path $PSScriptRoot "PLACEHOLDER_REGISTRY.md"),

    [Parameter()]
    [switch]$ShowDetails
)

# --- Configuration ---
$ScanPath = Join-Path $ProjectRoot $Scope
$FileExtensions = @("*.h", "*.cpp")

# Patterns that indicate doctrine violations
$ViolationPatterns = @(
    @{ Name = "Empty function body"; Pattern = '\{\s*\}'; Context = "function" },
    @{ Name = "TODO comment"; Pattern = '//\s*TODO'; Context = "any" },
    @{ Name = "FIXME comment"; Pattern = '//\s*FIXME'; Context = "any" },
    @{ Name = "HACK comment"; Pattern = '//\s*HACK'; Context = "any" },
    @{ Name = "Placeholder comment"; Pattern = '//\s*[Pp]laceholder'; Context = "any" },
    @{ Name = "Stub comment"; Pattern = '//\s*[Ss]tub'; Context = "any" },
    # Note: single-line 'return false/nullptr/0' are NOT flagged here because they are
    # legitimate guard clauses. Stub-return detection is handled by Find-StubFunctions which
    # checks for functions whose ONLY statement is a hardcoded return.
    @{ Name = "unimplemented macro"; Pattern = 'unimplemented!'; Context = "any" },
    @{ Name = "todo! macro"; Pattern = 'todo!'; Context = "any" },
    @{ Name = "Not implemented log"; Pattern = 'UE_LOG.*Not\s*[Ii]mplemented'; Context = "any" },
    @{ Name = "Placeholder log"; Pattern = 'UE_LOG.*[Pp]laceholder'; Context = "any" },
    @{ Name = "EXPLORATION tag (check if resolved)"; Pattern = 'EXPLORATION:'; Context = "any" },
    @{ Name = "ASSET_PENDING tag"; Pattern = 'ASSET_PENDING:'; Context = "any" }
)

# Patterns that are acceptable (not violations, just informational)
$AcceptablePatterns = @(
    'BLOCKED:',
    'PENDING_.*=\s*None'
)

# --- Functions ---
function Find-EmptyFunctionBodies {
    param([string]$FilePath, [string]$Content)

    $violations = @()
    $lines = $Content -split "`n"

    for ($i = 0; $i -lt $lines.Count - 1; $i++) {
        $line = $lines[$i]
        $nextLine = if ($i + 1 -lt $lines.Count) { $lines[$i + 1] } else { "" }
        $twoAhead = if ($i + 2 -lt $lines.Count) { $lines[$i + 2] } else { "" }

        # Pattern: function signature followed by { } on next lines with nothing between
        if ($line -match '^\s*\{' -and $nextLine -match '^\s*\}') {
            # Check if previous line looks like a function declaration
            $prevLine = if ($i -gt 0) { $lines[$i - 1] } else { "" }
            if ($prevLine -match '\)\s*$' -or $prevLine -match '\)\s*(const|override|final)?\s*$') {
                $violations += @{
                    File = $FilePath
                    Line = $i + 1
                    Type = "Empty function body"
                    Text = "$prevLine`n$line`n$nextLine".Trim()
                }
            }
        }

        # Pattern: { } on same line after function-like signature
        if ($line -match '\)\s*(const|override|final)?\s*\{\s*\}') {
            $violations += @{
                File = $FilePath
                Line = $i + 1
                Type = "Empty function body (inline)"
                Text = $line.Trim()
            }
        }
    }

    return $violations
}

function Find-StubFunctions {
    # Detects functions whose only statement is a hardcoded return (return false, return nullptr, return 0, etc.)
    # These are stub implementations that exist only to satisfy compilation.
    param([string]$FilePath, [string]$Content)

    $violations = @()
    $lines = $Content -split "`n"

    for ($i = 0; $i -lt $lines.Count - 2; $i++) {
        $line = $lines[$i]

        # Look for opening brace
        if ($line -match '^\s*\{' -or $line -match '\)\s*(const|override|final)?\s*\{') {
            # Check if previous line is a function signature (for standalone brace)
            $isFuncStart = $false
            if ($line -match '^\s*\{') {
                $prevLine = if ($i -gt 0) { $lines[$i - 1] } else { "" }
                if ($prevLine -match '\)\s*(const|override|final)?\s*$') {
                    $isFuncStart = $true
                }
            }
            elseif ($line -match '\)\s*(const|override|final)?\s*\{') {
                $isFuncStart = $true
            }

            if ($isFuncStart) {
                # Scan ahead: is the only non-whitespace line before closing } a return statement?
                $bodyLines = @()
                for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                    $bodyLine = $lines[$j].Trim()
                    if ($bodyLine -eq '}') {
                        # Found closing brace
                        if ($bodyLines.Count -eq 1 -and $bodyLines[0] -match '^return\s+(false|nullptr|0|0\.0f?|true|-1|FVector::ZeroVector|FRotator::ZeroRotator|FString\(\)|TEXT\(""\))\s*;') {
                            $violations += @{
                                File = $FilePath
                                Line = $i + 2
                                Type = "Stub function (only returns hardcoded value)"
                                Text = $bodyLines[0]
                            }
                        }
                        break
                    }
                    if ($bodyLine -ne '' -and -not $bodyLine.StartsWith('//')) {
                        $bodyLines += $bodyLine
                    }
                    if ($bodyLines.Count -gt 1) { break }  # More than one statement = not a stub
                }
            }
        }
    }

    return $violations
}

function Find-PatternViolations {
    param([string]$FilePath, [string]$Content)

    $violations = @()
    $lines = $Content -split "`n"

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        foreach ($pattern in $ViolationPatterns) {
            if ($line -match $pattern.Pattern) {
                # Check if it's in an acceptable context
                $isAcceptable = $false
                foreach ($ap in $AcceptablePatterns) {
                    if ($line -match $ap) {
                        $isAcceptable = $true
                        break
                    }
                }

                if (-not $isAcceptable) {
                    $violations += @{
                        File = $FilePath
                        Line = $i + 1
                        Type = $pattern.Name
                        Text = $line.Trim()
                    }
                }
            }
        }
    }

    return $violations
}

function Read-PlaceholderRegistry {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        Write-Host "  Registry not found at $Path. Skipping placeholder audit." -ForegroundColor Yellow
        return @()
    }

    $content = Get-Content $Path -Raw
    $entries = @()

    # Parse the Active Placeholders table
    $lines = $content -split "`n"
    $inActiveTable = $false

    foreach ($line in $lines) {
        if ($line -match '^\|\s*ID\s*\|.*File Path') {
            $inActiveTable = $true
            continue
        }
        if ($inActiveTable -and $line -match '^\|\s*-') {
            continue  # separator row
        }
        if ($inActiveTable -and $line -match '^\|\s*PH-(\d+)\s*\|') {
            $cols = $line -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
            if ($cols.Count -ge 7) {
                $entries += @{
                    ID = $cols[0]
                    FilePath = $cols[1]
                    Description = $cols[2]
                    ExpirationCondition = $cols[6]
                }
            }
        }
        if ($inActiveTable -and $line -match '^\s*$') {
            $inActiveTable = $false
        }
    }

    return $entries
}

function Find-UnregisteredPlaceholders {
    param(
        [array]$CodeViolations,
        [array]$RegistryEntries
    )

    $registeredPaths = $RegistryEntries | ForEach-Object { $_.FilePath }

    # Only explicit placeholder/exploration tags need registry entries.
    # Stub functions and empty bodies are violations but don't require registry approval —
    # they just need to be fixed.
    $unregistered = $CodeViolations | Where-Object {
        ($_.Type -match "Placeholder comment" -or $_.Type -match "EXPLORATION" -or $_.Type -match "ASSET_PENDING") -and
        ($_.File -notin $registeredPaths)
    }

    return $unregistered
}

# --- Main Execution ---
Write-Host "=== Structural Validator ===" -ForegroundColor Cyan
Write-Host "Project: $ProjectRoot" -ForegroundColor White
Write-Host "Scope:   $Scope" -ForegroundColor White
Write-Host "Registry: $RegistryPath" -ForegroundColor White
Write-Host ""

if (-not (Test-Path $ScanPath)) {
    Write-Host "ERROR: Scan path not found: $ScanPath" -ForegroundColor Red
    exit 1
}

# Collect all source files
$files = @()
foreach ($ext in $FileExtensions) {
    $files += Get-ChildItem -Path $ScanPath -Filter $ext -Recurse -File -ErrorAction SilentlyContinue
}

Write-Host "Scanning $($files.Count) source files..." -ForegroundColor White
Write-Host ""

$allViolations = @()

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    $emptyFunctions = Find-EmptyFunctionBodies -FilePath $file.FullName -Content $content
    $stubFunctions = Find-StubFunctions -FilePath $file.FullName -Content $content
    $patternViolations = Find-PatternViolations -FilePath $file.FullName -Content $content

    $allViolations += $emptyFunctions
    $allViolations += $stubFunctions
    $allViolations += $patternViolations
}

# Read placeholder registry
$registryEntries = Read-PlaceholderRegistry -Path $RegistryPath

# Check for unregistered placeholders
$unregistered = Find-UnregisteredPlaceholders -CodeViolations $allViolations -RegistryEntries $registryEntries

# --- Report ---
Write-Host "=== Results ===" -ForegroundColor Cyan
Write-Host ""

if ($allViolations.Count -eq 0) {
    Write-Host "PASS: No structural violations found." -ForegroundColor Green
}
else {
    Write-Host "VIOLATIONS FOUND: $($allViolations.Count)" -ForegroundColor Red
    Write-Host ""

    # Group by type
    $grouped = $allViolations | Group-Object -Property Type | Sort-Object Count -Descending

    foreach ($group in $grouped) {
        Write-Host "  [$($group.Count)] $($group.Name)" -ForegroundColor Yellow
        if ($ShowDetails) {
            foreach ($v in $group.Group) {
                $relativePath = $v.File.Replace($ProjectRoot, "").TrimStart("\")
                Write-Host "    $relativePath`:$($v.Line)" -ForegroundColor DarkGray
                Write-Host "      $($v.Text)" -ForegroundColor DarkGray
            }
        }
        else {
            # Show first 3 examples
            $examples = $group.Group | Select-Object -First 3
            foreach ($v in $examples) {
                $relativePath = $v.File.Replace($ProjectRoot, "").TrimStart("\")
                Write-Host "    $relativePath`:$($v.Line)  $($v.Text.Substring(0, [Math]::Min(80, $v.Text.Length)))" -ForegroundColor DarkGray
            }
            if ($group.Count -gt 3) {
                Write-Host "    ... and $($group.Count - 3) more" -ForegroundColor DarkGray
            }
        }
        Write-Host ""
    }
}

# Placeholder registry report
Write-Host "--- Placeholder Registry ---" -ForegroundColor Yellow
Write-Host "  Active registered placeholders: $($registryEntries.Count)" -ForegroundColor White

if ($unregistered.Count -gt 0) {
    Write-Host "  UNREGISTERED placeholders in code: $($unregistered.Count)" -ForegroundColor Red
    foreach ($u in $unregistered) {
        $relativePath = $u.File.Replace($ProjectRoot, "").TrimStart("\")
        Write-Host "    $relativePath`:$($u.Line) - $($u.Type)" -ForegroundColor Red
    }
}
else {
    Write-Host "  No unregistered placeholders found." -ForegroundColor Green
}

Write-Host ""

# --- Exit Code ---
$totalIssues = $allViolations.Count + $unregistered.Count
if ($totalIssues -gt 0) {
    Write-Host "RESULT: FAIL ($totalIssues issues)" -ForegroundColor Red
    exit 1
}
else {
    Write-Host "RESULT: PASS" -ForegroundColor Green
    exit 0
}
