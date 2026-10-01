import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/sip_provider.dart';
import 'providers/history_provider.dart';
import 'providers/wallet_provider.dart';
import 'services/secure_storage_service.dart';
import 'views/auth/sip_login_screen.dart';
import 'views/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

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
        ChangeNotifierProvider(create: (_) => SipProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: AuraVoipApp(hasSavedAccount: savedAccount != null),
    ),
  );
}

class AuraVoipApp extends StatelessWidget {
  final bool hasSavedAccount;

  const AuraVoipApp({super.key, required this.hasSavedAccount});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aura VoIP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: hasSavedAccount ? const MainNavigationScreen() : const SipLoginScreen(),
    );
  }
}

