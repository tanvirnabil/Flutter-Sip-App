import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/call_session_model.dart';
import '../providers/sip_provider.dart';
import 'dialpad/dialpad_screen.dart';
import 'history/call_history_screen.dart';
import 'contacts/contacts_screen.dart';
import 'settings/settings_screen.dart';
import 'call/active_call_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _isCallScreenPushed = false;

  final List<Widget> _screens = const [
    DialpadScreen(),
    CallHistoryScreen(),
    ContactsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final sip = context.watch<SipProvider>();

    // Full-screen incoming call trigger
    if (sip.hasActiveCall &&
        sip.session?.direction == AuraCallDirection.incoming &&
        sip.session?.status == AuraCallStatus.ringing &&
        !_isCallScreenPushed) {
      _isCallScreenPushed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context)
            .push(
              CupertinoPageRoute(
                fullscreenDialog: true,
                builder: (_) => const ActiveCallScreen(),
              ),
            )
            .then((_) {
          _isCallScreenPushed = false;
        });
      });
    }

    return Scaffold(
      // Apple-grade fluid animated page switching transition
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.02),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (_currentIndex != index) {
            setState(() => _currentIndex = index);
          }
        },
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
            icon: Icon(CupertinoIcons.person_2),
            activeIcon: Icon(CupertinoIcons.person_2_fill),
            label: 'Contacts',
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

