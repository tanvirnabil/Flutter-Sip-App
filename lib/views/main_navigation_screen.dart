import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/call_session_model.dart';
import '../providers/sip_provider.dart';
import 'dialpad/dialpad_screen.dart';
import 'contacts/contacts_screen.dart';
import 'history/call_history_screen.dart';
import 'chat/chat_screen.dart';
import 'settings/settings_screen.dart';
import 'call/active_call_screen.dart';
import 'widgets/dock_nav_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;
  bool _isCallScreenPushed = false;

  final List<Widget> _screens = const [
    DialpadScreen(),
    ContactsScreen(),
    CallHistoryScreen(),
    ChatScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
    );
  }

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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      extendBody: false,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // tab switching via dock
        children: _screens,
      ),
      bottomNavigationBar: AuraDockNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
