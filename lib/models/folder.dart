class Folder {
  final String id;
  final String userId;
  final FolderData data;
  final DateTime createdAt;
  final DateTime? deletedAt;

  Folder({
    required this.id,
    required this.userId,
    required this.data,
    required this.createdAt,
    this.deletedAt,
  });

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      data: FolderData.fromJson(json['data'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'data': data.toJson(),
      'created_at': createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  Folder copyWith({
    String? id,
    String? userId,
    FolderData? data,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return Folder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

class FolderData {
  final String name;
  final String? parentId;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  FolderData({
    required this.name,
    this.parentId,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FolderData.fromJson(Map<String, dynamic> json) {
    return FolderData(
      name: json['name'] as String,
      parentId: json['parent_id'] as String?,
      order: json['order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parent_id': parentId,
      'order': order,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FolderData copyWith({
    String? name,
    String? parentId,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FolderData(
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

