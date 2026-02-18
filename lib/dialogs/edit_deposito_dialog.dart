import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bhu_provider.dart';
import '../models/deposito.dart';
import '../utils/currency_formatter.dart';

class EditDepositoDialog extends StatefulWidget {
  final Deposito deposito;

  const EditDepositoDialog({
    super.key,
    required this.deposito,
  });

  @override
  State<EditDepositoDialog> createState() => _EditDepositoDialogState();
}

class _EditDepositoDialogState extends State<EditDepositoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _uiAmountController;
  late final TextEditingController _uiValueController;
  late DateTime _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: _formatNumber(widget.deposito.amount, 2),
    );
    _uiAmountController = TextEditingController(
      text: _formatNumber(widget.deposito.uiAmount, 4),
    );
    _uiValueController = TextEditingController(
      text: _formatNumber(widget.deposito.uiValue, 4),
    );
    
    // Parsear la fecha del formato dd-MM-yyyy
    final dateParts = widget.deposito.depositDate.split('-');
    _selectedDate = DateTime(
      int.parse(dateParts[2]),
      int.parse(dateParts[1]),
      int.parse(dateParts[0]),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _uiAmountController.dispose();
    _uiValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Editar Depósito',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ID: ${widget.deposito.id}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Formulario
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Monto en pesos
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Monto en pesos (\$)',
                            hintText: '0,00',
                            prefixIcon: Icon(Icons.monetization_on),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese el monto';
                            }
                            if (double.tryParse(value.replaceAll(',', '.')) == null) {
                              return 'Ingrese un número válido';
                            }
                            if (double.tryParse(value.replaceAll(',', '.'))! <= 0) {
                              return 'El monto debe ser mayor a 0';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Monto en UI
                        TextFormField(
                          controller: _uiAmountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Monto en UI',
                            hintText: '0,0000',
                            prefixIcon: Icon(Icons.calculate),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese el monto en UI';
                            }
                            if (double.tryParse(value.replaceAll(',', '.')) == null) {
                              return 'Ingrese un número válido';
                            }
                            if (double.tryParse(value.replaceAll(',', '.'))! <= 0) {
                              return 'El monto debe ser mayor a 0';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Fecha de depósito
                        InkWell(
                          onTap: _selectDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Fecha de depósito',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              DateFormat('dd-MM-yyyy').format(_selectedDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Valor UI del día
                        TextFormField(
                          controller: _uiValueController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Valor UI del día',
                            hintText: '6,4275',
                            prefixIcon: Icon(Icons.trending_up),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese el valor UI';
                            }
                            if (double.tryParse(value.replaceAll(',', '.')) == null) {
                              return 'Ingrese un número válido';
                            }
                            if (double.tryParse(value.replaceAll(',', '.'))! <= 0) {
                              return 'El valor debe ser mayor a 0';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Resumen de cambios
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Resumen',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildSummaryRow(
                                'Monto Original:',
                                '\$${_formatNumber(widget.deposito.amount, 2)}',
                              ),
                              _buildSummaryRow(
                                'Nuevo Monto:',
                                '\$${_formatNumber(double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0, 2)}',
                              ),
                              const Divider(),
                              _buildSummaryRow(
                                'Valor Actual:',
                                '\$${_formatNumber(_getNewCurrentValue(), 2)}',
                                isBold: true,
                                color: _getNewCurrentValue() >= widget.deposito.amount 
                                    ? Colors.green 
                                    : Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      child: _isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Guardar Cambios'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  double _getNewCurrentValue() {
    final uiAmount = double.tryParse(_uiAmountController.text.replaceAll(',', '.')) ?? 0;
    final provider = context.read<BHUProvider>();
    return uiAmount * provider.currentUi.value;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedDeposito = widget.deposito.copyWith(
        amount: double.parse(_amountController.text.replaceAll(',', '.')),
        uiAmount: double.parse(_uiAmountController.text.replaceAll(',', '.')),
        depositDate: DateFormat('dd-MM-yyyy').format(_selectedDate),
        uiValue: double.parse(_uiValueController.text.replaceAll(',', '.')),
        registrationDate: DateTime.now().toIso8601String(),
      );

      final success = await context.read<BHUProvider>().updateDeposit(updatedDeposito);

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Depósito actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        final provider = context.read<BHUProvider>();
        if (provider.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatNumber(double number, int decimalPlaces) {
    if (decimalPlaces == 4) {
      return CurrencyFormatter.format(number, 'UI');
    } else {
      return CurrencyFormatter.format(number, 'UYU');
    }
  }
}