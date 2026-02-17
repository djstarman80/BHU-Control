class Deposito {
  final int id;
  final double amount; // Monto en pesos
  final double uiAmount; // Monto en UI
  final String depositDate; // Fecha de depósito (dd-MM-yyyy)
  final double uiValue; // Valor UI al momento del depósito
  final String registrationDate; // Fecha de registro (ISO)

  Deposito({
    required this.id,
    required this.amount,
    required this.uiAmount,
    required this.depositDate,
    required this.uiValue,
    required this.registrationDate,
  });

  // Calcular valor actual en pesos usando el valor UI proporcionado
  double getCurrentValue(double currentUiValue) => uiAmount * currentUiValue;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'ui_amount': uiAmount,
      'deposit_date': depositDate,
      'ui_value': uiValue,
      'registration_date': registrationDate,
    };
  }

  factory Deposito.fromMap(Map<String, dynamic> map) {
    return Deposito(
      id: map['id']?.toInt() ?? 0,
      amount: map['amount']?.toDouble() ?? 0.0,
      uiAmount: map['ui_amount']?.toDouble() ?? 0.0,
      depositDate: map['deposit_date'] ?? '',
      uiValue: map['ui_value']?.toDouble() ?? 0.0,
      registrationDate:
          map['registration_date'] ?? DateTime.now().toIso8601String(),
    );
  }

  Deposito copyWith({
    int? id,
    double? amount,
    double? uiAmount,
    String? depositDate,
    double? uiValue,
    String? registrationDate,
  }) {
    return Deposito(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      uiAmount: uiAmount ?? this.uiAmount,
      depositDate: depositDate ?? this.depositDate,
      uiValue: uiValue ?? this.uiValue,
      registrationDate: registrationDate ?? this.registrationDate,
    );
  }

  @override
  String toString() {
    return 'Deposito(id: $id, amount: $amount, uiAmount: $uiAmount, depositDate: $depositDate, uiValue: $uiValue, registrationDate: $registrationDate)';
  }
}
