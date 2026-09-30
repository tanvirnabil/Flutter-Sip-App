import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/call_session_model.dart';
import '../providers/sip_provider.dart';
import 'dialpad/dialpad_screen.dart';
import 'history/call_history_screen.dart';
import 'wallet/wallet_screen.dart';
import 'settings/settings_screen.dart';
import 'call/active_call_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DialpadScreen(),
    CallHistoryScreen(),
    WalletScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final sip = context.watch<SipProvider>();

    if (sip.hasActiveCall &&
        sip.session?.direction == AuraCallDirection.incoming &&
        sip.session?.status == AuraCallStatus.ringing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(
          CupertinoPageRoute(
            fullscreenDialog: true,
            builder: (_) => const ActiveCallScreen(),
          ),
        );
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.circle_grid_3x3),
            activeIcon: Icon(CupertinoIcons.circle_grid_3x3_fill),
            label: 'Keypad',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.clock),
            activeIcon: Icon(CupertinoIcons.clock_fill),
            label: 'Recents',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.creditcard),
            activeIcon: Icon(CupertinoIcons.creditcard_fill),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.gear_alt),
            activeIcon: Icon(CupertinoIcons.gear_alt_fill),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
