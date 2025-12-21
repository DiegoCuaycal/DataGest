# Pruebas Unitarias del Módulo de Autenticación (Login)

Este directorio contiene las pruebas unitarias completas para el sistema de autenticación de la aplicación.

## Estructura de Pruebas

```
test/modules/auth/
├── domain/
│   └── entities/
│       └── user_entity_test.dart        # Pruebas de la entidad de usuario
├── data/
│   ├── models/
│   │   └── user_model_test.dart         # Pruebas del modelo de usuario
│   └── repositories/
│       └── auth_repository_test.dart    # Pruebas del repositorio de autenticación
└── presentation/
    └── providers/
        └── auth_provider_test.dart      # Pruebas del provider de autenticación
```

## Cobertura de Pruebas

### 1. UserEntity Tests (6 pruebas)
- Creación de entidad con todas las propiedades
- Creación de entidad mínima (solo token)
- Comparación de igualdad entre entidades
- Comparación de desigualdad
- Representación toString con valores
- Representación toString con valores nulos

**Archivo:** [user_entity_test.dart](domain/entities/user_entity_test.dart)

### 2. UserModel Tests (14 pruebas)
- Creación de modelo con todas las propiedades
- Parsing desde JSON con diferentes formatos
  - Campos estándar (email, nombre)
  - Campos alternativos (usuario, name)
  - Valores predeterminados
  - Solo token
- Conversión a JSON (con y sin valores nulos)
- Método copyWith
- Conversión entre modelo y entidad (toEntity/fromEntity)
- Representación toString
- Comparación con entidad padre

**Archivo:** [user_model_test.dart](data/models/user_model_test.dart)

### 3. AuthRepository Tests (15 pruebas)

#### Login (5 pruebas)
- Login exitoso y retorno de UserEntity
- Almacenamiento en caché después del login
- Manejo de NetworkException
- Manejo de ServerException
- Manejo de errores inesperados

#### Logout (2 pruebas)
- Limpieza de caché en logout exitoso
- Limpieza de caché cuando falla el logout remoto

#### getCachedUser (3 pruebas)
- Retornar UserEntity con datos válidos
- Retornar null cuando caché está vacío
- Retornar null cuando datos son inválidos

#### isAuthenticated (5 pruebas)
- Retornar true cuando existen token y usuario
- Retornar false cuando token es null
- Retornar false cuando token está vacío
- Retornar false cuando usuario es null
- Retornar false cuando ambos son null

**Archivo:** [auth_repository_test.dart](data/repositories/auth_repository_test.dart)

### 4. AuthProvider Tests (18 pruebas)

#### Inicialización (3 pruebas)
- Establecer isAuthenticated cuando existe sesión
- Establecer isAuthenticated como false sin sesión
- Manejo de errores durante inicialización

#### Login (7 pruebas)
- Login exitoso y actualización de estado
- Fallo de login y establecimiento de error
- Manejo de NetworkException
- Manejo de credenciales inválidas
- Manejo de timeout
- Manejo de errores del servidor
- Limpieza de errores previos

#### Logout (2 pruebas)
- Limpieza de estado en logout exitoso
- Limpieza de estado cuando logout falla

#### Getters (2 pruebas)
- Retornar currentUser correcto
- Retornar estado isAuthenticated correcto

#### Mensajes de Error (3 pruebas)
- Mensaje amigable para credenciales incorrectas
- Mensaje amigable para problemas de red
- Mensaje genérico para errores desconocidos

#### Dispose (1 prueba)
- Limpieza de estado en dispose

**Archivo:** [auth_provider_test.dart](presentation/providers/auth_provider_test.dart)

## Ejecutar las Pruebas

### Todas las pruebas de autenticación
```bash
flutter test test/modules/auth/
```

### Pruebas específicas
```bash
# Solo entidades
flutter test test/modules/auth/domain/

# Solo modelos
flutter test test/modules/auth/data/models/

# Solo repositorio
flutter test test/modules/auth/data/repositories/

# Solo provider
flutter test test/modules/auth/presentation/providers/
```

### Todas las pruebas del proyecto
```bash
flutter test
```

### Con reporte expandido
```bash
flutter test --reporter expanded
```

## Tecnologías Utilizadas

- **flutter_test**: Framework de pruebas de Flutter
- **mockito**: Generación de mocks para dependencias
- **build_runner**: Generación de código para mocks

## Dependencias de Desarrollo

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  build_runner: ^2.4.13
```

## Generar Mocks

Si necesitas regenerar los archivos mock después de modificar las clases:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Resultados Actuales

**Total de pruebas: 53**
- UserEntity: 6 pruebas ✅
- UserModel: 14 pruebas ✅
- AuthRepository: 15 pruebas ✅
- AuthProvider: 18 pruebas ✅

**Estado: Todas las pruebas pasando** 🎉

## Casos de Prueba Principales

### Flujo de Login Exitoso
1. Usuario ingresa credenciales válidas
2. AuthProvider llama a AuthRepository
3. AuthRepository llama a AuthRemoteDataSource
4. Usuario se almacena en caché local
5. Estado se actualiza con usuario autenticado

### Flujo de Login Fallido
1. Usuario ingresa credenciales inválidas
2. Se lanza una excepción
3. AuthProvider captura la excepción
4. Se genera un mensaje de error amigable
5. Estado se actualiza con el error

### Flujo de Logout
1. Usuario solicita cerrar sesión
2. Se llama al endpoint de logout
3. Se limpia el caché local
4. Estado se actualiza sin usuario

### Persistencia de Sesión
1. Usuario cierra la aplicación
2. Usuario abre la aplicación
3. AuthProvider verifica caché
4. Si existe token y usuario, restaura la sesión

## Buenas Prácticas Implementadas

- ✅ Patrón AAA (Arrange-Act-Assert)
- ✅ Nombres descriptivos de pruebas
- ✅ Aislamiento de pruebas con mocks
- ✅ Cobertura de casos exitosos y de error
- ✅ Pruebas de comportamiento, no de implementación
- ✅ Organización por funcionalidad
- ✅ Documentación clara

## Próximos Pasos

Para extender la cobertura de pruebas, considera agregar:

1. **Pruebas de Integración**: Probar el flujo completo de UI a datos
2. **Pruebas de Widget**: Probar LoginForm y LoginScreen
3. **Pruebas de AuthRemoteDataSource**: Probar la capa de red
4. **Pruebas de Rendimiento**: Medir tiempos de respuesta
5. **Pruebas de Accesibilidad**: Validar que la UI sea accesible
