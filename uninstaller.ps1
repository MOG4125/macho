# Stop the background PowerShell process running the macro
Get-Process -Name powershell -ErrorAction SilentlyContinue | Where-Object {$_.Id -ne $PID} | Stop-Process -Force

# Optional: Self-delete the macro file if it's in the same folder
if (Test-Path ".\shortcut.ps1") { Remove-Item ".\shortcut.ps1" -Force }

Write-Host "Macro stopped and removed successfully!" -ForegroundColor Green
Start-Sleep -Seconds 3
