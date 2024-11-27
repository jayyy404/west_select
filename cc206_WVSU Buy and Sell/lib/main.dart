import 'package:cc206_west_select/features/screens/home/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cc206_west_select/features/log_in.dart';
import 'package:cc206_west_select/features/screens/cart/cart_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(
    ChangeNotifierProvider(
      create: (context) => CartModel(),
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
      initialRoute: '/',
      routes: {
        '/': (context) => const LogInPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}
