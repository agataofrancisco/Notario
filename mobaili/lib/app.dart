import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/repositories/task_firestore_repository.dart';
import 'core/repositories/user_firestore_repository.dart';
import 'core/services/auth_service.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'shared/theme/app_theme.dart';

class NotarioApp extends StatelessWidget {
  const NotarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => TaskFirestoreRepository()),
        RepositoryProvider(create: (_) => UserFirestoreRepository()),
        RepositoryProvider(create: (_) => AuthService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => TaskBloc(
              repository: context.read<TaskFirestoreRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'NOTÁRIO',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: StreamBuilder(
            stream: context.read<AuthService>().authStateChanges,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasData) {
                return const DashboardScreen();
              }

              return const LoginScreen();
            },
          ),
        ),
      ),
    );
  }
}
