import 'package:cc206_west_select/features/screens/favorite/favorite_model.dart';
import 'package:cc206_west_select/features/screens/home/home_page.dart';
import 'package:cc206_west_select/features/screens/message/encryption_helper.dart';
import 'package:cc206_west_select/firebase/notification_service.dart';
import 'package:cc206_west_select/services/analytics_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cc206_west_select/features/screens/cart/cart_model.dart';
import 'package:cc206_west_select/features/auth_gate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {}

  await Firebase.initializeApp();
  await EncryptionSetupHelper.initializeEncryption();
  await NotificationService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartModel()),
        ChangeNotifierProvider(create: (context) => FavoriteModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'West Select',
      navigatorObservers: [AnalyticsService.getObserver()],
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/home': (context) => HomePage(),
      },
    );
  }
}
