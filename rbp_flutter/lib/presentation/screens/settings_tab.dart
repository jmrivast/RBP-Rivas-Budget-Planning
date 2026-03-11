import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/platform/app_capabilities.dart';
import '../../config/constants.dart';
import '../../data/models/user.dart';
import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';
import '../../services/settings_actions_service.dart';
import '../dialogs/confirm_dialog.dart';
import '../dialogs/rename_category_dialog.dart';
import '../dialogs/update_available_dialog.dart';
import '../widgets/category_item.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({
    super.key,
    this.onOpenActivation,
  });

  final VoidCallback? onOpenActivation;

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

  final _settingsActions = SettingsActionsService();

  String _periodMode = 'quincenal';
  int _profilePinLength = 4;
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

  Future<void> _editProfilePin(FinanceProvider finance, User profile) async {
    if (profile.id == null) {
      _show('Perfil no encontrado.');
      return;
    }
    final pinCtrl = TextEditingController();
    var pinLength = profile.pinLength == 6 ? 6 : 4;
    final result = await showDialog<(String, int)>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('PIN de ${profile.username}'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: pinLength,
                      items: const [
                        DropdownMenuItem(value: 4, child: Text('PIN 4')),
                        DropdownMenuItem(value: 6, child: Text('PIN 6')),
                      ],
                      onChanged: (value) {
                        setDialogState(() => pinLength = value ?? 4);
                      },
                      decoration:
                          const InputDecoration(labelText: 'Longitud PIN'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: pinCtrl,
                      autofocus: true,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nuevo PIN',
                        helperText: 'Deja vacio para quitar el PIN',
                      ),
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
                  onPressed: () => Navigator.of(context)
                      .pop((pinCtrl.text.trim(), pinLength)),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }
    final pin = result.$1.trim();
    final selectedLength = result.$2;
    if (pin.isNotEmpty && !_isValidPin(pin, selectedLength)) {
      _show('El PIN debe ser numerico de $selectedLength digitos.');
      return;
    }

    try {
      await finance.setProfilePin(
        profile.id!,
        pin: pin.isEmpty ? null : pin,
        pinLength: selectedLength,
      );
      _show(pin.isEmpty ? 'PIN removido.' : 'PIN actualizado.');
      setState(() {});
    } catch (e) {
      _show('No se pudo actualizar PIN: $e');
    }
  }

  Future<void> _renameProfile(FinanceProvider finance, User profile) async {
    final ctrl = TextEditingController(text: profile.username);
    final nextName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Renombrar perfil'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
    final name = (nextName ?? '').trim();
    if (name.isEmpty || name == profile.username) {
      return;
    }
    try {
      await finance.renameProfile(profile.id!, name);
      _show('Perfil actualizado.');
      setState(() {});
    } catch (e) {
      _show('No se pudo renombrar: $e');
    }
  }

  Future<void> _deleteProfile(FinanceProvider finance, User profile) async {
    if (profile.id == finance.activeProfile?.id) {
      _show('Cambia a otro perfil antes de eliminar este.');
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: 'Eliminar perfil',
      message:
          'Se eliminara el perfil "${profile.username}" de la lista activa. Sus datos quedaran archivados localmente.',
      confirmLabel: 'Eliminar',
    );
    if (!ok) {
      return;
    }
    String? pin;
    if (profile.hasPin) {
      pin = await _promptPin(
        username: profile.username,
        pinLength: profile.pinLength,
      );
      if (pin == null || pin.isEmpty) {
        return;
      }
    }
    try {
      await finance.deleteProfile(profile.id!, pin: pin);
      if (_selectedProfileId == profile.id) {
        _selectedProfileId = finance.activeProfile?.id;
      }
      _show('Perfil eliminado.');
      setState(() {});
    } catch (e) {
      _show('No se pudo eliminar: $e');
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
    final effectiveAutoExport =
        AppCapabilities.current.supportsAutoPeriodExport ? _autoExport : false;
    final effectiveIncludeBeta =
        AppCapabilities.current.supportsUpdateChecks ? _includeBeta : false;

    await finance.setSetting(
        'auto_export_close_period', '$effectiveAutoExport');
    await finance.setSetting(
        'include_beta_updates', '$effectiveIncludeBeta');
    await finance.setPeriodMode(_periodMode);
    await finance.goToCurrentPeriod();
    _show('Configuracion general guardada.');
  }

  Future<void> _checkForUpdatesManual(FinanceProvider finance) async {
    try {
      final result = await _settingsActions.checkForUpdates(
        includeBeta: _includeBeta,
      );
      if (result.checkKey != null && result.checkedOn != null) {
        await finance.setSetting(result.checkKey!, result.checkedOn!);
      }

      if (result.status != UpdateCheckStatus.updateAvailable) {
        _show(result.message);
        return;
      }

      if (!mounted || result.release == null || result.currentVersion == null) {
        return;
      }
      await showUpdateAvailableDialog(
        context,
        latest: result.release!,
        currentVersion: result.currentVersion!,
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
                        if (finance.isTrialMode && widget.onOpenActivation != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.trialBannerBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Icon(Icons.lock_outline, color: AppColors.trialBannerText),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 520),
                                  child: Text(
                                    'Estas usando la app en modo de prueba. Puedes activar la licencia desde aqui cuando quieras.',
                                    style: TextStyle(
                                      color: AppColors.trialBannerText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                FilledButton.icon(
                                  onPressed: widget.onOpenActivation,
                                  icon: const Icon(Icons.lock_open),
                                  label: const Text('Abrir activacion'),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                                Text(
                                  'Perfil actual: ${finance.activeProfile?.username ?? '-'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Los formularios se muestran al abrir cada seccion.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.subtitle,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  title: const Text('Cambiar perfil'),
                                  leading: const Icon(Icons.switch_account),
                                  childrenPadding:
                                      const EdgeInsets.only(bottom: 8),
                                  children: [
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 300,
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
                                            onChanged: (value) => setState(() =>
                                                _selectedProfileId = value),
                                            decoration: const InputDecoration(
                                              labelText: 'Selecciona perfil',
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
                                          icon: const Icon(Icons.login),
                                          label: const Text('Entrar'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  title: const Text('Crear nuevo perfil'),
                                  leading: const Icon(Icons.person_add),
                                  childrenPadding:
                                      const EdgeInsets.only(bottom: 8),
                                  children: [
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: constraints.maxWidth < 720 ? double.infinity : 240,
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
                                                  value: 4,
                                                  child: Text('PIN 4')),
                                              DropdownMenuItem(
                                                  value: 6,
                                                  child: Text('PIN 6')),
                                            ],
                                            onChanged: (value) => setState(() =>
                                                _profilePinLength = value ?? 4),
                                            decoration: const InputDecoration(
                                              labelText: 'Seguridad',
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: constraints.maxWidth < 720 ? double.infinity : 170,
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
                                          width: constraints.maxWidth < 720 ? double.infinity : 170,
                                          child: TextField(
                                            controller:
                                                _newProfilePinConfirmCtrl,
                                            obscureText: true,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Confirmar PIN',
                                            ),
                                          ),
                                        ),
                                        FilledButton.icon(
                                          onPressed: () =>
                                              _createProfile(finance),
                                          icon: const Icon(Icons.add),
                                          label: const Text('Crear'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Cada perfil guarda finanzas separadas. PIN opcional de 4 o 6 digitos.',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.subtitle),
                                    ),
                                  ],
                                ),
                                ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  title: const Text('Gestionar perfiles'),
                                  leading: const Icon(Icons.manage_accounts),
                                  childrenPadding:
                                      const EdgeInsets.only(bottom: 8),
                                  children: [
                                    SizedBox(
                                      height: 190,
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.cardBg,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: AppColors.cardBorder),
                                        ),
                                        child: ListView.builder(
                                          itemCount: finance.profiles.length,
                                          itemBuilder: (context, index) {
                                            final profile =
                                                finance.profiles[index];
                                            final isActive = profile.id ==
                                                finance.activeProfile?.id;
                                            return ListTile(
                                              dense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                              leading: Icon(
                                                isActive
                                                    ? Icons.person
                                                    : Icons.person_outline,
                                                color: isActive
                                                    ? AppColors.primary
                                                    : AppColors.iconNeutral,
                                              ),
                                              title: Text(
                                                profile.hasPin
                                                    ? '${profile.username} (PIN)'
                                                    : profile.username,
                                              ),
                                              subtitle: Text(
                                                isActive
                                                    ? 'Perfil activo'
                                                    : 'Perfil secundario',
                                              ),
                                              trailing: Wrap(
                                                spacing: 2,
                                                children: [
                                                  IconButton(
                                                    tooltip: profile.hasPin
                                                        ? 'Cambiar o quitar PIN'
                                                        : 'Agregar PIN',
                                                    onPressed: () =>
                                                        _editProfilePin(
                                                            finance, profile),
                                                    icon: Icon(
                                                      profile.hasPin
                                                          ? Icons.lock
                                                          : Icons.lock_open,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    tooltip: 'Renombrar',
                                                    onPressed: () =>
                                                        _renameProfile(
                                                            finance, profile),
                                                    icon: const Icon(
                                                        Icons.edit_outlined),
                                                  ),
                                                  IconButton(
                                                    tooltip: isActive
                                                        ? 'No se puede eliminar el perfil activo'
                                                        : 'Eliminar',
                                                    onPressed: isActive
                                                        ? null
                                                        : () => _deleteProfile(
                                                            finance, profile),
                                                    icon: const Icon(
                                                        Icons.delete_outline),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Proteccion: no se puede eliminar el perfil activo ni dejar la app sin perfiles.',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.subtitle),
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
                                      width: constraints.maxWidth < 720 ? double.infinity : 280,
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
                                      width: constraints.maxWidth < 720 ? double.infinity : 240,
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
                                    if (AppCapabilities.current.supportsAutoPeriodExport)
                                      SizedBox(
                                        width: constraints.maxWidth < 720 ? double.infinity : 320,
                                        child: SwitchListTile(
                                          value: _autoExport,
                                          onChanged: (value) =>
                                              setState(() => _autoExport = value),
                                          title: const Text(
                                              'Exportacion automatica al cerrar periodo'),
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    if (AppCapabilities.current.supportsUpdateChecks)
                                      SizedBox(
                                        width: constraints.maxWidth < 720 ? double.infinity : 340,
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
                                      width: constraints.maxWidth < 720 ? double.infinity : 170,
                                      child: TextField(
                                        controller: _q1Ctrl,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                            labelText: 'Dia cobro quincena 1'),
                                      ),
                                    ),
                                    SizedBox(
                                      width: constraints.maxWidth < 720 ? double.infinity : 170,
                                      child: TextField(
                                        controller: _q2Ctrl,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                            labelText: 'Dia cobro quincena 2'),
                                      ),
                                    ),
                                    SizedBox(
                                      width: constraints.maxWidth < 720 ? double.infinity : 170,
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
                                    if (AppCapabilities.current.supportsUpdateChecks)
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
                        if (AppCapabilities.current.supportsLocalBackup)
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                onPressed: () async {
                                  try {
                                    final result =
                                        await _settingsActions.createBackup();
                                    _show(result.message);
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
                                    final result =
                                        await _settingsActions.restoreBackup();
                                    if (result == null) {
                                      return;
                                    }
                                    if (result.requiresRefresh) {
                                      await finance.refreshAll();
                                    }
                                    _show(result.message);
                                  } catch (e) {
                                    _show('No se pudo restaurar respaldo: $e');
                                  }
                                },
                                icon: const Icon(Icons.restore),
                                label: const Text('Restaurar respaldo'),
                              ),
                            ],
                          )
                        else
                          Text(
                            'El respaldo local se mantiene solo para escritorio. En web y movil habra que usar un flujo distinto.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.subtitle),
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







