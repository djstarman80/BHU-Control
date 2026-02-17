import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';

class ManualEntryDialog extends StatefulWidget {
  final String moneda;
  final String errorMessage;

  const ManualEntryDialog({
    Key? key,
    required this.moneda,
    required this.errorMessage,
  }) : super(key: key);

  @override
  State<ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends State<ManualEntryDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    // Pre-llenar con valor por defecto
    final config = AppConfig.monedaConfigs[widget.moneda];
    if (config != null) {
      _controller.text = config.defaultValue.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final value = double.tryParse(_controller.text.replaceAll(',', '.'));

    if (value == null || value <= 0) {
      setState(() {
        _errorText = 'Ingrese un valor válido mayor a 0';
      });
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.monedaConfigs[widget.moneda];
    final hintValue = config?.defaultValue.toString() ?? '0.00';

    return WillPopScope(
      onWillPop: () async => false, // No permite cerrar con back button
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '${widget.moneda} - Ingreso Manual',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.errorMessage,
                style: TextStyle(color: Colors.red[700]),
              ),
              SizedBox(height: 16),
              Text(
                'Ingrese el valor manualmente:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Valor ${widget.moneda}',
                  hintText: 'Ej: $hintValue',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  errorText: _errorText,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                autofocus: true,
                onSubmitted: (_) => _validateAndSubmit(),
              ),
              SizedBox(height: 8),
              Text(
                'Este valor se guardará como fuente MANUAL',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Sin botón Cancelar - es obligatorio ingresar un valor
          FilledButton.icon(
            onPressed: _validateAndSubmit,
            icon: Icon(Icons.save),
            label: Text('Guardar Valor'),
          ),
        ],
      ),
    );
  }
}
