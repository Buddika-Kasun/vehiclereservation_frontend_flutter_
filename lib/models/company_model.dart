class Company {
  final int id;
  final String name;
  final String address;
  final String emailDomain;
  final String contactNumber;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Company({
    required this.id,
    required this.name,
    required this.address,
    required this.emailDomain,
    required this.contactNumber,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      emailDomain: json['emailDomain'] ?? json['email_domain'] ?? '',
      contactNumber: json['contactNumber'] ?? json['contact_no'] ?? '',
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'emailDomain': emailDomain,
      'contactNumber': contactNumber,
      'isActive': isActive,
    };
  }
}