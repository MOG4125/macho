# Terminate any background Macho engines processing keystrokes
Get-Process -Name powershell -ErrorAction SilentlyContinue | Where-Object {$_.Id -ne $PID} | Stop-Process -Force

# Visual confirmation
Write-Host "Macho mapping process killed. System keyboard settings normalized." -ForegroundColor Green
Start-Sleep -Seconds 2
