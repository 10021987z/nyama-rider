import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait uniquement — Kevin conduit une moto
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Formatage français
  await initializeDateFormatting('fr_FR');

  runApp(ProviderScope(child: App()));
}
