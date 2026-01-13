using System;
using System.IO;
using System.Diagnostics;
using System.Text;

namespace HerramientaCASE.Tools
{
    /// <summary>
    /// Generador de APK Pre-Configurada para Herramienta CASE
    ///
    /// Este script genera APKs personalizadas para bases de datos específicas.
    /// Al ejecutarse:
    /// 1. Modifica el archivo app_build_config.dart reemplazando el placeholder
    /// 2. Compila la APK con Flutter
    /// 3. Restaura el archivo original
    /// 4. Copia la APK a la carpeta de descargas
    /// </summary>
    public class GeneradorAPK
    {
        // Configuración de rutas
        private const string FLUTTER_PROJECT_PATH = @"D:\Desarrollo\Flutter\herramienta_case\herramienta_case";
        private const string CONFIG_FILE_PATH = @"lib\core\config\app_build_config.dart";
        private const string OUTPUT_FOLDER = @"D:\Desarrollo\Proyectos\BackFabrica\wwwroot\apks";
        private const string PLACEHOLDER = "{{DB_NAME_PLACEHOLDER}}";

        private readonly string _flutterProjectPath;
        private readonly string _configFilePath;
        private readonly string _outputFolder;
        private string _originalContent = string.Empty;

        public GeneradorAPK(
            string flutterProjectPath = FLUTTER_PROJECT_PATH,
            string outputFolder = OUTPUT_FOLDER)
        {
            _flutterProjectPath = flutterProjectPath;
            _configFilePath = Path.Combine(_flutterProjectPath, CONFIG_FILE_PATH);
            _outputFolder = outputFolder;
        }

        /// <summary>
        /// Genera una APK pre-configurada para una base de datos específica
        /// </summary>
        /// <param name="nombreBaseDatos">Nombre de la base de datos (ej: "Productos")</param>
        /// <returns>Ruta de la APK generada</returns>
        public string GenerarApk(string nombreBaseDatos)
        {
            try
            {
                Console.WriteLine($"╔════════════════════════════════════════════════════════════╗");
                Console.WriteLine($"║  GENERADOR DE APK PRE-CONFIGURADA - HERRAMIENTA CASE      ║");
                Console.WriteLine($"╚════════════════════════════════════════════════════════════╝");
                Console.WriteLine();
                Console.WriteLine($"📦 Base de Datos: {nombreBaseDatos}");
                Console.WriteLine($"📂 Proyecto Flutter: {_flutterProjectPath}");
                Console.WriteLine($"📁 Carpeta de Salida: {_outputFolder}");
                Console.WriteLine();

                // Validaciones
                ValidarConfiguracion(nombreBaseDatos);

                // Paso 1: Respaldar y modificar archivo de configuración
                Console.WriteLine("🔧 [1/5] Modificando archivo de configuración...");
                ModificarConfiguracion(nombreBaseDatos);

                // Paso 2: Limpiar compilaciones anteriores
                Console.WriteLine("🧹 [2/5] Limpiando compilaciones anteriores...");
                LimpiarProyecto();

                // Paso 3: Compilar APK
                Console.WriteLine("🏗️  [3/5] Compilando APK (esto puede tomar varios minutos)...");
                CompilarApk();

                // Paso 4: Copiar APK a carpeta de descargas
                Console.WriteLine("📋 [4/5] Copiando APK a carpeta de descargas...");
                string rutaApk = CopiarApk(nombreBaseDatos);

                // Paso 5: Restaurar archivo original
                Console.WriteLine("♻️  [5/5] Restaurando archivo de configuración...");
                RestaurarConfiguracion();

                Console.WriteLine();
                Console.WriteLine("✅ ¡APK generada exitosamente!");
                Console.WriteLine($"📦 Ubicación: {rutaApk}");
                Console.WriteLine($"📱 Nombre: DataGest_{nombreBaseDatos}.apk");
                Console.WriteLine();

                return rutaApk;
            }
            catch (Exception ex)
            {
                Console.WriteLine();
                Console.WriteLine($"❌ ERROR: {ex.Message}");
                Console.WriteLine();

                // Intentar restaurar el archivo original en caso de error
                try
                {
                    if (!string.IsNullOrEmpty(_originalContent))
                    {
                        Console.WriteLine("⚠️  Restaurando archivo de configuración...");
                        RestaurarConfiguracion();
                    }
                }
                catch (Exception restoreEx)
                {
                    Console.WriteLine($"⚠️  Error al restaurar configuración: {restoreEx.Message}");
                }

                throw;
            }
        }

        private void ValidarConfiguracion(string nombreBaseDatos)
        {
            if (string.IsNullOrWhiteSpace(nombreBaseDatos))
            {
                throw new ArgumentException("El nombre de la base de datos no puede estar vacío");
            }

            if (!Directory.Exists(_flutterProjectPath))
            {
                throw new DirectoryNotFoundException($"No se encuentra el proyecto Flutter en: {_flutterProjectPath}");
            }

            if (!File.Exists(_configFilePath))
            {
                throw new FileNotFoundException($"No se encuentra el archivo de configuración en: {_configFilePath}");
            }

            // Crear carpeta de salida si no existe
            if (!Directory.Exists(_outputFolder))
            {
                Directory.CreateDirectory(_outputFolder);
                Console.WriteLine($"📁 Carpeta de salida creada: {_outputFolder}");
            }
        }

        private void ModificarConfiguracion(string nombreBaseDatos)
        {
            // Leer contenido original
            _originalContent = File.ReadAllText(_configFilePath, Encoding.UTF8);

            // Verificar que el archivo contiene el placeholder
            if (!_originalContent.Contains(PLACEHOLDER))
            {
                throw new InvalidOperationException(
                    $"El archivo de configuración no contiene el placeholder '{PLACEHOLDER}'. " +
                    "Asegúrate de que el archivo app_build_config.dart no ha sido modificado manualmente.");
            }

            // Reemplazar placeholder con el nombre de la base de datos
            string nuevoContenido = _originalContent.Replace(PLACEHOLDER, nombreBaseDatos);

            // Escribir archivo modificado
            File.WriteAllText(_configFilePath, nuevoContenido, Encoding.UTF8);

            Console.WriteLine($"   ✓ Placeholder reemplazado: '{PLACEHOLDER}' → '{nombreBaseDatos}'");
        }

        private void LimpiarProyecto()
        {
            ExecutarComando("flutter", "clean", _flutterProjectPath);
            Console.WriteLine("   ✓ Proyecto limpiado");
        }

        private void CompilarApk()
        {
            Console.WriteLine("   ⏳ Compilando... (este proceso puede tardar 5-10 minutos)");
            ExecutarComando("flutter", "build apk --release", _flutterProjectPath);
            Console.WriteLine("   ✓ APK compilada exitosamente");
        }

        private string CopiarApk(string nombreBaseDatos)
        {
            // Ruta de la APK generada por Flutter
            string apkSource = Path.Combine(_flutterProjectPath, @"build\app\outputs\flutter-apk\app-release.apk");

            if (!File.Exists(apkSource))
            {
                throw new FileNotFoundException($"No se encontró la APK compilada en: {apkSource}");
            }

            // Nombre personalizado para la APK
            string timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
            string nombreApk = $"DataGest_{nombreBaseDatos}_{timestamp}.apk";
            string apkDestination = Path.Combine(_outputFolder, nombreApk);

            // Copiar APK
            File.Copy(apkSource, apkDestination, overwrite: true);

            // Obtener tamaño del archivo
            long tamanoBytes = new FileInfo(apkDestination).Length;
            double tamanoMB = tamanoBytes / 1024.0 / 1024.0;

            Console.WriteLine($"   ✓ APK copiada: {nombreApk}");
            Console.WriteLine($"   ✓ Tamaño: {tamanoMB:F2} MB");

            return apkDestination;
        }

        private void RestaurarConfiguracion()
        {
            if (string.IsNullOrEmpty(_originalContent))
            {
                throw new InvalidOperationException("No hay contenido original para restaurar");
            }

            File.WriteAllText(_configFilePath, _originalContent, Encoding.UTF8);
            Console.WriteLine($"   ✓ Configuración restaurada (placeholder: '{PLACEHOLDER}')");
        }

        private void ExecutarComando(string comando, string argumentos, string workingDirectory)
        {
            ProcessStartInfo startInfo = new ProcessStartInfo
            {
                FileName = comando,
                Arguments = argumentos,
                WorkingDirectory = workingDirectory,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            using (Process process = Process.Start(startInfo))
            {
                if (process == null)
                {
                    throw new InvalidOperationException($"No se pudo iniciar el proceso: {comando}");
                }

                // Leer salida en tiempo real (opcional, para debugging)
                string output = process.StandardOutput.ReadToEnd();
                string error = process.StandardError.ReadToEnd();

                process.WaitForExit();

                if (process.ExitCode != 0)
                {
                    throw new InvalidOperationException(
                        $"El comando '{comando} {argumentos}' falló con código {process.ExitCode}\n" +
                        $"Error: {error}");
                }
            }
        }

        /// <summary>
        /// Punto de entrada para uso desde línea de comandos
        /// </summary>
        static void Main(string[] args)
        {
            try
            {
                if (args.Length == 0)
                {
                    Console.WriteLine("Uso: GeneradorAPK <nombreBaseDatos>");
                    Console.WriteLine("Ejemplo: GeneradorAPK Productos");
                    return;
                }

                string nombreBaseDatos = args[0];
                var generador = new GeneradorAPK();
                string rutaApk = generador.GenerarApk(nombreBaseDatos);

                Console.WriteLine("Presiona cualquier tecla para salir...");
                Console.ReadKey();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error fatal: {ex.Message}");
                Console.WriteLine(ex.StackTrace);
                Console.WriteLine();
                Console.WriteLine("Presiona cualquier tecla para salir...");
                Console.ReadKey();
                Environment.Exit(1);
            }
        }
    }
}
