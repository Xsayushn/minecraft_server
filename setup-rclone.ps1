# Download and run portable Rclone for Google Drive configuration
$toolsDir = "$PSScriptRoot\tools"
$rcloneExe = "$toolsDir\rclone.exe"

if (-not (Test-Path $rcloneExe)) {
    Write-Host "Downloading portable Rclone..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null
    $zipPath = "$toolsDir\rclone.zip"
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri "https://downloads.rclone.org/rclone-current-windows-amd64.zip" -OutFile $zipPath
    
    Write-Host "Extracting Rclone..." -ForegroundColor Cyan
    Expand-Archive -Path $zipPath -DestinationPath "$toolsDir\temp" -Force
    $extractedExe = Get-ChildItem -Path "$toolsDir\temp" -Recurse -Filter "rclone.exe" | Select-Object -First 1
    Move-Item -Path $extractedExe.FullName -Destination $rcloneExe -Force
    Remove-Item -Recurse -Force "$toolsDir\temp", $zipPath
    Write-Host "Rclone is ready!" -ForegroundColor Green
}

Write-Host "`nStarting Rclone configuration..." -ForegroundColor Green
Write-Host "Follow the prompts: type 'n' -> name: 'gdrive' -> storage: 'drive' -> default options -> authenticate in browser." -ForegroundColor Yellow
& $rcloneExe config
