$ErrorActionPreference = "Stop"

$AppDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Port = 8010
$Url = "http://127.0.0.1:$Port/index.php"
$LogDir = Join-Path $AppDir "logs"
$RuntimeDir = Join-Path $AppDir ".runtime"

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

function New-LocalPhpIni {
    $Php = Get-Command "php" -ErrorAction Stop
    $PhpDir = Split-Path -Parent $Php.Source
    $ParentDir = Split-Path -Parent $PhpDir
    $Candidates = @(
        (Join-Path $PhpDir "ext"),
        (Join-Path $ParentDir "ext")
    )

    $ExtDir = $null
    foreach ($Candidate in $Candidates) {
        if ((Test-Path (Join-Path $Candidate "php_pdo_sqlite.dll")) -or (Test-Path (Join-Path $Candidate "pdo_sqlite.dll"))) {
            $ExtDir = $Candidate
            break
        }
    }

    if (-not $ExtDir) {
        throw "L'extension PHP SQLite est introuvable. Reinstallez PHP avec SQLite, ou installez PHP via winget/choco."
    }

    New-Item -ItemType Directory -Force -Path $RuntimeDir | Out-Null
    $PhpIni = Join-Path $RuntimeDir "php.ini"
    $ExtDirForIni = $ExtDir -replace "\\", "/"

    @"
extension_dir="$ExtDirForIni"
extension=pdo_sqlite
extension=sqlite3
memory_limit=512M
max_execution_time=600
display_errors=1
log_errors=1
"@ | Set-Content -Encoding ASCII -Path $PhpIni

    return $PhpIni
}

function Assert-PhpSqlite($PhpIni) {
    $Modules = & php -c $PhpIni -m 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "PHP n'arrive pas a charger la configuration locale: $Modules"
    }
    if (($Modules -notcontains "PDO") -or ($Modules -notcontains "pdo_sqlite")) {
        throw "PHP demarre, mais le driver SQLite PDO n'est pas charge. Consultez $PhpIni."
    }
}

function Stop-PortProcess {
    try {
        $Connections = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
        foreach ($Connection in $Connections) {
            if ($Connection.OwningProcess -and $Connection.OwningProcess -ne $PID) {
                Stop-Process -Id $Connection.OwningProcess -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {
    }
}

function Test-App {
    try {
        $Response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 2
        $Body = [string]$Response.Content
        return ($Response.StatusCode -eq 200 -and $Body.Contains("Autoresearch") -and -not $Body.Contains("Fatal error"))
    } catch {
        return $false
    }
}

Set-Location $AppDir
New-Item -ItemType Directory -Force -Path $LogDir, $RuntimeDir, (Join-Path $AppDir "data"), (Join-Path $AppDir "generated_apps") | Out-Null

Say "Preparation d'Autoresearch"
Install-PHP-IfPossible
$PhpIni = New-LocalPhpIni
Assert-PhpSqlite $PhpIni

if (-not (Test-App)) {
    Say "Demarrage avec PHP local"
    Stop-PortProcess
    $StdoutLog = Join-Path $LogDir "php-server.out.log"
    $StderrLog = Join-Path $LogDir "php-server.err.log"
    Start-Process -FilePath "php" -ArgumentList @("-c", "`"$PhpIni`"", "-S", "127.0.0.1:$Port", "-t", "`"$AppDir`"") -WindowStyle Hidden -RedirectStandardOutput $StdoutLog -RedirectStandardError $StderrLog
    Start-Sleep -Seconds 2
}

if (-not (Test-App)) {
    throw "Le serveur PHP n'a pas demarre. Consultez logs\php-server.out.log et logs\php-server.err.log."
}

Say "Ouverture du navigateur"
Start-Process $Url
Write-Host ""
Write-Host "Autoresearch est lance:"
Write-Host $Url
Start-Sleep -Seconds 3
