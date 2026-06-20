
class AppFormatters {
  static String formatPrice(num price) {
    return NumberFormat('#,###', 'ar').format(price);
  }

  static String generateRef(String prefix) {
    (10000 + (90000 * (DateTime.now().millisecondsSinceEpoch % 1))).toInt();
    return '$prefix-${DateTime.now().millisecondsSinceEpoch % 90000 + 10000}';
  }
}

class NumberFormat {
  NumberFormat(String s, String t);
  
  
 format(num price) {}
}
