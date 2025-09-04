import 'package:flutter/material.dart';
import 'package:hastayimm/splash.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase için gerekli
import 'package:intl/date_symbol_data_local.dart'; // Doğru paketi ekledik
import 'alert.dart';
import 'firebase_options.dart'; // Firebase yapılandırma dosyası
import 'const.dart';
import 'homePage.dart';
import 'login/giris.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Firebase'den önce gerekli
  await initializeDateFormatting('tr', ''); // Türkçe tarih bilgilerini yükle
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Firebase yapılandırma
  );
  Gemini.init(apiKey: GEMINI_API_KEY); // Gemini başlangıcı
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'restise',
        debugShowCheckedModeBanner: false,
        routes: {
          "/": (context) => SplashScreen(),
          '/login': (context) => const GirisPage(),
          '/alert': (context) => const AlertPage(),// Giriş ekranı rotası
          '/homePage': (context) => const homePage(), // Anasayfa rotası
        });
  }
}
