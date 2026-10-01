import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../providers/sip_provider.dart';
import '../../services/background_service.dart';
import '../../services/call_recording_service.dart';
import '../../services/dtmf_audio_service.dart';
import '../../services/ringtone_service.dart';
import '../../services/video_settings_service.dart';
import '../auth/sip_login_screen.dart';

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
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
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
          padding: const EdgeInsets.only(bottom: 84),
          children: [
            _buildSettingsRow(
              icon: CupertinoIcons.person_2_fill,
              iconColor: const Color(0xFF8E8E93),
              title: 'Accounts',
              subtitle: sip.account?.extension.isNotEmpty == true
                  ? '${sip.account!.extension}@${sip.account!.domain}'
                  : 'Configure SIP',
              isDark: isDark,
              onTap: () => _openAccountsPage(context, sip, isDark),
            ),
            _buildSettingsRow(
              icon: CupertinoIcons.music_note_2,
              iconColor: const Color(0xFF5856D6),
              title: 'Audio',
              subtitle: 'Ringtones, Keypad Tones, Codecs',
              isDark: isDark,
              onTap: () => _openAudioPage(context, isDark),
            ),
            _buildSettingsRow(
              icon: CupertinoIcons.video_camera_solid,
              iconColor: const Color(0xFF007AFF),
              title: 'Video',
              subtitle: _videoEnabled ? 'Enabled (${_videoService.preferredCodec})' : 'Disabled',
              isDark: isDark,
              onTap: () => _openVideoPage(context, isDark),
            ),
            _buildSettingsRow(
              icon: CupertinoIcons.antenna_radiowaves_left_right,
              iconColor: const Color(0xFFFF9500),
              title: 'Incoming Calls',
              subtitle: 'Background Service & Battery Wake Lock',
              isDark: isDark,
              onTap: () => _openIncomingCallsPage(context, isDark),
            ),
            _buildSettingsRow(
              icon: CupertinoIcons.circle_fill,
              iconColor: const Color(0xFFFF3B30),
              title: 'Recording Calls',
              subtitle: _autoRecord ? 'Auto-Record Enabled' : 'Manual',
              isDark: isDark,
              onTap: () => _openRecordingPage(context, isDark),
            ),
            _buildSettingsRow(
              icon: CupertinoIcons.wrench_fill,
              iconColor: const Color(0xFF8E8E93),
              title: 'Advanced',
              subtitle: 'SIP Transport, STUN, Network NAT',
              isDark: isDark,
              onTap: () => _openAdvancedPage(context, isDark),
            ),
            _buildSettingsRow(
              icon: CupertinoIcons.info_circle_fill,
              iconColor: const Color(0xFFFF9500),
              title: 'Information',
              subtitle: 'Network status & PBX Diagnostics',
              isDark: isDark,
              onTap: () => _openInfoPage(context, sip, isDark),
            ),
            _buildSettingsRow(
              icon: CupertinoIcons.chat_bubble_2_fill,
              iconColor: const Color(0xFF34C759),
              title: 'About',
              subtitle: 'Aura VoIP v1.3.0',
              isDark: isDark,
              onTap: () => _openAboutPage(context, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required Color iconColor,
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
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEFEFF4),
                width: 0.8,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
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
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: isDark ? Colors.white30 : const Color(0xFFC7C7CC),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SUB-PAGES ---

  void _openAccountsPage(BuildContext context, SipProvider sip, bool isDark) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          appBar: AppBar(title: const Text('SIP Accounts')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                title: const Text('Account Name'),
                subtitle: Text(sip.account?.displayName ?? 'Not set'),
              ),
              ListTile(
                title: const Text('SIP Username / Ext'),
                subtitle: Text(sip.account?.extension ?? 'Not set'),
              ),
              ListTile(
                title: const Text('PBX Domain / Host'),
                subtitle: Text(sip.account?.domain ?? 'Not set'),
              ),
              ListTile(
                title: const Text('Registration Status'),
                subtitle: Text(sip.status.name.toUpperCase()),
                trailing: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: sip.status.name == 'registered'
                        ? const Color(0xFF75B928)
                        : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF75B928),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  if (sip.account != null) {
                    sip.register(sip.account!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Re-registering SIP...')),
                    );
                  }
                },
                child: const Text('Reconnect / Re-register'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.endCallRed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.endCallRed),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  await sip.unregister();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      CupertinoPageRoute(builder: (_) => const SipLoginScreen()),
                      (route) => false,
                    );
                  }
                },
                child: const Text('Sign Out / Switch Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAudioPage(BuildContext context, bool isDark) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => StatefulBuilder(
          builder: (context, setSubState) => Scaffold(
            backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
            appBar: AppBar(title: const Text('Audio Settings')),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile.adaptive(
                  title: const Text('Keypad DTMF Tones'),
                  subtitle: const Text('Play audible dial tones when tapping keys'),
                  value: _dtmfSoundEnabled,
                  activeTrackColor: const Color(0xFF75B928),
                  onChanged: (val) async {
                    await _dtmfService.setEnabled(val);
                    setSubState(() => _dtmfSoundEnabled = val);
                    setState(() {});
                  },
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Incoming Call Ringtone',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                ...RingtoneService.availableRingtones.map((rt) {
                  final isSelected = rt.id == _ringtoneService.selectedRingtoneId;
                  return ListTile(
                    title: Text(rt.title),
                    trailing: isSelected
                        ? const Icon(CupertinoIcons.checkmark, color: Color(0xFF75B928))
                        : null,
                    onTap: () async {
                      await _ringtoneService.selectRingtone(rt.id);
                      await _ringtoneService.previewRingtone(rt.id);
                      setSubState(() {});
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openVideoPage(BuildContext context, bool isDark) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => StatefulBuilder(
          builder: (context, setSubState) => Scaffold(
            backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
            appBar: AppBar(title: const Text('Video Settings')),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile.adaptive(
                  title: const Text('Video Calling (WebRTC)'),
                  subtitle: const Text('Enable two-way video communication'),
                  value: _videoEnabled,
                  activeTrackColor: const Color(0xFF75B928),
                  onChanged: (val) async {
                    await _videoService.setVideoEnabled(val);
                    setSubState(() => _videoEnabled = val);
                    setState(() {});
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Preferred Video Codec'),
                  subtitle: Text(_videoService.preferredCodec),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
                  onTap: () {
                    showCupertinoActionSheet(
                      context: context,
                      title: 'Select Preferred Video Codec',
                      options: VideoSettingsService.availableCodecs,
                      onSelected: (val) async {
                        await _videoService.setPreferredCodec(val);
                        setSubState(() {});
                        setState(() {});
                      },
                    );
                  },
                ),
                ListTile(
                  title: const Text('Resolution & Framerate'),
                  subtitle: Text(_videoService.resolution),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
                  onTap: () {
                    showCupertinoActionSheet(
                      context: context,
                      title: 'Select Video Resolution',
                      options: VideoSettingsService.availableResolutions,
                      onSelected: (val) async {
                        await _videoService.setResolution(val);
                        setSubState(() {});
                        setState(() {});
                      },
                    );
                  },
                ),
                ListTile(
                  title: const Text('Default Camera'),
                  subtitle: Text(_videoService.defaultCamera),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
                  onTap: () {
                    showCupertinoActionSheet(
                      context: context,
                      title: 'Select Default Camera',
                      options: VideoSettingsService.availableCameras,
                      onSelected: (val) async {
                        await _videoService.setDefaultCamera(val);
                        setSubState(() {});
                        setState(() {});
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openIncomingCallsPage(BuildContext context, bool isDark) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => StatefulBuilder(
          builder: (context, setSubState) => Scaffold(
            backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
            appBar: AppBar(title: const Text('Incoming Calls & Service')),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  title: const Text('Background Service Status'),
                  subtitle: const Text('Always active in background for reliable call reception'),
                  trailing: const Icon(CupertinoIcons.checkmark_shield_fill, color: Color(0xFF75B928)),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Battery Optimization Exemption'),
                  subtitle: Text(_isIgnoringBattery
                      ? 'Exempted (Recommended for 100% background uptime)'
                      : 'Not Exempted (May delay background calls)'),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF75B928),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      await _backgroundService.requestBatteryOptimizationExemption();
                      final isExempt = await _backgroundService.checkBatteryOptimization();
                      setSubState(() => _isIgnoringBattery = isExempt);
                    },
                    child: Text(_isIgnoringBattery ? 'Verified' : 'Exempt'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openRecordingPage(BuildContext context, bool isDark) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => StatefulBuilder(
          builder: (context, setSubState) => Scaffold(
            backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
            appBar: AppBar(title: const Text('Call Recording')),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile.adaptive(
                  title: const Text('Auto-Record All Calls'),
                  subtitle: const Text('Automatically record two-way audio to local storage'),
                  value: _autoRecord,
                  activeTrackColor: const Color(0xFF75B928),
                  onChanged: (val) async {
                    await _recordingService.setAutoRecordEnabled(val);
                    setSubState(() => _autoRecord = val);
                    setState(() {});
                  },
                ),
                const Divider(),
                const ListTile(
                  title: Text('Recording Audio Format'),
                  subtitle: Text('AAC-LC 44.1 kHz (Broadcast Clarity)'),
                ),
                const ListTile(
                  title: Text('Playback Location'),
                  subtitle: Text('Recent Call Logs > Info (i) icon'),
                ),
                const ListTile(
                  title: Text('Storage Auto-Purge'),
                  subtitle: Text('Recordings are automatically deleted when call logs are deleted.'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openAdvancedPage(BuildContext context, bool isDark) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          appBar: AppBar(title: const Text('Advanced SIP Settings')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              ListTile(
                title: Text('Transport Protocol'),
                subtitle: Text('WebSocket (WSS / WS) / UDP Socket'),
              ),
              ListTile(
                title: Text('NAT Keep-Alive'),
                subtitle: Text('20 seconds heartbeat ping'),
              ),
              ListTile(
                title: Text('STUN / ICE Traversal'),
                subtitle: Text('stun:stun.l.google.com:19302'),
              ),
              ListTile(
                title: Text('SIP User Agent'),
                subtitle: Text('AuraVoIP/1.3.0 (Flutter/Android)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openInfoPage(BuildContext context, SipProvider sip, bool isDark) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          appBar: AppBar(title: const Text('Network & Diagnostic Info')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                title: const Text('SIP Status'),
                subtitle: Text(sip.status.name.toUpperCase()),
              ),
              ListTile(
                title: const Text('Connected PBX Server'),
                subtitle: Text(sip.account?.domain ?? 'None'),
              ),
              ListTile(
                title: const Text('Registered SIP URI'),
                subtitle: Text(sip.account != null
                    ? 'sip:${sip.account!.extension}@${sip.account!.domain}'
                    : 'Unregistered'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAboutPage(BuildContext context, bool isDark) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          appBar: AppBar(title: const Text('About Aura VoIP')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF75B928).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.phone_fill,
                      color: Color(0xFF75B928),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aura VoIP',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Version 1.3.0 (Build 4)',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Professional SIP / WebRTC Softphone Client for Android with Phonebook Sync, Call Recording, and HD Video Calling.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showCupertinoActionSheet({
    required BuildContext context,
    required String title,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(title),
        actions: options.map((opt) {
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              onSelected(opt);
            },
            child: Text(opt),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}
