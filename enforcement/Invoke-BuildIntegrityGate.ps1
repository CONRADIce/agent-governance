# Invoke-BuildIntegrityGate.ps1
# The full enforcement gate: compile + structural validation + placeholder audit.
# Referenced by Doctrine Section 12D.
#
# Usage:
#   .\Invoke-BuildIntegrityGate.ps1 -ProjectRoot "E:\the system"
#   .\Invoke-BuildIntegrityGate.ps1 -ProjectRoot "E:\the system" -SkipCompile
#   .\Invoke-BuildIntegrityGate.ps1 -ProjectRoot "E:\the system" -Scope "Source\the system\World" -Verbose

#Requires -Version 7.0

param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,

    [Parameter()]
    [string]$Scope = "Source",

    [Parameter()]
    [string]$RegistryPath = (Join-Path $PSScriptRoot "PLACEHOLDER_REGISTRY.md"),

    [Parameter()]
    [string]$UBTPath = "E:\UE_5.7\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe",

    [Parameter()]
    [string]$UProjectPath,

    [Parameter()]
    [string]$BuildTarget = "Editor",

    [Parameter()]
    [switch]$SkipCompile,

    [Parameter()]
    [switch]$ShowDetails
)

# --- Auto-detect uproject if not provided ---
if (-not $UProjectPath) {
    $uprojects = Get-ChildItem -Path $ProjectRoot -Filter "*.uproject" -File -ErrorAction SilentlyContinue
    if ($uprojects.Count -eq 1) {
        $UProjectPath = $uprojects[0].FullName
    }
    elseif ($uprojects.Count -gt 1) {
        Write-Host "ERROR: Multiple .uproject files found. Specify -UProjectPath." -ForegroundColor Red
        exit 1
    }
}

# --- Gate Results ---
$gates = @{
    Compile    = @{ Status = "SKIP"; Details = "" }
    Structural = @{ Status = "PENDING"; Details = "" }
    Placeholder = @{ Status = "PENDING"; Details = "" }
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  BUILD INTEGRITY GATE" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Project:  $ProjectRoot" -ForegroundColor White
Write-Host "Scope:    $Scope" -ForegroundColor White
Write-Host "Registry: $RegistryPath" -ForegroundColor White
Write-Host ""

# ============================================================
# GATE 1: COMPILE VALIDATION
# ============================================================
Write-Host "--- Gate 1: Compile Validation ---" -ForegroundColor Yellow

if ($SkipCompile) {
    Write-Host "  SKIPPED (--SkipCompile)" -ForegroundColor DarkGray
    $gates.Compile.Status = "SKIP"
}
elseif (-not $UProjectPath) {
    Write-Host "  SKIPPED (no .uproject found)" -ForegroundColor DarkGray
    $gates.Compile.Status = "SKIP"
}
elseif (-not (Test-Path $UBTPath)) {
    Write-Host "  SKIPPED (UBT not found at $UBTPath)" -ForegroundColor DarkGray
    $gates.Compile.Status = "SKIP"
}
else {
    $projectName = [System.IO.Path]::GetFileNameWithoutExtension($UProjectPath)
    $target = if ($BuildTarget -eq "Editor") { "${projectName}Editor" } else { $projectName }

    Write-Host "  Compiling: $target Win64 Development" -ForegroundColor White
    Write-Host "  UProject: $UProjectPath" -ForegroundColor DarkGray

    $compileArgs = "$target Win64 Development `"$UProjectPath`" -WaitMutex"
    $process = Start-Process -FilePath $UBTPath -ArgumentList $compileArgs -Wait -PassThru -NoNewWindow -RedirectStandardOutput "$env:TEMP\ubt_stdout.log" -RedirectStandardError "$env:TEMP\ubt_stderr.log"

    if ($process.ExitCode -eq 0) {
        Write-Host "  PASS: Compile succeeded." -ForegroundColor Green
        $gates.Compile.Status = "PASS"
    }
    else {
        $errorOutput = Get-Content "$env:TEMP\ubt_stderr.log" -Raw -ErrorAction SilentlyContinue
        $stdOutput = Get-Content "$env:TEMP\ubt_stdout.log" -Raw -ErrorAction SilentlyContinue

        # Extract error lines
        $errors = ($stdOutput + $errorOutput) -split "`n" | Where-Object { $_ -match "error\s*(C|LNK)" } | Select-Object -First 10
        $errorSummary = ($errors -join "`n").Trim()

        Write-Host "  FAIL: Compile failed (exit code $($process.ExitCode))." -ForegroundColor Red
        if ($errorSummary) {
            Write-Host "  First errors:" -ForegroundColor Red
            Write-Host "  $errorSummary" -ForegroundColor DarkGray
        }
        $gates.Compile.Status = "FAIL"
        $gates.Compile.Details = $errorSummary
    }

    # Cleanup temp files
    Remove-Item "$env:TEMP\ubt_stdout.log" -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:TEMP\ubt_stderr.log" -Force -ErrorAction SilentlyContinue
}

Write-Host ""

# ============================================================
# GATE 2: STRUCTURAL VALIDATION
# ============================================================
Write-Host "--- Gate 2: Structural Validation ---" -ForegroundColor Yellow

$validatorScript = Join-Path $PSScriptRoot "Invoke-StructuralValidator.ps1"

if (-not (Test-Path $validatorScript)) {
    Write-Host "  ERROR: Validator not found at $validatorScript" -ForegroundColor Red
    $gates.Structural.Status = "FAIL"
    $gates.Structural.Details = "Validator script missing"
}
else {
    $detailsFlag = if ($ShowDetails) { "-ShowDetails" } else { "" }
    $result = & $validatorScript -ProjectRoot $ProjectRoot -Scope $Scope -RegistryPath $RegistryPath $detailsFlag 2>&1

    if ($LASTEXITCODE -eq 0) {
        $gates.Structural.Status = "PASS"
    }
    else {
        $gates.Structural.Status = "FAIL"
        $gates.Structural.Details = "Structural violations detected"
    }
}

Write-Host ""

# ============================================================
# GATE 3: PLACEHOLDER AUDIT
# ============================================================
Write-Host "--- Gate 3: Placeholder Audit ---" -ForegroundColor Yellow

if (-not (Test-Path $RegistryPath)) {
    Write-Host "  Registry not found. Creating empty registry." -ForegroundColor Yellow
    $gates.Placeholder.Status = "PASS"
    $gates.Placeholder.Details = "No registry (no placeholders expected)"
}
else {
    $registryContent = Get-Content $RegistryPath -Raw

    # Count active placeholders
    $activeCount = ([regex]::Matches($registryContent, 'PH-\d+')).Count

    # Check for EXPLORATION: tags in code that aren't registered
    $scanPath = Join-Path $ProjectRoot $Scope
    $explorationHits = @()
    if (Test-Path $scanPath) {
        $sourceFiles = Get-ChildItem -Path $scanPath -Include "*.h", "*.cpp" -Recurse -File -ErrorAction SilentlyContinue
        foreach ($file in $sourceFiles) {
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($content -and $content -match 'EXPLORATION:') {
                $explorationHits += $file.FullName
            }
        }
    }

    Write-Host "  Active registered placeholders: $activeCount" -ForegroundColor White

    if ($explorationHits.Count -gt 0) {
        Write-Host "  WARNING: $($explorationHits.Count) files contain EXPLORATION: tags" -ForegroundColor Yellow
        foreach ($hit in $explorationHits) {
            $relativePath = $hit.Replace($ProjectRoot, "").TrimStart("\")
            Write-Host "    $relativePath" -ForegroundColor DarkGray
        }
        Write-Host "  These must be resolved before Production Mode completion." -ForegroundColor Yellow
        $gates.Placeholder.Status = "WARN"
        $gates.Placeholder.Details = "$($explorationHits.Count) exploration tags found"
    }
    else {
        Write-Host "  No unresolved exploration tags." -ForegroundColor Green
        $gates.Placeholder.Status = "PASS"
    }
}

Write-Host ""

# ============================================================
# FINAL VERDICT
# ============================================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  GATE RESULTS" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$failed = $false
foreach ($gate in $gates.GetEnumerator()) {
    $color = switch ($gate.Value.Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARN" { "Yellow" }
        "SKIP" { "DarkGray" }
        default { "White" }
    }
    $detail = if ($gate.Value.Details) { " — $($gate.Value.Details)" } else { "" }
    Write-Host "  $($gate.Key): $($gate.Value.Status)$detail" -ForegroundColor $color

    if ($gate.Value.Status -eq "FAIL") { $failed = $true }
}

Write-Host ""

if ($failed) {
    Write-Host "VERDICT: BLOCKED — Fix failures before declaring complete." -ForegroundColor Red
    exit 1
}
else {
    Write-Host "VERDICT: PASS — All enforcement gates satisfied." -ForegroundColor Green
    exit 0
}
