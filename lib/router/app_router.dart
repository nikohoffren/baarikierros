import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/route_screen.dart';

final GoRouter appRouter = GoRouter(
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
