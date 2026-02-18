import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/bhu_provider.dart';
import '../utils/currency_formatter.dart';

class ResumePanelWidget extends StatelessWidget {
  const ResumePanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BHUProvider>(
      builder: (context, provider, child) {
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RESULTADOS Y CÁLCULOS',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 16),

                // Grid de resultados
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: _getCrossAxisCount(context),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: _getChildAspectRatio(context),
                  children: [
                    _buildResultCard(
                      context,
                      'TOTAL DEPOSITADO \$',
                      '\$${_formatNumber(provider.totalAmount, 2)}',
                      const Color(0xFF2E86C1), // Azul BHU institucional
                      Icons.account_balance_wallet,
                    ),
                    _buildResultCard(
                      context,
                      'TOTAL DEPOSITADO UI',
                      '${_formatNumber(provider.totalUiAmount, 4)} UI',
                      const Color(0xFF546E7A), // Azul secundario institucional
                      Icons.calculate,
                    ),
                    _buildResultCard(
                      context,
                      'VALOR UI ACTUAL',
                      _formatNumber(provider.monedaData.ui, 4),
                      const Color(0xFF66BB6A), // Verde institucional suave
                      Icons.trending_up,
                      subtitle: provider.monedaData.uiSource,
                    ),
                    _buildResultCard(
                      context,
                      'TOTAL EN CUENTA \$',
                      '\$${_formatNumber(provider.totalCurrentValue, 2)}',
                      const Color(0xFF42A5F5), // Azul intermedio
                      Icons.savings,
                    ),
                    _buildResultCard(
                      context,
                      'GANANCIA \$',
                      '\$${_formatNumber(provider.profit, 2)}',
                      provider.profit >= 0
                          ? const Color(0xFF66BB6A)
                          : const Color(0xFFEF5350),
                      provider.profit >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      subtitle:
                          '${_getProfitPercentage(provider.totalAmount, provider.profit)}%',
                      subtitleColor: provider.profit >= 0
                          ? const Color(0xFF66BB6A)
                          : const Color(0xFFEF5350),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Resumen adicional
                _buildAdditionalInfo(context, provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultCard(
    BuildContext context,
    String title,
    String value,
    Color color,
    IconData icon, {
    String? subtitle,
    Color? subtitleColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono con animación
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 1.0, end: 1.1),
                  duration: const Duration(milliseconds: 150),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Valor principal con animación de entrada
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    value,
                    key: ValueKey(value),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: _getValueFontSize(context),
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 4),

                // Título
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Subtítulo (opcional)
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: subtitleColor ?? color,
                          fontSize: 10,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo(BuildContext context, BHUProvider provider) {
    if (provider.depositos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Comienza agregando tu primer depósito para ver estadísticas detalladas',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final averageDeposit = provider.totalAmount / provider.depositos.length;
    final profitPerDeposit = provider.profit / provider.depositos.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas Adicionales',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            direction: Axis.horizontal,
            spacing: 16,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 100,
                child: _buildStatItem(
                  context,
                  'Depósitos:',
                  '${provider.depositos.length}',
                  Icons.receipt_long,
                ),
              ),
              SizedBox(
                width: 100,
                child: _buildStatItem(
                  context,
                  'Promedio:',
                  '\$${_formatNumber(averageDeposit, 2)}',
                  Icons.bar_chart,
                ),
              ),
              SizedBox(
                width: 110,
                child: _buildStatItem(
                  context,
                  'Ganancia/dep:',
                  '\$${_formatNumber(profitPerDeposit, 2)}',
                  Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            direction: Axis.horizontal,
            spacing: 16,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 200,
                child: _buildStatItem(
                  context,
                  'Última actualización:',
                  provider.monedaData.formattedLastUpdate,
                  Icons.update,
                  isDate: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isDate = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: isDate ? 10 : 12,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 5;
    if (width >= 900) return 3;
    if (width >= 600) return 2;
    return 2;
  }

  double _getChildAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 600) return 1.2;
    return 1.0;
  }

  double _getValueFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 600) return 16;
    return 14;
  }

  String _formatNumber(double number, int decimalPlaces) {
    if (decimalPlaces == 4) {
      return CurrencyFormatter.format(number, 'UI');
    } else {
      return CurrencyFormatter.format(number, 'UYU');
    }
  }

  String _getProfitPercentage(double totalAmount, double profit) {
    if (totalAmount == 0) return '0.0';
    final percentage = (profit / totalAmount * 100);
    return percentage >= 0
        ? '+${percentage.toStringAsFixed(1)}'
        : percentage.toStringAsFixed(1);
  }
}
