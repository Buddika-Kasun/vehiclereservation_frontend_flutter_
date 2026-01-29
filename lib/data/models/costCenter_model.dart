class CostCenter {
  final int id;
  final String name;
  final double budget;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CostCenter({
    required this.id,
    required this.name,
    required this.budget,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory CostCenter.fromJson(Map<String, dynamic> json) {
    return CostCenter(
      id: json['_id'] ?? json['id'] ?? 0,
      name: json['name'] ?? '',
      budget: _parseDouble(json['budget'] ?? 0.0),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toString()),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'budget': budget,
      'isActive': isActive,
    };
  }
}
