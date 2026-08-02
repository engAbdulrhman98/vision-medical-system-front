import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _language = 'ar'; // Default language to Arabic as requested

  void _changeLanguage(String newLanguage) {
    setState(() {
      _language = newLanguage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vision Medical',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          primary: Colors.teal[800],
          secondary: Colors.cyan[700],
        ),
        fontFamily: 'Roboto', // Premium modern font standard in Flutter
      ),
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        // Route Guard: Redirect to /login if no valid login session arguments are provided
        if (settings.name != '/login' && (settings.arguments == null || settings.arguments is! Map)) {
          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(
              language: _language,
              onLanguageChanged: _changeLanguage,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        }

        if (settings.name == '/login') {
          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(
              language: _language,
              onLanguageChanged: _changeLanguage,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        } else if (settings.name == '/home') {
          String email = 'test@example.com';
          String token = '';
          String backendUrl = 'https://vision-medical-system-back-production.up.railway.app/api';
          Map user = {'role': 'admin'};

          if (settings.arguments is Map) {
            final args = settings.arguments as Map;
            email = args['email'] ?? 'test@example.com';
            token = args['token'] ?? '';
            backendUrl = args['backendUrl'] ?? 'https://vision-medical-system-back-production.up.railway.app/api';
            user = args['user'] ?? {'role': 'admin'};
          } else if (settings.arguments is String) {
            email = settings.arguments as String;
          }
          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => DashboardScreen(
              language: _language,
              onLanguageChanged: _changeLanguage,
              email: email,
              token: token,
              backendUrl: backendUrl,
              user: user,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        } else if (settings.name == '/reports') {
          String token = '';
          String backendUrl = '';
          if (settings.arguments is Map) {
            final args = settings.arguments as Map;
            token = args['token'] ?? '';
            backendUrl = args['backendUrl'] ?? '';
          }
          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => ReportsScreen(
              language: _language,
              token: token,
              backendUrl: backendUrl,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.ease;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          );
        } else if (settings.name == '/tasks') {
          String token = '';
          String backendUrl = '';
          if (settings.arguments is Map) {
            final args = settings.arguments as Map;
            token = args['token'] ?? '';
            backendUrl = args['backendUrl'] ?? '';
          }
          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => TasksScreen(
              language: _language,
              token: token,
              backendUrl: backendUrl,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.ease;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          );
        } else if (settings.name == '/chat') {
          String email = 'User';
          String token = '';
          String backendUrl = '';
          if (settings.arguments is Map) {
            final args = settings.arguments as Map;
            email = args['email'] ?? 'User';
            token = args['token'] ?? '';
            backendUrl = args['backendUrl'] ?? '';
          } else if (settings.arguments is String) {
            email = settings.arguments as String;
          }
          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(
              language: _language,
              email: email,
              token: token,
              backendUrl: backendUrl,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.ease;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          );
        } else if (settings.name == '/notifications') {
          String token = '';
          String backendUrl = '';
          if (settings.arguments is Map) {
            final args = settings.arguments as Map;
            token = args['token'] ?? '';
            backendUrl = args['backendUrl'] ?? '';
          }
          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => NotificationsScreen(
              language: _language,
              token: token,
              backendUrl: backendUrl,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.ease;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          );
        }
        return null;
      },
    );
  }
}
