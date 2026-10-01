import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
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
    {'digit': '2', 'letters': 'A B C'},
    {'digit': '3', 'letters': 'D E F'},
    {'digit': '4', 'letters': 'G H I'},
    {'digit': '5', 'letters': 'J K L'},
    {'digit': '6', 'letters': 'M N O'},
    {'digit': '7', 'letters': 'P Q R S'},
    {'digit': '8', 'letters': 'T U V'},
    {'digit': '9', 'letters': 'W X Y Z'},
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
        _numberController.text = _numberController.text.substring(0, _numberController.text.length - 1);
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildConnectionPill(sip, isDark),
            const Spacer(flex: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 52,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _numberController.text.isEmpty ? '' : _numberController.text,
                    style: AppTypography.dialedNumberDisplay.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
              ),
            ),
            if (_numberController.text.isEmpty)
              GestureDetector(
                onTap: _pasteClipboard,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Tap to paste number',
                    style: TextStyle(
                      color: AppColors.accentBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 22),
            const Spacer(flex: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  for (int row = 0; row < 4; row++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (int col = 0; col < 3; col++)
                            _buildDialButton(_keys[row * 3 + col], isDark),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  SizedBox(
                    width: 76,
                    child: Center(
                      child: InkWell(
                        onTap: () => _handleCall(isVideo: true),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.video_camera_solid,
                            color: AppColors.accentBlue,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: InkWell(
                        onTap: () => _handleCall(isVideo: false),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: const BoxDecoration(
                            color: AppColors.callGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x5534C759),
                                blurRadius: 16,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.phone_fill,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 76,
                    child: _numberController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: _onBackspace,
                            onLongPress: _onClearAll,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  CupertinoIcons.delete_left_fill,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  size: 28,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionPill(SipProvider sip, bool isDark) {
    Color pillColor;
    String label;

    switch (sip.status) {
      case SipConnectionStatus.registered:
        pillColor = AppColors.callGreen;
        label = sip.account != null ? '${sip.account!.extension}@${sip.account!.domain}' : 'Connected';
        break;
      case SipConnectionStatus.connecting:
        pillColor = AppColors.warningOrange;
        label = 'Connecting...';
        break;
      case SipConnectionStatus.registrationFailed:
        pillColor = AppColors.endCallRed;
        label = 'Registration Failed';
        break;
      case SipConnectionStatus.connected:
        pillColor = AppColors.accentBlue;
        label = 'Connected';
        break;
      case SipConnectionStatus.disconnected:
        pillColor = Colors.grey;
        label = 'Offline';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0x22FFFFFF) : const Color(0x15000000),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: pillColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialButton(Map<String, String> keyData, bool isDark) {
    final digit = keyData['digit']!;
    final letters = keyData['letters']!;

    return InkWell(
      onTap: () => _onKeyPressed(digit),
      onLongPress: () {
        if (digit == '0') {
          _onKeyPressed('+');
        }
      },
      customBorder: const CircleBorder(),
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkDialButton : AppColors.lightDialButton,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              digit,
              style: AppTypography.dialNumber.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            if (letters.isNotEmpty)
              Text(
                letters,
                style: AppTypography.dialLetters.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              )
            else if (digit == '0')
              Text(
                '+',
                style: AppTypography.dialLetters.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

