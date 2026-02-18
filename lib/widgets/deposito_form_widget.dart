import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bhu_provider.dart';
import '../models/deposito.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class DepositoFormWidget extends StatefulWidget {
  const DepositoFormWidget({super.key});

  @override
  State<DepositoFormWidget> createState() => _DepositoFormWidgetState();
}

class _DepositoFormWidgetState extends State<DepositoFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _uiAmountController = TextEditingController();
  final _uiValueController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _uiAmountController.dispose();
    _uiValueController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BHUProvider>();
      _uiValueController.text = _formatNumber(provider.monedaData.ui, 4);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NUEVO DEPÓSITO',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 16),

              // Fila de montos
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
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
                        if (double.tryParse(value.replaceAll(',', '.')) ==
                            null) {
                          return 'Ingrese un número válido';
                        }
                        if (double.tryParse(value.replaceAll(',', '.'))! <= 0) {
                          return 'El monto debe ser mayor a 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
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
                        if (value == null || value.isEmpty) {
                          return 'Ingrese el monto en UI';
                        }
                        if (double.tryParse(value.replaceAll(',', '.')) ==
                            null) {
                          return 'Ingrese un número válido';
                        }
                        if (double.tryParse(value.replaceAll(',', '.'))! <= 0) {
                          return 'El monto debe ser mayor a 0';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
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
                    DateFormatter.formatDisplay(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Valor UI
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
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
                        if (double.tryParse(value.replaceAll(',', '.')) ==
                            null) {
                          return 'Ingrese un número válido';
                        }
                        if (double.tryParse(value.replaceAll(',', '.'))! <= 0) {
                          return 'El valor debe ser mayor a 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: _fetchUiFromApi,
                      icon: const Icon(Icons.cloud_download, size: 16),
                      label: const Text('BROU'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _useCurrentUi,
                      icon: const Icon(Icons.sync, size: 16),
                      label: const Text('Actual'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Botón de agregar
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _addDeposit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(_isLoading ? 'Agregando...' : 'AGREGAR DEPÓSITO'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
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

  Future<void> _fetchUiFromApi() async {
    final provider = context.read<BHUProvider>();

    setState(() {
      _isLoading = true;
    });

    try {
      await provider.updateUiFromApi();
      _uiValueController.text = _formatNumber(provider.monedaData.ui, 4);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'UI actualizada: ${CurrencyFormatter.format(provider.monedaData.ui, 'UI')}'),
            backgroundColor: Colors.green,
          ),
        );
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

  void _useCurrentUi() {
    final provider = context.read<BHUProvider>();
    _uiValueController.text = _formatNumber(provider.monedaData.ui, 4);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Valor UI actual aplicado'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _addDeposit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<BHUProvider>();
      final deposito = Deposito(
        id: DateTime.now().millisecondsSinceEpoch, // ID temporal
        amount: double.parse(_amountController.text.replaceAll(',', '.')),
        uiAmount: double.parse(_uiAmountController.text.replaceAll(',', '.')),
        depositDate: DateFormatter.formatDisplay(_selectedDate),
        uiValue: double.parse(_uiValueController.text.replaceAll(',', '.')),
        registrationDate: DateTime.now().toIso8601String(),
      );

      final success = await provider.addDeposit(deposito);

      if (success && mounted) {
        _clearForm();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Depósito agregado: \$${_formatNumber(deposito.amount, 2)}'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted && provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            backgroundColor: Colors.red,
          ),
        );
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

  void _clearForm() {
    _amountController.clear();
    _uiAmountController.clear();
    _selectedDate = DateTime.now();

    // Restaurar valor UI actual
    final provider = context.read<BHUProvider>();
    _uiValueController.text = _formatNumber(provider.monedaData.ui, 4);
  }

  String _formatNumber(double number, int decimalPlaces) {
    if (decimalPlaces == 4) {
      return CurrencyFormatter.format(number, 'UI');
    } else {
      return CurrencyFormatter.format(number, 'UYU');
    }
  }
}
