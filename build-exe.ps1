$WorkingDir = Get-Location
$SedFile = "$WorkingDir\macho_build.sed"

if (!(Test-Path ".\macho.ps1") -or !(Test-Path ".\uninstall.ps1")) {
    Write-Host "Error: Missing core script assets inside workspace." -ForegroundColor Red
    Exit
}

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
TargetName=$WorkingDir\MachoApp.exe
FriendlyName=Macho Key Mapper
AppLaunched=powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File macho.ps1
PostInstallCmd=<None>
SourceFiles=SourceFiles
[SourceFiles]
SourceFiles0=$WorkingDir
[SourceFiles0]
%1=macho.ps1
%2=uninstall.ps1
"@

Set-Content -Path $SedFile -Value $SedContent
& iexpress.exe /N /Q $SedFile
if (Test-Path $SedFile) { Remove-Item $SedFile -Force }
