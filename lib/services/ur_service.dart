import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/logger.dart';

class UrService {
  static const String _baseUrlDatosUruguay = 'https://datosuruguay.com';

  static double? _parsePrice(String? value) {
    if (value == null) return null;
    try {
      // Remover todo excepto números, coma y punto
      String clean = value.replaceAll(RegExp(r'[^0-9,.]'), '');
      
      // Si tiene ambos, el último suele ser el decimal
      if (clean.contains(',') && clean.contains('.')) {
        if (clean.lastIndexOf(',') > clean.lastIndexOf('.')) {
          // Formato 1.851,83
          clean = clean.replaceAll('.', '').replaceAll(',', '.');
        } else {
          // Formato 1,851.83
          clean = clean.replaceAll(',', '');
        }
      } else if (clean.contains(',')) {
        // Formato 1851,83 -> convertir a 1851.83
        clean = clean.replaceAll(',', '.');
      }
      // Si solo tiene punto, y el valor es > 10000, podría ser miles? 
      // Pero UR está en el rango de ~1800-2000.
      
      final result = double.tryParse(clean);
      if (result != null && result > 1000 && result < 5000) {
        return result;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<double> getUrValue() async {
    try {
      final url = kIsWeb 
          ? 'https://api.allorigins.win/raw?url=${Uri.encodeComponent('https://datosuruguay.com/ur')}'
          : '$_baseUrlDatosUruguay/ur';
          
      AppLogger.i('Obteniendo valor UR desde: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: kIsWeb ? {} : {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        final html = response.body;
        if (html.isEmpty) return AppConfig.defaultUrValue;

        // Buscar UR con patrón más específico
        final pricePattern = RegExp(
          r'UR\s*\$?\s*([\d\.,]+)',
          caseSensitive: false,
        );

        final matches = pricePattern.allMatches(html);
        for (var match in matches) {
          final val = _parsePrice(match.group(1));
          if (val != null) {
            AppLogger.i('UR Encontrada: $val');
            return val;
          }
        }
      }

      return AppConfig.defaultUrValue;
    } catch (e) {
      AppLogger.e('Error fetching UR value', e);
      return AppConfig.defaultUrValue;
    }
  }

  static Future<Map<String, dynamic>> getAllValues() async {
    final val = await getUrValue();
    return {
      'ur': val,
      'source': 'datosuruguay.com',
      'lastUpdate': DateTime.now().toIso8601String(),
    };
  }
}
