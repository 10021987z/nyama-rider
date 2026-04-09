import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait uniquement — Kevin conduit une moto
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Formatage français
  await initializeDateFormatting('fr_FR');

  // Push notifications (no-op si Firebase non configuré)
  await PushNotificationService.instance.init();

  runApp(ProviderScope(child: App()));
}
