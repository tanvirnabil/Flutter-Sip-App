import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:aura_voip/core/theme/theme_provider.dart';
import 'package:aura_voip/main.dart';
import 'package:aura_voip/providers/sip_provider.dart';
import 'package:aura_voip/providers/history_provider.dart';
import 'package:aura_voip/providers/wallet_provider.dart';

void main() {
  testWidgets('Clario smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => SipProvider()),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
          ChangeNotifierProvider(create: (_) => WalletProvider()),
        ],
        child: const ClarioApp(hasSavedAccount: false),
      ),
    );

    // Verify splash screen elements render
    expect(find.text('Clario'), findsOneWidget);
  });
}
