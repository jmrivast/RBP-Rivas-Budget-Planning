import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../providers/finance_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/backup_service.dart';
import '../../services/update_service.dart';
import '../dialogs/confirm_dialog.dart';
import '../dialogs/rename_category_dialog.dart';
import '../dialogs/update_available_dialog.dart';
import '../widgets/category_item.dart';
import '../widgets/guided_showcase.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({
    super.key,
    this.guideKey,
    this.onGuideNext,
    this.onGuidePrevious,
    this.onStartGuidedTour,
  });
  final GlobalKey? guideKey;
  final VoidCallback? onGuideNext;
  final VoidCallback? onGuidePrevious;
  final VoidCallback? onStartGuidedTour;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _q1Ctrl = TextEditingController();
  final _q2Ctrl = TextEditingController();
  final _mCtrl = TextEditingController();
  final _newCategoryCtrl = TextEditingController();

  final _backupService = BackupService();
  final _updateService = UpdateService();

  String _periodMode = 'quincenal';
  bool _autoExport = false;
  bool _includeBeta = false;
  bool _loaded = false;

  @override
  void dispose() {
    _q1Ctrl.dispose();
    _q2Ctrl.dispose();
    _mCtrl.dispose();
    _newCategoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings(FinanceProvider finance) async {
    if (_loaded) {
      return;
    }
    _periodMode = finance.periodMode;
    _q1Ctrl.text =
        await finance.getSetting('quincenal_pay_day_1', defaultValue: '1');
    _q2Ctrl.text =
        await finance.getSetting('quincenal_pay_day_2', defaultValue: '16');
    _mCtrl.text =
        await finance.getSetting('monthly_pay_day', defaultValue: '1');
    _autoExport = (await finance.getSetting('auto_export_close_period',
                defaultValue: 'false'))
            .toLowerCase() ==
        'true';
    _includeBeta = (await finance.getSetting('include_beta_updates',
                defaultValue: 'false'))
            .toLowerCase() ==
        'true';
    _loaded = true;
  }

  void _show(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  int? _parseDay(String raw, String label) {
    final value = int.tryParse(raw.trim());
    if (value == null || value < 1 || value > 31) {
      _show('$label debe estar entre 1 y 31.');
      return null;
    }
    return value;
  }

  Future<void> _saveGeneral(FinanceProvider finance) async {
    final q1 = _parseDay(_q1Ctrl.text, 'Dia cobro quincena 1');
    if (q1 == null) {
      return;
    }
    final q2 = _parseDay(_q2Ctrl.text, 'Dia cobro quincena 2');
    if (q2 == null) {
      return;
    }
    final md = _parseDay(_mCtrl.text, 'Dia cobro mensual');
    if (md == null) {
      return;
    }
    if (q1 == q2) {
      _show('Los dos dias de cobro quincenal no pueden ser iguales.');
      return;
    }
    if (q1 > q2) {
      _show('En quincenal, el dia 1 debe ser menor que el dia 2.');
      return;
    }

    await finance.setSetting('quincenal_pay_day_1', '$q1');
    await finance.setSetting('quincenal_pay_day_2', '$q2');
    await finance.setSetting('monthly_pay_day', '$md');
    await finance.setSetting('auto_export_close_period', '$_autoExport');
    await finance.setSetting('include_beta_updates', '$_includeBeta');
    await finance.setPeriodMode(_periodMode);
    await finance.goToCurrentPeriod();
    _show('Configuracion general guardada.');
  }

  Future<void> _checkForUpdatesManual(FinanceProvider finance) async {
    try {
      final includeBeta = _includeBeta;
      final release =
          await _updateService.fetchLatest(includeBeta: includeBeta);
      final checkKey = includeBeta
          ? 'update_last_check_date_beta'
          : 'update_last_check_date_stable';
      final today = DateTime.now().toIso8601String().split('T').first;
      await finance.setSetting(checkKey, today);

      if (release == null) {
        _show('No se pudo verificar actualizaciones ahora mismo.');
        return;
      }

      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;
      final hasNew = UpdateService.isNewerVersion(currentVersion, release.tag);
      if (!hasNew) {
        if (includeBeta) {
          _show('Ya tienes la version mas reciente (incluyendo beta).');
        } else {
          _show('Ya tienes la version mas reciente.');
        }
        return;
      }

      if (!mounted) {
        return;
      }
      await showUpdateAvailableDialog(
        context,
        latest: release,
        currentVersion: currentVersion,
        manual: true,
      );
    } catch (e) {
      _show('No se pudo verificar actualizaciones: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Consumer<FinanceProvider>(
      builder: (context, finance, _) {
        return FutureBuilder<void>(
          future: _loadSettings(finance),
          builder: (context, snapshot) {
            final body = snapshot.connectionState != ConnectionState.done
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final generalCard = Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 280,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _periodMode,
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'quincenal',
                                            child: Text('Quincenal')),
                                        DropdownMenuItem(
                                            value: 'mensual',
                                            child: Text('Mensual')),
                                      ],
                                      onChanged: (value) => setState(() =>
                                          _periodMode = value ?? 'quincenal'),
                                      decoration: const InputDecoration(
                                          labelText:
                                              'Frecuencia de reporte y salario'),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 240,
                                    child: DropdownButtonFormField<String>(
                                      key: ValueKey(
                                          'theme-${settings.themePreset}'),
                                      initialValue: settings.themePreset,
                                      items: AppColors.presets
                                          .map(
                                            (p) => DropdownMenuItem(
                                              value: p.key,
                                              child: Text(p.label),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) async {
                                        if (value == null) {
                                          return;
                                        }
                                        await settings.updateThemePreset(value);
                                        if (context.mounted) {
                                          _show(
                                              'Tema aplicado: ${AppColors.presets.firstWhere((p) => p.key == value).label}');
                                        }
                                      },
                                      decoration: const InputDecoration(
                                        labelText: 'Tema visual',
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 320,
                                    child: SwitchListTile(
                                      value: _autoExport,
                                      onChanged: (value) =>
                                          setState(() => _autoExport = value),
                                      title: const Text(
                                          'Exportacion automatica al cerrar periodo'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 340,
                                    child: SwitchListTile(
                                      value: _includeBeta,
                                      onChanged: (value) =>
                                          setState(() => _includeBeta = value),
                                      title: const Text(
                                          'Incluir versiones beta en actualizaciones'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  SizedBox(
                                    width: 170,
                                    child: TextField(
                                      controller: _q1Ctrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: 'Dia cobro quincena 1'),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 170,
                                    child: TextField(
                                      controller: _q2Ctrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: 'Dia cobro quincena 2'),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 170,
                                    child: TextField(
                                      controller: _mCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: 'Dia cobro mensual'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Quincenal: Q1 inicia en dia 1 y Q2 en dia 2.\nMensual: inicia en ese dia y termina el dia anterior del proximo mes.',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.subtitle),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  FilledButton.icon(
                                    onPressed: () => _saveGeneral(finance),
                                    icon: const Icon(Icons.save),
                                    label: const Text('Guardar configuracion'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _checkForUpdatesManual(finance),
                                    icon: const Icon(Icons.system_update),
                                    label: const Text('Buscar actualizacion'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );

                      final guidedGeneralCard = widget.guideKey == null
                          ? generalCard
                          : GuidedShowcase(
                              showcaseKey: widget.guideKey!,
                              title: 'Configuracion',
                              description:
                                  '- Ajusta frecuencia y dias de cobro.\n'
                                  '- Cambia el tema visual.\n'
                                  '- Gestiona actualizaciones.\n'
                                  '- Desde aqui puedes relanzar esta guia.',
                              onNext: widget.onGuideNext,
                              onPrevious: widget.onGuidePrevious,
                              nextLabel: 'Finalizar',
                              child: generalCard,
                            );

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Configuracion',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                'Personaliza frecuencia, dias de cobro, exportacion y categorias.',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.subtitle),
                              ),
                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 10),
                              const Text('General',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              guidedGeneralCard,
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 10),
                              const Text('Respaldo y restauracion',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  FilledButton.icon(
                                    onPressed: () async {
                                      try {
                                        final path =
                                            await _backupService.createBackup();
                                        _show(
                                            'Respaldo creado: ${p.basename(path)}');
                                      } catch (e) {
                                        _show('No se pudo crear respaldo: $e');
                                      }
                                    },
                                    icon: const Icon(Icons.backup),
                                    label: const Text('Crear respaldo'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      try {
                                        final source = await _backupService
                                            .pickAndRestoreBackup();
                                        if (source == null) {
                                          return;
                                        }
                                        await finance.refreshAll();
                                        _show(
                                            'Respaldo restaurado: ${p.basename(source)}');
                                      } catch (e) {
                                        _show(
                                            'No se pudo restaurar respaldo: $e');
                                      }
                                    },
                                    icon: const Icon(Icons.restore),
                                    label: const Text('Restaurar respaldo'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 10),
                              const Text('Categorias',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  SizedBox(
                                    width: 260,
                                    child: TextField(
                                      controller: _newCategoryCtrl,
                                      decoration: const InputDecoration(
                                          labelText: 'Nueva categoria',
                                          hintText: 'Ej: Educacion'),
                                    ),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () async {
                                      final name = _newCategoryCtrl.text.trim();
                                      if (name.isEmpty) {
                                        _show('Completa campos.');
                                        return;
                                      }
                                      try {
                                        await finance.addCategory(name);
                                        _newCategoryCtrl.clear();
                                        _show(
                                            'Categoria creada correctamente.');
                                      } catch (e) {
                                        _show(
                                            'No se pudo crear la categoria: $e');
                                      }
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Agregar categoria'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      overlayColor: AppColors.hoverSuccess,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 300,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: finance.categories.isEmpty
                                      ? Align(
                                          alignment: Alignment.topLeft,
                                          child: Text('Sin categorias',
                                              style: TextStyle(
                                                  fontStyle: FontStyle.italic,
                                                  color: AppColors.subtitle)),
                                        )
                                      : ListView.builder(
                                          itemCount: finance.categories.length,
                                          itemBuilder: (context, index) {
                                            final cat =
                                                finance.categories[index];
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 6),
                                              child: CategoryItem(
                                                category: cat,
                                                onRename: () =>
                                                    showRenameCategoryDialog(
                                                  context,
                                                  finance: finance,
                                                  category: cat,
                                                ),
                                                onDelete: () async {
                                                  final ok =
                                                      await showConfirmDialog(
                                                    context,
                                                    title: 'Eliminar categoria',
                                                    message:
                                                        'Se eliminara si no esta en uso.',
                                                    confirmLabel: 'Eliminar',
                                                  );
                                                  if (!ok) {
                                                    return;
                                                  }
                                                  try {
                                                    await finance
                                                        .deleteCategory(
                                                            cat.id!);
                                                    _show(
                                                        'Categoria eliminada.');
                                                  } catch (e) {
                                                    _show('$e');
                                                  }
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
            return body;
          },
        );
      },
    );
  }
}
