import 'package:cloud_firestore/cloud_firestore.dart';

class TransferOrder {
  final String ref;
  final String name;
  final String phone;
  final double amount;
  final double commRate;
  final double commission;
  final double receive;
  final String fromBank;
  final String toBank;
  final String account;
  final String? notes;
  final String status;
  final DateTime? createdAt;

  TransferOrder({
    required this.ref,
    required this.name,
    required this.phone,
    required this.amount,
    required this.commRate,
    required this.commission,
    required this.receive,
    required this.fromBank,
    required this.toBank,
    required this.account,
    this.notes,
    required this.status,
    this.createdAt,
  });

  factory TransferOrder.fromFirestore(Map<String, dynamic> data) {
    return TransferOrder(
      ref: data['ref'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      commRate: (data['commRate'] ?? 5).toDouble(),
      commission: (data['commission'] ?? 0).toDouble(),
      receive: (data['receive'] ?? 0).toDouble(),
      fromBank: data['fromBank'] ?? '',
      toBank: data['toBank'] ?? '',
      account: data['account'] ?? '',
      notes: data['notes'],
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

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
