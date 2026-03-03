import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../data/models/user.dart';
import '../../providers/finance_provider.dart';

class ProfileAccessScreen extends StatefulWidget {
  const ProfileAccessScreen({
    super.key,
    required this.onAuthenticated,
    this.sessionHours = AppProfiles.sessionHours,
  });

  final VoidCallback onAuthenticated;
  final int sessionHours;

  @override
  State<ProfileAccessScreen> createState() => _ProfileAccessScreenState();
}

class _ProfileAccessScreenState extends State<ProfileAccessScreen> {
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  int? _selectedProfileId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final finance = context.read<FinanceProvider>();
      final active = finance.activeProfile;
      if (active?.id != null) {
        setState(() => _selectedProfileId = active!.id!);
      } else if (finance.profiles.isNotEmpty &&
          finance.profiles.first.id != null) {
        setState(() => _selectedProfileId = finance.profiles.first.id!);
      }
    });
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _authenticate(FinanceProvider finance) async {
    final profileId = _selectedProfileId;
    if (profileId == null) {
      setState(() => _error = 'Selecciona un perfil.');
      return;
    }
    User? profile;
    for (final p in finance.profiles) {
      if (p.id == profileId) {
        profile = p;
        break;
      }
    }
    if (profile == null) {
      setState(() => _error = 'Perfil no encontrado.');
      return;
    }

    final selectedProfile = profile;
    final pin = _pinCtrl.text.trim();
    if (selectedProfile.hasPin) {
      if (!RegExp(r'^\d+$').hasMatch(pin) ||
          pin.length != selectedProfile.pinLength) {
        final pinLength = selectedProfile.pinLength;
        setState(() => _error = 'PIN invalido ($pinLength digitos).');
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await finance.switchProfile(
        profileId,
        pin: selectedProfile.hasPin ? pin : null,
      );
      await finance.markProfileSession(sessionHours: widget.sessionHours);
      if (!mounted) {
        return;
      }
      widget.onAuthenticated();
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = 'No se pudo acceder: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Consumer<FinanceProvider>(
        builder: (context, finance, _) {
          final profiles = finance.profiles;
          User? selected;
          for (final profile in profiles) {
            if (profile.id == _selectedProfileId) {
              selected = profile;
              break;
            }
          }
          final requiresPin = selected?.hasPin ?? false;
          final title = profiles.length <= 1
              ? 'Acceder al perfil'
              : 'Selecciona un perfil';

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Para seguridad, la sesion de perfil dura ${widget.sessionHours} horas.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.subtitle),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedProfileId,
                          items: profiles
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
                          onChanged: (value) {
                            setState(() {
                              _selectedProfileId = value;
                              _error = null;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Perfil',
                          ),
                        ),
                        if (requiresPin) ...[
                          const SizedBox(height: 10),
                          TextField(
                            controller: _pinCtrl,
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText:
                                  'PIN (${selected?.pinLength ?? 4} digitos)',
                            ),
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style:
                                TextStyle(color: AppColors.error, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _loading || profiles.isEmpty
                                ? null
                                : () => _authenticate(finance),
                            icon: const Icon(Icons.login),
                            label: Text(_loading ? 'Entrando...' : 'Entrar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
