import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/trash_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeProvider,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Resume Builder',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/trash': (context) => const TrashScreen(),
          },
          onUnknownRoute: (settings) => MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(child: Text('Page not found')),
            ),
          ),
        );
      },
    );
  }
}
