# Antigravity Cleaner - PowerShell Installer
# Automatically installs Python if not found

$ErrorActionPreference = "Stop"

Write-Host "`n======================================================" -ForegroundColor Cyan
Write-Host "       ANTIGRAVITY CLEANER - Installer" -ForegroundColor White
Write-Host "======================================================" -ForegroundColor Cyan

# Check for Python
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue

if (-not $pythonCmd) {
    Write-Host "`n[!] Python not found. Installing Python..." -ForegroundColor Yellow
    
    # Try winget first (Windows 10/11)
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
        Write-Host "Installing Python via winget..." -ForegroundColor Cyan
        winget install Python.Python.3.12 --accept-source-agreements --accept-package-agreements
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    } else {
        # Download Python installer manually
        Write-Host "Downloading Python installer..." -ForegroundColor Cyan
        $pythonUrl = "https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe"
        $installerPath = "$env:TEMP\python-installer.exe"
        
        try {
            Invoke-WebRequest -Uri $pythonUrl -OutFile $installerPath -UseBasicParsing
            Write-Host "Installing Python (this may take a minute)..." -ForegroundColor Cyan
            Start-Process -FilePath $installerPath -ArgumentList "/quiet", "InstallAllUsers=0", "PrependPath=1" -Wait
            
            # Refresh PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        } catch {
            Write-Host "`n[ERROR] Could not download Python. Please install manually from https://python.org" -ForegroundColor Red
            Write-Host "Make sure to check 'Add Python to PATH' during installation!" -ForegroundColor Yellow
            Read-Host "Press Enter to exit"
            exit 1
        }
    }
    
    # Verify installation
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pythonCmd) {
        Write-Host "`n[ERROR] Python installation failed. Please install manually from https://python.org" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    Write-Host "[OK] Python installed successfully!" -ForegroundColor Green
}

# Show Python version
$pythonVersion = python --version 2>&1
Write-Host "`n[OK] Using: $pythonVersion" -ForegroundColor Green

# Download the cleaner
$repoUrl = "https://github.com/tawroot/antigravity-cleaner/archive/refs/heads/main.zip"
$zipPath = "$env:TEMP\antigravity-cleaner.zip"
$destPath = "$env:TEMP\antigravity-cleaner-install"

Write-Host "`nDownloading Antigravity Cleaner..." -ForegroundColor Cyan

try {
    Invoke-WebRequest -Uri $repoUrl -OutFile $zipPath -UseBasicParsing
} catch {
    Write-Host "[ERROR] Could not download. Check your internet connection." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

if (Test-Path $destPath) { Remove-Item -Recurse -Force $destPath }
Expand-Archive -Path $zipPath -DestinationPath $destPath

$innerFolder = Get-ChildItem $destPath | Select-Object -First 1
$srcFolder = Join-Path $innerFolder.FullName "src"

# Install requirements
Write-Host "Installing dependencies..." -ForegroundColor Cyan
$requirementsFile = Join-Path $innerFolder.FullName "src\requirements.txt"

if (Test-Path $requirementsFile) {
    # Try with mirror for Iran/restricted networks
    $mirrors = @(
        "",  # Default PyPI
        "--index-url https://pypi.tuna.tsinghua.edu.cn/simple",  # China mirror (works in Iran)
        "--index-url https://mirrors.aliyun.com/pypi/simple"     # Aliyun mirror
    )
    
    $installed = $false
    foreach ($mirror in $mirrors) {
        Write-Host "Trying to install packages..." -ForegroundColor Cyan
        try {
            if ($mirror) {
                python -m pip install --user $mirror -r $requirementsFile 2>&1 | Out-Null
            } else {
                python -m pip install --user -r $requirementsFile 2>&1 | Out-Null
            }
            $installed = $true
            break
        } catch {
            Write-Host "Retrying with different mirror..." -ForegroundColor Yellow
        }
    }
    
    if (-not $installed) {
        Write-Host "[WARNING] Some packages may not have installed. Continuing anyway..." -ForegroundColor Yellow
    }
}

# Run the main script (INTERACTIVE MODE - no auto clean!)
Write-Host "`nStarting Antigravity Cleaner..." -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Cyan

Set-Location $srcFolder
python main.py

# Cleanup
Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue

Write-Host "`nDone!" -ForegroundColor Green
