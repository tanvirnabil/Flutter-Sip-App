import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/chat_message.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  Database? _db;
  final _messageStreamController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get onMessage => _messageStreamController.stream;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'clario_messages.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE chat_messages (
            id TEXT PRIMARY KEY,
            remoteExtension TEXT NOT NULL,
            remoteName TEXT,
            message TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            isOutgoing INTEGER NOT NULL,
            isDelivered INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> saveMessage(ChatMessage message) async {
    final db = await database;
    await db.insert(
      'chat_messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _messageStreamController.add(message);
  }

  Future<List<ChatMessage>> getMessagesForContact(String extension) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'remoteExtension = ?',
      whereArgs: [extension],
      orderBy: 'timestamp ASC',
    );
    return maps.map((m) => ChatMessage.fromMap(m)).toList();
  }

  Future<List<ChatMessage>> getRecentConversations() async {
    final db = await database;
    // Get the latest message for each remoteExtension
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT m.* FROM chat_messages m
      INNER JOIN (
        SELECT remoteExtension, MAX(timestamp) as maxTime
        FROM chat_messages
        GROUP BY remoteExtension
      ) latest ON m.remoteExtension = latest.remoteExtension AND m.timestamp = latest.maxTime
      ORDER BY m.timestamp DESC
    ''');
    return maps.map((m) => ChatMessage.fromMap(m)).toList();
  }

  Future<void> deleteConversation(String extension) async {
    final db = await database;
    await db.delete(
      'chat_messages',
      where: 'remoteExtension = ?',
      whereArgs: [extension],
    );
  }
}
