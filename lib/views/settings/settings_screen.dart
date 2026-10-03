import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../models/sip_account.dart';
import '../../providers/sip_provider.dart';
import '../../services/background_service.dart';
import '../../services/call_recording_service.dart';
import '../../services/dtmf_audio_service.dart';
import '../../services/ringtone_service.dart';
import '../../services/secure_storage_service.dart';
import '../../services/video_settings_service.dart';
import '../widgets/app_logo.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DtmfAudioService _dtmfService = DtmfAudioService();
  final RingtoneService _ringtoneService = RingtoneService();
  final BackgroundService _backgroundService = BackgroundService();
  final CallRecordingService _recordingService = CallRecordingService();
  final VideoSettingsService _videoService = VideoSettingsService();

  bool _dtmfSoundEnabled = true;
  bool _isIgnoringBattery = false;
  bool _autoRecord = false;
  bool _videoEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _dtmfService.init();
    await _ringtoneService.init();
    await _recordingService.init();
    await _videoService.init();
    final batteryExempt = await _backgroundService.checkBatteryOptimization();
    if (mounted) {
      setState(() {
        _dtmfSoundEnabled = _dtmfService.isEnabled;
        _isIgnoringBattery = batteryExempt;
        _autoRecord = _recordingService.isAutoRecordEnabled;
        _videoEnabled = _videoService.isVideoEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sip = context.watch<SipProvider>();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            _buildSettingsRow(
              icon: CupertinoIcons.person_2_fill,
              title: 'Accounts',
              subtitle: sip.account?.extension.isNotEmpty == true
                  ? '${sip.account!.extension}@${sip.account!.domain}'
                  : 'Manage SIP Accounts',
              isDark: isDark,
              onTap: () => _openAccountsPage(context, sip, isDark),
            ),
            _buildSettingsRow(
              icon: CupertinoIcons.music_note_2,
              title: 'Audio',
              subtitle: 'Ringtones, Keypad Tones, Codecs',
              isDark: isDark,
              onTap: () => _openAudioPage(context, isDark),
            ),
            _buildSettingsRow(
              icon: CupertinoIcons.video_camera_solid,
              title: 'Video',
              subtitle: _videoEnabled ? 'Enabled (${_videoService.preferredCodec})' : 'Disabled',
              isDark: isDark,
              onTap: () => _openVideoPage(context, isDark),
            ),
            _buildSettingsRow(
              icon: CupertinoIcons.antenna_radiowaves_left_right,
              title: 'Incoming Calls',
              subtitle: 'Background Service & Push Wake Lock',
              isDark: isDark,
              onTap: () => _openIncomingCallsPage(context, isDark),
            ),
            _buildSettingsRow(
              icon: CupertinoIcons.circle_fill,
              title: 'Call Recording',
              subtitle: _autoRecord ? 'Auto-Record Active (AAC)' : 'Manual Recording',
              isDark: isDark,
              onTap: () => _openRecordingPage(context, isDark),
            ),
            _buildSettingsRow(
              icon: CupertinoIcons.wrench_fill,
              title: 'Advanced',
              subtitle: 'SIP Transport, STUN, Keep-Alive',
              isDark: isDark,
              onTap: () => _openAdvancedPage(context, isDark),
            ),
            _buildSettingsRow(
              icon: CupertinoIcons.info_circle_fill,
              title: 'Diagnostics',
              subtitle: 'Connection metrics & Local IP',
              isDark: isDark,
              onTap: () => _openInfoPage(context, sip, isDark),
            ),
            _buildSettingsRow(
              icon: CupertinoIcons.checkmark_shield_fill,
              title: 'About Clario',
              subtitle: 'Clario Softphone v1.4.0',
              isDark: isDark,
              onTap: () => _openAboutPage(context, isDark),
            ),
          ],
        ),
      ),
    );
  }

  /// Single-Pattern Uniform Settings Row (Matching exact brand primary design)
  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Haptics.light();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                width: 0.8,
              ),
            ),
          ),
          child: Row(
            children: [
              // Single-pattern uniform container for every row
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.brandPrimary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_forward,
                size: 16,
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 1. ACCOUNTS MANAGEMENT SUBPAGE
  // ==========================================
  void _openAccountsPage(BuildContext context, SipProvider sip, bool isDark) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => const AccountsManagementScreen(),
      ),
    );
  }

  // ==========================================
  // 2. AUDIO SETTINGS SUBPAGE
  // ==========================================
  void _openAudioPage(BuildContext context, bool isDark) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => StatefulBuilder(
          builder: (ctx, setAudioState) {
            final ringtones = RingtoneService.availableRingtones;
            final selectedRingtoneId = _ringtoneService.selectedRingtoneId;

            return Scaffold(
              backgroundColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
              appBar: AppBar(
                title: const Text('Audio Settings'),
                elevation: 0,
                backgroundColor: Colors.transparent,
              ),
              body: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildSubheader('KEYPAD FEEDBACK', isDark),
                  SwitchListTile.adaptive(
                    activeTrackColor: AppColors.brandPrimary,
                    title: const Text('Keypad DTMF Tones', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Play audible DTMF tones on dialpad press'),
                    value: _dtmfSoundEnabled,
                    onChanged: (val) async {
                      await _dtmfService.setEnabled(val);
                      setAudioState(() => _dtmfSoundEnabled = val);
                      setState(() => _dtmfSoundEnabled = val);
                    },
                  ),
                  const Divider(),
                  _buildSubheader('RINGTONES', isDark),
                  ...ringtones.map((r) {
                    final isSelected = r.id == selectedRingtoneId;
                    return ListTile(
                      title: Text(r.title, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                      subtitle: Text(r.subtitle),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(CupertinoIcons.play_circle, color: AppColors.brandPrimary),
                            onPressed: () => _ringtoneService.previewRingtone(r.id),
                          ),
                          if (isSelected)
                            const Icon(CupertinoIcons.checkmark_alt, color: AppColors.brandPrimary, size: 20),
                        ],
                      ),
                      onTap: () async {
                        Haptics.selection();
                        await _ringtoneService.selectRingtone(r.id);
                        setAudioState(() {});
                      },
                    );
                  }),
                  const Divider(),
                  _buildSubheader('PREFERRED AUDIO CODECS', isDark),
                  _buildCodecTile('PCMU / G.711u', '64 kbps, Standard Telecom standard', true),
                  _buildCodecTile('PCMA / G.711a', '64 kbps, European Telecom standard', true),
                  _buildCodecTile('Opus HD Audio', 'Adaptive 6-510 kbps, Crystal Clear VoLTE', true),
                  _buildCodecTile('G.722 Wideband', '64 kbps, High-Definition Audio', true),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCodecTile(String title, String subtitle, bool isSelected) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: isSelected
          ? const Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.brandAccent, size: 20)
          : const Icon(CupertinoIcons.circle, color: Colors.grey, size: 20),
    );
  }

  // ==========================================
  // 3. VIDEO SETTINGS SUBPAGE
  // ==========================================
  void _openVideoPage(BuildContext context, bool isDark) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => StatefulBuilder(
          builder: (ctx, setVideoState) {
            return Scaffold(
              backgroundColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
              appBar: AppBar(
                title: const Text('Video Settings'),
                elevation: 0,
                backgroundColor: Colors.transparent,
              ),
              body: ListView(
                children: [
                  _buildSubheader('VIDEO CALLING', isDark),
                  SwitchListTile.adaptive(
                    activeTrackColor: AppColors.brandPrimary,
                    title: const Text('Enable Video Calls', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Allow receiving and placing WebRTC video calls'),
                    value: _videoEnabled,
                    onChanged: (val) async {
                      await _videoService.setVideoEnabled(val);
                      setVideoState(() => _videoEnabled = val);
                      setState(() => _videoEnabled = val);
                    },
                  ),
                  const Divider(),
                  _buildSubheader('PREFERRED CODEC', isDark),
                  RadioListTile<String>(
                    activeColor: AppColors.brandPrimary,
                    title: const Text('VP8 (Recommended)'),
                    subtitle: const Text('High interoperability with Asterisk & FreePBX'),
                    value: 'VP8',
                    groupValue: _videoService.preferredCodec,
                    onChanged: _videoEnabled
                        ? (val) async {
                            if (val != null) {
                              await _videoService.setPreferredCodec(val);
                              setVideoState(() {});
                            }
                          }
                        : null,
                  ),
                  RadioListTile<String>(
                    activeColor: AppColors.brandPrimary,
                    title: const Text('H.264'),
                    subtitle: const Text('Hardware accelerated compression'),
                    value: 'H264',
                    groupValue: _videoService.preferredCodec,
                    onChanged: _videoEnabled
                        ? (val) async {
                            if (val != null) {
                              await _videoService.setPreferredCodec(val);
                              setVideoState(() {});
                            }
                          }
                        : null,
                  ),
                  const Divider(),
                  _buildSubheader('CAMERA & RESOLUTION', isDark),
                  ListTile(
                    title: const Text('Default Camera'),
                    subtitle: Text(_videoService.defaultCamera == 'front' ? 'Front Facing' : 'Back Facing'),
                    trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
                    onTap: _videoEnabled
                        ? () async {
                            final next = _videoService.defaultCamera == 'front' ? 'back' : 'front';
                            await _videoService.setDefaultCamera(next);
                            setVideoState(() {});
                          }
                        : null,
                  ),
                  ListTile(
                    title: const Text('Resolution'),
                    subtitle: Text(_videoService.resolution),
                    trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
                    onTap: _videoEnabled
                        ? () async {
                            final next = _videoService.resolution.contains('720p')
                                ? '480p SD (640x480 - Data Saver)'
                                : '720p HD (1280x720)';
                            await _videoService.setResolution(next);
                            setVideoState(() {});
                          }
                        : null,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================
  // 4. INCOMING CALLS SUBPAGE
  // ==========================================
  void _openIncomingCallsPage(BuildContext context, bool isDark) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => StatefulBuilder(
          builder: (ctx, setIncState) {
            return Scaffold(
              backgroundColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
              appBar: AppBar(
                title: const Text('Incoming Calls'),
                elevation: 0,
                backgroundColor: Colors.transparent,
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSubheader('PERSISTENT BACKGROUND SERVICE', isDark),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131B2E) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(CupertinoIcons.bolt_fill, color: AppColors.brandAccent, size: 20),
                            SizedBox(width: 8),
                            Text('Always Connected', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Keeps your SIP socket connected in the background so you never miss an incoming call even when the app is closed.',
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isIgnoringBattery ? Colors.grey : AppColors.brandPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: Icon(_isIgnoringBattery ? CupertinoIcons.checkmark_circle : CupertinoIcons.battery_charging),
                          label: Text(_isIgnoringBattery ? 'Battery Optimized (Exempt)' : 'Grant Battery Exemption'),
                          onPressed: _isIgnoringBattery
                              ? null
                              : () async {
                                  await _backgroundService.requestBatteryOptimizationExemption();
                                  final exempt = await _backgroundService.checkBatteryOptimization();
                                  setIncState(() => _isIgnoringBattery = exempt);
                                  setState(() => _isIgnoringBattery = exempt);
                                },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================
  // 5. CALL RECORDING SUBPAGE
  // ==========================================
  void _openRecordingPage(BuildContext context, bool isDark) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => StatefulBuilder(
          builder: (ctx, setRecState) {
            return Scaffold(
              backgroundColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
              appBar: AppBar(
                title: const Text('Call Recording'),
                elevation: 0,
                backgroundColor: Colors.transparent,
              ),
              body: ListView(
                children: [
                  _buildSubheader('AUTOMATION', isDark),
                  SwitchListTile.adaptive(
                    activeTrackColor: AppColors.brandPrimary,
                    title: const Text('Auto-Record All Calls', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Automatically record audio when a call connects'),
                    value: _autoRecord,
                    onChanged: (val) async {
                      await _recordingService.setAutoRecordEnabled(val);
                      setRecState(() => _autoRecord = val);
                      setState(() => _autoRecord = val);
                    },
                  ),
                  const Divider(),
                  _buildSubheader('RECORDING FORMAT', isDark),
                  const ListTile(
                    title: Text('Encoding Format'),
                    subtitle: Text('AAC-LC High Fidelity Stereo (128 kbps)'),
                    trailing: Icon(CupertinoIcons.waveform, color: AppColors.brandAccent),
                  ),
                  const ListTile(
                    title: Text('Storage Location'),
                    subtitle: Text('Private App Documents / Clario Recordings'),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.endCallRed,
                        side: const BorderSide(color: AppColors.endCallRed),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(CupertinoIcons.trash),
                      label: const Text('Clean All Local Recordings'),
                      onPressed: () async {
                        showCupertinoDialog(
                          context: ctx,
                          builder: (c) => CupertinoAlertDialog(
                            title: const Text('Delete Recordings'),
                            content: const Text('Are you sure you want to delete all call recording files from disk?'),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.pop(c),
                              ),
                              CupertinoDialogAction(
                                isDestructiveAction: true,
                                child: const Text('Delete'),
                                onPressed: () async {
                                  Navigator.pop(c);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Recordings cleaned.')),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================
  // 6. ADVANCED SETTINGS SUBPAGE
  // ==========================================
  void _openAdvancedPage(BuildContext context, bool isDark) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
          appBar: AppBar(
            title: const Text('Advanced Settings'),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          body: ListView(
            children: [
              _buildSubheader('NETWORK & NAT TRAVERSAL', isDark),
              const ListTile(
                title: Text('Default STUN Server'),
                subtitle: Text('stun:stun.l.google.com:19302'),
                trailing: Icon(CupertinoIcons.globe, color: AppColors.brandPrimary),
              ),
              const ListTile(
                title: Text('SIP Keep-Alive Ping'),
                subtitle: Text('15 seconds (Maintains NAT pinhole)'),
                trailing: Icon(CupertinoIcons.timer, color: AppColors.brandPrimary),
              ),
              const ListTile(
                title: Text('ICE Candidate Harvesting'),
                subtitle: Text('Enabled (Host, SRFLX, Relay)'),
                trailing: Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.brandAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 7. DIAGNOSTICS & INFO SUBPAGE
  // ==========================================
  void _openInfoPage(BuildContext context, SipProvider sip, bool isDark) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
          appBar: AppBar(
            title: const Text('Diagnostics & Network'),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildDiagCard('SIP REGISTRATION', [
                _DiagRow('Status', sip.status.name.toUpperCase()),
                _DiagRow('Message', sip.statusMessage),
                _DiagRow('Account', sip.account?.formattedLabel ?? 'None'),
                _DiagRow('Domain', sip.account?.domain ?? 'None'),
                _DiagRow('Transport', sip.account?.transport.toUpperCase() ?? 'UDP'),
              ], isDark),
              const SizedBox(height: 16),
              _buildDiagCard('SYSTEM METRICS', [
                _DiagRow('Engine', 'SIP UA + WebRTC Native'),
                _DiagRow('Platform', 'Android / iOS Ready'),
                _DiagRow('Audio Routing', 'Earpiece / Speaker / BT'),
                _DiagRow('Build Target', 'Clario v1.4.0'),
              ], isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiagCard(String title, List<_DiagRow> rows, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.brandPrimary)),
          const SizedBox(height: 12),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.label, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13)),
                    Text(r.value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ==========================================
  // 8. ABOUT SUBPAGE
  // ==========================================
  void _openAboutPage(BuildContext context, bool isDark) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
          appBar: AppBar(
            title: const Text('About Clario'),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppLogo(size: 96, useCard: true),
                  const SizedBox(height: 20),
                  Text(
                    'Clario',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Version 1.4.0 (Build 6)',
                    style: TextStyle(fontSize: 13, color: AppColors.brandPrimary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Professional Grade VoIP & SIP Softphone for Mobile Networks.\nEngineered for crystal-clear voice clarity, low-latency WebRTC, and unified enterprise messaging.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    '© 2026 Clario Telecom. All rights reserved.',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubheader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? Colors.white54 : const Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _DiagRow {
  final String label;
  final String value;
  _DiagRow(this.label, this.value);
}

// ============================================================
// DEDICATED MULTI-SIP ACCOUNTS MANAGEMENT SCREEN
// ============================================================
class AccountsManagementScreen extends StatefulWidget {
  const AccountsManagementScreen({super.key});

  @override
  State<AccountsManagementScreen> createState() => _AccountsManagementScreenState();
}

class _AccountsManagementScreenState extends State<AccountsManagementScreen> {
  List<SipAccount> _accounts = [];
  String? _activeAccountId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final all = await SecureStorageService.getAllAccounts();
    final active = await SecureStorageService.getActiveAccount();
    if (mounted) {
      setState(() {
        _accounts = all;
        _activeAccountId = active?.id;
        _isLoading = false;
      });
    }
  }

  Future<void> _switchAccount(SipAccount account) async {
    Haptics.medium();
    await SecureStorageService.setActiveAccount(account.id);
    if (!mounted) return;
    final sip = context.read<SipProvider>();
    await sip.register(account);
    setState(() => _activeAccountId = account.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to ${account.formattedLabel}'),
        backgroundColor: AppColors.brandPrimary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openAccountEditor({SipAccount? existing}) {
    final isEditing = existing != null;
    final extCtrl = TextEditingController(text: existing?.extension ?? '');
    final passCtrl = TextEditingController(text: existing?.password ?? '');
    final domCtrl = TextEditingController(text: existing?.domain ?? '');
    final nameCtrl = TextEditingController(text: existing?.displayName ?? '');
    final portCtrl = TextEditingController(text: existing?.port.toString() ?? '5060');
    final stunCtrl = TextEditingController(text: existing?.stunServer ?? 'stun:stun.l.google.com:19302');
    String transport = existing?.transport ?? 'udp';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131B2E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEditing ? 'Edit SIP Account' : 'Add SIP Account',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(nameCtrl, 'Account Label (e.g. Office, Home)', isDark),
                    const SizedBox(height: 10),
                    _buildTextField(extCtrl, 'Extension / Username *', isDark, isRequired: true),
                    const SizedBox(height: 10),
                    _buildTextField(passCtrl, 'SIP Password *', isDark, isPassword: true, isRequired: true),
                    const SizedBox(height: 10),
                    _buildTextField(domCtrl, 'Domain / PBX IP *', isDark, isRequired: true),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(portCtrl, 'Port', isDark, isNumber: true)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: transport,
                            decoration: InputDecoration(
                              labelText: 'Transport',
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'udp', child: Text('UDP')),
                              DropdownMenuItem(value: 'tcp', child: Text('TCP')),
                              DropdownMenuItem(value: 'tls', child: Text('TLS')),
                              DropdownMenuItem(value: 'ws', child: Text('WS')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => transport = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(stunCtrl, 'STUN Server', isDark),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        final newAccount = SipAccount(
                          id: existing?.id ?? '',
                          displayName: nameCtrl.text.trim(),
                          extension: extCtrl.text.trim(),
                          password: passCtrl.text.trim(),
                          domain: domCtrl.text.trim(),
                          port: int.tryParse(portCtrl.text.trim()) ?? 5060,
                          transport: transport,
                          stunServer: stunCtrl.text.trim(),
                        );

                        await SecureStorageService.saveAccount(newAccount);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _loadAccounts();

                        if (!mounted) return;
                        if (_activeAccountId == newAccount.id || _accounts.isEmpty) {
                          context.read<SipProvider>().register(newAccount);
                        }
                      },
                      child: Text(isEditing ? 'Save Changes' : 'Add Account', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _deleteAccount(SipAccount account) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to remove ${account.formattedLabel}?'),
        actions: [
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () async {
              Navigator.pop(ctx);
              await SecureStorageService.deleteAccount(account.id);
              _loadAccounts();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    bool isDark, {
    bool isPassword = false,
    bool isNumber = false,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: isRequired
          ? (v) => v == null || v.trim().isEmpty ? 'Required field' : null
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
      appBar: AppBar(
        title: const Text('SIP Accounts', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.plus_circle_fill, color: AppColors.brandPrimary),
            tooltip: 'Add Account',
            onPressed: () => _openAccountEditor(),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _accounts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.person_badge_plus, size: 54, color: AppColors.brandPrimary),
                        const SizedBox(height: 16),
                        const Text('No SIP Accounts Configured', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                        const SizedBox(height: 8),
                        const Text('Add your first SIP line to start calling.'),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _openAccountEditor(),
                          icon: const Icon(CupertinoIcons.plus),
                          label: const Text('Add SIP Account'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _accounts.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final acc = _accounts[index];
                      final isActive = acc.id == _activeAccountId;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF131B2E) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isActive ? AppColors.brandPrimary : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                            width: isActive ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Active Radio Selection
                            GestureDetector(
                              onTap: () => _switchAccount(acc),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive ? AppColors.brandPrimary : Colors.transparent,
                                  border: Border.all(
                                    color: isActive ? AppColors.brandPrimary : Colors.grey,
                                    width: 2,
                                  ),
                                ),
                                child: isActive
                                    ? const Icon(CupertinoIcons.checkmark, size: 16, color: Colors.white)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Account Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        acc.formattedLabel,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                      ),
                                      if (isActive) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.brandAccent.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'ACTIVE',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.brandAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${acc.extension}@${acc.domain}:${acc.port} (${acc.transport.toUpperCase()})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Edit & Delete Actions
                            IconButton(
                              icon: const Icon(CupertinoIcons.pencil, size: 20, color: AppColors.brandPrimary),
                              tooltip: 'Edit Account',
                              onPressed: () => _openAccountEditor(existing: acc),
                            ),
                            IconButton(
                              icon: const Icon(CupertinoIcons.trash, size: 20, color: AppColors.endCallRed),
                              tooltip: 'Delete Account',
                              onPressed: () => _deleteAccount(acc),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
