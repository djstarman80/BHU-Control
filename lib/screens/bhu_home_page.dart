import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/bhu_provider.dart';
import '../widgets/resumen_tab_widget.dart';
import '../widgets/depositos_list_tab_widget.dart';
import '../widgets/nuevo_deposito_tab_widget.dart';
import '../widgets/conversor_tab_widget.dart';
import 'settings_screen.dart';

class BHUHomePage extends StatefulWidget {
  const BHUHomePage({super.key});

  @override
  State<BHUHomePage> createState() => _BHUHomePageState();
}

class _BHUHomePageState extends State<BHUHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BHUProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ResumenTabWidget(),
          DepositosListTabWidget(),
          NuevoDepositoTabWidget(),
          ConversorTabWidget(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'BHU Control',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      actions: [
        Consumer<BHUProvider>(
          builder: (context, provider, child) {
            return IconButton(
              icon: Icon(
                provider.themeMode == ThemeMode.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onPressed: () => provider.toggleTheme(),
              tooltip: 'Cambiar tema',
            );
          },
        ),
        Consumer<BHUProvider>(
          builder: (context, provider, child) {
            return IconButton(
              onPressed: provider.isLoading
                  ? null
                  : () {
                      provider.refreshMonedasSafe();
                    },
              icon: provider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'Actualizar valores',
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          ),
          tooltip: 'Configuración',
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(icon: Icon(Icons.dashboard), text: 'Resumen'),
          Tab(icon: Icon(Icons.list), text: 'Depósitos'),
          Tab(icon: Icon(Icons.add_circle), text: 'Nuevo'),
          Tab(icon: Icon(Icons.currency_exchange), text: 'Conversor'),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index, String tooltip) {
    final isSelected = _tabController.index == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _tabController.animateTo(index);
          HapticFeedback.lightImpact();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.amber : Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
