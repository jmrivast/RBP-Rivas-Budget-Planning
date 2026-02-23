class User {
  const User({
    this.id,
    required this.username,
    this.email,
    this.createdAt,
    this.isActive = 1,
  });

  final int? id;
  final String username;
  final String? email;
  final String? createdAt;
  final int isActive;

  factory User.fromMap(Map<String, Object?> map) {
    return User(
      id: map['id'] as int?,
      username: (map['username'] ?? '') as String,
      email: map['email'] as String?,
      createdAt: map['created_at'] as String?,
      isActive: (map['is_active'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'created_at': createdAt,
      'is_active': isActive,
    };
  }
}
