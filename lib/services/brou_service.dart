import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/logger.dart';

class BrouService {
  static Future<Map<String, double>> fetchAllCotizaciones() async {
    try {
      AppLogger.i('BROU: Solicitando cotizaciones...');

      final response = await http.get(
        Uri.parse(AppConfig.brouCotizacionesUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
          'Accept-Language': 'es-ES,es;q=0.9',
          'Cache-Control': 'no-cache',
        },
      ).timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        return _parseCotizacionesHtml(response.body);
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      AppLogger.e('BROU: Error de conexión o timeout - $e');
      throw e;
    }
  }

  static Future<MonedaResult> fetchMoneda(String monedaCode) async {
    try {
      final cotizaciones = await fetchAllCotizaciones();
      final key = monedaCode.toUpperCase();

      if (cotizaciones.containsKey(key)) {
        return MonedaResult.success(cotizaciones[key]!, 'BROU');
      }
      return MonedaResult.error('$monedaCode no encontrado');
    } catch (e) {
      return MonedaResult.error('Error: $e');
    }
  }

  static Map<String, double> _parseCotizacionesHtml(String html) {
    final result = <String, double>{};

    try {
      // Limpiar el HTML para facilitar el regex (quitar espacios redundantes)
      final cleanHtml = html.replaceAll(RegExp(r'\s+'), ' ');

      // Regex mejorado para capturar la tabla de cotizaciones
      // Busca el texto y luego los valores numéricos siguientes
      
      // Buscar Dólar
      final dolarMatch = RegExp(
        r'Dólar.*?valor">([\d,\.]+)<.*?valor">([\d,\.]+)<',
        caseSensitive: false,
      ).firstMatch(cleanHtml);

      if (dolarMatch != null) {
        final venta = _parseNumero(dolarMatch.group(2)!);
        if (venta != null) {
          result['USD'] = venta;
          AppLogger.i('BROU (Regex): USD = $venta');
        }
      }

      // Buscar UI
      final uiMatch = RegExp(
        r'Unidad Indexada.*?valor">([\d,\.]+)<',
        caseSensitive: false,
      ).firstMatch(cleanHtml);

      if (uiMatch != null) {
        final val = _parseNumero(uiMatch.group(1)!, isUI: true);
        if (val != null) {
          result['UI'] = val;
          AppLogger.i('BROU (Regex): UI = $val');
        }
      }

      // Si fallan los regex específicos, intentar el método anterior como fallback
      if (result.isEmpty) {
        AppLogger.w('Regex BROU fallaron, intentando fallback por índices...');
        return _parseFallback(html);
      }

      return result;
    } catch (e) {
      AppLogger.e('BROU: Error parseando HTML - $e');
      return result;
    }
  }

  static Map<String, double> _parseFallback(String html) {
    final result = <String, double>{};
    try {
      final dolarIndex = html.indexOf('>Dólar<');
      if (dolarIndex >= 0) {
        final dolarSection = html.substring(dolarIndex, dolarIndex + 500);
        final dolarValores = RegExp(r'<p class="valor">\s*([\d,\.]+)\s*</p>')
            .allMatches(dolarSection)
            .map((m) => m.group(1)!)
            .toList();

        if (dolarValores.length >= 2) {
          final venta = _parseNumero(dolarValores[1]);
          if (venta != null) result['USD'] = venta;
        }
      }

      final uiIndex = html.indexOf('>Unidad Indexada<');
      if (uiIndex >= 0) {
        final uiSection = html.substring(uiIndex, uiIndex + 500);
        final uiValores = RegExp(r'<p class="valor">\s*([\d,\.]+)\s*</p>')
            .allMatches(uiSection)
            .map((m) => m.group(1)!)
            .toList();

        for (final val in uiValores) {
          final num = _parseNumero(val, isUI: true);
          if (num != null && num > 5 && num < 10) {
            result['UI'] = num;
            break;
          }
        }
      }
    } catch (e) {
      AppLogger.e('BROU Fallback: Error - $e');
    }
    return result;
  }

  static double? _parseNumero(String texto, {bool isUI = false}) {
    try {
      String limpio = texto.trim();

      // Formato BROU: 40,10000 (5 dígitos después de la coma)
      // UI tiene 4 decimales: 6,4465 -> 6.4465
      // USD tiene 2 decimales: 40,10 -> 40.10
      if (limpio.contains(',')) {
        final partes = limpio.split(',');
        if (partes.length == 2) {
          final entero = partes[0];
          final decimal = partes[1];

          // Si tiene 5 dígitos decimales
          if (decimal.length == 5) {
            if (isUI) {
              // UI: 6,44650 -> 6.4465 (4 decimales)
              limpio = '$entero.${decimal.substring(0, 4)}';
            } else {
              // USD: 40,10000 -> 40.10 (2 decimales)
              limpio = '$entero.${decimal.substring(0, 2)}';
            }
          } else if (decimal.length == 4 && isUI) {
            // UI con 4 decimales ya: 6,4465 -> 6.4465
            limpio = limpio.replaceAll(',', '.');
          } else if (decimal.length == 2) {
            // Decimal normal: 40,10 -> 40.10
            limpio = limpio.replaceAll(',', '.');
          } else {
            // Otros casos: quitar coma
            limpio = limpio.replaceAll(',', '');
          }
        }
      }

      return double.tryParse(limpio);
    } catch (e) {
      return null;
    }
  }
}

class MonedaResult {
  final bool success;
  final double? value;
  final String? source;
  final String? error;

  MonedaResult.success(this.value, this.source)
      : success = true,
        error = null;

  MonedaResult.error(this.error)
      : success = false,
        value = null,
        source = null;
}
