import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/intro_screen.dart';
import 'services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const JoFinanceApp(),
    ),
  );
}

class JoFinanceApp extends StatelessWidget {
  const JoFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Jo Finance App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeProvider.primaryColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeProvider.primaryColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    try {
      await NotificationService().initialize();
    } catch (e) {
      print('⚠️ Firebase não configurado: $e');
      print('   Ignorar se o Firebase Console ainda não foi configurado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF064e3b),
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (!auth.isAuthenticated) {
          return const IntroScreen();
        }

        // Registrar token FCM após login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _registerFcmToken();
        });

        // Se estiver autenticado, verificar onboarding
        if (auth.user?.onboardingDone == false) {
          return const OnboardingScreen();
        }

        return const DashboardScreen();
      },
    );
  }

  Future<void> _registerFcmToken() async {
    try {
      final notif = NotificationService();
      if (notif.token != null) {
        await notif.registerWithBackend(platform: 'android');
      }
    } catch (e) {
      print('⚠️ Erro ao registrar FCM token após login: $e');
    }
  }
}
