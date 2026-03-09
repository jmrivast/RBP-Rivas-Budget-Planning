class LicenseInfo {
  const LicenseInfo({
    this.key,
    this.keyPreview,
    this.machineId,
    this.machineFingerprint,
    this.activatedAt,
    this.scheme = 'aes-v3',
    this.isActivated = false,
    this.isTrial = false,
    this.trialDaysLeft,
  });

  final String? key;
  final String? keyPreview;
  final String? machineId;
  final String? machineFingerprint;
  final String? activatedAt;
  final String scheme;
  final bool isActivated;
  final bool isTrial;
  final int? trialDaysLeft;

  factory LicenseInfo.fromMap(Map<String, Object?> map) {
    return LicenseInfo(
      key: map['key'] as String?,
      keyPreview: map['key_preview'] as String?,
      machineId: map['machine_id'] as String?,
      machineFingerprint: map['machine_fingerprint'] as String?,
      activatedAt: map['activated_at'] as String? ?? map['activation_date'] as String?,
      scheme: map['scheme'] as String? ?? 'aes-v2',
      isActivated: map['is_activated'] == true || map['is_activated'] == 1,
      isTrial: map['is_trial'] == true || map['is_trial'] == 1,
      trialDaysLeft: (map['trial_days_left'] as num?)?.toInt(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'key': key,
      'key_preview': keyPreview,
      'machine_id': machineId,
      'machine_fingerprint': machineFingerprint,
      'activated_at': activatedAt,
      'scheme': scheme,
      'is_activated': isActivated ? 1 : 0,
      'is_trial': isTrial ? 1 : 0,
      'trial_days_left': trialDaysLeft,
    };
  }
}

