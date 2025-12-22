# Session Transfer Tool
# Export or Import sessions between systems

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("export", "import")]
    [string]$Action = "export"
)

$sessionDir = "$env:USERPROFILE\.antigravity-cleaner\sessions"
$exportPath = "$env:USERPROFILE\Desktop\antigravity-sessions-backup"

Write-Host "`n======================================================" -ForegroundColor Cyan
Write-Host "       SESSION TRANSFER TOOL" -ForegroundColor White
Write-Host "======================================================" -ForegroundColor Cyan

if ($Action -eq "export") {
    Write-Host "`n[EXPORT MODE] Backing up sessions to Desktop..." -ForegroundColor Yellow
    
    if (-not (Test-Path $sessionDir)) {
        Write-Host "[ERROR] No sessions found at: $sessionDir" -ForegroundColor Red
        exit 1
    }
    
    # Create export folder
    if (Test-Path $exportPath) { Remove-Item -Recurse -Force $exportPath }
    New-Item -ItemType Directory -Path $exportPath | Out-Null
    
    # Copy all session files and key
    Copy-Item -Path "$sessionDir\*" -Destination $exportPath -Recurse
    
    Write-Host "[OK] Sessions exported to: $exportPath" -ForegroundColor Green
    Write-Host "`nFiles exported:" -ForegroundColor Cyan
    Get-ChildItem $exportPath | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor White }
    
    Write-Host "`n[!] IMPORTANT: Copy the entire folder to the target system!" -ForegroundColor Yellow
    Write-Host "    Then run: .\transfer-session.ps1 import" -ForegroundColor Yellow
    
}
else {
    Write-Host "`n[IMPORT MODE] Restoring sessions from Desktop..." -ForegroundColor Yellow
    
    $importPath = "$env:USERPROFILE\Desktop\antigravity-sessions-backup"
    
    if (-not (Test-Path $importPath)) {
        Write-Host "[ERROR] No backup folder found at: $importPath" -ForegroundColor Red
        Write-Host "Please copy the 'antigravity-sessions-backup' folder to your Desktop first." -ForegroundColor Yellow
        exit 1
    }
    
    # Create session directory if not exists
    if (-not (Test-Path $sessionDir)) {
        New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null
    }
    
    # Copy files
    Copy-Item -Path "$importPath\*" -Destination $sessionDir -Recurse -Force
    
    Write-Host "[OK] Sessions imported successfully!" -ForegroundColor Green
    Write-Host "`nImported files:" -ForegroundColor Cyan
    Get-ChildItem $sessionDir | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor White }
    
    Write-Host "`nYou can now use Session Manager to restore these sessions." -ForegroundColor Yellow
}

Write-Host ""
