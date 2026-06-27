# Stop the background PowerShell process running the keyboard hook
Get-Process -Name powershell -ErrorAction SilentlyContinue | Where-ID {$_.Id -ne $PID} | Stop-Process -Force
Write-Host "Left-Ctrl macro has been stopped and normal key function restored!" -ForegroundColor Green
Pause
