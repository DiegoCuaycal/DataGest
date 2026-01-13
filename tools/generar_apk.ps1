<#
.SYNOPSIS
    Generador de APK Pre-Configurada para Herramienta CASE

.DESCRIPTION
    Este script genera APKs personalizadas de la Herramienta CASE
    pre-configuradas para una base de datos específica.

    Al ejecutarse:
    1. Modifica el archivo app_build_config.dart reemplazando el placeholder
    2. Compila la APK con Flutter
    3. Restaura el archivo original
    4. Copia la APK a la carpeta de descargas

.PARAMETER NombreBaseDatos
    Nombre de la base de datos para la cual se generará la APK

.PARAMETER RutaProyecto
    Ruta del proyecto Flutter (opcional)

.PARAMETER CarpetaSalida
    Carpeta donde se guardará la APK generada (opcional)

.EXAMPLE
    .\generar_apk.ps1 -NombreBaseDatos "Productos"

.EXAMPLE
    .\generar_apk.ps1 "Inventario"

.EXAMPLE
    .\generar_apk.ps1 -NombreBaseDatos "Ventas" -CarpetaSalida "C:\MisAPKs"
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$NombreBaseDatos,

    [Parameter(Mandatory=$false)]
    [string]$RutaProyecto = "D:\Desarrollo\Flutter\herramienta_case\herramienta_case",

    [Parameter(Mandatory=$false)]
    [string]$CarpetaSalida = "D:\Desarrollo\Proyectos\BackFabrica\wwwroot\apks"
)

# Configuración
$PLACEHOLDER = "{{DB_NAME_PLACEHOLDER}}"
$CONFIG_FILE_RELATIVE = "lib\core\config\app_build_config.dart"
$CONFIG_FILE = Join-Path $RutaProyecto $CONFIG_FILE_RELATIVE

# Colores para consola
$Host.UI.RawUI.ForegroundColor = "White"

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  $Message" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "   ✓ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ ERROR: $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message, [string]$Value)
    Write-Host "$Message " -NoNewline
    Write-Host $Value -ForegroundColor Cyan
}

# Función principal
function Generate-APK {
    try {
        Write-Header "GENERADOR DE APK PRE-CONFIGURADA - HERRAMIENTA CASE"

        Write-Info "📦 Base de Datos:" $NombreBaseDatos
        Write-Info "📂 Proyecto Flutter:" $RutaProyecto
        Write-Info "📁 Carpeta de Salida:" $CarpetaSalida
        Write-Host ""

        # Validaciones
        Write-Step "🔍 Validando configuración..."

        if (-not (Test-Path $RutaProyecto)) {
            throw "No se encuentra el proyecto Flutter en: $RutaProyecto"
        }
        Write-Success "Proyecto Flutter encontrado"

        if (-not (Test-Path $CONFIG_FILE)) {
            throw "No se encuentra el archivo de configuración en: $CONFIG_FILE"
        }
        Write-Success "Archivo de configuración encontrado"

        # Crear carpeta de salida si no existe
        if (-not (Test-Path $CarpetaSalida)) {
            New-Item -ItemType Directory -Path $CarpetaSalida -Force | Out-Null
            Write-Success "Carpeta de salida creada: $CarpetaSalida"
        }

        # Paso 1: Respaldar y modificar archivo de configuración
        Write-Host ""
        Write-Step "🔧 [1/5] Modificando archivo de configuración..."

        $originalContent = Get-Content $CONFIG_FILE -Raw -Encoding UTF8

        if (-not $originalContent.Contains($PLACEHOLDER)) {
            throw "El archivo de configuración no contiene el placeholder '$PLACEHOLDER'"
        }

        # Crear respaldo
        $backupFile = "$CONFIG_FILE.backup"
        $originalContent | Set-Content $backupFile -Encoding UTF8

        # Reemplazar placeholder
        $modifiedContent = $originalContent -replace [regex]::Escape($PLACEHOLDER), $NombreBaseDatos
        $modifiedContent | Set-Content $CONFIG_FILE -Encoding UTF8

        Write-Success "Placeholder reemplazado: '$PLACEHOLDER' → '$NombreBaseDatos'"

        # Paso 2: Limpiar proyecto
        Write-Host ""
        Write-Step "🧹 [2/5] Limpiando proyecto Flutter..."

        Push-Location $RutaProyecto
        $cleanProcess = Start-Process -FilePath "flutter" -ArgumentList "clean" -Wait -NoNewWindow -PassThru
        if ($cleanProcess.ExitCode -ne 0) {
            throw "El comando 'flutter clean' falló"
        }
        Write-Success "Proyecto limpiado"

        # Paso 3: Compilar APK
        Write-Host ""
        Write-Step "🏗️  [3/5] Compilando APK (esto puede tomar varios minutos)..."
        Write-Host "   ⏳ Compilando... Por favor, espera..." -ForegroundColor Gray

        $buildProcess = Start-Process -FilePath "flutter" -ArgumentList "build", "apk", "--release" -Wait -NoNewWindow -PassThru
        if ($buildProcess.ExitCode -ne 0) {
            throw "La compilación de Flutter falló"
        }
        Write-Success "APK compilada exitosamente"

        Pop-Location

        # Paso 4: Copiar APK
        Write-Host ""
        Write-Step "📋 [4/5] Copiando APK a carpeta de descargas..."

        $apkSource = Join-Path $RutaProyecto "build\app\outputs\flutter-apk\app-release.apk"
        if (-not (Test-Path $apkSource)) {
            throw "No se encontró la APK compilada en: $apkSource"
        }

        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $apkName = "DataGest_${NombreBaseDatos}_${timestamp}.apk"
        $apkDestination = Join-Path $CarpetaSalida $apkName

        Copy-Item $apkSource $apkDestination -Force

        $apkSize = (Get-Item $apkDestination).Length
        $apkSizeMB = [math]::Round($apkSize / 1MB, 2)

        Write-Success "APK copiada: $apkName"
        Write-Success "Tamaño: $apkSizeMB MB"

        # Paso 5: Restaurar configuración
        Write-Host ""
        Write-Step "♻️  [5/5] Restaurando archivo de configuración..."

        Get-Content $backupFile -Raw -Encoding UTF8 | Set-Content $CONFIG_FILE -Encoding UTF8
        Remove-Item $backupFile

        Write-Success "Configuración restaurada (placeholder: '$PLACEHOLDER')"

        # Resumen final
        Write-Host ""
        Write-Header "✅ ¡APK GENERADA EXITOSAMENTE!"

        Write-Info "📦 Ubicación:" $apkDestination
        Write-Info "📱 Nombre:" $apkName
        Write-Info "🎯 Base de Datos:" $NombreBaseDatos
        Write-Info "💾 Tamaño:" "$apkSizeMB MB"
        Write-Host ""
        Write-Host "📲 La APK está lista para distribuir. Al instalarla, la app" -ForegroundColor Gray
        Write-Host "   entrará directamente a la base de datos '$NombreBaseDatos'" -ForegroundColor Gray
        Write-Host "   sin mostrar el selector de bases de datos." -ForegroundColor Gray
        Write-Host ""

        return $apkDestination
    }
    catch {
        Write-Host ""
        Write-Error $_.Exception.Message
        Write-Host ""

        # Intentar restaurar configuración en caso de error
        try {
            $backupFile = "$CONFIG_FILE.backup"
            if (Test-Path $backupFile) {
                Write-Host "⚠️  Restaurando archivo de configuración..." -ForegroundColor Yellow
                Get-Content $backupFile -Raw -Encoding UTF8 | Set-Content $CONFIG_FILE -Encoding UTF8
                Remove-Item $backupFile
                Write-Success "Configuración restaurada"
            }
        }
        catch {
            Write-Host "⚠️  No se pudo restaurar la configuración automáticamente" -ForegroundColor Yellow
            Write-Host "   Restaura manualmente desde: $backupFile" -ForegroundColor Yellow
        }

        throw
    }
}

# Ejecutar generador
try {
    $result = Generate-APK

    # Abrir carpeta de salida (opcional)
    $openFolder = Read-Host "`n¿Deseas abrir la carpeta con la APK generada? (S/N)"
    if ($openFolder -eq "S" -or $openFolder -eq "s") {
        Start-Process $CarpetaSalida
    }

    exit 0
}
catch {
    Write-Host "`nPresiona Enter para salir..." -ForegroundColor Gray
    Read-Host
    exit 1
}
