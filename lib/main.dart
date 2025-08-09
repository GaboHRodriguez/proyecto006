// lib/main.dart
import 'package:flutter/material.dart';
import 'package:proyecto006/pages/home_page.dart';
import 'package:proyecto006/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    // Si 'isLoggedIn' no existe, devuelve false.
    return prefs.getBool('isLoggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Mantenimiento de Edificios',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Tu tema de diseño va aquí...
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2563EB),
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // ...otros estilos de tu tema...
      ),
      home: FutureBuilder<bool>(
        future: _isUserLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data == true) {
            return const HomePage();
          }
          return const LoginPage();
        },
      ),
    );
  }
}
