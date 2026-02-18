import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bhu_provider.dart';
import '../models/deposito.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class DepositoFormDialog extends StatefulWidget {
  const DepositoFormDialog({super.key});

  @override
  State<DepositoFormDialog> createState() => _DepositoFormDialogState();
}

class _DepositoFormDialogState extends State<DepositoFormDialog> {
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
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildForm(context),
              ),
            ),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NUEVO DEPÓSITO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Banco Hipotecario del Uruguay',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila de montos
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Monto en pesos (\$)',
                    hintText: '0,00',
                    prefixIcon: const Icon(Icons.monetization_on),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calculate),
                      onPressed: () => _calculateFromUI(),
                      tooltip: 'Calcular desde monto UI',
                    ),
                  ),
                  onChanged: (value) {
                    _validateAndCalculate();
                  },
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
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _uiAmountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Monto en UI',
                    hintText: '0,0000',
                    prefixIcon: const Icon(Icons.calculate),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.monetization_on),
                      onPressed: () => _calculateFromAmount(),
                      tooltip: 'Calcular desde monto pesos',
                    ),
                  ),
                  onChanged: (value) {
                    _validateAndCalculate();
                  },
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

          // Valor UI con Consumer para actualización automática
          Consumer<BHUProvider>(
            builder: (context, provider, child) {
              // Actualizar el controlador cuando cambia el valor UI
              if (provider.monedaData.ui > 0) {
                _uiValueController.text =
                    _formatNumber(provider.monedaData.ui, 4);
              }

              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _uiValueController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Valor UI del día',
                        hintText: '6,4275',
                        prefixIcon: const Icon(Icons.trending_up),
                        border: const OutlineInputBorder(),
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
                      onPressed: _isLoading ? null : _fetchUiFromApi,
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
                      onPressed: _isLoading ? null : _useCurrentUi,
                      icon: const Icon(Icons.sync, size: 16),
                      label: const Text('Actual'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.cancel),
              label: const Text('CANCELAR'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _addDeposit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(_isLoading ? 'AGREGANDO...' : 'AGREGAR DEPÓSITO'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
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

  Future<void> _fetchUiFromApi() async {
    final provider = context.read<BHUProvider>();

    setState(() {
      _isLoading = true;
    });

    try {
      await provider.updateUiFromApi();

      // Esperar a que el provider notifique a los listeners
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        final updatedProvider = context.read<BHUProvider>();
        setState(() {
          _uiValueController.text =
              _formatNumber(updatedProvider.currentUi.value, 4);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'UI actualizada: ${CurrencyFormatter.format(updatedProvider.currentUi.value, 'UI')}'),
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
    setState(() {
      _uiValueController.text = _formatNumber(provider.monedaData.ui, 4);
    });

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
        id: DateTime.now().millisecondsSinceEpoch,
        amount: double.parse(_amountController.text.replaceAll(',', '.')),
        uiAmount: double.parse(_uiAmountController.text.replaceAll(',', '.')),
        depositDate: DateFormatter.formatDisplay(_selectedDate),
        uiValue: double.parse(_uiValueController.text.replaceAll(',', '.')),
        registrationDate: DateTime.now().toIso8601String(),
      );

      final success = await provider.addDeposit(deposito);

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Depósito agregado: \$${_formatNumber(deposito.amount, 2)}'),
            backgroundColor: Colors.green,
          ),
        );
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
            content: Text('💥 Error: ${e.toString()}'),
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

  void _validateAndCalculate() {
    if (_amountController.text.isNotEmpty &&
        _uiValueController.text.isNotEmpty) {
      final amount =
          double.tryParse(_amountController.text.replaceAll(',', '.'));
      final uiValue =
          double.tryParse(_uiValueController.text.replaceAll(',', '.'));

      if (amount != null && uiValue != null && uiValue > 0) {
        final calculatedUI = amount / uiValue;
        _uiAmountController.text = _formatNumber(calculatedUI, 4);
        HapticFeedback.selectionClick();
      }
    }
  }

  void _calculateFromUI() {
    if (_uiAmountController.text.isNotEmpty &&
        _uiValueController.text.isNotEmpty) {
      final uiAmount =
          double.tryParse(_uiAmountController.text.replaceAll(',', '.'));
      final uiValue =
          double.tryParse(_uiValueController.text.replaceAll(',', '.'));

      if (uiAmount != null && uiValue != null && uiValue > 0) {
        final calculatedAmount = uiAmount * uiValue;
        _amountController.text = _formatNumber(calculatedAmount, 2);
        HapticFeedback.lightImpact();
      }
    }
  }

  void _calculateFromAmount() {
    if (_amountController.text.isNotEmpty &&
        _uiValueController.text.isNotEmpty) {
      final amount =
          double.tryParse(_amountController.text.replaceAll(',', '.'));
      final uiValue =
          double.tryParse(_uiValueController.text.replaceAll(',', '.'));

      if (amount != null && uiValue != null && uiValue > 0) {
        final calculatedUI = amount / uiValue;
        _uiAmountController.text = _formatNumber(calculatedUI, 4);
        HapticFeedback.lightImpact();
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
