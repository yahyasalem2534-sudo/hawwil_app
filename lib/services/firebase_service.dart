import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_constants.dart';
import '../models/bank_model.dart';
import '../models/game_model.dart';
import '../models/order_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Auth ──
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> registerWithEmail(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();

  // ── Real-time Streams ──
  Stream<List<BankModel>> banksStream() {
    return _db
        .collection(AppConstants.banksCollection)
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => BankModel.fromFirestore(d.data(), d.id))
            .toList());
  }

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

  // ── Orders ──
  Future<void> submitTransfer({
    required String uid,
    required String ref,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection(AppConstants.transfersCollection).add({
      'uid': uid,
      'ref': ref,
      ...data,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

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

  // ── User Orders ──
  Future<List<TransferOrder>> getUserTransfers(String uid) async {
    final snap = await _db
        .collection(AppConstants.transfersCollection)
        .where('uid', isEqualTo: uid)
        .get();

    final list = snap.docs.map((d) => TransferOrder.fromFirestore(d.data())).toList();
    list.sort((a, b) =>
        (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return list;
  }

  Future<List<CardOrder>> getUserCards(String uid) async {
    final snap = await _db
        .collection(AppConstants.cardsCollection)
        .where('uid', isEqualTo: uid)
        .get();

    final list = snap.docs.map((d) => CardOrder.fromFirestore(d.data())).toList();
    list.sort((a, b) =>
        (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return list;
  }

  // ── Order Tracking ──
  Stream<Map<String, dynamic>?> trackOrder(String ref) {
    final collection =
        ref.startsWith('HW') ? AppConstants.transfersCollection : AppConstants.cardsCollection;

    return _db
        .collection(collection)
        .where('ref', isEqualTo: ref)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty ? snap.docs.first.data() : null);
  }
}
