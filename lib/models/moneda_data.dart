import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

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

  String get formattedUi => CurrencyFormatter.format(ui, 'UI');
  String get formattedUr => CurrencyFormatter.format(ur, 'UR');
  String get formattedDolar => CurrencyFormatter.format(dolarVenta, 'USD');
  String get formattedLastUpdate => DateFormatter.formatLastUpdate(ultimaActualizacion);

  String get fuente => uiSource;
}
