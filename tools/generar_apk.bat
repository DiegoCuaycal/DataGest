@echo off
REM ====================================================================
REM  GENERADOR DE APK PRE-CONFIGURADA - HERRAMIENTA CASE
REM ====================================================================
REM
REM  Uso:
REM    generar_apk.bat NombreBaseDatos
REM
REM  Ejemplo:
REM    generar_apk.bat Productos
REM    generar_apk.bat Inventario
REM    generar_apk.bat Ventas
REM
REM ====================================================================

setlocal enabledelayedexpansion

REM Verificar que se proporcionó el nombre de la base de datos
if "%~1"=="" (
    echo.
    echo ╔════════════════════════════════════════════════════════════╗
    echo ║  ERROR: Falta el nombre de la base de datos               ║
    echo ╚════════════════════════════════════════════════════════════╝
    echo.
    echo Uso: generar_apk.bat ^<NombreBaseDatos^>
    echo.
    echo Ejemplo:
    echo   generar_apk.bat Productos
    echo   generar_apk.bat Inventario
    echo.
    pause
    exit /b 1
)

set DB_NAME=%~1
set FLUTTER_PROJECT=D:\Desarrollo\Flutter\herramienta_case\herramienta_case
set CONFIG_FILE=%FLUTTER_PROJECT%\lib\core\config\app_build_config.dart
set OUTPUT_FOLDER=D:\Desarrollo\Proyectos\BackFabrica\wwwroot\apks
set PLACEHOLDER={{DB_NAME_PLACEHOLDER}}

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║  GENERADOR DE APK PRE-CONFIGURADA - HERRAMIENTA CASE      ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo 📦 Base de Datos: %DB_NAME%
echo 📂 Proyecto Flutter: %FLUTTER_PROJECT%
echo 📁 Carpeta de Salida: %OUTPUT_FOLDER%
echo.

REM Verificar que existe el proyecto Flutter
if not exist "%FLUTTER_PROJECT%" (
    echo ❌ ERROR: No se encuentra el proyecto Flutter en:
    echo    %FLUTTER_PROJECT%
    echo.
    pause
    exit /b 1
)

REM Verificar que existe el archivo de configuración
if not exist "%CONFIG_FILE%" (
    echo ❌ ERROR: No se encuentra el archivo de configuración:
    echo    %CONFIG_FILE%
    echo.
    pause
    exit /b 1
)

REM Crear carpeta de salida si no existe
if not exist "%OUTPUT_FOLDER%" (
    mkdir "%OUTPUT_FOLDER%"
    echo 📁 Carpeta de salida creada: %OUTPUT_FOLDER%
    echo.
)

REM Guardar el contenido original del archivo
echo 🔧 [1/5] Respaldando configuración original...
copy "%CONFIG_FILE%" "%CONFIG_FILE%.backup" >nul
if errorlevel 1 (
    echo ❌ ERROR: No se pudo crear el respaldo de configuración
    pause
    exit /b 1
)
echo    ✓ Respaldo creado

REM Reemplazar el placeholder en el archivo
echo 🔧 [2/5] Modificando archivo de configuración...
powershell -Command "(Get-Content '%CONFIG_FILE%') -replace '%PLACEHOLDER%', '%DB_NAME%' | Set-Content '%CONFIG_FILE%'"
if errorlevel 1 (
    echo ❌ ERROR: No se pudo modificar el archivo de configuración
    copy "%CONFIG_FILE%.backup" "%CONFIG_FILE%" >nul
    del "%CONFIG_FILE%.backup" >nul
    pause
    exit /b 1
)
echo    ✓ Placeholder reemplazado: '%PLACEHOLDER%' ^→ '%DB_NAME%'

REM Cambiar al directorio del proyecto
cd /d "%FLUTTER_PROJECT%"

REM Limpiar el proyecto
echo 🧹 [3/5] Limpiando proyecto Flutter...
call flutter clean >nul 2>&1
echo    ✓ Proyecto limpiado

REM Compilar la APK
echo 🏗️  [4/5] Compilando APK (esto puede tomar varios minutos)...
echo    ⏳ Compilando... Por favor, espera...
call flutter build apk --release
if errorlevel 1 (
    echo ❌ ERROR: La compilación de Flutter falló
    echo.
    echo 📝 Restaurando configuración original...
    copy "%CONFIG_FILE%.backup" "%CONFIG_FILE%" >nul
    del "%CONFIG_FILE%.backup" >nul
    pause
    exit /b 1
)
echo    ✓ APK compilada exitosamente

REM Copiar APK a la carpeta de descargas con nombre personalizado
echo 📋 [5/5] Copiando APK a carpeta de descargas...

set APK_SOURCE=%FLUTTER_PROJECT%\build\app\outputs\flutter-apk\app-release.apk
if not exist "%APK_SOURCE%" (
    echo ❌ ERROR: No se encontró la APK compilada en:
    echo    %APK_SOURCE%
    echo.
    copy "%CONFIG_FILE%.backup" "%CONFIG_FILE%" >nul
    del "%CONFIG_FILE%.backup" >nul
    pause
    exit /b 1
)

REM Generar nombre con timestamp
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set TIMESTAMP=%datetime:~0,8%_%datetime:~8,6%
set APK_NAME=DataGest_%DB_NAME%_%TIMESTAMP%.apk
set APK_DEST=%OUTPUT_FOLDER%\%APK_NAME%

copy "%APK_SOURCE%" "%APK_DEST%" >nul
if errorlevel 1 (
    echo ❌ ERROR: No se pudo copiar la APK a la carpeta de descargas
    copy "%CONFIG_FILE%.backup" "%CONFIG_FILE%" >nul
    del "%CONFIG_FILE%.backup" >nul
    pause
    exit /b 1
)

REM Obtener tamaño del archivo
for %%A in ("%APK_DEST%") do set APK_SIZE=%%~zA
set /a APK_SIZE_MB=!APK_SIZE! / 1048576
echo    ✓ APK copiada: %APK_NAME%
echo    ✓ Tamaño: !APK_SIZE_MB! MB

REM Restaurar el archivo original
echo ♻️  Restaurando configuración original...
copy "%CONFIG_FILE%.backup" "%CONFIG_FILE%" >nul
del "%CONFIG_FILE%.backup" >nul
echo    ✓ Configuración restaurada

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║  ✅ ¡APK GENERADA EXITOSAMENTE!                            ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo 📦 Ubicación: %APK_DEST%
echo 📱 Nombre: %APK_NAME%
echo 🎯 Base de Datos: %DB_NAME%
echo.
echo 📲 La APK está lista para distribuir. Al instalarla, la app
echo    entrará directamente a la base de datos "%DB_NAME%"
echo    sin mostrar el selector de bases de datos.
echo.

pause
