import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class CertificateDbHelper {
  static final CertificateDbHelper instance = CertificateDbHelper._init();
  static Database? _database;

  CertificateDbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('certificates.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
CREATE TABLE certificates (
  id $idType,
  fileName $textType,
  localPath $textType
  )
''');
  }

  Future<int> insertCertificate(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('certificates', row);
  }

  Future<Map<String, dynamic>?> getCertificateByPath(String localPath) async {
    final db = await instance.database;
    final maps = await db.query(
      'certificates',
      columns: ['id', 'fileName', 'localPath'],
      where: 'localPath = ?',
      whereArgs: [localPath],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  Future<int> deleteCertificate(int id) async {
    final db = await instance.database;
    return await db.delete(
      'certificates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
