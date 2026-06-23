import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_constants.dart';
import '../models/bank_model.dart';
import '../models/game_model.dart';
import '../models/order_model.dart';

class FirebaseService {
  final FirebaseFirestore _db  = FirebaseFirestore.instance;
  final FirebaseAuth      _auth = FirebaseAuth.instance;

  // ── Auth ──────────────────────────────────────────────────────────────────
  User? get currentUser        => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signOut() => _auth.signOut();

  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }

  // ── Streams ───────────────────────────────────────────────────────────────
  Stream<List<GameModel>> gamesStream() {
    return _db
        .collection(AppConstants.gamesCollection)
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => GameModel.fromFirestore(d.data(), d.id))
            .toList());
  }

  Stream<List<BankModel>> paymentBanksStream() {
    return _db
        .collection(AppConstants.paymentBanksCollection)
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => BankModel.fromFirestore(d.data(), d.id))
            .toList());
  }

  // ── Sliders ───────────────────────────────────────────────────────────────
  Future<List<String>> fetchSliders() async {
    try {
      final snap = await _db.collection(AppConstants.slidersCollection).get();
      return snap.docs.map((doc) {
        final data = doc.data();
        final url = data['bannerUrl'] ?? data['image'] ?? data['imageUrl'] ?? '';
        return url.toString();
      }).where((url) => url.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Orders ────────────────────────────────────────────────────────────────
  Future<void> submitCard({
    required String uid,
    required String ref,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection(AppConstants.cardsCollection).add({
      'uid': uid,
      'ref': ref,
      ...data,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<CardOrder>> getUserCards(String uid) async {
    final snap = await _db
        .collection(AppConstants.cardsCollection)
        .where('uid', isEqualTo: uid)
        .get();
    final list = snap.docs
        .map((d) => CardOrder.fromFirestore(d.data()))
        .toList();
    list.sort((a, b) =>
        (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return list;
  }

  Stream<Map<String, dynamic>?> trackOrder(String ref) {
    return _db
        .collection(AppConstants.cardsCollection)
        .where('ref', isEqualTo: ref)
        .snapshots()
        .map((snap) =>
            snap.docs.isNotEmpty ? snap.docs.first.data() : null);
  }
}