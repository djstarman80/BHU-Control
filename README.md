# BHU Control - Aplicación Android

Sistema de Control BHU - Gestión de Depósitos para Android 15

## Descripción

Aplicación móvil nativa para Android desarrollada en Flutter que permite gestionar depósitos del Banco Hipotecario del Uruguay en Unidades Indexadas (UI).

**Características principales:**
- ✅ Gestión completa de depósitos (crear, editar, eliminar)
- ✅ Actualización automática del valor UI desde API del BROU
- ✅ Cálculo en tiempo real de valores actuales y ganancias
- ✅ Base de datos local SQLite
- ✅ Diseño Material Design 3 adaptable
- ✅ Búsqueda y ordenamiento de depósitos
- ✅ Estadísticas detalladas
- 🔄 Exportación a CSV (próximamente)
- 🔄 Backup/restore (próximamente)

## Requisitos

- Flutter SDK >=3.10.0
- Dart SDK >=3.0.0
- Android Studio o VS Code
- Android SDK API 34 (Android 14+) con soporte para Android 15

## Instalación

### 1. Clonar el repositorio
```bash
git clone <repository-url>
cd bhu_control_app
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
# Emulador
flutter run

# Dispositivo físico
flutter devices
flutter run -d <device-id>
```

## Configuración para Android 15

### Permisos configurados en AndroidManifest.xml:
- `INTERNET` - Para conexión a API del BROU
- `ACCESS_NETWORK_STATE` - Para verificar conexión
- `WRITE_EXTERNAL_STORAGE` - Para exportar reportes
- `READ_EXTERNAL_STORAGE` - Para importar backups
- `READ_MEDIA_*` - Para Android 13+

### Configuración de compilación:
- `compileSdkVersion: 34`
- `targetSdkVersion: 34`
- `minSdkVersion: 24` (Android 7.0+)

## Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada
├── models/
│   └── deposito.dart         # Modelo de datos
├── providers/
│   └── bhu_provider.dart     # Manejo de estado (Provider)
├── services/
│   ├── database_service.dart # Base de datos SQLite
│   └── ui_service.dart       # Servicio API UI
├── screens/
│   └── bhu_home_page.dart    # Pantalla principal
├── widgets/
│   ├── deposito_form_widget.dart
│   ├── depositos_table_widget.dart
│   └── resume_panel_widget.dart
└── dialogs/
    └── edit_deposito_dialog.dart
```

## Funcionalidades

### 1. Gestión de Depósitos
- **Agregar**: Formulario con validación en tiempo real
- **Editar**: Diálogo modal con previsualización de cambios
- **Eliminar**: Confirmación antes de borrar
- **Visualización**: Cards adaptables con información completa

### 2. Actualización de Valor UI
- **Automática**: Desde API del BROU (https://uy.dolarapi.com/v1/cotizaciones/ui)
- **Manual**: Ingresar valor manualmente
- **Historial**: Muestra fuente y última actualización

### 3. Cálculos y Estadísticas
- **Totales**: Montos depositados y valores actuales
- **Ganancias**: Cálculo individual y total
- **Promedios**: Por depósito y estadísticas adicionales
- **Porcentajes**: Rentabilidad en tiempo real

### 4. Interfaz de Usuario
- **Material Design 3**: Diseño moderno y adaptable
- **Tema claro/oscuro**: Según configuración del sistema
- **Responsive**: Adaptación a diferentes tamaños de pantalla
- **Colores BHU**: Paleta de colores institucional

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

## API Integration

### Endpoint: `https://uy.dolarapi.com/v1/cotizaciones/ui`

**Respuesta esperada:**
```json
{
  "venta": 6.4275,
  "fechaActualizacion": "2026-02-10T10:30:00.000Z"
}
```

## Construcción para Producción

### APK para pruebas:
```bash
flutter build apk --debug
flutter build apk --release
```

### App Bundle (Google Play):
```bash
flutter build appbundle --release
```

### Configuración de firma:
```bash
# Crear keystore
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key

# Configurar en android/key.properties
```

## Consideraciones para Android 15

1. **Permisos**: Se usan permisos adaptados para Android 13+
2. **Storage**: Manejo de almacenamiento según nuevas políticas
3. **Performance**: Optimización para nuevos dispositivos
4. **Security**: Configuración de seguridad actualizada

## Problemas Conocidos y Soluciones

### 1. Error de conexión API
- Verificar conexión a internet
- Revisar endpoint y timeout (10s)
- Manejar errores con Toasts

### 2. Problemas con SQLite
- Inicializar base de datos asíncronamente
- Manejar migraciones de versión
- Cerrar conexión adecuadamente

### 3. Tema claro/oscuro
- Configurar colores con ColorScheme
- Probar en ambos modos
- Adaptar íconos y textos

## Desarrollo Futuro

### Próximamente:
- 📊 Exportación a CSV y PDF
- 💾 Sistema de backup/restore
- 📈 Gráficos de evolución
- 🔔 Notificaciones de actualización UI
- 🔒 Biometric authentication
- ☁️ Sincronización en la nube

### Mejoras:
- Modo offline completo
- Historial detallado de valores UI
- Predicciones de ganancias
- Categorización de depósitos

## Licencia

Desarrollado para Banco Hipotecario del Uruguay

## Contacto

Marcelo Pereyra - Desarrollador

---

**Nota**: Esta es una migración completa de la aplicación PyQt6 original a Flutter para Android, manteniendo toda la funcionalidad y mejorando la experiencia móvil.