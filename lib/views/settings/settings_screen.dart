import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../providers/sip_provider.dart';
import '../auth/sip_login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _echoCancellation = true;
  bool _noiseSuppression = true;
  String _selectedCodec = 'Opus (HD Audio)';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sip = context.watch<SipProvider>();
    final account = sip.account;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0x22FFFFFF) : const Color(0x15000000),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.accentBlue.withOpacity(0.15),
                  child: const Icon(CupertinoIcons.person_solid, color: AppColors.accentBlue, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account?.displayName.isNotEmpty == true
                            ? account!.displayName
                            : (account != null ? 'Ext: ${account.extension}' : 'No SIP Account'),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        account != null
                            ? '${account.extension}@${account.domain}'
                            : 'Sign in to place & receive calls',
                        style: const TextStyle(fontSize: 13, color: AppColors.lightTextSecondary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: sip.isRegistered ? AppColors.callGreen : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            sip.statusMessage,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: sip.isRegistered ? AppColors.callGreen : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Text(account != null ? 'Edit' : 'Login'),
                  onPressed: () {
                    Haptics.selection();
                    Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (_) => const SipLoginScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('AUDIO & CODEC ENGINE', isDark),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Audio Codec'),
                  subtitle: Text(_selectedCodec, style: const TextStyle(color: AppColors.accentBlue)),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
                  onTap: () => _selectCodecModal(context),
                ),
                Divider(height: 0.5, indent: 16, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                SwitchListTile.adaptive(
                  title: const Text('Hardware Echo Cancellation'),
                  subtitle: const Text('Reduces speaker feedback in calls', style: TextStyle(fontSize: 12)),
                  value: _echoCancellation,
                  activeColor: AppColors.accentBlue,
                  onChanged: (val) => setState(() => _echoCancellation = val),
                ),
                Divider(height: 0.5, indent: 16, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                SwitchListTile.adaptive(
                  title: const Text('AI Background Noise Suppression'),
                  subtitle: const Text('Filters out room background sound', style: TextStyle(fontSize: 12)),
                  value: _noiseSuppression,
                  activeColor: AppColors.accentBlue,
                  onChanged: (val) => setState(() => _noiseSuppression = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('NETWORK & BACKGROUND CALLS', isDark),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Protocol Mode'),
                  trailing: Text(
                    account?.isWebRtc == true ? 'WebRTC (WSS)' : 'Standard SIP (UDP)',
                    style: const TextStyle(color: AppColors.lightTextSecondary, fontSize: 14),
                  ),
                ),
                Divider(height: 0.5, indent: 16, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                ListTile(
                  title: const Text('Keep-Alive Interval'),
                  trailing: const Text('30 Seconds', style: TextStyle(color: AppColors.lightTextSecondary, fontSize: 14)),
                ),
                Divider(height: 0.5, indent: 16, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                ListTile(
                  title: const Text('Background Ringing'),
                  subtitle: const Text('Enabled via CallKit & ConnectionService', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(CupertinoIcons.checkmark_alt_circle_fill, color: AppColors.callGreen, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          if (account != null)
            ElevatedButton(
              onPressed: () {
                Haptics.heavy();
                sip.unregister();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.endCallRed.withOpacity(0.12),
                foregroundColor: AppColors.endCallRed,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Disconnect & Sign Out', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 32),
          const Center(
            child: Column(
              children: [
                Text(
                  'Aura VoIP for Android & iOS',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 2),
                Text(
                  'Version 1.0.0 (Build 1)',
                  style: TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  void _selectCodecModal(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Select Preferred Audio Codec'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedCodec = 'Opus (HD Audio 48kHz)');
              Navigator.pop(ctx);
            },
            child: const Text('Opus (HD Audio 48kHz)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedCodec = 'G.711u / PCMU (PSTN Standard)');
              Navigator.pop(ctx);
            },
            child: const Text('G.711u / PCMU (PSTN Standard)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedCodec = 'G.711a / PCMA (Europe/ISDN)');
              Navigator.pop(ctx);
            },
            child: const Text('G.711a / PCMA (Europe/ISDN)'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

