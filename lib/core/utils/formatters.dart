import 'package:intl/intl.dart';

class AppFormatters {
  static String formatPrice(num price) {
    return NumberFormat('#,###', 'ar').format(price);
  }

  static String generateRef(String prefix) {
    final rand = (10000 + (90000 * (DateTime.now().millisecondsSinceEpoch % 1))).toInt();
    return '$prefix-${DateTime.now().millisecondsSinceEpoch % 90000 + 10000}';
  }
}
