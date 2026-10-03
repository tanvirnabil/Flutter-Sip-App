import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/dtmf_tones.dart';
import '../../core/utils/haptics.dart';
import '../../services/sip_service.dart';
import '../../providers/sip_provider.dart';
import '../call/active_call_screen.dart';

class DialpadScreen extends StatefulWidget {
  const DialpadScreen({super.key});

  @override
  State<DialpadScreen> createState() => _DialpadScreenState();
}

class _DialpadScreenState extends State<DialpadScreen> {
  final TextEditingController _numberController = TextEditingController();

  static const List<Map<String, String>> _keys = [
    {'digit': '1', 'letters': ''},
    {'digit': '2', 'letters': 'ABC'},
    {'digit': '3', 'letters': 'DEF'},
    {'digit': '4', 'letters': 'GHI'},
    {'digit': '5', 'letters': 'JKL'},
    {'digit': '6', 'letters': 'MNO'},
    {'digit': '7', 'letters': 'PQRS'},
    {'digit': '8', 'letters': 'TUV'},
    {'digit': '9', 'letters': 'WXYZ'},
    {'digit': '*', 'letters': ''},
    {'digit': '0', 'letters': '+'},
    {'digit': '#', 'letters': ''},
  ];

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  void _onKeyPressed(String digit) {
    Haptics.light();
    DtmfPlayer.playTone(digit);
    setState(() {
      _numberController.text += digit;
    });
  }

  void _onBackspace() {
    if (_numberController.text.isNotEmpty) {
      Haptics.light();
      setState(() {
        _numberController.text =
            _numberController.text.substring(0, _numberController.text.length - 1);
      });
    }
  }

  void _onClearAll() {
    if (_numberController.text.isNotEmpty) {
      Haptics.medium();
      setState(() {
        _numberController.clear();
      });
    }
  }

  Future<void> _pasteClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      Haptics.light();
      final clean = data.text!.replaceAll(RegExp(r'[^0-9*#+]'), '');
      setState(() {
        _numberController.text += clean;
      });
    }
  }

  Future<void> _handleCall({bool isVideo = false}) async {
    final number = _numberController.text.trim();
    if (number.isEmpty) return;

    Haptics.medium();
    final sip = context.read<SipProvider>();
    final ok = await sip.makeCall(number, isVideo: isVideo);

    if (mounted && ok) {
      Navigator.push(
        context,
        CupertinoPageRoute(builder: (_) => const ActiveCallScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sip = context.watch<SipProvider>();

    final gridLineColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFD1D1D6);
    final isRegistered = sip.status == SipConnectionStatus.registered;
    final accountTitle = sip.account?.displayName.isNotEmpty == true
        ? sip.account!.displayName
        : (sip.account?.extension.isNotEmpty == true ? 'Clario ${sip.account!.extension}' : 'Clario');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header: QR icon on left, Center Account Title + Status Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          CupertinoIcons.qrcode,
                          size: 22,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      onPressed: () {
                        // QR scan or PBX account info modal
                        _showAccountInfoSheet(context, sip, isDark);
                      },
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        accountTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isRegistered
                            ? 'Ready'
                            : (sip.status == SipConnectionStatus.connecting
                                ? 'Connecting...'
                                : 'Offline'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isRegistered
                              ? AppColors.brandAccent
                              : (sip.status == SipConnectionStatus.connecting
                                  ? AppColors.warningOrange
                                  : AppColors.endCallRed),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Dialed Number Display Area
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              child: _numberController.text.isNotEmpty
                  ? Row(
                      children: [
                        const SizedBox(width: 40),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _numberController.text,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 1.5,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            CupertinoIcons.delete_left_fill,
                            size: 24,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                          onPressed: _onBackspace,
                          onLongPress: _onClearAll,
                        ),
                      ],
                    )
                  : GestureDetector(
                      onTap: _pasteClipboard,
                      child: Text(
                        'Tap to paste number',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
            ),

            // Keypad Grid: Edge-to-edge thin lines dividing cells
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: gridLineColor, width: 0.8),
                    bottom: BorderSide(color: gridLineColor, width: 0.8),
                  ),
                ),
                child: Column(
                  children: [
                    for (int row = 0; row < 4; row++) ...[
                      if (row > 0)
                        Divider(
                          height: 1,
                          thickness: 0.8,
                          color: gridLineColor,
                        ),
                      Expanded(
                        child: Row(
                          children: [
                            for (int col = 0; col < 3; col++) ...[
                              if (col > 0)
                                VerticalDivider(
                                  width: 1,
                                  thickness: 0.8,
                                  color: gridLineColor,
                                ),
                              Expanded(
                                child: _buildKeypadCell(
                                  _keys[row * 3 + col],
                                  isDark,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Solid Green Call Button & Quick Video Action
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(
                children: [
                  // Video Call Toggle
                  Container(
                    height: 52,
                    width: 52,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        CupertinoIcons.video_camera_solid,
                        color: AppColors.brandPrimary,
                        size: 24,
                      ),
                      tooltip: 'Video Call',
                      onPressed: () => _handleCall(isVideo: true),
                    ),
                  ),

                  // Full-Width Luminous Mint "Call" Action Banner
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _handleCall(isVideo: false),
                        child: const Text(
                          'Call',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadCell(Map<String, String> keyInfo, bool isDark) {
    final digit = keyInfo['digit']!;
    final letters = keyInfo['letters']!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onKeyPressed(digit),
        onLongPress: () {
          if (digit == '0') {
            _onKeyPressed('+');
          }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                digit,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w200,
                  color: isDark ? Colors.white : const Color(0xFF2C2C2E),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 14,
                child: letters.isNotEmpty
                    ? Text(
                        letters,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: isDark ? Colors.white38 : const Color(0xFF8E8E93),
                          letterSpacing: 1.2,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountInfoSheet(BuildContext context, SipProvider sip, bool isDark) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(sip.account?.displayName ?? 'SIP Account'),
        message: Text(
          'Extension: ${sip.account?.extension ?? "N/A"}\n'
          'Server: ${sip.account?.domain ?? "N/A"}\n'
          'Status: ${sip.status.name.toUpperCase()}',
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              if (sip.account != null) {
                sip.register(sip.account!);
              }
            },
            child: const Text('Reconnect / Re-register'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ),
    );
  }
}
