import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
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
  bool _echoCancellation = true;
  bool _noiseSuppression = true;
  String _selectedCodec = 'PCMU / G.711u (PBX Default)';
  bool _dtmfSoundEnabled = true;
  bool _isIgnoringBattery = false;
  String? _pingResult;
  bool _isPinging = false;

  bool _autoRecord = false;
  bool _videoEnabled = true;

  final DtmfAudioService _dtmfService = DtmfAudioService();
  final RingtoneService _ringtoneService = RingtoneService();
  final BackgroundService _backgroundService = BackgroundService();
  final CallRecordingService _recordingService = CallRecordingService();
  final VideoSettingsService _videoService = VideoSettingsService();

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

  Future<void> _testPbxPing(String domain) async {
    setState(() {
      _isPinging = true;
      _pingResult = 'Testing connection...';
    });
    final stopwatch = Stopwatch()..start();
    try {
      final lookup = await InternetAddress.lookup(domain);
      stopwatch.stop();
      if (lookup.isNotEmpty && mounted) {
        setState(() {
          _pingResult = 'OK • ${stopwatch.elapsedMilliseconds} ms (${lookup.first.address})';
          _isPinging = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pingResult = 'Lookup failed: Check internet';
          _isPinging = false;
        });
      }
    }
  }

  void _showRingtoneSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Incoming Call Ringtone',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ...RingtoneService.availableRingtones.map((opt) {
                    final isSelected = _ringtoneService.selectedRingtoneId == opt.id;
                    final isPlaying = _ringtoneService.isPlayingPreview &&
                        _ringtoneService.currentlyPlayingId == opt.id;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: IconButton(
                        icon: Icon(
                          isPlaying ? CupertinoIcons.stop_circle_fill : CupertinoIcons.play_circle_fill,
                          color: AppColors.accentBlue,
                          size: 32,
                        ),
                        onPressed: () async {
                          await _ringtoneService.previewRingtone(opt.id, onStateChanged: () {
                            if (mounted) {
                              setSheetState(() {});
                              setState(() {});
                            }
                          });
                        },
                      ),
                      title: Text(
                        opt.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.accentBlue : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                      subtitle: Text(
                        opt.subtitle,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      trailing: isSelected
                          ? const Icon(CupertinoIcons.checkmark_alt, color: AppColors.accentBlue, size: 22)
                          : null,
                      onTap: () async {
                        Haptics.selection();
                        await _ringtoneService.selectRingtone(opt.id);
                        await _ringtoneService.stopPreview();
                        setSheetState(() {});
                        setState(() {});
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _ringtoneService.stopPreview();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sip = context.watch<SipProvider>();
    final themeProv = context.watch<ThemeProvider>();
    final account = sip.account;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Account Status Card
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
                  backgroundColor: AppColors.accentBlue.withValues(alpha: 0.15),
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
                            : (account != null ? 'Ext ${account.extension}' : 'No SIP Account'),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        account != null
                            ? '${account.extension}@${account.domain}'
                            : 'Sign in to place & receive calls',
                        style: const TextStyle(fontSize: 13, color: AppColors.lightTextSecondary),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: sip.isRegistered ? AppColors.callGreen : AppColors.warningOrange,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              sip.statusMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: sip.isRegistered ? AppColors.callGreen : AppColors.warningOrange,
                              ),
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

          const SizedBox(height: 22),

          // APPEARANCE & THEME
          _buildSectionHeader('APPEARANCE & THEME'),
          _buildCard(
            isDark: isDark,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Color Theme', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoSlidingSegmentedControl<AppThemeMode>(
                        groupValue: themeProv.themeMode,
                        children: const {
                          AppThemeMode.system: Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Text('System', style: TextStyle(fontSize: 12)),
                          ),
                          AppThemeMode.light: Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Text('Light', style: TextStyle(fontSize: 12)),
                          ),
                          AppThemeMode.dark: Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Text('Dark', style: TextStyle(fontSize: 12)),
                          ),
                          AppThemeMode.oled: Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Text('OLED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        },
                        onValueChanged: (mode) {
                          if (mode != null) themeProv.setThemeMode(mode);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // CALL RECORDING (NEW FEATURE)
          _buildSectionHeader('CALL RECORDING & RECENT AUDIO'),
          _buildCard(
            isDark: isDark,
            children: [
              SwitchListTile.adaptive(
                title: const Text('Auto-Record Calls'),
                subtitle: const Text('Automatically record calls and listen to audio in Recents'),
                value: _autoRecord,
                activeTrackColor: AppColors.accentBlue,
                onChanged: (val) async {
                  Haptics.selection();
                  setState(() => _autoRecord = val);
                  await _recordingService.setAutoRecordEnabled(val);
                },
              ),
              _buildDivider(isDark),
              const ListTile(
                title: Text('Storage & Privacy Policy'),
                subtitle: Text('Recordings are stored only on your local device. Deleting a recent call permanently deletes its audio file.'),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // VIDEO CALLING & MEDIA (NEW FEATURE)
          _buildSectionHeader('VIDEO CALLING & MEDIA'),
          _buildCard(
            isDark: isDark,
            children: [
              SwitchListTile.adaptive(
                title: const Text('Enable Video Calling'),
                subtitle: const Text('Allow SIP/WebRTC camera calls and video SDP negotiation'),
                value: _videoEnabled,
                activeTrackColor: AppColors.accentBlue,
                onChanged: (val) async {
                  Haptics.selection();
                  setState(() => _videoEnabled = val);
                  await _videoService.setVideoEnabled(val);
                },
              ),
              if (_videoEnabled) ...[
                _buildDivider(isDark),
                ListTile(
                  title: const Text('Preferred Video Codec'),
                  subtitle: Text(_videoService.preferredCodec, style: const TextStyle(color: AppColors.accentBlue)),
                  trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
                  onTap: _showVideoCodecDialog,
                ),
                _buildDivider(isDark),
                ListTile(
                  title: const Text('Video Quality / Resolution'),
                  subtitle: Text(_videoService.resolution, style: const TextStyle(color: AppColors.accentBlue)),
                  trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
                  onTap: _showVideoResolutionDialog,
                ),
                _buildDivider(isDark),
                ListTile(
                  title: const Text('Default Camera Facing'),
                  subtitle: Text(_videoService.defaultCamera, style: const TextStyle(color: AppColors.accentBlue)),
                  trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
                  onTap: _showDefaultCameraDialog,
                ),
              ],
            ],
          ),

          const SizedBox(height: 22),

          // SOUNDS & HAPTICS
          _buildSectionHeader('SOUNDS & AUDIO FEEDBACK'),
          _buildCard(
            isDark: isDark,
            children: [
              SwitchListTile.adaptive(
                title: const Text('Keypad Button Tones'),
                subtitle: const Text('Dual-Tone (DTMF) acoustic audio on tap'),
                value: _dtmfSoundEnabled,
                activeTrackColor: AppColors.accentBlue,
                onChanged: (val) async {
                  Haptics.selection();
                  setState(() => _dtmfSoundEnabled = val);
                  await _dtmfService.setEnabled(val);
                },
              ),
              _buildDivider(isDark),
              ListTile(
                title: const Text('Incoming Call Ringtone'),
                subtitle: Text(
                  RingtoneService.availableRingtones
                      .firstWhere(
                        (r) => r.id == _ringtoneService.selectedRingtoneId,
                        orElse: () => RingtoneService.availableRingtones.first,
                      )
                      .title,
                  style: const TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
                onTap: () {
                  Haptics.selection();
                  _showRingtoneSelector();
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          // 24/7 BACKGROUND PERSISTENCE & BATTERY
          _buildSectionHeader('BACKGROUND PERSISTENCE & BATTERY'),
          _buildCard(
            isDark: isDark,
            children: [
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.callGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.shield_fill, color: AppColors.callGreen, size: 20),
                ),
                title: const Text('Foreground Service Daemon'),
                subtitle: const Text('Keeps SIP connection alive when minimized'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.callGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(color: AppColors.callGreen, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              _buildDivider(isDark),
              ListTile(
                title: const Text('Battery Optimization Exemption'),
                subtitle: Text(
                  _isIgnoringBattery
                      ? 'Exempted (Protected from Android Doze Mode)'
                      : 'Not Exempted (Tap to allow background activity)',
                  style: TextStyle(
                    color: _isIgnoringBattery ? AppColors.callGreen : AppColors.warningOrange,
                    fontSize: 12,
                  ),
                ),
                trailing: _isIgnoringBattery
                    ? const Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.callGreen, size: 22)
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final granted = await _backgroundService.requestBatteryOptimizationExemption();
                          setState(() => _isIgnoringBattery = granted);
                        },
                        child: const Text('Whitelist'),
                      ),
              ),
              _buildDivider(isDark),
              ListTile(
                title: const Text('NAT Keep-Alive Heartbeat'),
                subtitle: const Text('Watchdog ensures SIP socket remains active'),
                trailing: const Text(
                  '30s (Auto)',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // AUDIO CODECS & MEDIA
          _buildSectionHeader('AUDIO CODECS & PROCESSING'),
          _buildCard(
            isDark: isDark,
            children: [
              ListTile(
                title: const Text('Preferred Audio Codec'),
                subtitle: Text(_selectedCodec),
                trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
                onTap: () {
                  _showCodecDialog();
                },
              ),
              _buildDivider(isDark),
              SwitchListTile.adaptive(
                title: const Text('Acoustic Echo Cancellation'),
                value: _echoCancellation,
                activeTrackColor: AppColors.accentBlue,
                onChanged: (val) => setState(() => _echoCancellation = val),
              ),
              _buildDivider(isDark),
              SwitchListTile.adaptive(
                title: const Text('Noise Suppression'),
                value: _noiseSuppression,
                activeTrackColor: AppColors.accentBlue,
                onChanged: (val) => setState(() => _noiseSuppression = val),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // NETWORK & PBX DIAGNOSTICS
          _buildSectionHeader('NETWORK & DIAGNOSTICS'),
          _buildCard(
            isDark: isDark,
            children: [
              ListTile(
                title: const Text('PBX Connectivity Tester'),
                subtitle: Text(
                  _pingResult ?? 'Measure round-trip latency to ${account?.domain ?? "sip.ranksitt.net"}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _pingResult != null ? AppColors.accentBlue : Colors.grey,
                  ),
                ),
                trailing: _isPinging
                    ? const CupertinoActivityIndicator()
                    : TextButton(
                        onPressed: () {
                          _testPbxPing(account?.domain ?? 'sip.ranksitt.net');
                        },
                        child: const Text('Test Ping'),
                      ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // RE-REGISTER & LOGOUT
          if (account != null) ...[
            Center(
              child: CupertinoButton(
                child: const Text('Re-Register SIP Account', style: TextStyle(color: AppColors.accentBlue)),
                onPressed: () {
                  Haptics.light();
                  sip.register(account);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Re-registering with PBX...')),
                  );
                },
              ),
            ),
            Center(
              child: CupertinoButton(
                child: const Text('Sign Out', style: TextStyle(color: AppColors.endCallRed)),
                onPressed: () => _confirmSignOut(context, sip),
              ),
            ),
          ],

          const SizedBox(height: 20),
          Center(
            child: Text(
              'Aura VoIP v1.2.0 • Enterprise SIP Edition\nBuilt for PBX ${account?.domain ?? "sip.ranksitt.net"}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white30 : Colors.black26,
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard({required bool isDark, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0x22FFFFFF) : const Color(0x15000000),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 16,
      color: isDark ? const Color(0x22FFFFFF) : const Color(0x15000000),
    );
  }

  void _showVideoCodecDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Select Preferred Video Codec'),
        actions: VideoSettingsService.availableCodecs.map((c) {
          return CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              await _videoService.setPreferredCodec(c);
              if (mounted) setState(() {});
            },
            child: Text(c),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showVideoResolutionDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Select Video Resolution & Framerate'),
        actions: VideoSettingsService.availableResolutions.map((r) {
          return CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              await _videoService.setResolution(r);
              if (mounted) setState(() {});
            },
            child: Text(r),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showDefaultCameraDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Select Default Camera'),
        actions: VideoSettingsService.availableCameras.map((cam) {
          return CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              await _videoService.setDefaultCamera(cam);
              if (mounted) setState(() {});
            },
            child: Text(cam),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showCodecDialog() {
    final codecs = [
      'PCMU / G.711u (PBX Default)',
      'PCMA / G.711a (Europe ISDN)',
      'Opus (Wideband HD Audio)',
      'G.722 (HD Voice)',
      'G.729 (Low Bandwidth)',
    ];

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Select Audio Codec Priority'),
        actions: codecs
            .map(
              (c) => CupertinoActionSheetAction(
                onPressed: () {
                  setState(() => _selectedCodec = c);
                  Navigator.pop(ctx);
                },
                child: Text(c),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, SipProvider sip) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out and stop receiving SIP calls?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Sign Out'),
            onPressed: () {
              Navigator.pop(ctx);
              sip.unregister();
            },
          ),
        ],
      ),
    );
  }
}
