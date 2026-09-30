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

class CallHistoryScreen extends StatelessWidget {
  const CallHistoryScreen({super.key});

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
                          history.deleteLog(item.id!);
                        }
                      },
                      child: ListTile(
                        leading: _buildCallTypeIcon(item.type),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: item.type == CallLogType.missed
                                ? AppColors.endCallRed
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          ),
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
                                CupertinoIcons.info_circle,
                                color: AppColors.accentBlue,
                                size: 22,
                              ),
                              onPressed: () => _callBack(context, item.phoneNumber),
                            ),
                          ],
                        ),
                        onTap: () => _callBack(context, item.phoneNumber),
                      ),
                    );
                  },
                ),
    );
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
        message: const Text('This will delete all recent call logs.'),
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

