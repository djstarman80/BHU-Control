import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/bhu_provider.dart';
import '../dialogs/conversion_dialog.dart';
import '../utils/currency_formatter.dart';

class ConversorTabWidget extends StatefulWidget {
  const ConversorTabWidget({super.key});

  @override
  State<ConversorTabWidget> createState() => _ConversorTabWidgetState();
}

class _ConversorTabWidgetState extends State<ConversorTabWidget> {
  final TextEditingController _amountController = TextEditingController();
  String _fromMoneda = 'USD';
  String _toMoneda = 'UYU';
  double _resultado = 0.0;

  final List<String> _monedas = ['USD', 'UYU', 'UI', 'UR'];
  final Map<String, String> _monedaSimbolos = {
    'USD': '\$',
    'UYU': '\$',
    'UI': 'UI',
    'UR': 'UR',
  };
  final Map<String, String> _monedaEmojis = {
    'USD': '💵',
    'UYU': '💵',
    'UI': '📊',
    'UR': '📈',
  };

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _calcular() {
    final text = _amountController.text.replaceAll(',', '.');
    final cantidad = double.tryParse(text) ?? 0.0;
    final provider = context.read<BHUProvider>();
    _resultado = provider.convertir(
      desde: _fromMoneda,
      hacia: _toMoneda,
      cantidad: cantidad,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BHUProvider>();
    final monedaData = provider.monedaData;

    return RefreshIndicator(
      onRefresh: () async {
        await provider.updateAllMonedas(context);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildMonedasActuales(context, provider, monedaData),
            const SizedBox(height: 24),
            _buildCalculadora(context, provider),
            const SizedBox(height: 24),
            _buildConversionesRapidas(context, provider),
            const SizedBox(height: 32),
          ],
        ),
      ),
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
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
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
              Icons.currency_exchange,
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
                  'CONVERSOR DE MONEDAS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Conversión de divisas uruguayas',
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

  Widget _buildMonedasActuales(
      BuildContext context, BHUProvider provider, dynamic monedaData) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'VALORES ACTUALES',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMonedaCard(
                  context,
                  'USD',
                  '\$',
                  monedaData.formattedDolar,
                  const Color(0xFF4CAF50),
                  monedaData.dolarSource,
                ),
                _buildMonedaCard(
                  context,
                  'UI',
                  '',
                  monedaData.formattedUi,
                  const Color(0xFF2196F3),
                  monedaData.uiSource,
                ),
                _buildMonedaCard(
                  context,
                  'UR',
                  '\$',
                  monedaData.formattedUr,
                  const Color(0xFFFF9800),
                  monedaData.urSource,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonedaCard(BuildContext context, String label, String simbolo,
      String valor, Color color, String source) {
    final bool isWeb = source == 'WEB';
    final Color sourceColor = isWeb ? Colors.green : Colors.orange;
    final String sourceText = isWeb ? 'WEB' : 'MANUAL';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$simbolo$valor',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: sourceColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: sourceColor),
            ),
            child: Text(
              sourceText,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: sourceColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculadora(BuildContext context, BHUProvider provider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CALCULADORA',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _fromMoneda,
                    decoration: const InputDecoration(
                      labelText: 'De',
                      border: OutlineInputBorder(),
                    ),
                    items: _monedas.map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(m),
                      );
                    }).toList(),
                    onChanged: (value) {
                      _fromMoneda = value ?? 'USD';
                      _calcular();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.swap_horiz, size: 32),
                  onPressed: () {
                    final temp = _fromMoneda;
                    _fromMoneda = _toMoneda;
                    _toMoneda = temp;
                    _calcular();
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _toMoneda,
                    decoration: const InputDecoration(
                      labelText: 'A',
                      border: OutlineInputBorder(),
                    ),
                    items: _monedas.map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(m),
                      );
                    }).toList(),
                    onChanged: (value) {
                      _toMoneda = value ?? 'UI';
                      _calcular();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
              ],
              decoration: InputDecoration(
                labelText: 'Cantidad en ${_monedaSimbolos[_fromMoneda]}',
                hintText: '0,00',
                prefixIcon: const Icon(Icons.attach_money),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => _calcular(),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'RESULTADO',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_monedaSimbolos[_toMoneda]} ${_formatNumber(_resultado, _toMoneda)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _amountController.clear();
                      _resultado = 0;
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('LIMPIAR'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionesRapidas(BuildContext context, BHUProvider provider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CONVERSIONES RÁPIDAS',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickChip(context, 'USD', 'UYU'),
                    _buildQuickChip(context, 'UYU', 'UI'),
                    _buildQuickChip(context, 'UYU', 'UR'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickChip(context, 'UYU', 'USD'),
                    _buildQuickChip(context, 'UI', 'UYU'),
                    _buildQuickChip(context, 'UR', 'UYU'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(BuildContext context, String from, String to) {
    return ActionChip(
      label: Text('$from → $to'),
      onPressed: () {
        setState(() {
          _fromMoneda = from;
          _toMoneda = to;
        });
        _calcular();
      },
      labelStyle: TextStyle(
        fontSize: 11,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  void _showAdvancedDialog() {
    showDialog(
      context: context,
      builder: (context) => ConversionDialog(),
    );
  }

  String _formatNumber(double number, String moneda) {
    return CurrencyFormatter.format(number, moneda);
  }
}
