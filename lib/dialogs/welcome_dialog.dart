import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeDialog extends StatelessWidget {
  const WelcomeDialog({super.key});

  static Future<void> showIfFirstLaunch(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (isFirstLaunch && context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const WelcomeDialog(),
      );
      await prefs.setBool('isFirstLaunch', false);
    }
  }

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
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📊 Controla tus depósitos en UI (Unidad Indexada)'),
            SizedBox(height: 8),
            Text('💰 Calcula automáticamente el valor en pesos'),
            SizedBox(height: 8),
            Text('🔄 Sincroniza valores de UI, USD y UR automáticamente'),
            SizedBox(height: 8),
            Text('💱 Convierte entre monedas (UI, USD, UR, Pesos)'),
            SizedBox(height: 16),
            Text(
              '¡Gestiona tus inversiones de forma simple!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            Text(
              'Creada Por Marcelo Pereyra',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Soporte: lm.marcelo@gmail.com',
              style: TextStyle(color: Colors.blue),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
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
