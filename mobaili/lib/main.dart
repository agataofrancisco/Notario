import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/di/injection.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar formatação de datas
  await initializeDateFormatting('pt_PT', null);

  // Inicializar SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Configurar injeção de dependências
  await configureDependencies();

  runApp(NotarioApp(prefs: prefs));
}
