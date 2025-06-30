import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/route_screen.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    await Future.wait([
      Firebase.initializeApp(),
      Future.delayed(const Duration(seconds: 5)),
    ]);
    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        home: SplashScreen(),
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
      );
    }
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp.router(
        title: 'Baarikierros',
        theme: AppTheme.darkTheme,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/route',
      builder: (context, state) => const RouteScreen(),
    ),
  ],
);
