import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../services/database_service.dart';
import '../services/ur_service.dart';
import '../models/moneda_data.dart';
import '../utils/logger.dart';
import '../utils/date_formatter.dart';
import '../config/app_config.dart';

class UiService {
  // Obtener valores de UI y UR desde BCU usando SOAP
  static Future<Map<String, double>> fetchUiUrFromBCU({bool isFallback = false}) async {
    if (kIsWeb) return {'ui': 0.0, 'ur': 0.0}; // BCU bloqueado por CORS en web
    try {
      AppLogger.i('Obteniendo UI y UR desde BCU usando SOAP (Fallback: $isFallback)');

      final today = DateTime.now();
      final fechaStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final soapXml = '''<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:cot="Cotiza">
   <soapenv:Header />
   <soapenv:Body>
      <cot:wsbcucotizaciones.Execute>
         <cot:Entrada>
            <cot:Moneda>
               <cot:item>${AppConfig.monedaUi}</cot:item>
               <cot:item>${AppConfig.monedaUr}</cot:item>
            </cot:Moneda>
            <cot:FechaDesde>$fechaStr</cot:FechaDesde>
            <cot:FechaHasta>$fechaStr</cot:FechaHasta>
            <cot:Grupo>0</cot:Grupo>
         </cot:Entrada>
      </cot:wsbcucotizaciones.Execute>
   </soapenv:Body>
</soapenv:Envelope>''';

      final timeout = isFallback ? AppConfig.bcuFallbackTimeout : AppConfig.apiTimeout;

      final response = await http
          .post(
            Uri.parse(AppConfig.bcuApiUrl),
            headers: {
              'Content-Type': 'text/xml; charset=utf-8',
              'SOAPAction': AppConfig.bcuSoapAction,
            },
            body: soapXml,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return _parseXmlResponse(response.body);
      }

      return {'ui': 0.0, 'ur': 0.0};
    } catch (e) {
      AppLogger.e('Error obteniendo valores desde BCU', e);
      return {'ui': 0.0, 'ur': 0.0};
    }
  }

  // Parsear respuesta XML del BCU
  static Map<String, double> _parseXmlResponse(String xml) {
    double? uiValue;
    double? urValue;

    try {
      final cotizacionPattern = RegExp(
        r'<datoscotizaciones\.dato[^>]*>.*?</datoscotizaciones\.dato>',
        dotAll: true,
      );
      final cotizaciones = cotizacionPattern.allMatches(xml).toList();

      for (var cot in cotizaciones) {
        final cotText = cot.group(0) ?? '';

        final monedaMatch = RegExp(
          r'<Moneda>(\d+)</Moneda>',
        ).firstMatch(cotText);
        final valorMatch = RegExp(r'<TCV>([^<]+)</TCV>').firstMatch(cotText);

        if (monedaMatch != null && valorMatch != null) {
          final moneda = monedaMatch.group(1);
          final valorStr = valorMatch.group(1)?.replaceAll(',', '.') ?? '0';
          final valor = double.tryParse(valorStr);

          if (moneda == AppConfig.monedaUi && valor != null) {
            uiValue = valor;
          } else if (moneda == AppConfig.monedaUr && valor != null) {
            urValue = valor;
          }
        }
      }
    } catch (e) {
      AppLogger.e('Error parseando XML del BCU', e);
    }

    return {'ui': uiValue ?? 0.0, 'ur': urValue ?? 0.0};
  }

  // Obtener valor de UI desde la API (usando BCU)
  static Future<UiResult> fetchUiValue() async {
    try {
      AppLogger.i('Obteniendo valor UI desde DolarApi');
      // Intentar primero DolarApi por estabilidad y CORS
      final response = await http
          .get(Uri.parse(AppConfig.dolarApiUrl))
          .timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        double? value;
        if (data['venta'] != null) {
          value = double.tryParse(data['venta'].toString());
        } else if (data['compra'] != null) {
          value = double.tryParse(data['compra'].toString());
        } else if (data['valor'] != null) {
          value = double.tryParse(data['valor'].toString());
        }

        if (value != null && value > 0) {
          final source = data['fechaActualizacion']?.toString() ?? 'DolarApi.com';

          await DatabaseService.instance.setConfig(
            'current_ui_value',
            value.toString(),
          );
          await DatabaseService.instance.setConfig('ui_source', source);
          await DatabaseService.instance.setConfig(
            'ui_last_update',
            DateTime.now().toIso8601String(),
          );

          return UiResult.success(value, source);
        }
      }

      if (!kIsWeb) {
        AppLogger.w('DolarApi falló, intentando BCU como fallback');
        final bcuValues = await fetchUiUrFromBCU(isFallback: true);

        if (bcuValues['ui']! > 0) {
          final value = bcuValues['ui']!;
          final source = 'BCU';

          await DatabaseService.instance.setConfig(
            'current_ui_value',
            value.toString(),
          );
          await DatabaseService.instance.setConfig('ui_source', source);
          await DatabaseService.instance.setConfig(
            'ui_last_update',
            DateTime.now().toIso8601String(),
          );

          return UiResult.success(value, source);
        }
      }

      return UiResult.error('No se pudo obtener el valor de UI desde fuentes web');
    } catch (e) {
      AppLogger.e('Error obteniendo valor UI', e);
      return UiResult.error('Error de conexión: ${e.toString()}');
    }
  }

  // Obtener valor de USD (venta) desde la API
  static Future<double> fetchDolarValue() async {
    try {
      final response = await http
          .get(Uri.parse(AppConfig.dolarVentaApiUrl))
          .timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map<String, dynamic>) {
          final dolarVenta = data['venta'] ?? data['compra'];
          if (dolarVenta != null) {
            final value = double.tryParse(dolarVenta.toString()) ??
                AppConfig.defaultDolarValue;

            await DatabaseService.instance.setConfig(
              'dolar_venta',
              value.toString(),
            );
            return value;
          }
        }
      }

      final storedValue = await DatabaseService.instance.getConfig(
        'dolar_venta',
      );
      return double.tryParse(
              storedValue ?? AppConfig.defaultDolarValue.toString()) ??
          AppConfig.defaultDolarValue;
    } catch (e) {
      AppLogger.e('Error obteniendo valor USD', e);
      final storedValue = await DatabaseService.instance.getConfig(
        'dolar_venta',
      );
      return double.tryParse(
              storedValue ?? AppConfig.defaultDolarValue.toString()) ??
          AppConfig.defaultDolarValue;
    }
  }

  // Obtener valor de UR desde BCU
  static Future<double> fetchUrValue() async {
    try {
      double urValue = 0;

      // Intentar primero BCU en móvil/desktop (fuente oficial)
      if (!kIsWeb) {
        AppLogger.i('Intentando obtener UR desde BCU');
        final bcuValues = await fetchUiUrFromBCU();
        urValue = bcuValues['ur'] ?? 0;
      }

      // Si BCU falló o estamos en web, intentar UrService (Proxy/Scraper)
      if (urValue <= 0) {
        AppLogger.i('Intentando obtener UR desde UrService (Proxy/Scraper)');
        urValue = await UrService.getUrValue();
      }

      if (urValue > 0) {
        await DatabaseService.instance.setConfig(
          'ur_value',
          urValue.toString(),
        );
        await DatabaseService.instance.setConfig('ur_source', kIsWeb ? 'WEB (Proxy)' : 'BCU');
        await DatabaseService.instance.setConfig(
          'ur_last_update',
          DateTime.now().toIso8601String(),
        );
        return urValue;
      }

      AppLogger.w('Todas las fuentes de UR fallaron, usando valor guardado');
      final storedValue = await DatabaseService.instance.getConfig('ur_value');
      final fallbackValue =
          double.tryParse(storedValue ?? AppConfig.defaultUrValue.toString()) ??
              AppConfig.defaultUrValue;
      
      return fallbackValue;
    } catch (e) {
      if (!kIsWeb) AppLogger.e('Error obteniendo valor UR', e);
      final storedValue = await DatabaseService.instance.getConfig('ur_value');
      return double.tryParse(
              storedValue ?? AppConfig.defaultUrValue.toString()) ??
          AppConfig.defaultUrValue;
    }
  }

  // Obtener todos los valores de monedas
  static Future<MonedaData> getAllValues() async {
    try {
      final uiValueStr = await DatabaseService.instance.getConfig(
        'current_ui_value',
      );
      final dolarValueStr = await DatabaseService.instance.getConfig(
        'dolar_venta',
      );
      final urValueStr = await DatabaseService.instance.getConfig('ur_value');

      final uiSourceRaw =
          await DatabaseService.instance.getConfig('ui_source') ??
              'DolarApi.com';
      final urSourceRaw =
          await DatabaseService.instance.getConfig('ur_source') ?? 'BCU';

      final uiSource = (uiSourceRaw.contains('BCU') ||
              uiSourceRaw.contains('DolarApi') ||
              uiSourceRaw.contains('API') ||
              uiSourceRaw.contains('BROU'))
          ? 'WEB'
          : 'MANUAL';
      final urSource =
          (urSourceRaw.contains('BCU') || 
           urSourceRaw.contains('API') ||
           urSourceRaw.contains('WEB') ||
           urSourceRaw.contains('Proxy'))
              ? 'WEB'
              : 'MANUAL';

      // Obtener fechas de última actualización
      final uiLastUpdate =
          await DatabaseService.instance.getConfig('ui_last_update') ?? '';
      final urLastUpdate =
          await DatabaseService.instance.getConfig('ur_last_update') ?? '';
      final dolarLastUpdate =
          await DatabaseService.instance.getConfig('dolar_last_update') ?? '';

      return MonedaData(
        ui: double.tryParse(
                uiValueStr ?? AppConfig.defaultUiValue.toString()) ??
            AppConfig.defaultUiValue,
        ur: double.tryParse(
                urValueStr ?? AppConfig.defaultUrValue.toString()) ??
            AppConfig.defaultUrValue,
        dolarVenta: double.tryParse(
                dolarValueStr ?? AppConfig.defaultDolarValue.toString()) ??
            AppConfig.defaultDolarValue,
        ultimaActualizacion: DateTime.now(),
        uiSource: uiSource,
        urSource: urSource,
        dolarSource: 'WEB',
        uiLastUpdate: uiLastUpdate,
        urLastUpdate: urLastUpdate,
        dolarLastUpdate: dolarLastUpdate,
      );
    } catch (e) {
      AppLogger.e('Error obteniendo valores de monedas', e);
      return MonedaData(
        ui: AppConfig.defaultUiValue,
        ur: AppConfig.defaultUrValue,
        dolarVenta: AppConfig.defaultDolarValue,
        ultimaActualizacion: DateTime.now(),
        uiSource: 'MANUAL',
        urSource: 'MANUAL',
        dolarSource: 'WEB',
      );
    }
  }

  // Obtener valor actual de UI desde la base de datos
  static Future<UiData> getCurrentUiValue() async {
    try {
      final valueStr = await DatabaseService.instance.getConfig(
        'current_ui_value',
      );
      final source = await DatabaseService.instance.getConfig('ui_source');
      final lastUpdate = await DatabaseService.instance.getConfig(
        'ui_last_update',
      );

      final value =
          double.tryParse(valueStr ?? AppConfig.defaultUiValue.toString()) ??
              AppConfig.defaultUiValue;

      return UiData(
        value: value,
        source: source ?? 'Manual',
        lastUpdate: lastUpdate ?? DateTime.now().toIso8601String(),
      );
    } catch (e) {
      AppLogger.e('Error obteniendo valor UI actual', e);
      return UiData(
        value: AppConfig.defaultUiValue,
        source: 'Manual',
        lastUpdate: DateTime.now().toIso8601String(),
      );
    }
  }

  // Actualizar valor manualmente
  static Future<void> updateUiValueManually(double value) async {
    await DatabaseService.instance.setConfig(
      'current_ui_value',
      value.toString(),
    );
    await DatabaseService.instance.setConfig('ui_source', 'Manual');
    await DatabaseService.instance.setConfig(
      'ui_last_update',
      DateTime.now().toIso8601String(),
    );
  }
}

class UiResult {
  final bool success;
  final double? value;
  final String? source;
  final String? error;

  UiResult.success(this.value, this.source)
      : success = true,
        error = null;

  UiResult.error(this.error)
      : success = false,
        value = null,
        source = null;
}

class UiData {
  final double value;
  final String source;
  final String lastUpdate;

  UiData({required this.value, required this.source, required this.lastUpdate});

  DateTime get lastUpdateDateTime => DateTime.parse(lastUpdate);

  String get formattedLastUpdate => DateFormatter.formatDateTime(lastUpdateDateTime);
}
