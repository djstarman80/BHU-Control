import 'package:intl/intl.dart';

class MonedaData {
  final double ui;
  final double ur;
  final double dolarVenta;
  final DateTime ultimaActualizacion;
  final String uiSource;
  final String urSource;
  final String dolarSource;
  final String uiLastUpdate;
  final String urLastUpdate;
  final String dolarLastUpdate;

  MonedaData({
    required this.ui,
    required this.ur,
    required this.dolarVenta,
    required this.ultimaActualizacion,
    required this.uiSource,
    required this.urSource,
    required this.dolarSource,
    this.uiLastUpdate = '',
    this.urLastUpdate = '',
    this.dolarLastUpdate = '',
  });

  String get formattedUi => ui.toStringAsFixed(4);
  String get formattedUr => _formatNumber(ur);
  String get formattedDolar => _formatNumber(dolarVenta);

  String get formattedLastUpdate {
    final months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'setiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    return '${ultimaActualizacion.day} ${months[ultimaActualizacion.month - 1]} ${ultimaActualizacion.year}';
  }

  String _formatNumber(double number) {
    final formatter = NumberFormat.currency(
      locale: 'es_UY',
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(number).replaceAll(',', '.');
  }

  String get fuente => uiSource;
}
