import 'package:flutter/material.dart';
import 'package:rbp_flutter/utils/web_font.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../services/profile_access_service.dart';
import '../providers/finance_provider.dart';

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
  final _profileAccess = ProfileAccessService();
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
      setState(() {
        _selectedProfileId = _profileAccess.resolveInitialProfileId(finance);
      });
    });
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _authenticate(FinanceProvider finance) async {
    final profile = _profileAccess.findProfile(finance, _selectedProfileId);
    final pin = _pinCtrl.text.trim();
    final validationError = _profileAccess.validateAccess(
      profileId: _selectedProfileId,
      profile: profile,
      pin: pin,
    );
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    final selectedProfile = profile!;
    final selectedProfileId = _selectedProfileId!;

    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _profileAccess.authenticate(
      finance: finance,
      profileId: selectedProfileId,
      profile: selectedProfile,
      pin: pin,
      sessionHours: widget.sessionHours,
    );
    if (!mounted) {
      return;
    }
    if (!result.success) {
      setState(() {
        _loading = false;
        _error = result.error;
      });
      return;
    }
    widget.onAuthenticated();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Consumer<FinanceProvider>(
        builder: (context, finance, _) {
          final profiles = finance.profiles;
          final selected = _profileAccess.findProfile(finance, _selectedProfileId);
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
                            fontWeight: fw700,
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
