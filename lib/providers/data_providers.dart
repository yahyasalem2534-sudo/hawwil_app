import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bank_model.dart';
import '../models/game_model.dart';
import 'auth_provider.dart';

final banksProvider = StreamProvider<List<BankModel>>((ref) {
  return ref.watch(firebaseServiceProvider).banksStream();
});

final gamesProvider = StreamProvider<List<GameModel>>((ref) {
  return ref.watch(firebaseServiceProvider).gamesStream();
});

final paymentBanksProvider = StreamProvider<List<BankModel>>((ref) {
  return ref.watch(firebaseServiceProvider).paymentBanksStream();
});

// Filtered Games
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
