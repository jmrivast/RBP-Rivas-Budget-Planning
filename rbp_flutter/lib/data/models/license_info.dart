class LicenseInfo {
  const LicenseInfo({
    this.key,
    this.machineId,
    this.activatedAt,
    this.isActivated = false,
    this.isTrial = false,
    this.trialDaysLeft,
  });

  final String? key;
  final String? machineId;
  final String? activatedAt;
  final bool isActivated;
  final bool isTrial;
  final int? trialDaysLeft;

  factory LicenseInfo.fromMap(Map<String, Object?> map) {
    return LicenseInfo(
      key: map['key'] as String?,
      machineId: map['machine_id'] as String?,
      activatedAt: map['activated_at'] as String?,
      isActivated: map['is_activated'] == true || map['is_activated'] == 1,
      isTrial: map['is_trial'] == true || map['is_trial'] == 1,
      trialDaysLeft: (map['trial_days_left'] as num?)?.toInt(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'key': key,
      'machine_id': machineId,
      'activated_at': activatedAt,
      'is_activated': isActivated ? 1 : 0,
      'is_trial': isTrial ? 1 : 0,
      'trial_days_left': trialDaysLeft,
    };
  }
}
