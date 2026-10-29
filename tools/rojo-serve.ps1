# Serves the Rojo project and restarts it if it crashes.
# Rojo 7.7.1 crashes ("change_processor.rs ... cannot find the file specified") when files vanish for a moment,
# e.g. during a git pull/rebase. After a restart, reconnect each Studio: Plugins -> Rojo -> Connect.
# Run from the repo root:  .\tools\rojo-serve.ps1   (Ctrl+C twice to stop)

$rojo = Join-Path $env:USERPROFILE ".rokit\bin\rojo.exe"
Set-Location (Split-Path $PSScriptRoot -Parent)
while ($true) {
    & $rojo serve default.project.json
    Write-Host "[rojo-serve] Rojo stopped at $(Get-Date -Format HH:mm:ss); restarting in 2 s. Reconnect Studio afterwards." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
}
