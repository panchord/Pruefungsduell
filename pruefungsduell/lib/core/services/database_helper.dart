import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _dbName = 'pruefungsduell.db';
  static const _dbVersion = 2;

  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users-Tabelle
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      );
    ''');

    await _createDeckAndCardTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createDeckAndCardTables(db);
    }
  }

  Future<void> _createDeckAndCardTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS decks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deck_id INTEGER NOT NULL,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        FOREIGN KEY (deck_id) REFERENCES decks (id) ON DELETE CASCADE
      );
    ''');
  }

  Future<int> insertDeck(String title) async {
    final db = await database;
    return db.insert('decks', {'title': title});
  }

  Future<List<Map<String, dynamic>>> getDecks() async {
    final db = await database;
    return db.query('decks', orderBy: 'title COLLATE NOCASE');
  }

  Future<int> insertCard({
    required int deckId,
    required String question,
    required String answer,
  }) async {
    final db = await database;
    return db.insert('cards', {
      'deck_id': deckId,
      'question': question,
      'answer': answer,
    });
  }

  Future<List<Map<String, dynamic>>> getCardsForDeck(int deckId) async {
    final db = await database;
    return db.query(
      'cards',
      where: 'deck_id = ?',
      whereArgs: [deckId],
      orderBy: 'id ASC',
    );
  }

  Future<int> deleteDeck(int id) async {
    final db = await database;

    await db.delete('cards', where: 'deck_id = ?', whereArgs: [id]);

    return db.delete('decks', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCard(int id) async {
    final db = await database;
    return db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }
}
