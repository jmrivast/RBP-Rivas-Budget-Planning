import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../data/models/user.dart';
import '../../providers/finance_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/backup_service.dart';
import '../../services/update_service.dart';
import '../dialogs/confirm_dialog.dart';
import '../dialogs/rename_category_dialog.dart';
import '../dialogs/update_available_dialog.dart';
import '../widgets/category_item.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _q1Ctrl = TextEditingController();
  final _q2Ctrl = TextEditingController();
  final _mCtrl = TextEditingController();
  final _newCategoryCtrl = TextEditingController();
  final _newProfileCtrl = TextEditingController();
  final _newProfilePinCtrl = TextEditingController();
  final _newProfilePinConfirmCtrl = TextEditingController();
  final _activeProfilePinCtrl = TextEditingController();

  final _backupService = BackupService();
  final _updateService = UpdateService();

  String _periodMode = 'quincenal';
  int _profilePinLength = 4;
  int _activeProfilePinLength = 4;
  int? _selectedProfileId;
  bool _autoExport = false;
  bool _includeBeta = false;
  bool _loaded = false;

  @override
  void dispose() {
    _q1Ctrl.dispose();
    _q2Ctrl.dispose();
    _mCtrl.dispose();
    _newCategoryCtrl.dispose();
    _newProfileCtrl.dispose();
    _newProfilePinCtrl.dispose();
    _newProfilePinConfirmCtrl.dispose();
    _activeProfilePinCtrl.dispose();
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

  bool _isValidPin(String pin, int length) {
    if (length != 4 && length != 6) {
      return false;
    }
    if (pin.length != length) {
      return false;
    }
    return RegExp(r'^\d+$').hasMatch(pin);
  }

  Future<String?> _promptPin({
    required String username,
    required int pinLength,
  }) async {
    final ctrl = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('PIN de $username'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'PIN ($pinLength digitos)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
    return value?.trim();
  }

  Future<void> _createProfile(FinanceProvider finance) async {
    final name = _newProfileCtrl.text.trim();
    if (name.isEmpty) {
      _show('Escribe el nombre del perfil.');
      return;
    }

    final pin = _newProfilePinCtrl.text.trim();
    final pinConfirm = _newProfilePinConfirmCtrl.text.trim();
    if (pin.isNotEmpty || pinConfirm.isNotEmpty) {
      if (!_isValidPin(pin, _profilePinLength)) {
        _show('El PIN debe ser numerico de $_profilePinLength digitos.');
        return;
      }
      if (pin != pinConfirm) {
        _show('La confirmacion del PIN no coincide.');
        return;
      }
    }

    try {
      await finance.createProfile(
        name,
        pin: pin.isEmpty ? null : pin,
        pinLength: _profilePinLength,
      );
      _newProfileCtrl.clear();
      _newProfilePinCtrl.clear();
      _newProfilePinConfirmCtrl.clear();
      _show('Perfil creado correctamente.');
      setState(() {});
    } catch (e) {
      _show('No se pudo crear el perfil: $e');
    }
  }

  Future<void> _switchProfile(FinanceProvider finance, int profileId) async {
    final activeId = finance.activeProfile?.id;
    if (profileId == activeId) {
      _show('Ese perfil ya esta activo.');
      return;
    }
    User? target;
    for (final profile in finance.profiles) {
      if (profile.id == profileId) {
        target = profile;
        break;
      }
    }
    if (target == null) {
      _show('Perfil no encontrado.');
      return;
    }
    String? pin;
    if (target.hasPin) {
      pin = await _promptPin(
        username: target.username,
        pinLength: target.pinLength,
      );
      if (pin == null || pin.isEmpty) {
        return;
      }
    }

    try {
      await finance.switchProfile(profileId, pin: pin);
      if (!mounted) {
        return;
      }
      await context.read<SettingsProvider>().loadThemePreset();
      _loaded = false;
      _selectedProfileId = profileId;
      setState(() {});
      _show('Perfil activo: ${target.username}');
    } catch (e) {
      _show('No se pudo cambiar perfil: $e');
    }
  }

  Future<void> _saveActiveProfilePin(FinanceProvider finance) async {
    final active = finance.activeProfile;
    if (active?.id == null) {
      _show('No hay perfil activo.');
      return;
    }
    final pin = _activeProfilePinCtrl.text.trim();
    try {
      if (pin.isEmpty) {
        await finance.setProfilePin(active!.id!, pin: null);
        _show('PIN removido del perfil activo.');
      } else {
        if (!_isValidPin(pin, _activeProfilePinLength)) {
          _show(
              'El PIN debe ser numerico de $_activeProfilePinLength digitos.');
          return;
        }
        await finance.setProfilePin(
          active!.id!,
          pin: pin,
          pinLength: _activeProfilePinLength,
        );
        _show('PIN actualizado.');
      }
      _activeProfilePinCtrl.clear();
    } catch (e) {
      _show('No se pudo actualizar PIN: $e');
    }
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
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            _selectedProfileId ??= finance.activeProfile?.id;
            final currentPinLength = finance.activeProfile?.pinLength ?? 0;
            if (currentPinLength == 4 || currentPinLength == 6) {
              _activeProfilePinLength = currentPinLength;
            }
            final profileIds = finance.profiles
                .map((profile) => profile.id)
                .whereType<int>()
                .toSet();
            if (_selectedProfileId != null &&
                !profileIds.contains(_selectedProfileId)) {
              _selectedProfileId = finance.activeProfile?.id;
            }

            return LayoutBuilder(
              builder: (context, constraints) {
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
                                fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          'Personaliza frecuencia, dias de cobro, exportacion y categorias.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.subtitle),
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        const Text('Perfiles',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 260,
                                      child: DropdownButtonFormField<int>(
                                        initialValue: _selectedProfileId,
                                        items: finance.profiles
                                            .map(
                                              (p) => DropdownMenuItem<int>(
                                                value: p.id,
                                                child: Text(
                                                  p.hasPin
                                                      ? '${p.username} (PIN)'
                                                      : p.username,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (value) => setState(
                                            () => _selectedProfileId = value),
                                        decoration: const InputDecoration(
                                          labelText: 'Perfil activo',
                                        ),
                                      ),
                                    ),
                                    FilledButton.icon(
                                      onPressed: _selectedProfileId == null
                                          ? null
                                          : () => _switchProfile(
                                                finance,
                                                _selectedProfileId!,
                                              ),
                                      icon: const Icon(Icons.switch_account),
                                      label: const Text('Cambiar perfil'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Divider(height: 1),
                                const SizedBox(height: 10),
                                const Text(
                                  'Crear nuevo perfil',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 220,
                                      child: TextField(
                                        controller: _newProfileCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Nombre del perfil',
                                          hintText: 'Ej: Casa / Trabajo',
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 140,
                                      child: DropdownButtonFormField<int>(
                                        initialValue: _profilePinLength,
                                        items: const [
                                          DropdownMenuItem(
                                              value: 4, child: Text('PIN 4')),
                                          DropdownMenuItem(
                                              value: 6, child: Text('PIN 6')),
                                        ],
                                        onChanged: (value) => setState(() =>
                                            _profilePinLength = value ?? 4),
                                        decoration: const InputDecoration(
                                          labelText: 'Seguridad',
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 160,
                                      child: TextField(
                                        controller: _newProfilePinCtrl,
                                        obscureText: true,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'PIN (opcional)',
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 180,
                                      child: TextField(
                                        controller: _newProfilePinConfirmCtrl,
                                        obscureText: true,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Confirmar PIN',
                                        ),
                                      ),
                                    ),
                                    FilledButton.icon(
                                      onPressed: () => _createProfile(finance),
                                      icon: const Icon(Icons.person_add),
                                      label: const Text('Crear perfil'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Cada perfil guarda finanzas totalmente separadas. El PIN puede ser de 4 o 6 digitos.',
                                  style: TextStyle(
                                      fontSize: 12, color: AppColors.subtitle),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 220,
                                      child: DropdownButtonFormField<int>(
                                        initialValue: _activeProfilePinLength,
                                        items: const [
                                          DropdownMenuItem(
                                              value: 4, child: Text('PIN 4')),
                                          DropdownMenuItem(
                                              value: 6, child: Text('PIN 6')),
                                        ],
                                        onChanged: (value) => setState(() =>
                                            _activeProfilePinLength =
                                                value ?? 4),
                                        decoration: const InputDecoration(
                                          labelText: 'PIN perfil activo',
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 180,
                                      child: TextField(
                                        controller: _activeProfilePinCtrl,
                                        obscureText: true,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText:
                                              'Nuevo PIN (vacio = quitar)',
                                        ),
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _saveActiveProfilePin(finance),
                                      icon: const Icon(Icons.lock),
                                      label: const Text('Guardar PIN'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        const Text('General',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Card(
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
                                          await settings
                                              .updateThemePreset(value);
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
                                        onChanged: (value) => setState(
                                            () => _includeBeta = value),
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
                                      label:
                                          const Text('Guardar configuracion'),
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
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        const Text('Respaldo y restauracion',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
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
                                  _show('Respaldo creado: ${p.basename(path)}');
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
                                  _show('No se pudo restaurar respaldo: $e');
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
                                fontSize: 16, fontWeight: FontWeight.w600)),
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
                                  _show('Categoria creada correctamente.');
                                } catch (e) {
                                  _show('No se pudo crear la categoria: $e');
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
                              border: Border.all(color: AppColors.cardBorder),
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
                                      final cat = finance.categories[index];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 6),
                                        child: CategoryItem(
                                          category: cat,
                                          onRename: () =>
                                              showRenameCategoryDialog(
                                            context,
                                            finance: finance,
                                            category: cat,
                                          ),
                                          onDelete: () async {
                                            final ok = await showConfirmDialog(
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
                                                  .deleteCategory(cat.id!);
                                              _show('Categoria eliminada.');
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
          },
        );
      },
    );
  }
}
