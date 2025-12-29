# DataGest - Frontend Flutter

Sistema de gestión de Herramientas CASE con autenticación, desarrollado en Flutter siguiendo Clean Architecture.

## 🏗️ Arquitectura

El proyecto sigue **Clean Architecture** con la siguiente estructura modular:

```
lib/
├── core/                  # Funcionalidades base
│   ├── config/           # Configuración (rutas, env, app)
│   ├── constants/        # Constantes (colores, strings, estilos)
│   ├── errors/           # Manejo de errores y excepciones
│   ├── network/          # Cliente HTTP y endpoints
│   └── utils/            # Utilidades (validadores, helpers)
├── shared/               # Componentes compartidos
│   ├── widgets/          # Widgets reutilizables
│   └── providers/        # Providers base
└── modules/              # Módulos de la aplicación
    ├── auth/             # Autenticación
    ├── database_selector/ # Selección de base de datos
    ├── table_list/       # Listado de tablas
    └── dynamic_crud/     # CRUD dinámico
```

## 📦 Dependencias

- **provider**: State management
- **http**: Cliente HTTP
- **flutter_dotenv**: Variables de entorno
- **shared_preferences**: Almacenamiento local
- **equatable**: Comparación de objetos

## 🚀 Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/DiegoCuaycal/DataGest.git
cd herramienta_case
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar variables de entorno

El archivo `.env` debe contener la URL del backend de Azure:

```env
API_URL=https://backfabrica20251213173926-c4a0e0h6dhatanev.canadacentral-01.azurewebsites.net
API_TIMEOUT=30
DEBUG=true
```

### 4. Ejecutar la aplicación

```bash
flutter run
```

## 🎯 Funcionalidades Implementadas

### ✅ Módulo de Autenticación
- [x] Login con validación de formulario
- [x] Almacenamiento seguro de token
- [x] Persistencia de sesión
- [x] Logout
- [x] Conexión con backend .NET en Azure

### ✅ Módulo de Selección de Base de Datos
- [x] Listado de bases de datos disponibles
- [x] Selección dinámica de BD
- [x] Navegación a listado de tablas

### ✅ Módulo de Listado de Tablas
- [x] Obtención de metadatos de BD seleccionada
- [x] Visualización de todas las tablas
- [x] Navegación al CRUD de cada tabla

### ✅ Módulo CRUD Dinámico
- [x] Listado de registros con paginación
- [x] Búsqueda en registros
- [x] Crear nuevos registros
- [x] Editar registros existentes
- [x] Eliminar registros
- [x] Formularios dinámicos basados en metadatos
- [x] Soporte para llaves foráneas con dropdowns
- [x] Validación de campos

### ✅ Componentes Compartidos
- [x] CustomButton (con estado de carga)
- [x] CustomTextField (con validación)
- [x] EmailTextField
- [x] PasswordTextField
- [x] LoadingIndicator
- [x] EmptyStateWidget
- [x] ErrorStateWidget

## 🔌 Endpoints del Backend

El backend está desplegado en Azure:
```
https://backfabrica20251213173926-c4a0e0h6dhatanev.canadacentral-01.azurewebsites.net
```

### Autenticación
- `POST /api/Auth/login` - Login inicial
- `POST /api/{db}/auth/login` - Login a base de datos específica

### Bases de Datos
- `GET /api/Schema/databases` - Obtener lista de bases de datos

### Metadatos
- `GET /api/Schema/generate?db={dbName}` - Obtener metadatos de una BD

### CRUD Dinámico
- `GET /api/{db}/table/{table}` - Listar registros de una tabla
- `GET /api/{db}/table/{table}/{id}` - Obtener un registro por ID
- `POST /api/{db}/table/{table}` - Crear un nuevo registro
- `PUT /api/{db}/table/{table}/{id}` - Actualizar un registro
- `DELETE /api/{db}/table/{table}/{id}` - Eliminar un registro
- `GET /api/{db}/table/{table}/dropdown` - Obtener opciones para dropdowns (relaciones)

## 📱 Pantallas Disponibles

| Ruta | Pantalla | Descripción |
|------|----------|-------------|
| `/` | LoginScreen | Inicio de sesión |
| `/database-selector` | DatabaseSelectorScreen | Selección de base de datos |
| `/table-list` | TableListScreen | Lista de tablas de la BD |
| `/record-list` | RecordListScreen | Lista de registros de una tabla |
| `/record-form` | RecordFormScreen | Crear/Editar registro |


## 🛠️ Comandos Útiles

### Limpiar proyecto
```bash
flutter clean
flutter pub get
```

### Ejecutar en modo release
```bash
flutter run --release
```

### Generar APK
```bash
flutter build apk --release
```

### Analizar código
```bash
flutter analyze
```

## 🐛 Solución de Problemas

### Error: "No se puede conectar con la API"
- Verifica que el backend de Azure esté activo
- Revisa la URL en `.env`
- Verifica tu conexión a internet

### Error: "Sesión expirada"
- El token JWT puede haber expirado
- Vuelve a iniciar sesión

### Error en Android Emulator
- Si usas un emulador local con backend local, usa `http://10.0.2.2:puerto`
- Para Azure, usa la URL completa proporcionada

## 📄 Licencia

Este proyecto es privado y confidencial.

---

**Desarrollado con ❤️ usando Flutter y Clean Architecture**
