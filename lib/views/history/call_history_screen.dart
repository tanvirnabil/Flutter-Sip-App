import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
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

  @override
  void initState() {
    super.initState();
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
      _playingLogId = item.id;
      _isPlaying = true;
      _position = Duration.zero;
      setState(() {});
      await _audioPlayer.play(DeviceFileSource(item.recordingPath!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final history = context.watch<HistoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recents'),
        actions: [
          if (history.logs.isNotEmpty)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: () => _confirmClearHistory(context, history),
              child: const Text('Clear', style: TextStyle(color: AppColors.endCallRed, fontSize: 16)),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: history.selectedFilterIndex,
                children: const {
                  0: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('All')),
                  1: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Missed')),
                },
                onValueChanged: (val) {
                  if (val != null) {
                    Haptics.selection();
                    history.setFilter(val);
                  }
                },
              ),
            ),
          ),
        ),
      ),
      body: history.isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : history.logs.isEmpty
              ? _buildEmptyState(isDark)
              : ListView.separated(
                  itemCount: history.logs.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 0.5,
                    indent: 68,
                    color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  ),
                  itemBuilder: (context, index) {
                    final item = history.logs[index];
                    final isCurrentPlaying = _playingLogId == item.id;

                    return Dismissible(
                      key: Key('call_log_${item.id ?? index}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: AppColors.endCallRed,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(CupertinoIcons.trash, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        if (item.id != null) {
                          if (_playingLogId == item.id) {
                            _audioPlayer.stop();
                          }
                          history.deleteLog(item.id!);
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: _buildCallTypeIcon(item.type),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      color: item.type == CallLogType.missed
                                          ? AppColors.endCallRed
                                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                    ),
                                  ),
                                ),
                                if (item.hasRecording)
                                  GestureDetector(
                                    onTap: () => _togglePlayback(item),
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isCurrentPlaying && _isPlaying
                                            ? AppColors.callGreen.withValues(alpha: 0.2)
                                            : AppColors.accentBlue.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isCurrentPlaying && _isPlaying
                                                ? CupertinoIcons.pause_fill
                                                : CupertinoIcons.play_arrow_solid,
                                            size: 12,
                                            color: isCurrentPlaying && _isPlaying
                                                ? AppColors.callGreen
                                                : AppColors.accentBlue,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'REC',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isCurrentPlaying && _isPlaying
                                                  ? AppColors.callGreen
                                                  : AppColors.accentBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              '${item.type.name.toUpperCase()} • ${item.formattedDuration}',
                              style: const TextStyle(fontSize: 13, color: AppColors.lightTextSecondary),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.formattedDate,
                                  style: const TextStyle(fontSize: 13, color: AppColors.lightTextSecondary),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    CupertinoIcons.phone_fill,
                                    color: AppColors.callGreen,
                                    size: 20,
                                  ),
                                  onPressed: () => _callBack(context, item.phoneNumber),
                                ),
                              ],
                            ),
                            onTap: item.hasRecording ? () => _togglePlayback(item) : () => _callBack(context, item.phoneNumber),
                          ),

                          // Inline Audio Scrubber Player when recording is active
                          if (item.hasRecording && isCurrentPlaying)
                            Container(
                              margin: const EdgeInsets.fromLTRB(68, 0, 16, 10),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      _isPlaying ? CupertinoIcons.pause_circle_fill : CupertinoIcons.play_circle_fill,
                                      color: AppColors.accentBlue,
                                      size: 30,
                                    ),
                                    onPressed: () => _togglePlayback(item),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                        trackHeight: 3,
                                      ),
                                      child: Slider(
                                        value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0),
                                        max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
                                        onChanged: (val) {
                                          _audioPlayer.seek(Duration(seconds: val.toInt()));
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.phone_badge_plus,
            size: 64,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Recent Calls',
            style: AppTypography.headline.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Placed and received calls will appear here',
            style: TextStyle(fontSize: 14, color: AppColors.lightTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCallTypeIcon(CallLogType type) {
    switch (type) {
      case CallLogType.incoming:
        return const CircleAvatar(
          backgroundColor: Color(0x2234C759),
          child: Icon(CupertinoIcons.phone_arrow_down_left, color: AppColors.callGreen, size: 20),
        );
      case CallLogType.outgoing:
        return const CircleAvatar(
          backgroundColor: Color(0x22007AFF),
          child: Icon(CupertinoIcons.phone_arrow_up_right, color: AppColors.accentBlue, size: 20),
        );
      case CallLogType.missed:
        return const CircleAvatar(
          backgroundColor: Color(0x22FF3B30),
          child: Icon(CupertinoIcons.phone_badge_plus, color: AppColors.endCallRed, size: 20),
        );
    }
  }

  void _callBack(BuildContext context, String phoneNumber) async {
    Haptics.medium();
    final sip = context.read<SipProvider>();
    final ok = await sip.makeCall(phoneNumber);
    if (context.mounted && ok) {
      Navigator.push(
        context,
        CupertinoPageRoute(builder: (_) => const ActiveCallScreen()),
      );
    }
  }

  void _confirmClearHistory(BuildContext context, HistoryProvider history) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Clear Call History?'),
        message: const Text('This will delete all recent call logs and their call recordings.'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              history.clearHistory();
            },
            child: const Text('Clear All Recents'),
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
