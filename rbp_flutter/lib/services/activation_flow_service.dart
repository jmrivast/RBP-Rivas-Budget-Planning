import 'app_access_service.dart';

class ActivationMachineResult {
  const ActivationMachineResult({
    required this.machineId,
    this.error,
  });

  final String machineId;
  final String? error;
}

class ActivationAttemptResult {
  const ActivationAttemptResult({
    required this.success,
    this.error,
  });

  final bool success;
  final String? error;
}

class ActivationFlowService {
  ActivationFlowService({
    AppAccessService? accessService,
  }) : _accessService = accessService ?? AppAccessService();

  final AppAccessService _accessService;

  AppAccessService get accessService => _accessService;

  Future<ActivationMachineResult> loadMachineId() async {
    try {
      final id = await _accessService.getMachineId();
      return ActivationMachineResult(machineId: id);
    } catch (e) {
      return ActivationMachineResult(
        machineId: 'NO DISPONIBLE',
        error: 'No se pudo obtener el ID de maquina: $e',
      );
    }
  }

  Future<ActivationAttemptResult> activate(String rawKey) async {
    final key = rawKey.trim().toUpperCase();
    if (key.isEmpty) {
      return const ActivationAttemptResult(
        success: false,
        error: 'Ingresa una clave de licencia.',
      );
    }

    final ok = await _accessService.validateLicenseKey(key);
    if (!ok) {
      return const ActivationAttemptResult(
        success: false,
        error: 'Clave invalida. Verifica e intenta de nuevo.',
      );
    }

    await _accessService.storeLicenseKey(key);
    return const ActivationAttemptResult(success: true);
  }
}
