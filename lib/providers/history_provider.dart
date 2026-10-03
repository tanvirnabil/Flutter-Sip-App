import 'dart:async';
import 'package:flutter/material.dart';
import '../models/call_log_item.dart';
import '../services/call_history_service.dart';

class HistoryProvider extends ChangeNotifier {
  final CallHistoryService _historyService = CallHistoryService();
  StreamSubscription<CallLogItem>? _logSubscription;

  List<CallLogItem> _logs = [];
  bool _isLoading = false;
  int _selectedFilterIndex = 0;

  List<CallLogItem> get logs {
    if (_selectedFilterIndex == 1) {
      return _logs.where((l) => l.type == CallLogType.missed).toList();
    }
    return _logs;
  }

  bool get isLoading => _isLoading;
  int get selectedFilterIndex => _selectedFilterIndex;

  HistoryProvider() {
    loadLogs();
    _logSubscription = _historyService.onNewLog.listen((newLog) {
      _logs.removeWhere((l) => l.id == newLog.id);
      _logs.insert(0, newLog);
      notifyListeners();
    });
  }

  void setFilter(int index) {
    _selectedFilterIndex = index;
    notifyListeners();
  }

  Future<void> loadLogs({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      _logs = await _historyService.getAllLogs();
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteLog(int id) async {
    await _historyService.deleteLog(id);
    _logs.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _historyService.clearHistory();
    _logs.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    super.dispose();
  }
}
