import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/receipt.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'receiptly.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Receipts table
    await db.execute('''
      CREATE TABLE receipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        imagePath TEXT NOT NULL,
        merchantName TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        date INTEGER NOT NULL,
        category TEXT NOT NULL,
        notes TEXT,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Receipt items table
    await db.execute('''
      CREATE TABLE receipt_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        receiptId INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        category TEXT,
        FOREIGN KEY (receiptId) REFERENCES receipts (id) ON DELETE CASCADE
      )
    ''');

    // Create index for faster queries
    await db.execute('CREATE INDEX idx_receipts_date ON receipts (date)');
    await db.execute('CREATE INDEX idx_receipts_category ON receipts (category)');
  }

  // Receipt operations
  Future<int> insertReceipt(Receipt receipt) async {
    final db = await database;
    
    // Insert receipt
    final receiptId = await db.insert('receipts', receipt.toMap());
    
    // Insert receipt items
    for (final item in receipt.items) {
      await db.insert('receipt_items', {
        ...item.toMap(),
        'receiptId': receiptId,
      });
    }
    
    return receiptId;
  }

  Future<List<Receipt>> getAllReceipts() async {
    final db = await database;
    final receiptsResult = await db.query(
      'receipts',
      orderBy: 'createdAt DESC',
    );

    final receipts = <Receipt>[];
    for (final receiptMap in receiptsResult) {
      final items = await getReceiptItems(receiptMap['id'] as int);
      final receipt = Receipt.fromMap(receiptMap).copyWith(items: items);
      receipts.add(receipt);
    }

    return receipts;
  }

  Future<List<ReceiptItem>> getReceiptItems(int receiptId) async {
    final db = await database;
    final result = await db.query(
      'receipt_items',
      where: 'receiptId = ?',
      whereArgs: [receiptId],
    );

    return result.map((map) => ReceiptItem.fromMap(map)).toList();
  }

  Future<Receipt?> getReceiptById(int id) async {
    final db = await database;
    final result = await db.query(
      'receipts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    final items = await getReceiptItems(id);
    return Receipt.fromMap(result.first).copyWith(items: items);
  }

  Future<void> updateReceipt(Receipt receipt) async {
    final db = await database;
    
    // Update receipt
    await db.update(
      'receipts',
      receipt.toMap(),
      where: 'id = ?',
      whereArgs: [receipt.id],
    );

    // Delete old items and insert new ones
    await db.delete(
      'receipt_items',
      where: 'receiptId = ?',
      whereArgs: [receipt.id],
    );

    for (final item in receipt.items) {
      await db.insert('receipt_items', {
        ...item.toMap(),
        'receiptId': receipt.id,
      });
    }
  }

  Future<void> deleteReceipt(int id) async {
    final db = await database;
    await db.delete(
      'receipts',
      where: 'id = ?',
      whereArgs: [id],
    );
    // Items will be deleted automatically due to CASCADE
  }

  // Analytics queries
  Future<double> getTotalExpensesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(totalAmount) as total FROM receipts WHERE date BETWEEN ? AND ?',
      [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
    );
    
    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<Map<String, double>> getExpensesByCategory(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT category, SUM(totalAmount) as total FROM receipts WHERE date BETWEEN ? AND ? GROUP BY category',
      [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
    );

    final expenses = <String, double>{};
    for (final row in result) {
      expenses[row['category'] as String] = row['total'] as double;
    }
    
    return expenses;
  }

  Future<List<Map<String, dynamic>>> getDailyExpenses(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        DATE(date / 1000, 'unixepoch') as day,
        SUM(totalAmount) as total
      FROM receipts 
      WHERE date BETWEEN ? AND ? 
      GROUP BY DATE(date / 1000, 'unixepoch')
      ORDER BY day
    ''', [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch]);

    return result;
  }

  Future<List<Map<String, dynamic>>> getMonthlyExpenses(int year) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        strftime('%m', date / 1000, 'unixepoch') as month,
        SUM(totalAmount) as total
      FROM receipts 
      WHERE strftime('%Y', date / 1000, 'unixepoch') = ?
      GROUP BY strftime('%m', date / 1000, 'unixepoch')
      ORDER BY month
    ''', [year.toString()]);

    return result;
  }

  Future<List<Receipt>> getReceiptsByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final receiptsResult = await db.query(
      'receipts',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
      orderBy: 'date DESC',
    );

    final receipts = <Receipt>[];
    for (final receiptMap in receiptsResult) {
      final items = await getReceiptItems(receiptMap['id'] as int);
      final receipt = Receipt.fromMap(receiptMap).copyWith(items: items);
      receipts.add(receipt);
    }

    return receipts;
  }

  Future<Map<String, int>> getReceiptCountByCategory() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT category, COUNT(*) as count FROM receipts GROUP BY category',
    );

    final counts = <String, int>{};
    for (final row in result) {
      counts[row['category'] as String] = row['count'] as int;
    }
    
    return counts;
  }

  // Clean up
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
