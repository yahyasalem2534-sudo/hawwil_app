import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

class TelegramService {
  static Future<void> sendNotification(String message) async {
    try {
      final url =
          'https://api.telegram.org/bot${AppConstants.telegramToken}/sendMessage'
          '?chat_id=${AppConstants.telegramChatId}'
          '&text=${Uri.encodeComponent(message)}';
      await http.get(Uri.parse(url));
    } catch (_) {
      // Silent fail
    }
  }
}