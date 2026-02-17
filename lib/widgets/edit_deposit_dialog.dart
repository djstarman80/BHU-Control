import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bhu_provider.dart';
import '../models/deposito.dart';

class EditDepositDialog extends StatefulWidget {
  final Deposito deposito;

  const EditDepositDialog({super.key, required this.deposito});

  @override
  State<EditDepositDialog> createState() => _EditDepositDialogState();
}

class _EditDepositDialogState extends State<EditDepositDialog> {
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
      text: widget.deposito.amount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _uiAmountController = TextEditingController(
      text: widget.deposito.uiAmount.toStringAsFixed(4).replaceAll('.', ','),
    );
    _uiValueController = TextEditingController(
      text: widget.deposito.uiValue.toStringAsFixed(4).replaceAll('.', ','),
    );
    _selectedDate = _parseDate(widget.deposito.depositDate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _uiAmountController.dispose();
    _uiValueController.dispose();
    super.dispose();
  }

  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      return DateTime(
          int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } catch (e) {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<BHUProvider>();

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.edit, color: Color(0xFF2E86C1)),
          const SizedBox(width: 8),
          Text('Editar Depósito #${widget.deposito.id}'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
              TextFormField(
                controller: _uiAmountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto en UI',
                  hintText: '0,0000',
                  prefixIcon: Icon(Icons.calculate),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value.replaceAll(',', '.')) == null) {
                      return 'Ingrese un número válido';
                    }
                    if (double.tryParse(value.replaceAll(',', '.'))! <= 0) {
                      return 'El monto debe ser mayor a 0';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
              TextFormField(
                controller: _uiValueController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _useCurrentUi,
                      icon: const Icon(Icons.sync, size: 18),
                      label: const Text('Actual'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _updateDeposit,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: Text(_isLoading ? 'Guardando...' : 'Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
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

  void _useCurrentUi() {
    final provider = context.read<BHUProvider>();
    setState(() {
      _uiValueController.text =
          provider.monedaData.ui.toStringAsFixed(4).replaceAll('.', ',');
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Valor UI actual aplicado'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _validateAndCalculate() {
    if (_amountController.text.isNotEmpty &&
        _uiValueController.text.isNotEmpty) {
      final amount =
          double.tryParse(_amountController.text.replaceAll(',', '.'));
      final uiValue =
          double.tryParse(_uiValueController.text.replaceAll(',', '.'));

      if (amount != null && uiValue != null && uiValue > 0) {
        final calculatedUI = amount / uiValue;
        _uiAmountController.text =
            calculatedUI.toStringAsFixed(4).replaceAll('.', ',');
      }
    }
  }

  Future<void> _updateDeposit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<BHUProvider>();
      final updatedDeposito = Deposito(
        id: widget.deposito.id,
        amount: double.parse(_amountController.text.replaceAll(',', '.')),
        uiAmount: double.parse(_uiAmountController.text.replaceAll(',', '.')),
        depositDate: DateFormat('dd-MM-yyyy').format(_selectedDate),
        uiValue: double.parse(_uiValueController.text.replaceAll(',', '.')),
        registrationDate: widget.deposito.registrationDate,
      );

      final success = await provider.updateDeposit(updatedDeposito);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Depósito actualizado'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else if (mounted && provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${provider.error!}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('💥 Error: $e'),
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
}
