class CurrencyFormatter {
  static String format(double value, String currency) {
    switch (currency) {
      case 'UI':
        return _formatUI(value);
      case 'UR':
        return _formatWithThousands(value, 2);
      case 'USD':
        return _formatUSD(value);
      case 'UYU':
        return _formatUYU(value);
      default:
        return value.toStringAsFixed(2).replaceAll('.', ',');
    }
  }

  static String _formatUI(double value) {
    return value.toStringAsFixed(4).replaceAll('.', ',');
  }

  static String _formatUSD(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  static String _formatUYU(double value) {
    return _formatWithThousands(value, 0);
  }

  static String _formatWithThousands(double value, int decimals) {
    final parts = value.toStringAsFixed(decimals).split('.');
    final intPart = int.parse(parts[0]);
    final decPart = decimals > 0 ? parts[1] : '';
    
    final intStr = intPart.abs().toString();
    final buffer = StringBuffer();
    
    for (int i = 0; i < intStr.length; i++) {
      if (i > 0 && (intStr.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(intStr[i]);
    }
    
    var result = intPart < 0 ? '-${buffer.toString()}' : buffer.toString();
    
    if (decimals > 0 && decPart.isNotEmpty) {
      result = '$result,$decPart';
    }
    
    return result;
  }
}
