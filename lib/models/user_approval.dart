class UserApproval {
  final String id;
  final String userId;
  final String email;
  final bool isApproved;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final Map<String, dynamic> preferences;

  UserApproval({
    required this.id,
    required this.userId,
    required this.email,
    this.isApproved = false,
    required this.requestedAt,
    this.approvedAt,
    this.approvedBy,
    Map<String, dynamic>? preferences,
  }) : preferences = preferences ?? {
          'theme': 'light',
          'sidebarPosition': 'left',
        };

  factory UserApproval.fromJson(Map<String, dynamic> json) {
    return UserApproval(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      email: json['email'] as String,
      isApproved: json['is_approved'] as bool? ?? false,
      requestedAt: DateTime.parse(json['requested_at'] as String),
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      approvedBy: json['approved_by'] as String?,
      preferences: json['preferences'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'email': email,
      'is_approved': isApproved,
      'requested_at': requestedAt.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'preferences': preferences,
    };
  }
}

