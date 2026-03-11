import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/constants.dart';
import '../../services/activation_flow_service.dart';
import '../../services/license_service.dart';
import '../theme/app_icon_button.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({
    super.key,
    required this.licenseService,
    required this.onActivated,
    required this.onContinueTrial,
  });

  final LicenseService licenseService;
  final VoidCallback onActivated;
  final VoidCallback onContinueTrial;

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _keyCtrl = TextEditingController();
  late final ActivationFlowService _activationFlow;
  String _machineId = '';
  String? _error;
  bool _loadingMachine = true;
  bool _activating = false;

  @override
  void initState() {
    super.initState();
    _activationFlow = ActivationFlowService(
      licenseService: widget.licenseService,
    );
    _loadMachineId();
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMachineId() async {
    final result = await _activationFlow.loadMachineId();
    if (!mounted) {
      return;
    }
    setState(() {
      _machineId = result.machineId;
      _error = result.error;
      _loadingMachine = false;
    });
  }

  Future<void> _copyMachineId() async {
    if (_machineId.isEmpty || _machineId == 'NO DISPONIBLE') {
      return;
    }
    await Clipboard.setData(ClipboardData(text: _machineId));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ID de maquina copiado.')),
    );
  }

  Future<void> _activate() async {
    setState(() {
      _activating = true;
      _error = null;
    });
    try {
      final result = await _activationFlow.activate(_keyCtrl.text);
      if (!mounted) {
        return;
      }
      if (!result.success) {
        setState(() => _error = result.error);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Licencia activada correctamente.')),
      );
      widget.onActivated();
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = 'No se pudo activar: $e');
    } finally {
      if (mounted) {
        setState(() => _activating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Image(
                  image: AssetImage('assets/Untitled.png'),
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                Text(
                  'Activar RBP',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ingresa tu clave cifrada de licencia para activar la aplicacion.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.subtitle),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tu ID de maquina',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.subtitle),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.mutedSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _loadingMachine ? 'Cargando...' : _machineId,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                              ),
                              AppIconButton(
                                onPressed:
                                    _loadingMachine ? null : _copyMachineId,
                                tooltip: 'Copiar',
                                icon: Icons.copy,
                                color: AppColors.primary,
                                hoverColor: AppColors.hoverPrimary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _keyCtrl,
                          textCapitalization: TextCapitalization.characters,
                          onChanged: (value) {
                            final upper = value.toUpperCase();
                            if (upper != value) {
                              _keyCtrl.value = _keyCtrl.value.copyWith(
                                text: upper,
                                selection: TextSelection.collapsed(
                                    offset: upper.length),
                              );
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Clave de licencia',
                            hintText: 'XXXXX-XXXXX-XXXXX-...',
                            errorText: _error,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _activating || _loadingMachine
                                ? null
                                : _activate,
                            icon: const Icon(Icons.vpn_key),
                            label:
                                Text(_activating ? 'Activando...' : 'Activar'),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed:
                                _activating ? null : widget.onContinueTrial,
                            child: const Text(
                                'Continuar sin activar (modo de prueba)'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Contacta al desarrollador con tu ID de maquina para obtener tu clave cifrada.\n'
                  '${AppLicense.developerContact} | ${AppLicense.developerEmail}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.subtitle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
