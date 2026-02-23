class Category {
  const Category({
    this.id,
    required this.userId,
    required this.name,
    this.color,
    this.icon,
    this.createdAt,
  });

  final int? id;
  final int userId;
  final String name;
  final String? color;
  final String? icon;
  final String? createdAt;

  factory Category.fromMap(Map<String, Object?> map) {
    return Category(
      id: map['id'] as int?,
      userId: (map['user_id'] as num).toInt(),
      name: (map['name'] ?? '') as String,
      color: map['color'] as String?,
      icon: map['icon'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'color': color,
      'icon': icon,
      'created_at': createdAt,
    };
  }
}
