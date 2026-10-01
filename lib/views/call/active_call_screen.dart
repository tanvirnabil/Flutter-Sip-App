import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../models/call_session_model.dart';
import '../../providers/sip_provider.dart';
import '../../services/call_recording_service.dart';
import 'dtmf_sheet.dart';

class ActiveCallScreen extends StatefulWidget {
  const ActiveCallScreen({super.key});

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _waveController;

  // Local draggable PiP video offset
  Offset _pipOffset = const Offset(16, 80);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sip = context.watch<SipProvider>();
    final session = sip.session;

    if (session == null || session.status == AuraCallStatus.ended) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
      return const Scaffold(backgroundColor: AppColors.darkBackground);
    }

    final isIncomingRinging = session.direction == AuraCallDirection.incoming &&
        session.status == AuraCallStatus.ringing;
    final isActive = session.status == AuraCallStatus.active;
    final isVideo = session.isVideo;

    return Scaffold(
      backgroundColor: AppColors.inCallBackground,
      body: isVideo && (isActive || session.status == AuraCallStatus.connecting)
          ? _buildVideoCallView(context, sip, session)
          : _buildAudioCallView(context, sip, session, isIncomingRinging, isActive),
    );
  }

  Widget _buildVideoCallView(BuildContext context, SipProvider sip, CallSessionModel session) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // 1. Remote Video (Full Screen)
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child: RTCVideoView(
              sip.remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
        ),

        // Gradient Vignette for UI visibility
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0x99000000),
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xCC000000),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.25, 0.7, 1.0],
              ),
            ),
          ),
        ),

        // 2. Top Header (Caller Info & Duration)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      session.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.callGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          sip.formattedDuration,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                // Flip Camera Quick Button
                IconButton(
                  icon: const Icon(CupertinoIcons.switch_camera, color: Colors.white, size: 28),
                  tooltip: 'Flip Camera',
                  onPressed: () {
                    Haptics.light();
                    sip.switchCamera();
                  },
                ),
              ],
            ),
          ),
        ),

        // 3. Floating Draggable Local Camera PiP (Picture-in-Picture)
        Positioned(
          left: _pipOffset.dx.clamp(16.0, size.width - 126.0),
          top: _pipOffset.dy.clamp(60.0, size.height - 240.0),
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _pipOffset += details.delta;
              });
            },
            child: Container(
              width: 110,
              height: 155,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white30, width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 6)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: session.isLocalCameraEnabled
                  ? RTCVideoView(
                      sip.localRenderer,
                      mirror: true,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : const Center(
                      child: Icon(CupertinoIcons.videocam_fill, color: Colors.white38, size: 36),
                    ),
            ),
          ),
        ),

        // 4. Bottom Video Controls
        Positioned(
          bottom: 36,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Camera On/Off Toggle
                _buildControlCircle(
                  icon: session.isLocalCameraEnabled
                      ? CupertinoIcons.videocam_fill
                      : CupertinoIcons.videocam,
                  label: session.isLocalCameraEnabled ? 'Camera On' : 'Camera Off',
                  isActive: session.isLocalCameraEnabled,
                  onTap: () {
                    Haptics.light();
                    sip.toggleCamera();
                  },
                ),
                // Mic Mute
                _buildControlCircle(
                  icon: session.isMuted ? CupertinoIcons.mic_off : CupertinoIcons.mic_fill,
                  label: 'Mute',
                  isActive: session.isMuted,
                  onTap: () {
                    Haptics.light();
                    sip.toggleMute();
                  },
                ),
                // Speakerphone
                _buildControlCircle(
                  icon: session.isSpeaker ? CupertinoIcons.speaker_3_fill : CupertinoIcons.speaker_fill,
                  label: 'Speaker',
                  isActive: session.isSpeaker,
                  onTap: () {
                    Haptics.light();
                    sip.toggleSpeaker();
                  },
                ),
                // End Call Red Button
                InkWell(
                  onTap: () {
                    Haptics.heavy();
                    sip.hangup();
                  },
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.endCallRed,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Color(0x66FF3B30), blurRadius: 16, offset: Offset(0, 6)),
                      ],
                    ),
                    child: const Icon(CupertinoIcons.phone_down_fill, color: Colors.white, size: 30),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioCallView(
    BuildContext context,
    SipProvider sip,
    CallSessionModel session,
    bool isIncomingRinging,
    bool isActive,
  ) {
    final recordingService = CallRecordingService();

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 36),

          // Caller Avatar with Apple Pulsing Radar Rings
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isIncomingRinging) ...[
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale1 = 1.0 + _pulseController.value * 0.45;
                        final opacity1 = (1.0 - _pulseController.value).clamp(0.0, 1.0);
                        return Transform.scale(
                          scale: scale1,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.callGreen.withValues(alpha: opacity1 * 0.6),
                                width: 2.0,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final progress2 = (_pulseController.value + 0.5) % 1.0;
                        final scale2 = 1.0 + progress2 * 0.45;
                        final opacity2 = (1.0 - progress2).clamp(0.0, 1.0);
                        return Transform.scale(
                          scale: scale2,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.callGreen.withValues(alpha: opacity2 * 0.35),
                                width: 1.5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  // Avatar Circle
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accentBlue.withValues(alpha: 0.9),
                          const Color(0xFF5856D6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isIncomingRinging
                              ? AppColors.callGreen.withValues(alpha: 0.3)
                              : Colors.black45,
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        session.displayName.isNotEmpty
                            ? session.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 38,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Text(
            session.displayName,
            textAlign: TextAlign.center,
            style: AppTypography.title2.copyWith(color: Colors.white),
          ),
          if (session.targetName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              session.targetNumber,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
          const SizedBox(height: 10),

          // Status Banner with Waveform
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? AppColors.callGreen.withValues(alpha: 0.2) : Colors.white10,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isActive) ...[
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, _) {
                      return Row(
                        children: List.generate(4, (i) {
                          final h = 6.0 + 8.0 * sin((_waveController.value * pi) + (i * 0.8)).abs();
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            width: 2.5,
                            height: h,
                            decoration: BoxDecoration(
                              color: AppColors.callGreen,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  _getStatusText(session, sip),
                  style: TextStyle(
                    color: isActive ? AppColors.callGreen : Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isActive && recordingService.isRecording) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.endCallRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'REC',
                    style: TextStyle(color: AppColors.endCallRed, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),

          const Spacer(),

          if (isIncomingRinging)
            Padding(
              padding: const EdgeInsets.only(bottom: 60, left: 44, right: 44),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionButton(
                    icon: CupertinoIcons.phone_down_fill,
                    color: AppColors.endCallRed,
                    label: 'Decline',
                    onTap: () {
                      Haptics.heavy();
                      sip.hangup();
                    },
                  ),
                  _buildActionButton(
                    icon: session.isVideo ? CupertinoIcons.video_camera_solid : CupertinoIcons.phone_fill,
                    color: AppColors.callGreen,
                    label: session.isVideo ? 'Accept Video' : 'Accept',
                    isPulsing: true,
                    onTap: () {
                      Haptics.medium();
                      sip.answerCall(isVideo: session.isVideo);
                    },
                  ),
                ],
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildControlCircle(
                        icon: session.isMuted ? CupertinoIcons.mic_off : CupertinoIcons.mic_fill,
                        label: 'Mute',
                        isActive: session.isMuted,
                        onTap: () {
                          Haptics.light();
                          sip.toggleMute();
                        },
                      ),
                      _buildControlCircle(
                        icon: CupertinoIcons.circle_grid_3x3_fill,
                        label: 'Keypad',
                        isActive: false,
                        onTap: () {
                          Haptics.light();
                          _showDtmfSheet(context, sip);
                        },
                      ),
                      _buildControlCircle(
                        icon: session.isSpeaker ? CupertinoIcons.speaker_3_fill : CupertinoIcons.speaker_fill,
                        label: 'Speaker',
                        isActive: session.isSpeaker,
                        onTap: () {
                          Haptics.light();
                          sip.toggleSpeaker();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildControlCircle(
                        icon: CupertinoIcons.pause_fill,
                        label: 'Hold',
                        isActive: session.isOnHold,
                        onTap: () {
                          Haptics.medium();
                          sip.toggleHold();
                        },
                      ),
                      _buildControlCircle(
                        icon: recordingService.isRecording ? CupertinoIcons.stop_fill : CupertinoIcons.circle_fill,
                        label: recordingService.isRecording ? 'Stop Rec' : 'Record',
                        isActive: recordingService.isRecording,
                        onTap: () async {
                          Haptics.light();
                          if (recordingService.isRecording) {
                            await recordingService.stopRecording();
                          } else {
                            await recordingService.startRecording(session.id, session.targetNumber);
                          }
                          setState(() {});
                        },
                      ),
                      _buildControlCircle(
                        icon: CupertinoIcons.waveform,
                        label: 'HD Voice',
                        isActive: true,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Center(
                child: InkWell(
                  onTap: () {
                    Haptics.heavy();
                    sip.hangup();
                  },
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      color: AppColors.endCallRed,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x66FF3B30),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.phone_down_fill,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusText(CallSessionModel session, SipProvider sip) {
    switch (session.status) {
      case AuraCallStatus.connecting:
        return 'Connecting...';
      case AuraCallStatus.ringing:
        return session.direction == AuraCallDirection.incoming ? 'Incoming Call...' : 'Ringing...';
      case AuraCallStatus.held:
        return 'Call On Hold';
      case AuraCallStatus.active:
        return sip.formattedDuration;
      case AuraCallStatus.ended:
        return 'Call Ended';
      case AuraCallStatus.idle:
        return '';
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    bool isPulsing = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildControlCircle({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black : Colors.white,
              size: 26,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showDtmfSheet(BuildContext context, SipProvider sip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DtmfKeypadSheet(onKeyPressed: (digit) => sip.sendDTMF(digit)),
    );
  }
}
