import 'package:pruefungsduell/core/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class AuthRepository {
  final DatabaseHelper _dbHelper;

  AuthRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> register({
    required String email,
    required String password,
  }) async {
    final db = await _dbHelper.database;

    try {
      await db.insert('users', {
        'email': email,
        'password': password, // Demo: Klartext, später: Hash!
      }, conflictAlgorithm: ConflictAlgorithm.abort);
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw AuthException('Diese E-Mail ist bereits registriert');
      }
      rethrow;
    }
  }

  Future<void> login({required String email, required String password}) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
      limit: 1,
    );

    if (result.isEmpty) {
      throw AuthException('E-Mail oder Passwort ist falsch');
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
