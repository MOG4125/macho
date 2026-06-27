# ==============================================================================
# MACHO - Native EXE Compiler Script
# ==============================================================================
# This script bundles macho.ps1 and uninstall.ps1 into an independent executable.

$WorkingDir = Get-Location
$SedFile = "$WorkingDir\macho_build.sed"

# Check if required files exist before building
if (!(Test-Path ".\macho.ps1") -or !(Test-Path ".\uninstall.ps1")) {
    Write-Host "Error: macho.ps1 and uninstall.ps1 must be in the same folder!" -ForegroundColor Red
    Exit
}

Write-Host "Generating Macho build configurations..." -ForegroundColor Cyan

# Define the express package generation configuration
$SedContent = @"
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=CreateCAB
ShowInstallProgramWindow=0
HideExtractAnimation=1
UseLongFileName=1
InsideCompressed=1
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=
DisplayLicense=
FinishMessage=
TargetName=$WorkingDir\MachoApp.exe
FriendlyName=Macho Key Mapper
AppLaunched=powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File macho.ps1
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
SourceFiles=SourceFiles
[SourceFiles]
SourceFiles0=$WorkingDir
[SourceFiles0]
%1=macho.ps1
%2=uninstall.ps1
"@

Set-Content -Path $SedFile -Value $SedContent

Write-Host "Compiling standalone Macho executable..." -ForegroundColor Yellow

# Call the hidden native Windows compiler engine
& iexpress.exe /N /Q $SedFile

# Clean up temporary configuration build artifacts
if (Test-Path $SedFile) { Remove-Item $SedFile -Force }

if (Test-Path ".\MachoApp.exe") {
    Write-Host "Success! 'MachoApp.exe' has been generated in your folder." -ForegroundColor Green
} else {
    Write-Host "Compilation failed. Ensure you have administrator access to the folder." -ForegroundColor Red
}

Start-Sleep -Seconds 3
