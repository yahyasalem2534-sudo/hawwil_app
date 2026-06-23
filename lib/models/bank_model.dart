class BankModel {
  final String id;
  final String name;

  BankModel({required this.id, required this.name});

  factory BankModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return BankModel(
      id: documentId,
      name: data['name'] ?? 'بدون اسم',
    );
  }
}