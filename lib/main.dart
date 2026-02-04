import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/di/injection.dart';
import 'core/services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar formatação de datas
  await initializeDateFormatting('pt_PT', null);

  // Inicializar SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Configurar injeção de dependências
  await configureDependencies();

  // Inicializar Notificações
  await NotificationService().initialize();

  runApp(NotarioApp(prefs: prefs));
}
