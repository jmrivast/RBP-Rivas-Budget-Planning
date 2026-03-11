import '../config/constants.dart';
import '../data/models/user.dart';
import '../presentation/providers/finance_provider.dart';

class ProfileAuthenticationResult {
  const ProfileAuthenticationResult({
    required this.success,
    this.error,
  });

  final bool success;
  final String? error;
}

class ProfileAccessService {
  int? resolveInitialProfileId(FinanceProvider finance) {
    final active = finance.activeProfile;
    if (active?.id != null) {
      return active!.id!;
    }
    if (finance.profiles.isNotEmpty && finance.profiles.first.id != null) {
      return finance.profiles.first.id!;
    }
    return null;
  }

  User? findProfile(FinanceProvider finance, int? profileId) {
    if (profileId == null) {
      return null;
    }
    for (final profile in finance.profiles) {
      if (profile.id == profileId) {
        return profile;
      }
    }
    return null;
  }

  String? validateAccess({
    required int? profileId,
    required User? profile,
    required String pin,
  }) {
    if (profileId == null) {
      return 'Selecciona un perfil.';
    }
    if (profile == null) {
      return 'Perfil no encontrado.';
    }
    if (profile.hasPin) {
      if (!RegExp(r'^\d+$').hasMatch(pin) || pin.length != profile.pinLength) {
        return 'PIN invalido (${profile.pinLength} digitos).';
      }
    }
    return null;
  }

  Future<ProfileAuthenticationResult> authenticate({
    required FinanceProvider finance,
    required int profileId,
    required User profile,
    required String pin,
    int sessionHours = AppProfiles.sessionHours,
  }) async {
    try {
      await finance.switchProfile(
        profileId,
        pin: profile.hasPin ? pin : null,
      );
      await finance.markProfileSession(sessionHours: sessionHours);
      return const ProfileAuthenticationResult(success: true);
    } catch (e) {
      return ProfileAuthenticationResult(
        success: false,
        error: 'No se pudo acceder: $e',
      );
    }
  }
}
