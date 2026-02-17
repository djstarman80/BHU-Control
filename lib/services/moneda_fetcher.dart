import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/app_config.dart';
import '../services/brou_service.dart';
import '../services/ui_service.dart';
import '../utils/logger.dart';

class MonedaFetcher {
  // Obtener valor según modo configurado
  static Future<FetchResult> fetch(String moneda, String mode) async {
    AppLogger.i('Fetch $moneda en modo: $mode');

    switch (mode) {
      case 'AUTO':
        return await _fetchWithFallback(moneda);
      case 'BROU':
        if (kIsWeb) return FetchResult.error('BROU no disponible en web por CORS');
        return await _fetchFromBrou(moneda);
      case 'BCU':
        if (kIsWeb) {
          if (moneda == 'UR') {
            // UR no tiene fuente alternativa en web, usar valor guardado como éxito
            final val = await UiService.fetchUrValue();
            return FetchResult.success(val, 'Valor guardado (WEB)');
          }
          return FetchResult.error('BCU no disponible en web por CORS. Intente DolarApi.');
        }
        return await _fetchFromBcu(moneda);
      case 'DolarApi':
        return await _fetchFromDolarApi(moneda);
      case 'MANUAL':
        return FetchResult.manual();
      default:
        return FetchResult.error('Modo desconocido: $mode');
    }
  }

  // Modo AUTO: Intentar fuentes en orden de prioridad
  static Future<FetchResult> _fetchWithFallback(String moneda) async {
    final config = AppConfig.monedaConfigs[moneda];
    if (config == null) {
      return FetchResult.error('Configuración no encontrada para $moneda');
    }

    final errors = <String>[];

    for (String source in config.webSources) {
      try {
        if (kIsWeb && (source == 'BROU' || source == 'BCU')) {
          if (moneda == 'UR') {
            // Para UR en web, intentar UrService (que usa proxy)
            final val = await UiService.fetchUrValue();
            if (val > 0) return FetchResult.success(val, 'WEB (Proxy)');
            errors.add('Proxy UR: Sin datos');
          } else {
            AppLogger.w('Omitiendo fuente web $source por restricciones de CORS');
          }
          continue;
        }

        FetchResult result;
// ... (rest of method)

// ... (rest of the loop)


        switch (source) {
          case 'BROU':
            result = await _fetchFromBrou(moneda);
            break;
          case 'BCU':
            result = await _fetchFromBcu(moneda);
            break;
          case 'DolarApi':
            result = await _fetchFromDolarApi(moneda);
            break;
          default:
            continue;
        }

        if (result.success) {
          AppLogger.i('$moneda obtenido de $source: ${result.value}');
          return result;
        } else {
          errors.add('$source: ${result.error}');
        }
      } catch (e) {
        errors.add('$source: ${e.toString()}');
        AppLogger.w('Fuente $source falló para $moneda: $e');
      }
    }

    // Todas las fuentes web fallaron
    final errorMsg = 'Todas las fuentes fallaron:\n${errors.join('\n')}';
    AppLogger.e(errorMsg);
    return FetchResult.error(errorMsg);
  }

  // Fetch desde BROU
  static Future<FetchResult> _fetchFromBrou(String moneda) async {
    try {
      if (kIsWeb) return FetchResult.error('BROU no disponible en web por CORS');
      final result = await BrouService.fetchMoneda(moneda);

      if (result.success && result.value != null) {
        return FetchResult.success(result.value!, 'BROU');
      } else {
        return FetchResult.error(result.error ?? 'BROU: Sin datos');
      }
    } catch (e) {
      return FetchResult.error('BROU: ${e.toString()}');
    }
  }

  // Fetch desde BCU
  static Future<FetchResult> _fetchFromBcu(String moneda) async {
    try {
      if (kIsWeb) {
        if (moneda == 'UR') {
          // UR no tiene fuente alternativa en web, usar valor guardado como éxito
          final val = await UiService.fetchUrValue();
          return FetchResult.success(val, 'Valor guardado (WEB)');
        }
        return FetchResult.error('BCU no disponible en web por CORS. Intente DolarApi.');
      }

      if (moneda == 'UI' || moneda == 'UR') {
        final bcuValues = await UiService.fetchUiUrFromBCU();

        if (moneda == 'UI' && bcuValues['ui']! > 0) {
          return FetchResult.success(bcuValues['ui']!, 'BCU');
        } else if (moneda == 'UR' && bcuValues['ur']! > 0) {
          return FetchResult.success(bcuValues['ur']!, 'BCU');
        }

        return FetchResult.error('BCU: Moneda $moneda no disponible');
      } else {
        return FetchResult.error('BCU: Solo disponible para UI y UR');
      }
    } catch (e) {
      return FetchResult.error('BCU: ${e.toString()}');
    }
  }

  // Fetch desde DolarApi
  static Future<FetchResult> _fetchFromDolarApi(String moneda) async {
    try {
      if (moneda == 'USD') {
        final value = await UiService.fetchDolarValue();
        return FetchResult.success(value, 'DolarApi');
      } else if (moneda == 'UI') {
        final result = await UiService.fetchUiValue();
        if (result.success && result.value != null) {
          return FetchResult.success(result.value!, 'DolarApi');
        }
        return FetchResult.error('DolarApi: ${result.error ?? 'Sin datos'}');
      } else {
        return FetchResult.error('DolarApi: Solo disponible para USD y UI');
      }
    } catch (e) {
      return FetchResult.error('DolarApi: ${e.toString()}');
    }
  }
}

class FetchResult {
  final bool success;
  final double? value;
  final String? source;
  final String? error;
  final bool isManual;

  FetchResult.success(this.value, this.source)
      : success = true,
        error = null,
        isManual = false;

  FetchResult.error(this.error)
      : success = false,
        value = null,
        source = null,
        isManual = false;

  FetchResult.manual()
      : success = true,
        value = null,
        source = 'MANUAL',
        error = null,
        isManual = true;
}
