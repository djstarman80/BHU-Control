import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bhu_provider.dart';
import '../models/deposito.dart';
import '../dialogs/edit_deposito_dialog.dart';
import '../utils/currency_formatter.dart';

class DepositosTableWidget extends StatelessWidget {
  final String searchQuery;

  const DepositosTableWidget({
    super.key,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BHUProvider>(
      builder: (context, provider, child) {
        final depositos = provider.searchDepositos(searchQuery);

        return Card(
          elevation: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, depositos.length),
              if (depositos.isEmpty)
                _buildEmptyState(context)
              else
                _buildTable(context, depositos),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'REGISTROS DE DEPÓSITOS',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count ${count == 1 ? 'registro' : 'registros'}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty
                ? 'No hay depósitos registrados'
                : 'No se encontraron resultados para "$searchQuery"',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          if (searchQuery.isEmpty)
            Text(
              'Agrega tu primer depósito usando el formulario superior',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<Deposito> depositos) {
    // Para móviles, mostramos como cards en lugar de tabla
    return Column(
      children: [
        _buildSortButtons(context),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: depositos.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final deposito = depositos[index];
            return _buildDepositoCard(context, deposito, index);
          },
        ),
      ],
    );
  }

  Widget _buildSortButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ActionChip(
            avatar: const Icon(Icons.calendar_today, size: 16),
            label: const Text('Fecha'),
            onPressed: () {
              context.read<BHUProvider>().sortDepositos('date');
            },
          ),
          ActionChip(
            avatar: const Icon(Icons.monetization_on, size: 16),
            label: const Text('Monto'),
            onPressed: () {
              context.read<BHUProvider>().sortDepositos('amount');
            },
          ),
          ActionChip(
            avatar: const Icon(Icons.calculate, size: 16),
            label: const Text('UI'),
            onPressed: () {
              context.read<BHUProvider>().sortDepositos('uiAmount');
            },
          ),
          ActionChip(
            avatar: const Icon(Icons.trending_up, size: 16),
            label: const Text('Valor Actual'),
            onPressed: () {
              context.read<BHUProvider>().sortDepositos('currentValue');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDepositoCard(
      BuildContext context, Deposito deposito, int index) {
    final provider = context.read<BHUProvider>();
    final profit =
        (deposito.uiAmount * provider.monedaData.ui) - deposito.amount;
    final profitPercentage = (profit / deposito.amount) * 100;
    final isProfit = profit >= 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Dismissible(
        key: Key(deposito.id.toString()),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          HapticFeedback.mediumImpact();
          if (direction == DismissDirection.startToEnd) {
            // Editar (derecha a izquierda)
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EditDepositoDialog(deposito: deposito),
              ),
            );
            return false;
          } else {
            // Eliminar (izquierda a derecha)
            return await _confirmDelete(context, deposito);
          }
        },
        background: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.edit, color: Colors.white),
                ),
              ),
              const Spacer(),
              Container(
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.delete, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        child: Card(
          elevation: 4,
          shadowColor: isProfit
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isProfit
                  ? const Color(0xFF66BB6A).withOpacity(0.3)
                  : const Color(0xFFEF5350).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _showDepositOptions(context, deposito);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con ID y fecha mejorado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF2E86C1),
                              const Color(0xFF546E7A),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E86C1).withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'ID: ${deposito.id}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            deposito.depositDate,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Montos principales con mejor diseño
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Monto Original',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  '\$${_formatNumber(deposito.amount, 2)}',
                                  key: ValueKey(deposito.amount),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2E86C1),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Monto UI',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  '${_formatNumber(deposito.uiAmount, 4)} UI',
                                  key: ValueKey(deposito.uiAmount),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF546E7A),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Valor actual mejorado
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF42A5F5).withOpacity(0.1),
                          const Color(0xFF2E86C1).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF42A5F5).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Valor Actual',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: const Color(0xFF42A5F5),
                                  ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                '\$${_formatNumber(deposito.uiAmount * provider.monedaData.ui, 2)}',
                                key: ValueKey('current_value_${deposito.id}'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2E86C1),
                                    ),
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.savings,
                          color: const Color(0xFF42A5F5),
                          size: 20,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Ganancia mejorada con indicador visual
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isProfit
                            ? [
                                const Color(0xFF66BB6A).withOpacity(0.1),
                                const Color(0xFF4CAF50).withOpacity(0.05),
                              ]
                            : [
                                const Color(0xFFEF5350).withOpacity(0.1),
                                const Color(0xFFE53935).withOpacity(0.05),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isProfit
                            ? const Color(0xFF66BB6A).withOpacity(0.4)
                            : const Color(0xFFEF5350).withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isProfit
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    color: isProfit
                                        ? const Color(0xFF66BB6A)
                                        : const Color(0xFFEF5350),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isProfit ? 'Ganancia' : 'Pérdida',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: isProfit
                                              ? const Color(0xFF66BB6A)
                                              : const Color(0xFFEF5350),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  '${isProfit ? '+' : ''}${_formatNumber(profit, 2)} (${isProfit ? '+' : ''}${profitPercentage.toStringAsFixed(1)}%)',
                                  key: ValueKey('profit_${deposito.id}'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isProfit
                                            ? const Color(0xFF66BB6A)
                                            : const Color(0xFFEF5350),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'UI: ${deposito.uiValue.toStringAsFixed(4)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Deposito deposito) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: Text(
                '¿Está seguro que desea eliminar el depósito ID ${deposito.id} por \$${_formatNumber(deposito.amount, 2)}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF5350),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showDepositOptions(BuildContext context, Deposito deposito) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Depósito ID: ${deposito.id}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context, deposito);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title:
                  const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, deposito);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Deposito deposito) {
    showDialog(
      context: context,
      builder: (context) => EditDepositoDialog(deposito: deposito),
    );
  }

  String _formatNumber(double number, int decimalPlaces) {
    if (decimalPlaces == 4) {
      return CurrencyFormatter.format(number, 'UI');
    } else {
      return CurrencyFormatter.format(number, 'UYU');
    }
  }
}
