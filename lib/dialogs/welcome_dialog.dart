import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeDialog extends StatefulWidget {
  const WelcomeDialog({super.key});

  static const String _prefKey = 'showWelcomeDialog';

  static Future<bool> shouldShowWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? true;
  }

  static Future<void> setShowWelcome(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }

  static Future<void> showIfEnabled(BuildContext context) async {
    if (await shouldShowWelcome() && context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const WelcomeDialog(),
      );
    }
  }

  @override
  State<WelcomeDialog> createState() => _WelcomeDialogState();
}

class _WelcomeDialogState extends State<WelcomeDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.home_work, color: Color(0xFF2E86C1), size: 32),
          SizedBox(width: 8),
          Text('BHU Control'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📊 Controla tus depósitos en UI (Unidad Indexada)'),
            const SizedBox(height: 8),
            const Text('💰 Calcula automáticamente el valor en pesos'),
            const SizedBox(height: 8),
            const Text('🔄 Sincroniza valores de UI, USD y UR automáticamente'),
            const SizedBox(height: 8),
            const Text('💱 Convierte entre monedas (UI, USD, UR, Pesos)'),
            const SizedBox(height: 16),
            const Text(
              '¡Gestiona tus inversiones de forma simple!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Creada Por Marcelo Pereyra',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Soporte: lm.marcelo@gmail.com',
              style: TextStyle(color: Colors.blue),
            ),
            const SizedBox(height: 16),
            const Divider(),
            CheckboxListTile(
              value: _dontShowAgain,
              onChanged: (value) {
                setState(() {
                  _dontShowAgain = value ?? false;
                });
              },
              title: const Text('No mostrar este mensaje de nuevo'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            if (_dontShowAgain) {
              await WelcomeDialog.setShowWelcome(false);
            }
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E86C1),
            foregroundColor: Colors.white,
          ),
          child: const Text('Comenzar'),
        ),
      ],
    );
  }
}
