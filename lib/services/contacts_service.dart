import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
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

    return await openDatabase(
      path,
      version: 1,
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

        // Seed default corporate PBX directory contacts
        final seedContacts = [
          ContactItem(
            id: const Uuid().v4(),
            name: 'Echo Test (Audio Check)',
            extension: '*43',
            isFavorite: true,
          ),
          ContactItem(
            id: const Uuid().v4(),
            name: 'Voicemail PBX',
            extension: '*97',
            isFavorite: true,
          ),
          ContactItem(
            id: const Uuid().v4(),
            name: 'PBX Operator',
            extension: '0',
            isFavorite: false,
          ),
          ContactItem(
            id: const Uuid().v4(),
            name: 'IT Support Desk',
            extension: '100',
            isFavorite: false,
          ),
        ];

        for (final c in seedContacts) {
          await db.insert('contacts', c.toMap());
        }
      },
    );
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
