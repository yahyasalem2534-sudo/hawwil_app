import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
// تم استبدال استدعاء main_layout بشاشة الترحيب الجديدة
import 'views/splash_screen.dart'; 

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

void main() async {
  // التأكد من تهيئة بيئة فلاتر قبل تشغيل أي شيء
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة فايربيز (بدون أي تعديل)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // جعل شريط الحالة (Status Bar) شفافاً ليأخذ لون التطبيق بشكل أنيق
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  // قفل اتجاه الشاشة على الوضع العمودي فقط للحفاظ على جمالية التصميم
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // تشغيل التطبيق مع Riverpod Scope
  runApp(const ProviderScope(child: HawwilApp()));
}

class HawwilApp extends ConsumerWidget {
  const HawwilApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Hawwil - حوّل',
      debugShowCheckedModeBanner: false, // إخفاء شريط Debug المزعج
      
      // ربط الثيمات الاحترافية
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      
      // دعم اللغة العربية والاتجاه من اليمين لليسار بشكل مثالي
      locale: const Locale('ar', 'MR'),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      
      // توجيه المستخدم إلى شاشة الترحيب الاحترافية أولاً
      home: const SplashScreen(),
    );
  }
}
