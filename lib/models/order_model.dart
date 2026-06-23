import 'package:cloud_firestore/cloud_firestore.dart';

class CardOrder {
  final String ref;
  final String game;
  final String gameId;
  final String package;
  final double price;
  final String paymentBank;
  final String playerId;
  final String phone;
  final String status;
  final String? deliveredCode;
  final DateTime? createdAt;

  CardOrder({
    required this.ref,
    required this.game,
    required this.gameId,
    required this.package,
    required this.price,
    required this.paymentBank,
    required this.playerId,
    required this.phone,
    required this.status,
    this.deliveredCode,
    this.createdAt,
  });

  factory CardOrder.fromFirestore(Map<String, dynamic> data) {
    return CardOrder(
      ref: data['ref'] ?? '',
      game: data['game'] ?? '',
      gameId: data['gameId'] ?? '',
      package: data['package'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      paymentBank: data['paymentBank'] ?? '',
      playerId: data['playerId'] ?? '',
      phone: data['phone'] ?? '',
      status: data['status'] ?? 'pending',
      deliveredCode: data['deliveredCode'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}