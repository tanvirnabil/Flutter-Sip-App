import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:aura_voip/main.dart';
import 'package:aura_voip/providers/sip_provider.dart';
import 'package:aura_voip/providers/history_provider.dart';
import 'package:aura_voip/providers/wallet_provider.dart';

void main() {
  testWidgets('Aura VoIP smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SipProvider()),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
          ChangeNotifierProvider(create: (_) => WalletProvider()),
        ],
        child: const AuraVoipApp(hasSavedAccount: false),
      ),
    );

    // Verify login screen elements render
    expect(find.text('Aura VoIP'), findsOneWidget);
    expect(find.text('Connect SIP Account'), findsOneWidget);
  });
}
