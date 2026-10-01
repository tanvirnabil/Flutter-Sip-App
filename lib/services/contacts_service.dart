import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/contact_item.dart';

class ContactsService {
  static final ContactsService _instance = ContactsService._internal();
  factory ContactsService() => _instance;

  Database? _db;

  ContactsService._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'aura_contacts.db');

    final db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE contacts(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            extension TEXT NOT NULL,
            email TEXT,
            isFavorite INTEGER DEFAULT 0,
            avatarUrl TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Clean up legacy seed dummy contacts if upgrading from version 1
        await db.delete(
          'contacts',
          where: "name IN ('Echo Test (Audio Check)', 'Voicemail PBX', 'PBX Operator', 'IT Support Desk')",
        );
      },
    );

    // Also proactively clean any dummy contacts
    try {
      await db.delete(
        'contacts',
        where: "name IN ('Echo Test (Audio Check)', 'Voicemail PBX', 'PBX Operator', 'IT Support Desk')",
      );
    } catch (_) {}

    return db;
  }

  Future<List<ContactItem>> getAllContacts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contacts',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return maps.map((m) => ContactItem.fromMap(m)).toList();
  }

  Future<List<ContactItem>> getFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contacts',
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return maps.map((m) => ContactItem.fromMap(m)).toList();
  }

  Future<void> addContact(ContactItem contact) async {
    final db = await database;
    await db.insert(
      'contacts',
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateContact(ContactItem contact) async {
    final db = await database;
    await db.update(
      'contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<void> toggleFavorite(String id, bool currentStatus) async {
    final db = await database;
    await db.update(
      'contacts',
      {'isFavorite': currentStatus ? 0 : 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteContact(String id) async {
    final db = await database;
    await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
