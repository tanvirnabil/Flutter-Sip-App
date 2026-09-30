import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../models/call_session_model.dart';
import '../../providers/sip_provider.dart';
import 'dtmf_sheet.dart';

class ActiveCallScreen extends StatelessWidget {
  const ActiveCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sip = context.watch<SipProvider>();
    final session = sip.session;

    if (session == null || session.status == AuraCallStatus.ended) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
      return const Scaffold(backgroundColor: AppColors.darkBackground);
    }

    final isIncomingRinging = session.direction == AuraCallDirection.incoming &&
        session.status == AuraCallStatus.ringing;

    return Scaffold(
      backgroundColor: AppColors.inCallBackground,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white12,
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    session.displayName.isNotEmpty
                        ? session.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 38,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: session.status == AuraCallStatus.active
                    ? AppColors.callGreen.withOpacity(0.2)
                    : Colors.white10,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusText(session, sip),
                style: TextStyle(
                  color: session.status == AuraCallStatus.active
                      ? AppColors.callGreen
                      : Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const Spacer(),

            if (isIncomingRinging)
              Padding(
                padding: const EdgeInsets.only(bottom: 60, left: 40, right: 40),
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
                      icon: CupertinoIcons.phone_fill,
                      color: AppColors.callGreen,
                      label: 'Accept',
                      onTap: () {
                        Haptics.medium();
                        sip.answerCall();
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
                          icon: session.isMuted
                              ? CupertinoIcons.mic_off
                              : CupertinoIcons.mic_fill,
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
                          icon: session.isSpeaker
                              ? CupertinoIcons.speaker_3_fill
                              : CupertinoIcons.speaker_fill,
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
                          icon: CupertinoIcons.add,
                          label: 'Add Call',
                          isActive: false,
                          onTap: () {
                            Haptics.light();
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

  void _showDtmfSheet(BuildContext context, SipProvider sip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DtmfKeypadSheet(
        onKeyPressed: (key) => sip.sendDTMF(key),
      ),
    );
  }

  Widget _buildControlCircle({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.white : Colors.white12,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black : Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
