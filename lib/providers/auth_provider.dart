import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bank_model.dart';
import '../models/game_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

// ── Core Services ─────────────────────────────────────────────────────────
final firebaseServiceProvider = Provider<FirebaseService>((ref) => FirebaseService());
final authServiceProvider      = Provider<AuthService>((ref) => AuthService());

// ── Auth ──────────────────────────────────────────────────────────────────
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

// ── Games ─────────────────────────────────────────────────────────────────
final gamesProvider = StreamProvider<List<GameModel>>((ref) {
  return ref.watch(firebaseServiceProvider).gamesStream();
});

final gameGamesProvider = Provider<AsyncValue<List<GameModel>>>((ref) {
  return ref.watch(gamesProvider).whenData(
    (games) => games.where((g) => g.productType != 'service').toList(),
  );
});

final serviceGamesProvider = Provider<AsyncValue<List<GameModel>>>((ref) {
  return ref.watch(gamesProvider).whenData(
    (games) => games.where((g) => g.productType == 'service').toList(),
  );
});

// ── Payment Banks (لشاشة الدفع فقط) ──────────────────────────────────────
final paymentBanksProvider = StreamProvider<List<BankModel>>((ref) {
  return ref.watch(firebaseServiceProvider).paymentBanksStream();
});

// ── Sliders ───────────────────────────────────────────────────────────────
final slidersProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(firebaseServiceProvider).fetchSliders();
});