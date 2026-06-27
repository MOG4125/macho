Get-Process -Name powershell -ErrorAction SilentlyContinue | Where-Object {$_.Id -ne $PID} | Stop-Process -Force
Write-Host "Macho environment system processing cleared." -ForegroundColor Green
Start-Sleep -Seconds 2
