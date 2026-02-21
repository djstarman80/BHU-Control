import 'dart:async';
import 'dart:io';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/bhu_provider.dart';
import 'package:file_saver/file_saver.dart';
import '../config/app_config.dart';
import '../dialogs/welcome_dialog.dart';

class ImportProgressDialog extends StatefulWidget {
  final Function(bool success)? onComplete;

  const ImportProgressDialog({super.key, this.onComplete});

  @override
  State<ImportProgressDialog> createState() => _ImportProgressDialogState();
}

class _ImportProgressDialogState extends State<ImportProgressDialog> {
  int _secondsLeft = 20;
  Timer? _timer;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_completed) {
        setState(() {
          _secondsLeft--;
        });
        if (_secondsLeft <= 0) {
          timer.cancel();
          widget.onComplete?.call(false);
        }
      }
    });
  }

  void complete(bool success) {
    if (_completed) return;
    _completed = true;
    _timer?.cancel();
    if (mounted) {
      Navigator.of(context).pop();
      widget.onComplete?.call(success);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Importando datos... ($_secondsLeft seg)'),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (20 - _secondsLeft) / 20,
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Volver',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('💰 VALORES DE MONEDAS'),
          const Divider(),
          _buildMonedasSection(context),
          const SizedBox(height: 24),
          _buildSectionHeader('📁 BACKUPS'),
          const Divider(),
          _buildSettingsItem(
            context,
            icon: Icons.upload_file,
            title: 'Importar Backup',
            subtitle: 'Restaurar datos desde un archivo',
            onTap: () => _showImportDialog(context),
          ),
          _buildSettingsItem(
            context,
            icon: Icons.download,
            title: 'Exportar a CSV',
            subtitle: 'Descargar todos los depósitos',
            onTap: () => _exportToCSV(context),
          ),
          _buildSettingsItem(
            context,
            icon: Icons.backup,
            title: 'Crear Backup',
            subtitle: 'Guardar copia de seguridad',
            onTap: () => _createBackup(context),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('📄 EXPORTAR RESUMEN'),
          const Divider(),
          _buildSettingsItem(
            context,
            icon: Icons.picture_as_pdf,
            title: 'Exportar Resumen Completo a PDF',
            subtitle: 'Incluye estadísticas y todos los depósitos',
            onTap: () => _exportPDF(context),
            iconColor: const Color(0xFFE53935),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('⚙️ PREFERENCIAS'),
          const Divider(),
          _buildWelcomeDialogSwitch(context),
          const SizedBox(height: 24),
          _buildSectionHeader('ℹ️ ACERCA DE'),
          const Divider(),
          _buildSettingsItem(
            context,
            icon: Icons.info,
            title: 'Acerca de BHU Control',
            subtitle: 'Información de la aplicación',
            onTap: () => _showAboutDialog(context),
          ),
          _buildSettingsItem(
            context,
            icon: Icons.description,
            title: 'Licencia',
            subtitle: 'Ver licencia de uso',
            onTap: () => _showLicenseDialog(context),
          ),
          const SizedBox(height: 32),
          _buildAppInfo(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? Theme.of(context).colorScheme.primary)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor ?? Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildMonedasSection(BuildContext context) {
    return Consumer<BHUProvider>(
      builder: (context, provider, child) {
        final monedaData = provider.monedaData;
        return Column(
          children: [
            // USD Card
            _buildMonedaConfigCard(
              context,
              provider,
              moneda: 'USD',
              icon: '💵',
              value: monedaData?.formattedDolar ??
                  AppConfig.defaultDolarValue.toString(),
              availableModes: AppConfig.monedaConfigs['USD']!.availableModes,
            ),
            const SizedBox(height: 12),
            // UI Card
            _buildMonedaConfigCard(
              context,
              provider,
              moneda: 'UI',
              icon: '📊',
              value: monedaData?.formattedUi ??
                  AppConfig.defaultUiValue.toString(),
              availableModes: AppConfig.monedaConfigs['UI']!.availableModes,
            ),
            const SizedBox(height: 12),
            // UR Card
            _buildMonedaConfigCard(
              context,
              provider,
              moneda: 'UR',
              icon: '📈',
              value: monedaData?.formattedUr ??
                  AppConfig.defaultUrValue.toString(),
              availableModes: AppConfig.monedaConfigs['UR']!.availableModes,
            ),
            const SizedBox(height: 16),
            // Botón Actualizar Todas
            FilledButton.icon(
              onPressed: () => _actualizarTodasMonedas(context, provider),
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar Todas'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonedaConfigCard(
    BuildContext context,
    BHUProvider provider, {
    required String moneda,
    required String icon,
    required String value,
    required List<String> availableModes,
  }) {
    return FutureBuilder<String>(
      future: provider.getMonedaMode(moneda),
      builder: (context, snapshot) {
        final currentMode = snapshot.data ?? 'AUTO';
        final isManual = currentMode == 'MANUAL';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con valor
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          moneda,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Selector de modo
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: currentMode,
                        decoration: const InputDecoration(
                          labelText: 'Fuente',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: availableModes.map((mode) {
                          String label;
                          switch (mode) {
                            case 'AUTO':
                              label = 'Automático';
                              break;
                            case 'BROU':
                              label = 'BROU';
                              break;
                            case 'BCU':
                              label = 'BCU';
                              break;
                            case 'DolarApi':
                              label = 'DolarApi';
                              break;
                            case 'MANUAL':
                              label = 'Manual';
                              break;
                            default:
                              label = mode;
                          }
                          return DropdownMenuItem(
                            value: mode,
                            child: Text(label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            provider.setMonedaMode(moneda, value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Botón Actualizar (solo si no es MANUAL)
                    if (!isManual)
                      Expanded(
                        flex: 1,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _actualizarMoneda(context, provider, moneda),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Actualizar'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          onPressed: () => _showEditarMonedaManual(
                              context, provider, moneda),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Editar'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                  ],
                ),
                if (isManual) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Modo Manual: Edite el valor directamente',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditarMonedaManual(
      BuildContext context, BHUProvider provider, String moneda) {
    final config = AppConfig.monedaConfigs[moneda];
    double currentValue;

    switch (moneda) {
      case 'USD':
        currentValue =
            provider.monedaData?.dolarVenta ?? AppConfig.defaultDolarValue;
        break;
      case 'UI':
        currentValue = provider.monedaData?.ui ?? AppConfig.defaultUiValue;
        break;
      case 'UR':
        currentValue = provider.monedaData?.ur ?? AppConfig.defaultUrValue;
        break;
      default:
        currentValue = config?.defaultValue ?? 0.0;
    }

    final controller = TextEditingController(text: currentValue.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar $moneda (Manual)'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Valor $moneda',
              border: const OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value != null && value > 0) {
                  provider.setManualMonedaValue(moneda, value);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ $moneda actualizado manualmente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _actualizarMoneda(
      BuildContext context, BHUProvider provider, String moneda) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text('Actualizando $moneda...'),
            ],
          ),
        );
      },
    );

    try {
      final success = await provider.updateMoneda(moneda, context);

      if (context.mounted) {
        Navigator.of(context).pop();
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $moneda actualizado'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('💥 Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _performImport(BuildContext context) async {
    final provider = context.read<BHUProvider>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return ImportProgressDialog(
          onComplete: (success) {
            Navigator.of(dialogContext).pop();
            if (!context.mounted) return;
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '✅ ${provider.depositos.length} depósitos importados'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('❌ ${provider.error ?? "Tiempo de espera agotado"}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      },
    );

    try {
      final success = await provider.importFromJson();

      Navigator.of(context).pop();

      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('✅ ${provider.depositos.length} depósitos importados'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${provider.error ?? "Error desconocido"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('💥 Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _actualizarTodasMonedas(
      BuildContext context, BHUProvider provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Actualizando monedas...'),
            ],
          ),
        );
      },
    );

    try {
      await provider.updateAllMonedas(context);

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Monedas actualizadas'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Widget _buildMonedaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  void _showEditarMonedasDialog(BuildContext context, BHUProvider provider) {
    final uiController = TextEditingController(
        text: provider.monedaData?.formattedUi ??
            AppConfig.defaultUiValue.toString());
    final urController = TextEditingController(
        text: provider.monedaData?.formattedUr ??
            AppConfig.defaultUrValue.toString());
    final dolarController = TextEditingController(
        text: provider.monedaData?.formattedDolar ??
            AppConfig.defaultDolarValue.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.currency_exchange),
              SizedBox(width: 8),
              Text('Editar Valores'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dolarController,
                  decoration: const InputDecoration(
                    labelText: 'USD (Dólar)',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: uiController,
                  decoration: const InputDecoration(
                    labelText: 'UI (Unidad Indexada)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urController,
                  decoration: const InputDecoration(
                    labelText: 'UR (Unidad Reajustable)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final ui = double.tryParse(uiController.text) ??
                    AppConfig.defaultUiValue;
                final ur = double.tryParse(urController.text) ??
                    AppConfig.defaultUrValue;
                final dolar = double.tryParse(dolarController.text) ??
                    AppConfig.defaultDolarValue;

                provider.setManualMonedaValues(ui: ui, ur: ur, dolar: dolar);

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Valores actualizados manualmente'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _actualizarMonedas(BuildContext context, BHUProvider provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Actualizando valores...'),
            ],
          ),
        );
      },
    );

    try {
      await provider.updateAllMonedas(context);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Valores actualizados desde la web'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAppInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'BHU Control',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            'Versión 1.0.0',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Sistema de Control de Depósitos\nBanco Hipotecario del Uruguay',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Importar Backup'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¿Está seguro que desea importar el backup?'),
              SizedBox(height: 8),
              Text(
                'Esta acción reemplazará todos los datos actuales.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Depósitos existentes'),
              Text('• Valor UI actual'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performImport(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Seleccionar archivo'),
            ),
          ],
        );
      },
    );
  }

  void _exportToCSV(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generando CSV...'),
            ],
          ),
        );
      },
    );

    try {
      final provider = context.read<BHUProvider>();
      final file = await provider.exportCsv();

      Navigator.of(context).pop();

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Depósitos BHU - ${DateTime.now().day} de ${_getMonthName(DateTime.now().month)} de ${DateTime.now().year}',
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error exportando CSV: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _createBackup(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Creando backup...'),
            ],
          ),
        );
      },
    );

    try {
      final provider = context.read<BHUProvider>();

      if (kIsWeb) {
        final jsonString = await provider.createBackupWeb();
        Navigator.of(context).pop();

        final timestamp = DateTime.now().toIso8601String().split('T')[0];
        final fileName = 'bhu_backup_$timestamp.json';

        final blob = html.Blob([jsonString], 'application/json');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Backup descargado: $fileName'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      final file = await provider.createBackup();

      Navigator.of(context).pop();

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Backup BHU - ${DateTime.now().day} de ${_getMonthName(DateTime.now().month)} de ${DateTime.now().year}',
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error creando backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _exportPDF(BuildContext context) async {
    print('DEBUG SETTINGS - _exportPDF() iniciado');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generando PDF...'),
            ],
          ),
        );
      },
    );

    try {
      print('DEBUG: kIsWeb=$kIsWeb, Platform.isWindows=${Platform.isWindows}');
      print('DEBUG SETTINGS - Obteniendo provider...');
      final provider = context.read<BHUProvider>();

      final bytes = await provider.generatePDFBytes();
      final fileName = 'bhu_resumen_${DateTime.now().millisecondsSinceEpoch}';

      Navigator.of(context).pop();

      if (kIsWeb ||
          Platform.isWindows ||
          Platform.isLinux ||
          Platform.isMacOS) {
        print('DEBUG: Usando FileSaver (web/desktop)');
        print('DEBUG SETTINGS - Modo Web/Desktop: guardando archivo...');
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: bytes,
          ext: 'pdf',
          mimeType: MimeType.pdf,
        );
        print('DEBUG SETTINGS - PDF guardado');
      } else {
        print('DEBUG SETTINGS - Modo Mobile: compartiendo...');
        final file = await provider.generatePDF();
        await Share.shareXFiles(
          [XFile(file.path)],
          text:
              'Resumen BHU - ${DateTime.now().day} de ${_getMonthName(DateTime.now().month)} de ${DateTime.now().year}',
        );
        print('DEBUG SETTINGS - Share completado');
      }
    } catch (e) {
      print('DEBUG SETTINGS - ERROR: $e');
      print('DEBUG SETTINGS - Stack trace: ${StackTrace.current}');
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generando PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getMonthName(int month) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    return months[month - 1];
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'BHU Control',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.account_balance, size: 48),
      children: const [
        Text('Sistema de Control BHU - Gestión de Depósitos'),
        Text('Versión móvil para Android'),
        Text('Desarrollado por Marcelo Pereyra'),
        Text('Desarrollado para Banco Hipotecario del Uruguay'),
      ],
    );
  }

  void _showLicenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Licencia'),
        content: SingleChildScrollView(
          child: Text(
            'BHU Control - Sistema de Gestión de Depósitos\n\n'
            'Copyright © 2024\n\n'
            'Este software está desarrollado para uso exclusivo '
            'del Banco Hipotecario del Uruguay.\n\n'
            'Todos los derechos reservados.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeDialogSwitch(BuildContext context) {
    return const _WelcomeDialogSwitch();
  }
}

class _WelcomeDialogSwitch extends StatefulWidget {
  const _WelcomeDialogSwitch();

  @override
  State<_WelcomeDialogSwitch> createState() => _WelcomeDialogSwitchState();
}

class _WelcomeDialogSwitchState extends State<_WelcomeDialogSwitch> {
  bool? _showWelcome;

  @override
  void initState() {
    super.initState();
    _loadValue();
  }

  Future<void> _loadValue() async {
    final value = await WelcomeDialog.shouldShowWelcome();
    if (mounted) {
      setState(() {
        _showWelcome = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.waving_hand,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: const Text(
          'Mostrar bienvenida al iniciar',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
            'Muestra el diálogo de bienvenida cada vez que se abre la app'),
        value: _showWelcome ?? true,
        onChanged: _showWelcome == null
            ? null
            : (value) async {
                await WelcomeDialog.setShowWelcome(value);
                setState(() {
                  _showWelcome = value;
                });
              },
      ),
    );
  }
}
