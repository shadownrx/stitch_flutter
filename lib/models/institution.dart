class Institution {
  final String id;
  final String name;
  final String? address;
  final String? logoUrl;
  final String? joinCode;

  Institution({
    required this.id,
    required this.name,
    this.address,
    this.logoUrl,
    this.joinCode,
  });

  factory Institution.fromMap(Map<String, dynamic> data, String documentId) {
    return Institution(
      id: documentId,
      name: data['name'] ?? '',
      address: data['address'],
      logoUrl: data['logoUrl'],
      joinCode: data['joinCode'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'logoUrl': logoUrl,
      'joinCode': joinCode,
    };
  }
}
