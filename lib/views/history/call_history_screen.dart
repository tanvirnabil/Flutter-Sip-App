import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../models/call_log_item.dart';
import '../../providers/history_provider.dart';
import '../../providers/sip_provider.dart';
import '../call/active_call_screen.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _playingLogId;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HistoryProvider>().loadLogs(showLoading: false);
      }
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback(CallLogItem item) async {
    if (item.recordingPath == null) return;
    final file = File(item.recordingPath!);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording file not found on disk.')),
      );
      return;
    }

    if (_playingLogId == item.id && _isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else if (_playingLogId == item.id && !_isPlaying) {
      await _audioPlayer.resume();
      setState(() => _isPlaying = true);
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(item.recordingPath!));
      setState(() {
        _playingLogId = item.id;
        _isPlaying = true;
      });
    }
  }

  void _callNumber(String number, {bool isVideo = false}) {
    Haptics.medium();
    final sip = context.read<SipProvider>();
    sip.makeCall(number, isVideo: isVideo);
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => const ActiveCallScreen()),
    );
  }

  void _confirmClearAll() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Clear Call History'),
        content: const Text('Are you sure you want to clear all recent calls and recordings?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              context.read<HistoryProvider>().clearHistory();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showCallDetailsSheet(CallLogItem item, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isCurrentPlaying = _playingLogId == item.id && _isPlaying;
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.displayName.isNotEmpty ? item.displayName : item.phoneNumber,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.type.name.toUpperCase()} • ${item.formattedDuration} • ${DateFormat('MMM d, yyyy h:mm a').format(item.timestamp)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Call Recording Player if Available
                  if (item.hasRecording) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.endCallRed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Call Recording (AAC-LC)',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  isCurrentPlaying
                                      ? CupertinoIcons.pause_circle_fill
                                      : CupertinoIcons.play_circle_fill,
                                  color: AppColors.callGreen,
                                  size: 38,
                                ),
                                onPressed: () async {
                                  await _togglePlayback(item);
                                  setSheetState(() {});
                                },
                              ),
                              Expanded(
                                child: Slider(
                                  value: (_playingLogId == item.id && _duration.inMilliseconds > 0)
                                      ? (_position.inMilliseconds / _duration.inMilliseconds)
                                          .clamp(0.0, 1.0)
                                      : 0.0,
                                  activeColor: AppColors.callGreen,
                                  onChanged: (val) {
                                    if (_playingLogId == item.id && _duration.inMilliseconds > 0) {
                                      final target = _duration * val;
                                      _audioPlayer.seek(target);
                                    }
                                  },
                                ),
                              ),
                              Text(
                                _playingLogId == item.id
                                    ? '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}'
                                    : item.formattedDuration,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Action Buttons: Voice Call, Video Call, Delete
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF75B928),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(CupertinoIcons.phone_fill, size: 18),
                        label: const Text('Voice Call'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _callNumber(item.phoneNumber, isVideo: false);
                        },
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(CupertinoIcons.video_camera_solid, size: 18),
                        label: const Text('Video Call'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _callNumber(item.phoneNumber, isVideo: true);
                        },
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.trash, color: AppColors.endCallRed),
                        tooltip: 'Delete Log',
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (item.id != null) {
                            context.read<HistoryProvider>().deleteLog(item.id!);
                          }
                        },
                      ),
                    ],
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
    final historyProv = context.watch<HistoryProvider>();
    final logs = historyProv.logs;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text(
          'Call History',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leadingWidth: 80,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: logs.isEmpty ? null : _confirmClearAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: logs.isEmpty
                        ? Colors.grey
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  Haptics.selection();
                  setState(() => _isEditing = !_isEditing);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isEditing
                        ? AppColors.brandPrimary
                        : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _isEditing ? 'Done' : 'Edit',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isEditing
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: logs.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.clock,
                      size: 48,
                      color: Colors.grey.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    const Text('No Recent Calls',
                        style: TextStyle(fontSize: 15, color: Colors.grey)),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: logs.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 0.8,
                  indent: 48,
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEFEFF4),
                ),
                itemBuilder: (context, index) {
                  final item = logs[index];
                  return _buildHistoryRow(item, isDark, historyProv);
                },
              ),
      ),
    );
  }

  Widget _buildHistoryRow(CallLogItem item, bool isDark, HistoryProvider prov) {
    final isMissed = item.type == CallLogType.missed;
    final dateStr = DateFormat('M/d/yy').format(item.timestamp); // Matches Screenshot 3: 8/20/26

    IconData directionIcon;
    Color directionColor;

    switch (item.type) {
      case CallLogType.incoming:
        directionIcon = CupertinoIcons.phone_arrow_down_left;
        directionColor = const Color(0xFF8E8E93);
        break;
      case CallLogType.outgoing:
        directionIcon = CupertinoIcons.phone_arrow_up_right;
        directionColor = const Color(0xFF8E8E93);
        break;
      case CallLogType.missed:
        directionIcon = CupertinoIcons.phone_down_fill;
        directionColor = AppColors.endCallRed;
        break;
    }

    final displayName = item.displayName.isNotEmpty ? item.displayName : item.phoneNumber;
    final subtitleLabel = item.displayName.isNotEmpty ? 'mobile' : 'Unknown';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_isEditing) {
            if (item.id != null) prov.deleteLog(item.id!);
          } else {
            _callNumber(item.phoneNumber, isVideo: false);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Delete circle if in Edit mode
              if (_isEditing) ...[
                GestureDetector(
                  onTap: () {
                    if (item.id != null) prov.deleteLog(item.id!);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: const Icon(
                      CupertinoIcons.minus_circle_fill,
                      color: AppColors.endCallRed,
                      size: 22,
                    ),
                  ),
                ),
              ],

              // Direction Icon (Slanted phone handset from screenshot)
              Icon(
                directionIcon,
                size: 18,
                color: directionColor,
              ),
              const SizedBox(width: 14),

              // Title (Red for missed, else standard) & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isMissed
                            ? const Color(0xFFD32F2F) // Bold red for missed in Screenshot 3
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          subtitleLabel,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
                          ),
                        ),
                        if (item.hasRecording) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.endCallRed.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'REC',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.endCallRed,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Right side: Brand primary date & info button
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.brandPrimary,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _showCallDetailsSheet(item, isDark),
                child: const Icon(
                  CupertinoIcons.info_circle,
                  size: 22,
                  color: AppColors.brandPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
