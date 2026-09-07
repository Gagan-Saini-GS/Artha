class Tracker {
  final String id;
  final String name;
  final double budgetAmount;
  final double currentAmount;
  final String description;
  final String userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Tracker({
    required this.id,
    required this.name,
    required this.budgetAmount,
    this.currentAmount = 0,
    this.description = '',
    this.userId = '',
    this.createdAt,
    this.updatedAt,
  });

  factory Tracker.fromJson(Map<String, dynamic> json) {
    return Tracker(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      budgetAmount: (json['budget_amount'] as num?)?.toDouble() ?? 0,
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0,
      description: json['description'] ?? '',
      userId: json['user_id'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Tracker copyWith({
    String? id,
    String? name,
    double? budgetAmount,
    double? currentAmount,
    String? description,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tracker(
      id: id ?? this.id,
      name: name ?? this.name,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
