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
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'views/splash_screen.dart'; 

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

void main() async {
  // 1. التأكد من تهيئة بيئة فلاتر
  WidgetsFlutterBinding.ensureInitialized();

  String? initializationError;

  // 2. محاولة تشغيل الخدمات الحساسة داخل حزام أمان (Try-Catch)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
    );

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (error) {
    // حفظ نص الخطأ في حال حدوث انهيار أثناء التهيئة
    initializationError = error.toString();
  }

  // 3. توجيه التطبيق بناءً على النتيجة
  if (initializationError != null) {
    // إذا انهار Firebase، اعرض الخطأ فوراً على الشاشة بدلاً من إغلاق التطبيق
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'حدث خطأ أثناء تهيئة التطبيق:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      initializationError,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 14, color: Colors.red),
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  } else {
    // إذا نجحت التهيئة، يعمل التطبيق بشكل طبيعي وآمن
    runApp(const ProviderScope(child: HawwilApp()));
  }
}

class HawwilApp extends ConsumerWidget {
  const HawwilApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Hawwil - حوّل',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: const Locale('ar', 'MR'),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: const SplashScreen(),
    );
  }
}
