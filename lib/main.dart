import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/route_screen.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const BaarikierrosApp());
}

class BaarikierrosApp extends StatefulWidget {
  const BaarikierrosApp({super.key});

  @override
  State<BaarikierrosApp> createState() => _BaarikierrosAppState();
}

class _BaarikierrosAppState extends State<BaarikierrosApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    //* Artificial delay for splash screen
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp.router(
        title: 'Baarikierros',
        theme: AppTheme.darkTheme,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
        builder: (context, router) {
          return _initialized ? router! : const SplashScreen();
        },
      ),
    );
  }
}
