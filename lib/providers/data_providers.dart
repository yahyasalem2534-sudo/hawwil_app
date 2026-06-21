import 'package:cloud_firestore/cloud_firestore.dart';
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

// 🌟 السلايدر الآن يبحث عن bannerUrl (الحقل الصحيح في Firebase)
final slidersProvider = FutureProvider<List<String>>((ref) async {
  try {
    final snapshot = await FirebaseFirestore.instance.collection('sliders').get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data();
      // التعديل هنا: bannerUrl هو الأولوية الأولى
      final url = data['bannerUrl'] ?? data['image'] ?? data['imageUrl'] ?? data['photo'] ?? '';
      return url.toString();
    }).where((url) => url.isNotEmpty).toList();
  } catch (e) {
    print('Error fetching sliders: $e');
    return [];
  }
});
