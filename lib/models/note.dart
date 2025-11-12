class Note {
  final String id;
  final String userId;
  final NoteData data;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Note({
    required this.id,
    required this.userId,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      data: NoteData.fromJson(json['data'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
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
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  Note copyWith({
    String? id,
    String? userId,
    NoteData? data,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

class NoteData {
  final String title;
  final String content;
  final String? folderId;
  final bool isFavorite;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteData({
    required this.title,
    required this.content,
    this.folderId,
    this.isFavorite = false,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteData.fromJson(Map<String, dynamic> json) {
    return NoteData(
      title: json['title'] as String? ?? '제목 없음',
      content: json['content'] as String? ?? '',
      folderId: json['folder_id'] as String?,
      isFavorite: json['is_favorite'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'folder_id': folderId,
      'is_favorite': isFavorite,
      'order': order,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  NoteData copyWith({
    String? title,
    String? content,
    String? folderId,
    bool? isFavorite,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteData(
      title: title ?? this.title,
      content: content ?? this.content,
      folderId: folderId ?? this.folderId,
      isFavorite: isFavorite ?? this.isFavorite,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

