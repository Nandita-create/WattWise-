import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'state/app_state.dart';

class WattWiseApp extends StatelessWidget {
  const WattWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return MaterialApp(
      title: 'WattWise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF167D69)),
        scaffoldBackgroundColor: const Color(0xFFF6F8F7),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E8E4)),
          ),
        ),
      ),
      home: state.isLoading
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : (state.isAuthenticated
              ? const DashboardScreen()
              : const LoginScreen()),
    );
  }
}
