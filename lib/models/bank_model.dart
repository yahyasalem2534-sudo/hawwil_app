class BankModel {
  final String id;
  final String name;
  final String? logo;
  final String? color;
  final int order;

  BankModel({
    required this.id,
    required this.name,
    this.logo,
    this.color,
    required this.order,
  });

  factory BankModel.fromFirestore(Map<String, dynamic> data, String id) {
    return BankModel(
      id: id,
      name: data['name'] ?? '',
      logo: data['logo'],
      color: data['color'],
      order: data['order'] ?? 0,
    );
  }
}
