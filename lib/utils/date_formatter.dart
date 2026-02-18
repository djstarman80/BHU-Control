import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _displayFormat = DateFormat('dd-MM-yyyy');
  static final DateFormat _longFormat = DateFormat("d 'de' MMMM 'de' yyyy", 'es_ES');
  static final DateFormat _dateTimeFormat = DateFormat('dd-MM-yyyy HH:mm');
  
  static String formatDisplay(DateTime date) {
    return _displayFormat.format(date);
  }
  
  static String formatLong(DateTime date) {
    return _longFormat.format(date);
  }
  
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }
  
  static String formatLastUpdate(DateTime date) {
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'setiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
  
  static DateTime parse(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    try {
      return _displayFormat.parse(dateStr);
    } catch (e) {
      try {
        return DateTime.parse(dateStr);
      } catch (e2) {
        return DateTime.now();
      }
    }
  }
}

class ProfitCalculator {
  static double calculate(double amount, double uiAmount, double currentUi) {
    return (uiAmount * currentUi) - amount;
  }
  
  static double calculatePercentage(double profit, double amount) {
    if (amount == 0) return 0;
    return (profit / amount) * 100;
  }
  
  static String formatPercentage(double percentage) {
    final sign = percentage >= 0 ? '+' : '';
    return '$sign${percentage.toStringAsFixed(1)}%';
  }
}
