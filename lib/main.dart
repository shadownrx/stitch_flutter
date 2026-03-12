import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'theme/app_theme.dart';
import 'models/course.dart';
import 'services/auth_service.dart';
import 'screens/roll_call_screen.dart';
import 'screens/login_screen.dart';
import 'screens/grades_screen.dart';
import 'screens/class_plan_screen.dart';
import 'screens/activities_screen.dart';
import 'screens/main_navigation_wrapper.dart';
import 'screens/settings_screen.dart';
import 'screens/student_list_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/chat_detail_screen.dart';
import 'screens/teacher_selection_screen.dart';
import 'services/theme_service.dart';
import 'services/chat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const StitchApp(),
    ),
  );
}

class StitchApp extends StatelessWidget {
  const StitchApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<ChatService>(create: (_) => ChatService()),
        StreamProvider<auth.User?>(
          create: (context) => context.read<AuthService>().user,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'Stitch Educator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const AuthWrapper(),
        onGenerateRoute: (settings) {
          if (settings.name == '/roll_call') {
            final course = settings.arguments as Course;
            return MaterialPageRoute(
              builder: (context) => RollCallScreen(course: course),
            );
          }
          if (settings.name == '/grades') {
            final course = settings.arguments as Course;
            return MaterialPageRoute(
              builder: (context) => GradesScreen(course: course),
            );
          }
          if (settings.name == '/activities') {
            final course = settings.arguments as Course;
            return MaterialPageRoute(
              builder: (context) => ActivitiesScreen(course: course),
            );
          }
          if (settings.name == '/class_plan') {
            final course = settings.arguments as Course;
            return MaterialPageRoute(
              builder: (context) => ClassPlanScreen(course: course),
            );
          }
          if (settings.name == '/settings') {
            return MaterialPageRoute(
              builder: (context) => const SettingsScreen(),
            );
          }
          if (settings.name == '/student_list') {
            return MaterialPageRoute(
              builder: (context) => const StudentListScreen(),
            );
          }
          if (settings.name == '/chat_list') {
            return MaterialPageRoute(
              builder: (context) => const ChatListScreen(),
            );
          }
          if (settings.name == '/teacher_selection') {
            final institutionId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) =>
                  TeacherSelectionScreen(institutionId: institutionId),
            );
          }
          if (settings.name == '/chat_detail') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                roomId: args['roomId'],
                otherTeacherName: args['otherTeacherName'],
                otherTeacherId: args['otherTeacherId'],
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<auth.User?>(context);

    // If logged in, go to Dashboard (via Wrapper), otherwise go to Login
    if (user != null) {
      return const MainNavigationWrapper();
    } else {
      return const LoginScreen();
    }
  }
}
