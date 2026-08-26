<#
A helper PowerShell script to run Flutter commands in this project even if Flutter is not in PATH.
Usage:
  - If flutter is in PATH: .\run_flutter.ps1 pub-get
  - If flutter is not in PATH: .\run_flutter.ps1 pub-get -flutterPath "C:\src\flutter\bin\flutter.bat"

Commands supported: pub-get, analyze, run, doctor
#>
param(
  [Parameter(Mandatory=$true, Position=0)]
  [ValidateSet("pub-get","analyze","run","doctor")] [string]$cmd,
  [string]$flutterPath
)

function RunFlutter([string]$arguments, [string]$flutterExe) {
  if (-not (Test-Path $flutterExe)) {
    Write-Error "flutter executable not found at: $flutterExe"
    exit 2
  }
  Write-Host "Running: $flutterExe $arguments" -ForegroundColor Cyan
  & $flutterExe $arguments
  if ($LASTEXITCODE -ne 0) { Write-Error "Command failed with exit code $LASTEXITCODE"; exit $LASTEXITCODE }
}

# locate flutter
$flutterExe = "flutter"
try {
  $where = (Get-Command flutter -ErrorAction SilentlyContinue).Path
  if ($where) { $flutterExe = $where }
} catch {}

if ($flutterPath) {
  $flutterExe = $flutterPath
}

switch ($cmd) {
  'pub-get' {
    RunFlutter 'pub get' $flutterExe
  }
  'analyze' {
    RunFlutter 'analyze' $flutterExe
  }
  'doctor' {
    RunFlutter 'doctor' $flutterExe
  }
  'run' {
    # forwards any extra args from $args
    $extra = $args -join ' '
    if ([string]::IsNullOrWhiteSpace($extra)) { $extra = '' }
    RunFlutter "run $extra" $flutterExe
  }
}
