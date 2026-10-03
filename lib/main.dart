import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'providers/contacts_provider.dart';
import 'providers/sip_provider.dart';
import 'providers/history_provider.dart';
import 'providers/wallet_provider.dart';
import 'services/background_service.dart';
import 'services/dtmf_audio_service.dart';
import 'services/ringtone_service.dart';
import 'services/secure_storage_service.dart';
import 'views/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize background services and audio systems
  await BackgroundService().init();
  await DtmfAudioService().init();
  await RingtoneService().init();

  try {
    await [
      Permission.microphone,
      Permission.notification,
    ].request();
  } catch (_) {}

  final savedAccount = await SecureStorageService.getAccount();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SipProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => ContactsProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: ClarioApp(hasSavedAccount: savedAccount != null),
    ),
  );
}

class ClarioApp extends StatelessWidget {
  final bool hasSavedAccount;

  const ClarioApp({super.key, required this.hasSavedAccount});

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Clario',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: themeProv.isOled ? AppTheme.oledTheme : AppTheme.darkTheme,
      themeMode: themeProv.flutterThemeMode,
      home: SplashScreen(hasSavedAccount: hasSavedAccount),
    );
  }
}

// Backward compatibility alias for widget tests
typedef AuraVoipApp = ClarioApp;

