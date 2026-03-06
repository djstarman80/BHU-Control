import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/deposito.dart';
import '../models/moneda_data.dart';
import '../services/database_service.dart';
import '../services/ui_service.dart';
import '../services/moneda_fetcher.dart';
import '../utils/pdf_generator.dart';
import '../utils/logger.dart';
import '../config/app_config.dart';
import '../dialogs/manual_entry_dialog.dart';

class BHUProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;

  // Estado
  List<Deposito> _depositos = [];
  UiData _currentUi = UiData(
    value: AppConfig.defaultUiValue,
    source: 'Manual',
    lastUpdate: DateTime.now().toIso8601String(),
  );
  MonedaData _monedaData = MonedaData(
    ui: AppConfig.defaultUiValue,
    ur: AppConfig.defaultUrValue,
    dolarVenta: AppConfig.defaultDolarValue,
    ultimaActualizacion: DateTime.now(),
    uiSource: 'WEB',
    urSource: 'WEB',
    dolarSource: 'WEB',
  );
  bool _isLoading = false;
  String? _error;

  // Theme
  ThemeMode _themeMode = ThemeMode.system;

  // Getters
  List<Deposito> get depositos => List.unmodifiable(_depositos);
  UiData get currentUi => _currentUi;
  MonedaData get monedaData => _monedaData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ThemeMode get themeMode => _themeMode;

  // Getters de monedas individuales
  double get uiValue => _monedaData.ui;
  double get urValue => _monedaData.ur;
  double get dolarVenta => _monedaData.dolarVenta;

  // Cálculos
  double get totalAmount => _depositos.fold(0.0, (sum, d) => sum + d.amount);
  double get totalUiAmount =>
      _depositos.fold(0.0, (sum, d) => sum + d.uiAmount);
  double get totalCurrentValue => _depositos.fold(
        0.0,
        (sum, d) => sum + d.getCurrentValue(_currentUi.value),
      );
  double get profit => totalCurrentValue - totalAmount;

  // Inicialización
  Future<void> initialize() async {
    await loadThemeMode();
    await loadDepositos();
    await loadCurrentUi();
    await loadMonedaData();
    await refreshMonedasSafe();
  }

  // Theme
  Future<void> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt('themeMode') ?? 0;
      _themeMode = ThemeMode.values[themeIndex];
      notifyListeners();
    } catch (e) {
      AppLogger.e('Error cargando theme mode', e);
    }
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('themeMode', _themeMode.index);
    } catch (e) {
      AppLogger.e('Error guardando theme mode', e);
    }
    notifyListeners();
  }

  // Cargar datos de monedas (UI, UR, USD)
  Future<void> loadMonedaData() async {
    try {
      _monedaData = await UiService.getAllValues();
      notifyListeners();
    } catch (e) {
      _error = 'Error cargando datos de monedas: ${e.toString()}';
      AppLogger.e('Error cargando datos de monedas', e);
    }
  }

  // Actualizar todas las monedas según modo configurado (sin diálogos)
  Future<void> refreshMonedasSafe() async {
    try {
      _setLoading(true);
      AppLogger.i('Actualizando monedas (sin diálogos)...');

      for (String moneda in ['USD', 'UI', 'UR']) {
        final mode = await getMonedaMode(moneda);
        if (mode == 'MANUAL') continue;

        final result = await MonedaFetcher.fetch(moneda, mode);
        if (result.success && result.value != null) {
          await _saveMonedaValue(moneda, result.value!, result.source!);
        }
      }

      await loadMonedaData();
      _error = null;
      AppLogger.i(
        'Monedas actualizadas: UI=${_monedaData.ui}, UR=${_monedaData.ur}, USD=${_monedaData.dolarVenta}',
      );
    } catch (e) {
      AppLogger.e('Error actualizando monedas', e);
    } finally {
      _setLoading(false);
    }
  }

  // Guardar valores de monedas manualmente
  Future<void> setManualMonedaValues({
    required double ui,
    required double ur,
    required double dolar,
  }) async {
    try {
      await DatabaseService.instance.setConfig(
        'current_ui_value',
        ui.toString(),
      );
      await DatabaseService.instance.setConfig('ur_value', ur.toString());
      await DatabaseService.instance.setConfig('dolar_venta', dolar.toString());
      await DatabaseService.instance.setConfig('monedas_source', 'manual');

      await loadMonedaData();

      AppLogger.i('Valores manuales guardados: UI=$ui, UR=$ur, USD=$dolar');
    } catch (e) {
      _error = 'Error guardando valores manuales: ${e.toString()}';
      AppLogger.e('Error guardando valores manuales', e);
    }
  }

  // Conversiones de monedas
  double convertir({
    required String desde,
    required String hacia,
    required double cantidad,
  }) {
    switch ('$desde-$hacia') {
      case 'USD-UYU':
      case 'USD-\$':
        return cantidad * dolarVenta;
      case 'UYU-USD':
      case '\$-USD':
        return cantidad / dolarVenta;
      case 'UI-UYU':
      case 'UI-\$':
        return cantidad * uiValue;
      case 'UYU-UI':
      case '\$-UI':
        return cantidad / uiValue;
      case 'UR-UYU':
      case 'UR-\$':
        return cantidad * urValue;
      case 'UYU-UR':
      case '\$-UR':
        return cantidad / urValue;
      case 'UI-UR':
        return (cantidad * uiValue) / urValue;
      case 'UR-UI':
        return (cantidad * urValue) / uiValue;
      case 'USD-UI':
        return (cantidad * dolarVenta) / uiValue;
      case 'UI-USD':
        return (cantidad * uiValue) / dolarVenta;
      case 'USD-UR':
        return (cantidad * dolarVenta) / urValue;
      case 'UR-USD':
        return (cantidad * urValue) / dolarVenta;
      default:
        return cantidad;
    }
  }

  String getSimboloMoneda(String moneda) {
    switch (moneda) {
      case 'USD':
        return 'USD';
      case 'UYU':
      case '\$':
        return '\$';
      case 'UI':
        return 'UI';
      case 'UR':
        return 'UR';
      default:
        return moneda;
    }
  }

  // Cargar depósitos
  Future<void> loadDepositos() async {
    try {
      _setLoading(true);
      _depositos = await _dbService.getAllDepositos();
      _error = null;
    } catch (e) {
      _error = 'Error cargando depósitos: ${e.toString()}';
      AppLogger.e('Error cargando depósitos', e);
    } finally {
      _setLoading(false);
    }
  }

  // Cargar valor UI actual
  Future<void> loadCurrentUi() async {
    try {
      _currentUi = await UiService.getCurrentUiValue();
      notifyListeners();
    } catch (e) {
      _error = 'Error cargando valor UI: ${e.toString()}';
      AppLogger.e('Error cargando valor UI', e);
    }
  }

  // Actualizar valor UI desde API
  Future<void> updateUiFromApi() async {
    try {
      _setLoading(true);
      AppLogger.i('Actualizando UI desde API');
      final result = await UiService.fetchUiValue();

      if (result.success) {
        await loadCurrentUi();
        await loadMonedaData(); // Sincronizar monedaData
        await loadDepositos();
        _error = null;
        AppLogger.i('UI actualizada: ${_currentUi.value}');
      }
    } catch (e) {
      _error = 'Error actualizando UI: ${e.toString()}';
      AppLogger.e('Error actualizando UI', e);
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar valor UI manualmente
  Future<void> updateUiManually(double value) async {
    try {
      await UiService.updateUiValueManually(value);
      await loadCurrentUi();
      await loadMonedaData(); // Sincronizar monedaData
      await loadDepositos();
      _error = null;
      AppLogger.i('UI actualizada manualmente: $value');
    } catch (e) {
      _error = 'Error actualizando UI manualmente: ${e.toString()}';
      AppLogger.e('Error actualizando UI manualmente', e);
    }
  }

  // Importar datos desde JSON
  Future<bool> importFromJson() async {
    try {
      _setLoading(true);
      final success = await _dbService.importFromJson();
      if (success) {
        await initialize();
        _error = null;
        AppLogger.i('Importación desde JSON exitosa');
        return true;
      } else {
        _error = 'Error importando datos desde JSON';
        return false;
      }
    } catch (e) {
      _error = 'Error importando JSON: ${e.toString()}';
      AppLogger.e('Error importando JSON', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Importar datos desde JSON (ruta fija para desarrollo)
  Future<bool> importFromJsonFixedPath() async {
    try {
      _setLoading(true);
      final success = await _dbService.importFromJsonFixedPath();
      if (success) {
        await initialize();
        _error = null;
        AppLogger.i('Importación desde ruta fija exitosa');
        return true;
      } else {
        _error = 'Error importando datos desde JSON (ruta fija)';
        return false;
      }
    } catch (e) {
      _error = 'Error importando JSON: ${e.toString()}';
      AppLogger.e('Error importando JSON desde ruta fija', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Importar datos desde string JSON (pegar directamente)
  Future<bool> importFromJsonString(String jsonString) async {
    try {
      _setLoading(true);
      final success = await _dbService.importFromJsonString(jsonString);
      if (success) {
        await initialize();
        _error = null;
        AppLogger.i('Importación desde string JSON exitosa');
        return true;
      } else {
        _error = 'Error importando datos desde string JSON';
        return false;
      }
    } catch (e) {
      _error = 'Error importando JSON: ${e.toString()}';
      AppLogger.e('Error importando JSON desde string', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Agregar depósito
  Future<bool> addDeposit(Deposito deposito) async {
    try {
      _setLoading(true);
      await _dbService.insertDeposito(deposito);
      await loadDepositos();
      _error = null;
      AppLogger.i('Depósito agregado: ${deposito.id}');
      return true;
    } catch (e) {
      _error = 'Error agregando depósito: ${e.toString()}';
      AppLogger.e('Error agregando depósito', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar depósito
  Future<bool> updateDeposit(Deposito deposito) async {
    try {
      _setLoading(true);
      await _dbService.updateDeposito(deposito);
      await loadDepositos();
      _error = null;
      AppLogger.i('Depósito actualizado: ${deposito.id}');
      return true;
    } catch (e) {
      _error = 'Error actualizando depósito: ${e.toString()}';
      AppLogger.e('Error actualizando depósito', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Eliminar depósito
  Future<bool> deleteDeposit(int id) async {
    try {
      _setLoading(true);
      await _dbService.deleteDeposito(id);
      await loadDepositos();
      _error = null;
      AppLogger.i('Depósito eliminado: $id');
      return true;
    } catch (e) {
      _error = 'Error eliminando depósito: ${e.toString()}';
      AppLogger.e('Error eliminando depósito', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Buscar depósitos
  List<Deposito> searchDepositos(String query) {
    if (query.isEmpty) return _depositos;

    return _depositos.where((deposito) {
      return deposito.depositDate.toLowerCase().contains(query.toLowerCase()) ||
          deposito.amount.toString().contains(query) ||
          deposito.uiAmount.toString().contains(query) ||
          deposito.uiValue.toString().contains(query) ||
          deposito.getCurrentValue(_currentUi.value).toString().contains(query);
    }).toList();
  }

  // Ordenar depósitos
  void sortDepositos(String criteria) {
    switch (criteria) {
      case 'date':
        _depositos.sort(
          (a, b) =>
              _parseDate(a.depositDate).compareTo(_parseDate(b.depositDate)),
        );
        break;
      case 'amount':
        _depositos.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'uiAmount':
        _depositos.sort((a, b) => b.uiAmount.compareTo(a.uiAmount));
        break;
      case 'currentValue':
        _depositos.sort(
          (a, b) => b
              .getCurrentValue(_currentUi.value)
              .compareTo(a.getCurrentValue(_currentUi.value)),
        );
        break;
    }
    notifyListeners();
  }

  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (e) {
      return DateTime.now();
    }
  }

  // Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Generar PDF de resumen (bytes para web y desktop)
  Future<Uint8List> generatePDFBytes() async {
    AppLogger.i('Generando PDF de resumen (bytes)');
    final bytes = await PDFGenerator.generateResumenPDFBytes(provider: this);
    AppLogger.i('PDF generado en memoria: ${bytes.length} bytes');
    return bytes;
  }

  // Generar PDF de resumen (archivo - solo desktop/mobile)
  Future<io.File> generatePDF() async {
    AppLogger.i('Generando PDF de resumen');

    final file = await PDFGenerator.generateResumenPDF(provider: this);

    AppLogger.i('PDF generado en: ${file.path}');
    return file;
  }

  // Recuperación de bloqueos de base de datos
  Future<bool> recoverFromLock() async {
    try {
      _setLoading(true);
      await _dbService.resetConnection();
      await initialize();
      _error = null;
      AppLogger.i('Recuperación de bloqueo exitosa');
      return true;
    } catch (e) {
      _error = 'Error recuperando de bloqueo: ${e.toString()}';
      AppLogger.e('Error recuperando de bloqueo', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Método privado para manejar loading
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Exportar a CSV
  Future<io.File> exportCsv() async {
    AppLogger.i('Exportando a CSV');
    final file = await _dbService.exportToCsv(_currentUi.value);
    AppLogger.i('CSV generado: ${file.path}');
    return file;
  }

  // Crear backup
  Future<io.File> createBackup() async {
    AppLogger.i('Creando backup');
    final file = await _dbService.createBackup();
    AppLogger.i('Backup generado: ${file.path}');
    return file;
  }

  // Crear backup para web (GitHub Pages)
  Future<String> createBackupWeb() async {
    AppLogger.i('Creando backup web');
    final jsonString = await _dbService.createBackupWeb();
    AppLogger.i('Backup web generado');
    return jsonString;
  }

  // ===== MÉTODOS PARA GESTIÓN DE MODOS DE FUENTES =====

  // Obtener modo actual de una moneda
  Future<String> getMonedaMode(String moneda) async {
    try {
      final mode = await _dbService.getConfig('${moneda.toLowerCase()}_mode');
      return mode ?? 'AUTO';
    } catch (e) {
      return 'AUTO';
    }
  }

  // Establecer modo de una moneda
  Future<void> setMonedaMode(String moneda, String mode) async {
    try {
      await _dbService.setConfig('${moneda.toLowerCase()}_mode', mode);
      AppLogger.i('Modo de $moneda cambiado a: $mode');
      notifyListeners();
    } catch (e) {
      AppLogger.e('Error cambiando modo de $moneda', e);
    }
  }

  // Actualizar una moneda específica según su modo
  Future<bool> updateMoneda(String moneda, BuildContext context) async {
    try {
      _setLoading(true);
      final mode = await getMonedaMode(moneda);

      AppLogger.i('Actualizando $moneda en modo: $mode');

      if (mode == 'MANUAL') {
        // En modo manual, no se actualiza automáticamente
        AppLogger.i('$moneda está en modo MANUAL - no se actualiza');
        return true;
      }

      final result = await MonedaFetcher.fetch(moneda, mode);

      if (result.success && !result.isManual) {
        // Guardar valor y fuente
        await _saveMonedaValue(moneda, result.value!, result.source!);
        await loadMonedaData();
        await loadCurrentUi();
        _error = null;
        AppLogger.i(
            '$moneda actualizado desde ${result.source}: ${result.value}');
        return true;
      } else if (!result.success) {
        // Falló la obtención - mostrar diálogo manual obligatorio
        final manualValue =
            await _showManualEntryDialog(context, moneda, result.error!);

        if (manualValue != null) {
          await _saveMonedaValue(moneda, manualValue, 'MANUAL');
          await loadMonedaData();
          await loadCurrentUi();
          // Cambiar automáticamente a modo MANUAL
          await setMonedaMode(moneda, 'MANUAL');
          AppLogger.i('$moneda guardado manualmente: $manualValue');
          return true;
        }
      }

      return false;
    } catch (e) {
      _error = 'Error actualizando $moneda: ${e.toString()}';
      AppLogger.e('Error en updateMoneda', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar todas las monedas según sus modos
  Future<void> updateAllMonedas(BuildContext context) async {
    try {
      _setLoading(true);
      AppLogger.i('Actualizando todas las monedas según sus modos');

      await updateMoneda('USD', context);
      await updateMoneda('UI', context);
      await updateMoneda('UR', context);

      _error = null;
      AppLogger.i('Todas las monedas actualizadas');
    } catch (e) {
      _error = 'Error actualizando monedas: ${e.toString()}';
      AppLogger.e('Error en updateAllMonedas', e);
    } finally {
      _setLoading(false);
    }
  }

  // Establecer valor manual para una moneda
  Future<void> setManualMonedaValue(String moneda, double value) async {
    try {
      await _saveMonedaValue(moneda, value, 'MANUAL');
      await setMonedaMode(moneda, 'MANUAL');
      await loadMonedaData();
      AppLogger.i('$moneda establecido manualmente: $value');
    } catch (e) {
      AppLogger.e('Error estableciendo $moneda manual', e);
    }
  }

  // Guardar valor de moneda en base de datos
  Future<void> _saveMonedaValue(
      String moneda, double value, String source) async {
    final now = DateTime.now().toIso8601String();
    switch (moneda) {
      case 'USD':
        await _dbService.setConfig('dolar_venta', value.toString());
        await _dbService.setConfig('dolar_source', source);
        await _dbService.setConfig('dolar_last_update', now);
        break;
      case 'UI':
        await _dbService.setConfig('current_ui_value', value.toString());
        await _dbService.setConfig('ui_source', source);
        await _dbService.setConfig('ui_last_update', now);
        break;
      case 'UR':
        await _dbService.setConfig('ur_value', value.toString());
        await _dbService.setConfig('ur_source', source);
        await _dbService.setConfig('ur_last_update', now);
        break;
    }
  }

  // Mostrar diálogo de ingreso manual obligatorio
  Future<double?> _showManualEntryDialog(
      BuildContext context, String moneda, String error) async {
    return await showDialog<double>(
      context: context,
      barrierDismissible: false, // Obligatorio
      builder: (context) => ManualEntryDialog(
        moneda: moneda,
        errorMessage: error,
      ),
    );
  }
}
