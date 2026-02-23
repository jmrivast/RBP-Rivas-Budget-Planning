class UserSetting {
  const UserSetting({
    this.id,
    required this.userId,
    required this.settingKey,
    required this.settingValue,
    this.updatedAt,
  });

  final int? id;
  final int userId;
  final String settingKey;
  final String settingValue;
  final String? updatedAt;

  factory UserSetting.fromMap(Map<String, Object?> map) {
    return UserSetting(
      id: map['id'] as int?,
      userId: (map['user_id'] as num).toInt(),
      settingKey: (map['setting_key'] ?? '') as String,
      settingValue: (map['setting_value'] ?? '') as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'setting_key': settingKey,
      'setting_value': settingValue,
      'updated_at': updatedAt,
    };
  }
}
