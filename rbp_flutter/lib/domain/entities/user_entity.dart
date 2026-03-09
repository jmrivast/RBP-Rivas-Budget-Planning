class UserEntity {
  const UserEntity({
    required this.id,
    required this.username,
    this.email,
    this.pinHash,
    this.pinLength,
    this.isActive = true,
    this.lastAccessAt,
  });
  final int id;
  final String username;
  final String? email;
  final String? pinHash;
  final int? pinLength;
  final bool isActive;
  final DateTime? lastAccessAt;

  bool get hasPinEnabled => pinHash != null && pinHash!.isNotEmpty;
}
