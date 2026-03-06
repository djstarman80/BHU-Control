import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/bhu_provider.dart';
import '../models/deposito.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class NuevoDepositoTabWidget extends StatefulWidget {
  const NuevoDepositoTabWidget({super.key});

  @override
  State<NuevoDepositoTabWidget> createState() => _NuevoDepositoTabWidgetState();
}

class _NuevoDepositoTabWidgetState extends State<NuevoDepositoTabWidget> {
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
    return Consumer<BHUProvider>(
      builder: (context, provider, child) {
        if (provider.monedaData.ui > 0 && _uiValueController.text.isEmpty) {
          _uiValueController.text = _formatNumber(provider.monedaData.ui, 4);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildForm(context, provider),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.add_circle,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NUEVO DEPÓSITO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
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
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, BHUProvider provider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                    onChanged: (value) => _calculateFromAmount(),
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese el monto';
                      }
                      if (_parseInputValue(value) == null) {
                        return 'Ingrese un número válido';
                      }
                      if (_parseInputValue(value)! <= 0) {
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
                    onChanged: (value) => _calculateFromUI(),
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
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (_parseInputValue(value) == null) {
                          return 'Ingrese un número válido';
                        }
                        if (_parseInputValue(value)! <= 0) {
                          return 'El monto debe ser mayor a 0';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

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

            const SizedBox(height: 20),

            // Valor UI
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _uiValueController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) => _calculateFromAmount(),
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
                      if (_parseInputValue(value) == null) {
                        return 'Ingrese un número válido';
                      }
                      if (_parseInputValue(value)! <= 0) {
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
                    icon: const Icon(Icons.cloud_download, size: 18),
                    label: const Text('BROU'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _useCurrentUi,
                    icon: const Icon(Icons.sync, size: 18),
                    label: const Text('Actual'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _resetForm,
                    icon: const Icon(Icons.cancel),
                    label: const Text('LIMPIAR'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _addDeposit,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.add),
                    label:
                        Text(_isLoading ? 'AGREGANDO...' : 'AGREGAR DEPÓSITO'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        final updatedProvider = context.read<BHUProvider>();
        setState(() {
          _uiValueController.text =
              _formatNumber(updatedProvider.currentUi.value, 4);
          _calculateFromAmount(); // Recalcular con el nuevo valor de la UI
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
            content: Text('Error: $e'),
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
      _calculateFromAmount(); // Recalcular con el nuevo valor de la UI
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
        amount: _parseInputValue(_amountController.text) ?? 0.0,
        uiAmount: _parseInputValue(_uiAmountController.text) ?? 0.0,
        depositDate: DateFormatter.formatDisplay(_selectedDate),
        uiValue: _parseInputValue(_uiValueController.text) ?? 0.0,
        registrationDate: DateTime.now().toIso8601String(),
      );

      final success = await provider.addDeposit(deposito);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Depósito agregado: ${_formatNumber(deposito.amount, 2)}'),
            backgroundColor: Colors.green,
          ),
        );
        _resetForm();
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

  void _resetForm() {
    _amountController.clear();
    _uiAmountController.clear();
    setState(() {
      _selectedDate = DateTime.now();
    });
    HapticFeedback.lightImpact();
  }

  double? _parseInputValue(String text) {
    if (text.isEmpty) return null;
    // Eliminar puntos de miles y reemplazar comas por puntos para el parseo
    final cleanText = text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleanText);
  }

  void _calculateFromAmount() {
    final amount = _parseInputValue(_amountController.text);
    final uiValue = _parseInputValue(_uiValueController.text);

    if (amount != null && uiValue != null && uiValue > 0) {
      final calculatedUI = amount / uiValue;
      final formattedUI = _formatNumber(calculatedUI, 4);
      
      if (_uiAmountController.text != formattedUI) {
        _uiAmountController.text = formattedUI;
      }
    } else if (_amountController.text.isEmpty) {
      _uiAmountController.clear();
    }
  }

  void _calculateFromUI() {
    final uiAmount = _parseInputValue(_uiAmountController.text);
    final uiValue = _parseInputValue(_uiValueController.text);

    if (uiAmount != null && uiValue != null && uiValue > 0) {
      final calculatedAmount = uiAmount * uiValue;
      final formattedAmount = _formatNumber(calculatedAmount, 2);
      
      if (_amountController.text != formattedAmount) {
        _amountController.text = formattedAmount;
      }
    } else if (_uiAmountController.text.isEmpty) {
      _amountController.clear();
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
