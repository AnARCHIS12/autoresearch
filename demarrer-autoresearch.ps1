$ErrorActionPreference = "Stop"

$AppDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Port = 8010
$Url = "http://127.0.0.1:$Port/index.php"
$LogDir = Join-Path $AppDir "logs"

function Say($Message) {
    Write-Host ""
    Write-Host "== $Message =="
}

function HasCommand($Name) {
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Install-PHP-IfPossible {
    if (HasCommand "php") { return }

    Say "PHP est absent, tentative d'installation"
    if (HasCommand "winget") {
        $packages = @("PHP.PHP.8.4", "PHP.PHP.8.3", "PHP.PHP.8.2")
        foreach ($package in $packages) {
            winget install --id $package -e --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -eq 0) { break }
        }
    } elseif (HasCommand "choco") {
        choco install php -y
    }

    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
    if (-not (HasCommand "php")) {
        throw "PHP est absent. Installez PHP 8 avec SQLite/cURL, puis relancez ce fichier."
    }
}

function Test-App {
    try {
        Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 2 | Out-Null
        return $true
    } catch {
        return $false
    }
}

Set-Location $AppDir
New-Item -ItemType Directory -Force -Path $LogDir, (Join-Path $AppDir "data"), (Join-Path $AppDir "generated_apps") | Out-Null

Say "Preparation d'Autoresearch"
Install-PHP-IfPossible

if (-not (Test-App)) {
    Say "Demarrage avec PHP local"
    $LogFile = Join-Path $LogDir "php-server.log"
    Start-Process -FilePath "php" -ArgumentList @("-S", "127.0.0.1:$Port", "-t", "`"$AppDir`"") -WindowStyle Hidden -RedirectStandardOutput $LogFile -RedirectStandardError $LogFile
    Start-Sleep -Seconds 2
}

if (-not (Test-App)) {
    throw "Le serveur PHP n'a pas demarre. Consultez logs\php-server.log."
}

Say "Ouverture du navigateur"
Start-Process $Url
Write-Host ""
Write-Host "Autoresearch est lance:"
Write-Host $Url
Start-Sleep -Seconds 3
