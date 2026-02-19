# BHU Control - Sistema de Gestión de Depósitos

Aplicación multiplataforma para gestión de depósitos del Banco Hipotecario del Uruguay en Unidades Indexadas (UI).

## Descripción

BHU Control permite gestionar depósitos en UI, calcular ganancias y visualizar estadísticas. Obtiene automáticamente el valor UI desde APIs externas.

**Características principales:**
- Gestión completa de depósitos (crear, editar, eliminar)
- Actualización automática del valor UI desde API del BROU
- Cálculo en tiempo real de valores actuales y ganancias
- Conversor de monedas (UI, UR, USD, UYU)
- Base de datos local SQLite
- Diseño Material Design 3
- Soporte multiplataforma: Android, Windows, Web
- Búsqueda y ordenamiento de depósitos
- Estadísticas detalladas

## Requisitos

- Flutter SDK >=3.10.0
- Dart SDK >=3.0.0
- Android Studio o VS Code
- Android SDK API 34 (Android 14+)

## Instalación

### 1. Clonar el repositorio
```bash
git clone https://github.com/djstarman80/BHU-Control.git
cd BHU-Control
```

### 2. Instalar dependencias
```bash
flutter pub get
```

### 3. Verificar configuración
```bash
flutter doctor
```

### 4. Ejecutar la aplicación
```bash
flutter run
```

## Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada
├── config/
│   └── app_config.dart          # Configuración (CORS proxy)
├── models/
│   ├── deposito.dart            # Modelo de depósito
│   └── moneda_data.dart         # Datos de monedas
├── providers/
│   └── bhu_provider.dart        # Estado (Provider)
├── services/
│   ├── database_service.dart    # Base de datos SQLite
│   ├── brou_service.dart        # API BROU
│   ├── ur_service.dart          # API UR
│   └── moneda_fetcher.dart      # Fetch de monedas
├── screens/
│   ├── bhu_home_page.dart       # Pantalla principal
│   └── settings_screen.dart     # Configuración
├── widgets/
│   ├── deposito_form_widget.dart
│   ├── depositos_table_widget.dart
│   ├── resumen_tab_widget.dart
│   └── conversor_tab_widget.dart
├── dialogs/
│   ├── conversion_dialog.dart
│   ├── edit_deposito_dialog.dart
│   └── manual_entry_dialog.dart
└── utils/
    ├── currency_formatter.dart  # Formateo de monedas
    ├── date_formatter.dart      # Formateo de fechas
    ├── logger.dart              # Logging
    └── pdf_generator.dart       # Generación de PDF
```

## Funcionalidades

### 1. Gestión de Depósitos
- Agregar depósitos con validación
- Editar depósitos existentes
- Eliminar con confirmación
- Visualización en cards adaptables

### 2. Actualización de Valor UI
- Automática desde API del BROU
- Entrada manual de valor
- Historial de actualizaciones

### 3. Cálculos y Estadísticas
- Totales en UI y pesos
- Ganancias individuales y totales
- Porcentajes de rentabilidad
- Promedios por depósito

### 4. Conversor de Monedas
- UI (Unidades Indexadas)
- UR (Unidades Reajustables)
- USD (Dólares)
- UYU (Pesos Uruguayos)

## Compilación

### Android APK
```bash
flutter build apk --release
```
Resultado: `build/app/outputs/flutter-apk/app-release.apk`

### Windows
```bash
flutter build windows --release
```
Resultado: `build/windows/x64/runner/Release/`

### Web
```bash
flutter build web --release
```
Resultado: `build/web/`

## Demo Web

Disponible en: https://djstarman80.github.io/BHU-Control/

## Tecnologías

| Categoría | Tecnología |
|-----------|------------|
| Framework | Flutter 3.10+ |
| Estado | Provider |
| Base de datos | SQLite (sqflite) |
| HTTP | Dio |
| Almacenamiento | Shared Preferences |
| PDF | pdf package |
| Exportación | csv, share_plus |

## Base de Datos

### Tablas SQLite:

**depositos**:
- `id` (INTEGER PRIMARY KEY)
- `amount` (REAL) - Monto en pesos
- `ui_amount` (REAL) - Monto en UI
- `deposit_date` (TEXT) - Fecha depósito
- `ui_value` (REAL) - Valor UI al momento
- `registration_date` (TEXT) - Fecha registro

**config**:
- `key` (TEXT PRIMARY KEY)
- `value` (TEXT) - Configuración general

## APIs Utilizadas

| Moneda | Endpoint | Fuente |
|--------|----------|--------|
| UI | `uy.dolarapi.com/v1/cotizaciones/ui` | BROU |
| UR | API específica | BCU |

Para web, se usa un CORS proxy: `https://mi-cors-proxy.bhu-cors-proxy.workers.dev`

## Licencia

Desarrollado para Banco Hipotecario del Uruguay

## Contacto

Marcelo Pereyra - Desarrollador
