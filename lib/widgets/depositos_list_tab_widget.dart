import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bhu_provider.dart';
import '../models/deposito.dart';
import '../utils/currency_formatter.dart';
import 'edit_deposit_dialog.dart';

class DepositosListTabWidget extends StatefulWidget {
  const DepositosListTabWidget({super.key});

  @override
  State<DepositosListTabWidget> createState() => _DepositosListTabWidgetState();
}

class _DepositosListTabWidgetState extends State<DepositosListTabWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BHUProvider>(
      builder: (context, provider, child) {
        final depositos = provider.searchDepositos(_searchQuery);

        return RefreshIndicator(
          onRefresh: () => provider.updateUiFromApi(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(depositos.length),
                const SizedBox(height: 16),
                _buildSearchField(),
                const SizedBox(height: 12),
                _buildSortChips(context, provider),
                const SizedBox(height: 8),
                if (depositos.isEmpty)
                  _buildEmptyState()
                else
                  _buildDepositosList(context, provider, depositos),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DEPÓSITOS REGISTRADOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count ${count == 1 ? 'depósito' : 'depósitos'}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Total: ${_formatNumber(context.read<BHUProvider>().totalAmount, 2)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Buscar depósitos...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSortChips(BuildContext context, BHUProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 8,
        children: [
          ActionChip(
            avatar: const Icon(Icons.calendar_today, size: 18),
            label: const Text('Fecha'),
            onPressed: () {
              provider.sortDepositos('date');
            },
          ),
          ActionChip(
            avatar: const Icon(Icons.monetization_on, size: 18),
            label: const Text('Monto'),
            onPressed: () {
              provider.sortDepositos('amount');
            },
          ),
          ActionChip(
            avatar: const Icon(Icons.calculate, size: 18),
            label: const Text('UI'),
            onPressed: () {
              provider.sortDepositos('uiAmount');
            },
          ),
          ActionChip(
            avatar: const Icon(Icons.trending_up, size: 18),
            label: const Text('Valor Actual'),
            onPressed: () {
              provider.sortDepositos('currentValue');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
            _searchQuery.isEmpty
                ? 'No hay depósitos registrados'
                : 'No se encontraron resultados para "$_searchQuery"',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (_searchQuery.isEmpty)
            Text(
              'Agrega tu primer depósito desde la pestaña "Nuevo"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildDepositosList(
    BuildContext context,
    BHUProvider provider,
    List<Deposito> depositos,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_UY',
      symbol: '\$',
      decimalDigits: 2,
    );

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: depositos.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final deposito = depositos[index];
        final profit =
            (deposito.uiAmount * provider.monedaData.ui) - deposito.amount;
        final profitPercentage = (profit / deposito.amount) * 100;
        final isProfit = profit >= 0;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isProfit
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => _showDepositOptions(context, deposito, provider),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF2E86C1),
                              const Color(0xFF546E7A),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ID: ${deposito.id}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            deposito.depositDate,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monto Original',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                          Text(
                            currencyFormat.format(deposito.amount),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2E86C1),
                                ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Valor Actual',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                          Text(
                            currencyFormat.format(
                                deposito.uiAmount * provider.monedaData.ui),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF42A5F5),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isProfit
                            ? [
                                Colors.green.withOpacity(0.1),
                                Colors.green.withOpacity(0.05)
                              ]
                            : [
                                Colors.red.withOpacity(0.1),
                                Colors.red.withOpacity(0.05)
                              ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isProfit
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isProfit
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              size: 16,
                              color: isProfit ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isProfit ? 'Ganancia' : 'Pérdida',
                              style: TextStyle(
                                color: isProfit ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${isProfit ? '+' : ''}${currencyFormat.format(profit)} (${isProfit ? '+' : ''}${profitPercentage.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            color: isProfit ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDepositOptions(
      BuildContext context, Deposito deposito, BHUProvider provider) {
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
                _confirmDelete(context, deposito, provider);
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
      builder: (context) => EditDepositDialog(deposito: deposito),
    );
  }

  Future<bool> _confirmDelete(
      BuildContext context, Deposito deposito, BHUProvider provider) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: Text(
                '¿Está seguro que desea eliminar el depósito ID ${deposito.id} por ${_formatNumber(deposito.amount, 2)}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop(true);
                  HapticFeedback.mediumImpact();
                  await provider.deleteDeposit(deposito.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _formatNumber(double number, int decimalPlaces) {
    if (decimalPlaces == 4) {
      return CurrencyFormatter.format(number, 'UI');
    } else {
      return CurrencyFormatter.format(number, 'UYU');
    }
  }
}
