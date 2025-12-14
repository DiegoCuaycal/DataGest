# Herramientas CASE - Frontend Flutter

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
    ├── home/             # Pantalla principal
    └── case_tools/       # Gestión de herramientas CASE
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
git clone <repository-url>
cd herramienta_case
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar variables de entorno

El archivo `.env` ya está creado con valores por defecto. Puedes modificarlo según tu backend:

```env
API_URL=http://localhost:5000/api
API_TIMEOUT=30
DEBUG=true
```

### 4. Ejecutar la aplicación

```bash
flutter run
```

## 🔐 Credenciales de Prueba (Mock)

Para probar la aplicación **sin backend**:

- **Email**: admin@test.com
- **Password**: 123456

## 🎯 Funcionalidades Implementadas

### ✅ Módulo de Autenticación
- [x] Login con validación de formulario
- [x] Almacenamiento seguro de token
- [x] Persistencia de sesión
- [x] Logout
- [x] Mock de API para pruebas sin backend

### ✅ Módulo Home
- [x] Pantalla principal con saludo al usuario
- [x] Menú lateral (drawer) con navegación
- [x] Tarjetas de acceso rápido
- [x] Diseño responsive

### ✅ Módulo Herramientas CASE
- [x] Lista de herramientas con búsqueda
- [x] Detalle de herramienta
- [x] Datos mock para pruebas
- [x] UI responsive

### ✅ Componentes Compartidos
- [x] CustomButton (con estado de carga)
- [x] CustomTextField (con validación)
- [x] EmailTextField
- [x] PasswordTextField
- [x] LoadingIndicator
- [x] EmptyStateWidget
- [x] ErrorStateWidget

## 🔌 Conexión con Backend .NET

Cuando el backend esté listo, realiza los siguientes cambios:

### 1. Actualizar `.env`

```env
API_URL=https://tu-backend.com/api
```

### 2. Cambiar de mock a API real

En `lib/modules/auth/data/repositories/auth_repository.dart`:

```dart
// CAMBIAR ESTO:
final userModel = await remoteDataSource.mockLogin(
  email: email,
  password: password,
);

// POR ESTO:
final userModel = await remoteDataSource.login(
  email: email,
  password: password,
);
```

### 3. Implementar data sources para herramientas

Crear `ToolRemoteDataSource` similar a `AuthRemoteDataSource` y conectar con el repositorio.

## 📱 Pantallas Disponibles

| Ruta | Pantalla | Descripción |
|------|----------|-------------|
| `/` | LoginScreen | Inicio de sesión |
| `/home` | HomeScreen | Dashboard principal |
| `/tools` | ToolsListScreen | Lista de herramientas CASE |
| `/tools/detail` | ToolDetailScreen | Detalle de una herramienta |

## 🎨 Personalización

### Colores

Edita `lib/core/constants/app_colors.dart`:

```dart
static const Color primary = Color(0xFF2196F3); // Azul
static const Color secondary = Color(0xFF00BCD4); // Cyan
```

### Textos

Edita `lib/core/constants/app_strings.dart`:

```dart
static const String appName = 'Tu App Name';
```

### Estilos

Edita `lib/core/constants/app_styles.dart` para modificar estilos de texto, espaciados y decoraciones.

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

## 📋 Checklist de Implementación

### Backend Integrado
- [ ] Actualizar URL de API en `.env`
- [ ] Cambiar `mockLogin` por `login` en AuthRepository
- [ ] Implementar ToolRemoteDataSource
- [ ] Conectar con endpoints reales
- [ ] Manejar errores del servidor

### Funcionalidades Futuras
- [ ] Recuperación de contraseña
- [ ] Registro de nuevos usuarios
- [ ] CRUD completo de herramientas CASE
- [ ] Filtros por categoría
- [ ] Paginación en listas
- [ ] Modo offline
- [ ] Tests unitarios e integración

## 🐛 Solución de Problemas

### Error: "No se puede conectar con la API"
- Verifica que el backend esté ejecutándose
- Revisa la URL en `.env`
- En Android, usa `http://10.0.2.2:5000` en lugar de `localhost`

### Error: "Sesión expirada"
- El token JWT puede haber expirado
- Implementar refresh token en futuras versiones

## 📄 Licencia

Este proyecto es privado y confidencial.

---

**Desarrollado con ❤️ usando Flutter y Clean Architecture**
