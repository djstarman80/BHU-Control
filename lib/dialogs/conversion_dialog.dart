import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/bhu_provider.dart';
import '../utils/currency_formatter.dart';

class ConversionDialog extends StatefulWidget {
  const ConversionDialog({super.key});

  @override
  State<ConversionDialog> createState() => _ConversionDialogState();
}

class _ConversionDialogState extends State<ConversionDialog> {
  final TextEditingController _amountController = TextEditingController();
  String _fromMoneda = 'USD';
  String _toMoneda = 'UYU';
  double _resultado = 0.0;

  final List<Map<String, dynamic>> _monedas = [
    {'code': 'USD', 'symbol': '\$', 'emoji': '💵'},
    {'code': 'UYU', 'symbol': '\$', 'emoji': '💵'},
    {'code': 'UI', 'symbol': 'UI', 'emoji': '📊'},
    {'code': 'UR', 'symbol': 'UR', 'emoji': '📈'},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _calcular() {
    final cantidad = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
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

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.currency_exchange, color: Color(0xFF2E86C1)),
          const SizedBox(width: 8),
          const Text('Conversor de Monedas'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'De:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildMonedaSelector(true),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Cantidad',
                hintText: '0,00',
                prefixIcon: const Icon(Icons.attach_money),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => _calcular(),
            ),
            const SizedBox(height: 16),
            const Text(
              'A:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildMonedaSelector(false),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2E86C1),
                    const Color(0xFF546E7A),
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
                    '${_getMoneda(_toMoneda)['symbol']} ${_formatNumber(_resultado)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
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
                    label: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _copiarResultado,
                    icon: const Icon(Icons.content_copy),
                    label: const Text('Copiar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _buildMonedaSelector(bool isFrom) {
    final selectedMoneda = isFrom ? _fromMoneda : _toMoneda;
    final onChanged = (String? value) {
      if (isFrom) {
        _fromMoneda = value ?? 'USD';
      } else {
        _toMoneda = value ?? 'UI';
      }
      _calcular();
    };

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: _monedas.map((m) {
          final isSelected = m['code'] == selectedMoneda;
          return InkWell(
            onTap: () => onChanged(m['code']),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF2E86C1).withOpacity(0.1)
                    : Colors.transparent,
                border: isSelected
                    ? Border(left: BorderSide(color: const Color(0xFF2E86C1), width: 4))
                    : null,
              ),
              child: Row(
                children: [
                  Text(m['emoji'], style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Text(
                    m['symbol'],
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                      color: isSelected ? const Color(0xFF2E86C1) : Colors.black87,
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check, color: Color(0xFF2E86C1), size: 18),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Map<String, dynamic> _getMoneda(String code) {
    return _monedas.firstWhere((m) => m['code'] == code);
  }

  void _copiarResultado() {
    final texto = '${_getMoneda(_toMoneda)['symbol']} ${_formatNumber(_resultado)}';
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Resultado copiado al portapapeles'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatNumber(double number) {
    return CurrencyFormatter.format(number, 'UYU');
  }
}
