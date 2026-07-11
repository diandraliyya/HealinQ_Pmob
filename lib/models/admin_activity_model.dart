class AdminActivityModel {
  final String id;
  final String actorName;
  final String actorRole;
  final String action;
  final String category;
  final String status;
  final String description;
  final String? targetType;
  final String? targetId;
  final DateTime createdAt;

  const AdminActivityModel({
    required this.id,
    required this.actorName,
    required this.actorRole,
    required this.action,
    required this.category,
    required this.status,
    required this.description,
    this.targetType,
    this.targetId,
    required this.createdAt,
  });

  factory AdminActivityModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return AdminActivityModel(
      id: map['id'],
      actorName: map['actor_name'] ?? 'System',
      actorRole: map['actor_role'] ?? 'system',
      action: map['action'] ?? '',
      category: map['category'] ?? '',
      status: map['status'] ?? '',
      description: map['description'] ?? '',
      targetType: map['target_type'],
      targetId: map['target_id'],
      createdAt: DateTime.parse(map['created_at']).toLocal(),
    );
  }
}
