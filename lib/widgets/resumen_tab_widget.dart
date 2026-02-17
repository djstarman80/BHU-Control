import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bhu_provider.dart';
import 'resume_panel_widget.dart';

class ResumenTabWidget extends StatelessWidget {
  const ResumenTabWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BHUProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await provider.updateAllMonedas(context);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUIHeader(context, provider),
                const SizedBox(height: 24),
                const ResumePanelWidget(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUIHeader(BuildContext context, BHUProvider provider) {
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
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BANCO HIPOTECARIO DEL URUGUAY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'CONTROL DE DEPÓSITOS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UNIDAD INDEXADA:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        NumberFormat.currency(
                          locale: 'es_UY',
                          symbol: '',
                          decimalDigits: 4,
                        ).format(provider.monedaData.ui).replaceAll(',', '.'),
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${provider.monedaData.uiSource})',
                        style: TextStyle(
                          color: Colors.blue.shade100,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  provider.monedaData.formattedLastUpdate,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
