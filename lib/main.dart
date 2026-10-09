import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'models/app_user.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/auth/choose_role_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/client/client_shell.dart';
import 'screens/tutor/tutor_profile_setup_screen.dart';
import 'screens/tutor/tutor_shell.dart';
import 'services/auth_service.dart';
import 'services/session.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AuthService.init();
  // Let the blue headers run behind a transparent status bar.
  SystemChrome.setSystemUIOverlayStyle(appOverlayStyle);
  runApp(ChangeNotifierProvider(create: (_) => Session(), child: const LearnHubApp()));
}

class LearnHubApp extends StatelessWidget {
  const LearnHubApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'LearnHub',
        debugShowCheckedModeBanner: false,
        navigatorKey: rootNavigatorKey,
        theme: buildAppTheme(),
        home: const RootGate(),
      );
}

/// Routes the signed-in user to the interface that matches their role.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    switch (session.status) {
      case SessionStatus.loading:
        return const _Splash();
      case SessionStatus.signedOut:
        return const LoginScreen();
      case SessionStatus.needsRole:
        return const ChooseRoleScreen();
      case SessionStatus.ready:
        final user = session.currentUser;
        return switch (user.role) {
          UserRole.admin => const AdminShell(),
          UserRole.tutor when !user.profileComplete => const TutorProfileSetupScreen(onboarding: true),
          UserRole.tutor => const TutorShell(),
          _ => const ClientShell(),
        };
    }
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.gradient),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.school_rounded, size: 64, color: Colors.white),
              SizedBox(height: 12),
              Text('LearnHub', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
              SizedBox(height: 24),
              SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)),
            ]),
          ),
        ),
      );
}
