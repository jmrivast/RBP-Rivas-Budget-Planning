# RBP - Finanzas Personales

Aplicacion de finanzas personales construida con Flutter para escritorio, enfocada en control financiero por quincena, operacion local-first y distribucion comercial en Windows.

Este repo esta curado como proyecto personal para mostrar arquitectura, criterio de producto y codigo real de una app distribuible: gestion de ingresos, gastos, pagos fijos, ahorro, prestamos, perfiles multiples y activacion local.

## Table of Contents
- [1. Resumen del proyecto](#1-resumen-del-proyecto)
- [2. Problema que resuelve](#2-problema-que-resuelve)
- [3. Estado actual](#3-estado-actual)
- [4. Stack tecnologico](#4-stack-tecnologico)
- [5. Arquitectura de la app](#5-arquitectura-de-la-app)
- [6. Modulos principales](#6-modulos-principales)
- [7. Persistencia local y modelo de datos](#7-persistencia-local-y-modelo-de-datos)
- [8. Seguridad y licenciamiento](#8-seguridad-y-licenciamiento)
- [9. Estructura del repositorio](#9-estructura-del-repositorio)
- [10. Como ejecutar el proyecto](#10-como-ejecutar-el-proyecto)
- [11. Testing y calidad](#11-testing-y-calidad)
- [12. Ejemplos de codigo](#12-ejemplos-de-codigo)
- [13. Roadmap tecnico](#13-roadmap-tecnico)

## 1. Resumen del proyecto

RBP - Finanzas Personales es una app desktop pensada para usuarios que cobran por quincena y necesitan separar:

- salario base
- ajuste de salario por quincena
- ingresos extra
- gastos del periodo
- pagos fijos
- ahorro y metas
- prestamos y deudas personales

La app prioriza una experiencia clara para uso diario, almacenamiento local con SQLite y un flujo comercial real con activacion por licencia.

## 2. Problema que resuelve

Muchas apps financieras asumen un flujo mensual simple. RBP resuelve un escenario mucho mas comun en Latinoamerica:

- personas que cobran dos veces al mes
- quincenas con montos diferentes
- gastos que salen de una quincena especifica
- prestamos personales y compromisos recurrentes
- necesidad de operar sin depender de una cuenta en la nube

El resultado es una app enfocada en control practico, no solo en registro contable.

## 3. Estado actual

Estado del producto hoy:

- app principal en Flutter para Windows
- arquitectura en proceso de separacion para multiplataforma
- exportacion de reportes
- perfiles multiples con PIN
- licenciamiento local endurecido con cifrado
- base responsive en componentes clave para futura expansion a web y Android

Estado tecnico:

- `lib/presentation/` consolidando la capa de UI actual
- `lib/data/` como capa de persistencia y repositorios
- `lib/services/` concentrando integraciones y logica operacional
- `lib/domain/` y `lib/core/` ya introducidos como base para una estructura mas limpia

## 4. Stack tecnologico

Cliente:

- Flutter
- Dart
- Provider
- fl_chart
- intl

Persistencia y archivos:

- SQLite
- sqflite
- sqflite_common_ffi
- path_provider
- pdf
- csv
- share_plus

Licencia y plataforma:

- device_info_plus
- cryptography
- crypto
- window_manager
- package_info_plus
- url_launcher

Testing:

- flutter_test
- flutter_lints

## 5. Arquitectura de la app

La app sigue una separacion pragmatica por capas:

- `lib/main.dart`: bootstrap multiplataforma
- `lib/app.dart`: configuracion global de tema, providers y entrada principal
- `lib/presentation/`: pantallas, widgets, dialogs, tema y estado UI
- `lib/data/`: modelos, tablas, repositorios y acceso SQLite
- `lib/services/`: logica operacional, exportes, licencias y actualizaciones
- `lib/domain/`: entidades y contratos para evolucionar hacia una arquitectura mas desacoplada
- `lib/core/`: utilidades base, errores y abstracciones comunes

Flujo principal:

```text
main.dart
  -> inicializacion de plataforma
  -> RbpApp
  -> MultiProvider
  -> AppEntryScreen
  -> HomeScreen
  -> tabs y servicios
  -> SQLite / export / licencia
```

## 6. Modulos principales

La app cubre estas areas funcionales:

- Resumen financiero del periodo
- Ingresos base y extras
- Registro de gastos con categorias
- Pagos fijos y control de estado
- Prestamos y deudas personales
- Ahorro de periodo y ahorro total
- Metas de ahorro
- Configuracion por usuario
- Perfiles multiples
- Activacion/licenciamiento

Pantallas clave:

- `rbp_flutter/lib/presentation/screens/dashboard_tab.dart`
- `rbp_flutter/lib/presentation/screens/income_tab.dart`
- `rbp_flutter/lib/presentation/screens/expense_tab.dart`
- `rbp_flutter/lib/presentation/screens/fixed_payments_tab.dart`
- `rbp_flutter/lib/presentation/screens/loans_tab.dart`
- `rbp_flutter/lib/presentation/screens/savings_tab.dart`
- `rbp_flutter/lib/presentation/screens/settings_tab.dart`

## 7. Persistencia local y modelo de datos

La app opera en modo local-first. El almacenamiento principal vive en SQLite y se inicializa desde `rbp_flutter/lib/data/database/database_helper.dart`.

Ese helper:

- resuelve la ruta local de la base de datos
- crea tablas e indices
- garantiza compatibilidad de esquema
- expone operaciones CRUD y transacciones

Modelos de dominio representados en SQLite:

- usuarios
- gastos
- ingresos
- pagos fijos
- ahorro
- prestamos
- deudas personales
- pagos de deuda
- categorias
- configuraciones de usuario

## 8. Seguridad y licenciamiento

El proyecto incluye una capa de licenciamiento local para distribucion comercial.

Puntos tecnicos destacados:

- huella de maquina normalizada
- salting aplicado a la derivacion de claves
- cifrado `AES-GCM`
- compatibilidad con versiones anteriores de tokens
- almacenamiento local cifrado para registros de activacion

Archivos clave:

- `rbp_flutter/lib/services/license_crypto.dart`
- `rbp_flutter/lib/services/license_key_codec.dart`
- `rbp_flutter/lib/services/license_service_io.dart`
- `rbp_flutter/lib/data/models/license_info.dart`

## 9. Estructura del repositorio

```text
.
|-- README.md
|-- rbp_flutter/
|   |-- lib/
|   |   |-- app.dart
|   |   |-- main.dart
|   |   |-- core/
|   |   |-- data/
|   |   |-- domain/
|   |   |-- presentation/
|   |   `-- services/
|   |-- assets/
|   |-- test/
|   |-- web/
|   `-- windows/
`-- LICENSE
```

La raiz del repo se mantiene intencionalmente reducida para que un reclutador pueda entender el proyecto rapido.

## 10. Como ejecutar el proyecto

Requisitos:

- Flutter SDK 3.24+
- Windows para el build desktop actual

Instalacion:

```powershell
cd rbp_flutter
flutter pub get
```

Ejecutar en Windows:

```powershell
flutter run -d windows
```

Analisis estatico:

```powershell
flutter analyze --no-pub
```

Build release:

```powershell
flutter build windows --release
```

## 11. Testing y calidad

El repo incluye pruebas para logica financiera, servicios y widgets.

Suites destacadas:

- `rbp_flutter/test/providers/finance_provider_test.dart`
- `rbp_flutter/test/services/finance_service_test.dart`
- `rbp_flutter/test/services/export_services_test.dart`
- `rbp_flutter/test/services/license_service_test.dart`
- `rbp_flutter/test/widget_test.dart`

Ejecutar tests:

```powershell
cd rbp_flutter
flutter test
```

## 12. Ejemplos de codigo

### Bootstrap de la app

`rbp_flutter/lib/app.dart`

```dart
return MultiProvider(
  providers: [
    ChangeNotifierProvider(
      create: (_) => FinanceProvider(),
    ),
    ChangeNotifierProxyProvider<FinanceProvider, SettingsProvider>(
      create: (context) => SettingsProvider(context.read<FinanceProvider>()),
      update: (context, finance, previous) =>
          previous ?? SettingsProvider(finance),
    ),
  ],
  child: Consumer<SettingsProvider>(
    builder: (context, settings, _) => MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      home: const AppEntryScreen(),
    ),
  ),
);
```

Este fragmento muestra el bootstrap real de estado global y la entrada principal de la app.

### Inicializacion multiplataforma

`rbp_flutter/lib/main.dart`

```dart
Future<void> _initPlatformServices() async {
  if (PlatformConfig.isWeb) {
    databaseFactory = databaseFactoryFfiWeb;
    return;
  }

  if (PlatformConfig.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
```

Este punto deja preparada la app para escritorio hoy y para build web en la evolucion multiplataforma.

### Persistencia local

`rbp_flutter/lib/data/database/database_helper.dart`

```dart
Future<Database> _initDatabase() async {
  final path = await _resolveDatabasePath();
  final db = await openDatabase(
    path,
    version: databaseVersion,
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON;');
    },
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  );
  await _ensureSchemaCompatibility(db);
  return db;
}
```

### Cifrado de licencia

`rbp_flutter/lib/services/license_crypto.dart`

```dart
final secretBox = await _aesGcm.encrypt(
  payload,
  secretKey: SecretKey(key),
  nonce: nonce,
  aad: utf8.encode('rbp-license-v3'),
);
```

Esta capa protege la activacion local con `AES-GCM`, salting y versionado de tokens.

## 13. Roadmap tecnico

Siguientes frentes de evolucion:

- normalizar por completo la migracion `ui -> presentation`
- cerrar build web estable sin comportamiento colgado
- continuar la separacion entre codigo desktop-only y multiplataforma
- preparar Android como siguiente destino natural
- seguir desacoplando logica de producto para futura sincronizacion cloud/freemium

---

Si quieres conocer el proyecto en detalle tecnico, la mejor ruta de lectura es:

1. `README.md`
2. `rbp_flutter/lib/app.dart`
3. `rbp_flutter/lib/main.dart`
4. `rbp_flutter/lib/presentation/`
5. `rbp_flutter/lib/data/database/database_helper.dart`
6. `rbp_flutter/lib/services/license_crypto.dart`
