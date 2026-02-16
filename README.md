# DataGest - Dynamic Database Management Platform

> Full-stack enterprise application for dynamic database management with automatic CRUD generation, built with **Flutter** (Mobile) + **.NET 8 Web API** (Backend) + **SQL Server** (Database).


## Overview

**DataGest** is a full-stack platform that dynamically generates CRUD interfaces from any SQL Server database schema at runtime. Instead of writing static screens for each table, the system introspects the database metadata (tables, columns, primary keys, foreign keys, data types) and automatically renders:

- Typed form fields (text, number, date picker, checkbox, dropdown)
- Data tables with pagination, search, and sorting
- Foreign key resolution with relational dropdowns
- Field validation based on column constraints

The platform also includes an **APK Builder** that compiles customized Flutter apps on-demand from a web interface, injecting the target database schema at build time.

---

## Repositories

| Project | Repository |
|---------|-----------|
| **Backend** (.NET 8 Web API) | [github.com/rodman751/BackFabrica](https://github.com/rodman751/BackFabrica) |
| **Frontend** (Flutter Mobile App) | This repository |

### Business Value

- Eliminates repetitive CRUD boilerplate for new database modules
- Supports multiple business domains (Education, Healthcare, Inventory) from a single codebase
- Enables non-technical users to manage data through auto-generated interfaces
- Reduces development time from weeks to minutes for standard data management screens

---

## Key Features

| Feature | Description |
|---------|-------------|
| **Dynamic CRUD Engine** | Auto-generates Create, Read, Update, Delete interfaces from database metadata |
| **Schema Introspection** | Reads SQL Server schema via stored procedures to extract tables, columns, PKs, FKs, and data types |
| **Multi-Database Support** | Connect to any SQL Server database at runtime via connection profiles |
| **Foreign Key Dropdowns** | Automatically detects FK relationships and renders relational dropdowns |
| **Type-Safe Forms** | Maps SQL types (varchar, int, decimal, datetime, bit) to appropriate Flutter input widgets |
| **Field Validation** | Enforces required fields, max length, numeric ranges, and date constraints from column metadata |
| **JWT Authentication** | Secure login with role-based access and token-based session management |
| **SQL File Import** | Parse `.sql` CREATE TABLE scripts and provision new databases on the fly |
| **Data Export** | Export table data to CSV or JSON with configurable columns and limits |
| **APK Builder** | Server-side Flutter compilation that generates customized APKs per database |
| **Connection Profiles** | Support for multiple SQL Server instances (Local, Azure, Remote, ngrok tunnels) |
| **Pagination & Search** | Client-side pagination with real-time search filtering across all columns |

---

## System Architecture

```
+------------------+       HTTPS/JWT        +---------------------+       Dapper/SP       +----------------+
|                  | ---------------------> |                     | ------------------->  |                |
|   Flutter App    |   REST API + Headers   |   .NET 8 Web API    |   Dynamic SQL         |   SQL Server   |
|   (Mobile)       | <--------------------- |   (BackFabrica)     | <-------------------  |   (Multi-DB)   |
|                  |       JSON Response    |                     |   Schema Metadata     |                |
+------------------+                        +---------------------+                       +----------------+
        |                                           |
        | Provider                                  | MVC
        | (State Mgmt)                              | (Web UI)
        v                                           v
+------------------+                        +---------------------+
| Clean Architecture|                       |   GenAPK (MVC)      |
| - Presentation   |                        |   - APK Builder     |
| - Domain         |                        |   - Source Export    |
| - Data           |                        |   - Connection Mgmt |
+------------------+                        +---------------------+
```

### Communication Flow

1. **Mobile App** sends requests with headers: `Authorization` (JWT), `X-DbName` (target database), `X-Connection-Profile` (server profile)
2. **Backend API** resolves the connection profile, builds a dynamic connection string using `string.Format(template, dbName)`, and executes queries via **Dapper**
3. **Schema Introspection** is handled by the stored procedure `sp_GetDatabaseSchema`, which returns the full schema as JSON (tables, columns, PKs, FKs, identity columns)
4. **Dynamic CRUD** operations build SQL statements at runtime, validating column names against the schema to prevent injection

---

## Tech Stack

### Backend

| Technology | Version | Purpose |
|-----------|---------|---------|
| .NET | 8.0 | Runtime framework |
| ASP.NET Core Web API | 8.0 | RESTful API layer |
| ASP.NET Core MVC | 8.0 | Web UI for APK generation (GenAPK project) |
| Dapper | 2.1.66 | Micro-ORM for high-performance data access |
| Microsoft.Data.SqlClient | 6.1.3 | SQL Server connectivity |
| JWT Bearer Authentication | 8.0.22 | Token-based authentication |
| Swashbuckle (Swagger) | 6.6.2 | API documentation |
| SQL Server | 2019+ | Relational database engine |

### Frontend (Mobile)

| Technology | Version | Purpose |
|-----------|---------|---------|
| Flutter | 3.x | Cross-platform mobile framework |
| Dart | 3.x | Programming language |
| Provider | 6.1.2 | State management (ChangeNotifier) |
| http | 1.2.2 | HTTP client for API communication |
| flutter_dotenv | 5.2.1 | Environment variable management |
| shared_preferences | 2.3.3 | Local key-value storage |
| equatable | 2.0.7 | Value equality for entities |
| intl | 0.19.0 | Internationalization and date formatting |
| csv | 6.0.0 | CSV file generation |
| path_provider | 2.1.5 | Device file system access |
| file_picker | 8.0.0 | SQL file selection for import |
| lottie | 3.2.0 | Animated UI elements |
| permission_handler | 11.3.1 | Runtime permission management |

---

## Backend - .NET 8 Web API

### Solution Structure

The backend follows a **layered architecture** with clear separation of concerns across 4 projects:

```
BackFabrica.sln
│
├── BackFabrica/              # API Layer - REST Controllers + Swagger + DI
│   └── Controllers/          #   Auth, DynamicCrud, Schema, Productos, Educacion, Salud
│
├── CapaDapper/               # Data Access Layer - Dapper micro-ORM
│   ├── Cadena/               #   Dynamic connection factory + DB context per request
│   ├── DataService/          #   Repositories (DynamicCrud, Schema, domain-specific)
│   ├── Dtos/                 #   Data Transfer Objects (Schema, Login, Requests)
│   └── Entidades/            #   Domain entities (Educacion, Productos, Salud)
│
├── Services/                 # Business Logic Layer
│                             #   JWT auth service, APK builder, interfaces
│
└── GenAPK/                   # MVC Web App - APK Generator
                              #   Web UI to compile customized Flutter APKs
```

> Full source code: [github.com/rodman751/BackFabrica](https://github.com/rodman751/BackFabrica)

### Key Backend Patterns

**Dynamic Connection String Resolution:**
```
Request Header (X-Connection-Profile) → appsettings.json profile lookup
    → Connection template with {0} placeholder → string.Format(template, CurrentDb)
        → SqlConnection ready for Dapper queries
```

**Dynamic SQL Generation (DynamicCrudService):**
- **INSERT:** Filters out identity columns, builds parameterized `INSERT INTO` with Dapper `DynamicParameters`
- **UPDATE:** Locates PK from schema, builds `SET` clauses excluding PK, parameterized `WHERE`
- **SELECT ALL:** Validates table against schema, executes `SELECT *` with schema prefix
- **GET BY ID:** Resolves PK column name from `pk_info`, parameterized `WHERE [PK] = @Id`

**Schema-Driven Security:**
- All dynamic queries validate table and column names against the schema definition before execution
- Column names are bracket-escaped `[ColumnName]` to prevent SQL injection
- Identity columns are automatically excluded from INSERT operations
- PascalCase/camelCase to snake_case mapping for frontend-backend interoperability

---

## Frontend - Flutter Mobile App

### Architecture: Clean Architecture + Provider

```
lib/
├── core/          # Config, constants, errors, network layer, services
├── modules/       # Feature modules (auth, dynamic_crud, export, home, settings...)
└── shared/        # Reusable widgets and base providers
```

Each module follows `data/` (API + repositories) → `domain/` (entities + services) → `presentation/` (providers + screens).

**9 modules:** Auth, Dynamic CRUD, Database Selector, Database Creator, Export, Home, Notifications, Settings, Help.

### Dynamic CRUD Flow

The core feature auto-generates CRUD screens at runtime:

1. User selects a database → backend returns full schema (tables, columns, PKs, FKs)
2. App renders the table list → user picks a table → fetches records with pagination
3. Forms are generated dynamically: SQL types map to Flutter widgets (TextField, DatePicker, Checkbox, Dropdown for FKs)
4. On submit, the backend validates columns against the schema and executes parameterized SQL

### State Management Architecture

```
MultiProvider (main.dart)
├── ChangeNotifierProvider<AuthProvider>
│   └── AuthRepository → AuthRemoteDataSource → API
├── ChangeNotifierProvider<DatabaseSelectorProvider>
│   └── DatabaseRepository → DatabaseRemoteDataSource → API
├── ChangeNotifierProvider<MetadataProvider>
│   └── DynamicCrudRepository → DynamicRemoteDataSource → API
├── ChangeNotifierProvider<DynamicCrudProvider>
│   └── DynamicCrudRepository (shared)
├── ChangeNotifierProvider<ExportProvider>
│   └── ExportRepository → ExportService → File System
├── ChangeNotifierProvider<NotificationProvider>
└── ChangeNotifierProvider<RecentActivityProvider>
```

---

## API Reference

### Authentication

| Method | Endpoint | Headers | Description |
|--------|----------|---------|-------------|
| POST | `/api/Auth/login` | `X-DbName`, `X-Usuario`, `X-Password` | Authenticate user, returns JWT + user data |
| POST | `/api/Auth/crear-modulo` | `Authorization: Bearer {token}` | Create new database module from JSON schema |

### Schema Introspection

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/Schema/databases` | List all available databases (excludes system DBs) |
| GET | `/api/Schema/generate?db={name}` | Get full schema JSON (tables, columns, PKs, FKs, types) |

### Dynamic CRUD (V2)

| Method | Endpoint | Body | Description |
|--------|----------|------|-------------|
| POST | `/api/DynamicCrud/V2/GETALL?tableName={t}` | `{ Schema, Data: null }` | Fetch all records |
| POST | `/api/DynamicCrud/V2/GETBYID/{id}?tableName={t}` | `{ Schema }` | Fetch single record by PK |
| POST | `/api/DynamicCrud/V2/CREADTE?tableName={t}` | `{ Schema, Data }` | Insert new record |
| POST | `/api/DynamicCrud/V2/UPDATE?tableName={t}` | `{ Schema, Data }` | Update existing record |

### Domain-Specific Endpoints

<details>
<summary><strong>Products Module</strong> (ProductosController)</summary>

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/Productos` | List all products |
| GET | `/api/Productos/{id}` | Get product by ID |
| POST | `/api/Productos` | Create product |
| PUT | `/api/Productos/{id}` | Update product |
| DELETE | `/api/Productos/{id}` | Delete product |
| GET | `/api/Productos/categorias` | List categories |
| POST | `/api/Productos/categorias` | Create category |
| GET | `/api/Productos/proveedores` | List suppliers |
| POST | `/api/Productos/proveedores` | Create supplier |
| GET | `/api/Productos/inventario` | List inventory |
| POST | `/api/Productos/inventario/ajustar` | Adjust stock level |

</details>

<details>
<summary><strong>Education Module</strong> (EducacionController) - [Authorize]</summary>

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/Educacion/estudiantes` | List students |
| POST | `/api/Educacion/estudiantes` | Enroll student |
| GET | `/api/Educacion/profesores` | List professors |
| POST | `/api/Educacion/profesores` | Register professor |
| GET | `/api/Educacion/cursos` | List courses |
| POST | `/api/Educacion/cursos` | Create course |
| POST | `/api/Educacion/inscribir` | Enroll student in course |
| POST | `/api/Educacion/calificar` | Submit grade |
| GET | `/api/Educacion/historial/{studentId}` | Academic transcript |

</details>

<details>
<summary><strong>Healthcare Module</strong> (SaludController)</summary>

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/Salud/pacientes` | List patients |
| GET | `/api/Salud/pacientes/buscar/{dni}` | Find patient by DNI |
| POST | `/api/Salud/pacientes` | Register patient |
| GET | `/api/Salud/medicos` | List doctors |
| POST | `/api/Salud/medicos` | Register doctor |
| POST | `/api/Salud/citas` | Schedule appointment |
| GET | `/api/Salud/citas/agenda/{doctorId}` | Doctor's schedule |
| POST | `/api/Salud/diagnosticos` | Record diagnosis |

</details>

All domain endpoints require the `X-DbName` header to specify the target database.

---

## Database Design

### Multi-Database Architecture

The system uses a **template connection string** pattern where the database name is injected at runtime:

```
Server={host};Database={0};User Id={user};Password={pass};...
                         ↑
              Replaced with selected DB name
```

### Connection Profile System

Multiple server profiles are configured in `appsettings.json`:

```json
{
  "ConnectionProfiles": {
    "Local":    { "ConnectionString": "Server=localhost;Database={0};..." },
    "Azure":    { "ConnectionString": "Server=azure.database.windows.net;Database={0};..." },
    "Remote":   { "ConnectionString": "Server=vpn-host;Database={0};..." }
  }
}
```

Profile selection priority:
1. `X-Connection-Profile` HTTP header (API/Mobile)
2. Session variable (MVC Web)
3. Default fallback (`TemplateConnection`)

### Schema Introspection

The stored procedure `sp_GetDatabaseSchema` returns a JSON object containing:

```json
{
  "database_name": "EducacionDB",
  "tables": [
    { "schema": "dbo", "table": "Estudiantes" }
  ],
  "columns": [
    { "table": "Estudiantes", "name": "Id", "type": "int", "is_identity": true },
    { "table": "Estudiantes", "name": "Nombre", "type": "varchar", "is_identity": false }
  ],
  "pk_info": [
    { "table": "Estudiantes", "column": "Id" }
  ]
}
```

### Supported Business Domains

| Domain | Tables | Description |
|--------|--------|-------------|
| **Education** | Estudiantes, Profesores, Cursos, Inscripciones | Academic management with enrollment and grading |
| **Healthcare** | Pacientes, Medicos, Citas, Diagnosticos | Clinical management with appointments and medical records |
| **Products** | Productos, Categorias, Proveedores, Inventario | Inventory management with stock adjustment |

---

## Design Patterns

### Backend Patterns

| Pattern | Implementation | Location |
|---------|---------------|----------|
| **Repository Pattern** | `IProductosRepository`, `IEducacionRepository`, `ISaludRepository` | `CapaDapper/DataService/` |
| **Dependency Injection** | `builder.Services.AddScoped<>()` | `Program.cs` |
| **Factory Pattern** | `DbConnectionFactory.CreateConnection()` | `CapaDapper/Cadena/` |
| **Strategy Pattern** | Connection profile resolution (Header → Session → Default) | `DbConnectionFactory.cs` |
| **DTO Pattern** | `DbSchema`, `DynamicRequestDto`, `LoginResponseDto` | `CapaDapper/Dtos/` |
| **Scoped Context** | `DatabaseContext.CurrentDb` per-request database selection | `CapaDapper/Cadena/` |
| **Service Layer** | `AuthService` (JWT generation), `ApkBuilderService` | `Services/` |
| **Dynamic SQL Builder** | Runtime query construction from schema metadata | `DynamicCrudService.cs` |

### Frontend Patterns

| Pattern | Implementation | Location |
|---------|---------------|----------|
| **Clean Architecture** | Presentation → Domain → Data layers per module | `lib/modules/` |
| **Repository Pattern** | `AuthRepository`, `DynamicCrudRepository`, `ExportRepository` | `*/data/repositories/` |
| **Provider Pattern** | `ChangeNotifier`-based state management | `*/presentation/providers/` |
| **Adapter Pattern** | `SchemaAdapter` converts metadata to V2 DTO | `dynamic_crud/data/datasources/` |
| **Mapper Pattern** | `FieldTypeMapper`, `ColumnNameMapper`, `EndpointMapper` | `core/network/`, `domain/services/` |
| **Factory Pattern** | `UserModel.fromJson()`, `UserModel.fromEntity()` | `*/data/models/` |
| **Strategy Pattern** | Export formats (CSV, JSON) via `ExportFormat` enum | `modules/export/` |
| **Observer Pattern** | `ChangeNotifier` + `Consumer` widget rebuilds | Throughout UI |
| **Template Method** | `AppProvider` base class with `setLoading()`, `setError()` | `shared/providers/` |

### SOLID Principles Applied

- **Single Responsibility:** Each service/repository handles one concern
- **Open/Closed:** New database modules can be added without modifying existing code
- **Liskov Substitution:** Interfaces (`IAuthRepository`, `IDbConnectionFactory`) enable substitution
- **Interface Segregation:** Specific interfaces per domain (`IProductosRepository` vs `ISaludRepository`)
- **Dependency Inversion:** Controllers depend on abstractions, not concrete implementations

---

## Security

| Mechanism | Implementation |
|-----------|---------------|
| **JWT Authentication** | HMAC-SHA256 signed tokens with 8-hour expiration |
| **Stored Procedure Login** | Credentials validated via `sp_ValidarLoginFinal` (no raw SQL) |
| **Parameterized Queries** | All Dapper queries use `DynamicParameters` (prevents SQL injection) |
| **Schema Validation** | Column names validated against `DbSchema` before query execution |
| **Bracket Escaping** | Column/table names wrapped in `[brackets]` in generated SQL |
| **Token Storage** | JWT stored in `SharedPreferences` with key isolation |
| **Header-Based Auth** | Bearer token sent via `Authorization` header on every request |
| **Connection String Security** | Frontend never sees connection strings; database routing via headers only |
| **Identity Column Protection** | Auto-increment columns automatically excluded from INSERT operations |

---

## Getting Started

### Prerequisites

- **Flutter SDK** 3.x+
- **.NET SDK** 8.0+
- **SQL Server** 2019+ (or Azure SQL Database)
- **Android Studio** or **VS Code** with Flutter extension

### Backend Setup

```bash
# Clone the repository
cd BackFabrica

# Restore NuGet packages
dotnet restore

# Update connection strings in appsettings.json
# Configure your SQL Server instance

# Run the API
dotnet run --project BackFabrica
```

The API will be available at `https://localhost:{port}/swagger` with full Swagger documentation.

### Frontend Setup

```bash
# Navigate to Flutter project
cd herramienta_case

# Install dependencies
flutter pub get

# Configure environment
# Edit .env file with your backend URL:
#   API_URL=https://your-backend-url
#   API_TIMEOUT=30
#   DEBUG=true

# Run on device/emulator
flutter run
```

### Build APK

```bash
flutter build apk --release
```

The release APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

---

## Screenshots

> *Screenshots can be added here showing: Login Screen, Database Selection, Tables Menu, Dynamic List View, Dynamic Form with FK Dropdowns, Export Options, Home Dashboard*

---

## Author

Developed as a full-stack portfolio project demonstrating:
- Enterprise architecture with Clean Architecture and layered design
- Dynamic code generation from database metadata
- Full-stack development with .NET and Flutter
- RESTful API design with Swagger documentation
- Multi-database support with runtime schema introspection
- Security best practices (JWT, parameterized queries, input validation)

---

*Built with .NET 8, Flutter, Dapper, SQL Server, and Clean Architecture*
