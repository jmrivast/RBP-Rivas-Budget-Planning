class User {
  const User({
    this.id,
    required this.username,
    this.email,
    this.pinHash,
    this.pinLength = 0,
    this.createdAt,
    this.isActive = 1,
  });

  final int? id;
  final String username;
  final String? email;
  final String? pinHash;
  final int pinLength;
  final String? createdAt;
  final int isActive;
  bool get hasPin =>
      (pinHash ?? '').isNotEmpty && (pinLength == 4 || pinLength == 6);

  factory User.fromMap(Map<String, Object?> map) {
    return User(
      id: map['id'] as int?,
      username: (map['username'] ?? '') as String,
      email: map['email'] as String?,
      pinHash: map['pin_hash'] as String?,
      pinLength: (map['pin_length'] as num?)?.toInt() ?? 0,
      createdAt: map['created_at'] as String?,
      isActive: (map['is_active'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'pin_hash': pinHash,
      'pin_length': pinLength,
      'created_at': createdAt,
      'is_active': isActive,
    };
  }
}
