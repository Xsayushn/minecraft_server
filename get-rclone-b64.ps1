# PowerShell Helper to get Rclone Base64 string for Render Environment Variables
$rclonePath = "$env:APPDATA\rclone\rclone.conf"
$altPath = "$env:USERPROFILE\.config\rclone\rclone.conf"

if (Test-Path $rclonePath) {
    $target = $rclonePath
} elseif (Test-Path $altPath) {
    $target = $altPath
} else {
    Write-Host "Could not find rclone.conf at default paths." -ForegroundColor Yellow
    Write-Host "If you have rclone installed, run 'rclone config file' to find your config path." -ForegroundColor Cyan
    exit 1
}

Write-Host "Found rclone config at: $target" -ForegroundColor Green
$base64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($target))
Set-Clipboard -Value $base64
Write-Host "=========================================================" -ForegroundColor Green
Write-Host "Base64 config has been COPIED TO YOUR CLIPBOARD!" -ForegroundColor Cyan
Write-Host "Paste this as the value for 'RCLONE_CONFIG_BASE64' in Render." -ForegroundColor Yellow
Write-Host "=========================================================" -ForegroundColor Green
