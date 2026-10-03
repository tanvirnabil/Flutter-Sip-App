import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/call_log_item.dart';
import 'call_recording_service.dart';

class CallHistoryService {
  static final CallHistoryService _instance = CallHistoryService._internal();
  factory CallHistoryService() => _instance;
  CallHistoryService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'aura_call_history.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE call_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            phoneNumber TEXT NOT NULL,
            displayName TEXT,
            type TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            durationSeconds INTEGER NOT NULL,
            recordingPath TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE call_logs ADD COLUMN recordingPath TEXT');
          } catch (_) {}
        }
      },
    );
  }

  final _logController = StreamController<CallLogItem>.broadcast();
  Stream<CallLogItem> get onNewLog => _logController.stream;

  Future<int> insertCallLog(CallLogItem item) async {
    final db = await database;
    final id = await db.insert('call_logs', item.toMap());
    final saved = item.copyWith(id: id);
    _logController.add(saved);
    return id;
  }

  Future<List<CallLogItem>> getAllLogs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'call_logs',
      orderBy: 'timestamp DESC',
    );
    return maps.map((e) => CallLogItem.fromMap(e)).toList();
  }

  Future<List<CallLogItem>> getMissedLogs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'call_logs',
      where: 'type = ?',
      whereArgs: [CallLogType.missed.name],
      orderBy: 'timestamp DESC',
    );
    return maps.map((e) => CallLogItem.fromMap(e)).toList();
  }

  Future<int> deleteLog(int id) async {
    final db = await database;
    // 1. Fetch item to clean up its recording file
    final List<Map<String, dynamic>> maps = await db.query(
      'call_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      final item = CallLogItem.fromMap(maps.first);
      if (item.hasRecording) {
        await CallRecordingService().deleteRecordingFile(item.recordingPath);
      }
    }
    // 2. Delete database entry
    return await db.delete('call_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearHistory() async {
    final db = await database;
    // Delete all recording audio files
    final all = await getAllLogs();
    for (final item in all) {
      if (item.hasRecording) {
        await CallRecordingService().deleteRecordingFile(item.recordingPath);
      }
    }
    return await db.delete('call_logs');
  }
}
