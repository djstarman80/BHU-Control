# BHU Control App - Scripts de Compilacion

## Archivos disponibles

### 1. `compilar.bat`
Compila e instala la version **DEBUG** del APK.
- Mas rapido de compilar
- Incluye logs de debug
- Ideal para desarrollo y pruebas

**Uso:** Doble click en `compilar.bat`

---

### 2. `compilar_release.bat`
Compila e instala la version **RELEASE** del APK.
- Optimizado para produccion
- Sin logs de debug
- Firma el APK automaticamente

**Uso:** Doble click en `compilar_release.bat`

---

### 3. `analizar.bat`
Ejecuta verificaciones de calidad de codigo.
- Analiza el codigo en busca de errores
- Verifica formato
- Muestra dependencias desactualizadas

**Uso:** Doble click en `analizar.bat`

---

### 4. `backup.bat`
Crea un backup completo del proyecto en formato ZIP.
- Incluye todos los archivos del proyecto
- Nombre del backup con fecha y hora
- Se guarda en la carpeta `backups/`

**Uso:** Doble click en `backup.bat`

**Restaurar backup:**
1. Extraer el archivo `.zip`
2. Copiar los archivos sobre el proyecto

---

### 5. `restore.bat`
Restaura un backup previamente creado.
- Lista todos los backups disponibles
- Permite seleccionar cual restaurar
- Pide confirmacion antes de sobrescribir

**Uso:** Doble click en `restore.bat`

**Despues de restaurar:**
```bash
flutter pub get
flutter clean
flutter build apk --debug
```

---

## Requisitos previos

1. **Flutter** instalado y en PATH
2. **Android SDK** configurado
3. **ADB** configurado y dispositivo conectado

## Comandos manuales

```bash
# Compilar debug
flutter build apk --debug
adb install -r build\app\outputs\flutter-apk\app-debug.apk

# Compilar release
flutter build apk --release
adb install -r build\app\outputs\flutter-apk\app-release.apk

# Analizar codigo
flutter analyze

# Formatear codigo
flutter format lib/

# Obtener dependencias
flutter pub get

# Limpiar cache
flutter clean
```

---

## Estructura del proyecto

```
bhu_control_app/
├── android/          # Configuracion Android
├── lib/             # Codigo fuente Flutter
│   ├── main.dart
│   ├── providers/   # Providers de estado
│   ├── models/      # Modelos de datos
│   ├── services/    # Servicios (DB, API)
│   ├── widgets/     # Widgets de UI
│   └── utils/       # Utilidades (PDF, etc.)
├── build/           # Archivos compilados
├── pubspec.yaml     # Dependencias Flutter
└── scripts/         # Scripts de compilacion
    ├── compilar.bat
    ├── compilar_release.bat
    └── analizar.bat
```
