import 'package:news_app/portfolio_service/add_portfolio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class PortfolioDbHelper {
  // A private constructor to prevent creating multiple instances
  PortfolioDbHelper._privateConstructor();
  // The single, static instance of the PortfolioDbHelper
  static final PortfolioDbHelper instance =
      PortfolioDbHelper._privateConstructor();

  static Database? _database;

  // Getter for the database. If it doesn't exist, it's initialized.
  Future<Database> get database async {
    if (_database == null) {
      _database = await _initDatabase();
    }
    return _database!;
  }

  // Initializes the database: gets the path and opens the database.
  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, portfolioDb);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate, // This runs the first time the database is created
    );
  }

  // Creates the database table.
  Future _onCreate(Database db, int version) async {
    await db.execute(createPortfolioTable);
  }

  // --- CRUD (Create, Read, Update, Delete) Methods ---

  // Adds a new stock holding to the database.
  Future<void> insertStock(StockHolding holding) async {
    final db = await instance.database;
    await db.insert(
      portfolioDb,
      {
        'symbol': holding.symbol,
        'companyName': holding.companyName,
        'shares': holding.shares,
      },
      // If the stock already exists, replace it.
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Updates an existing stock holding's shares.
  Future<void> updateStock(StockHolding holding) async {
    final db = await instance.database;
    await db.update(
      portfolioDb,
      {'shares': holding.shares},
      where: 'symbol = ?',
      whereArgs: [holding.symbol],
    );
  }

  // Retrieves all stock holdings from the database.
  Future<List<StockHolding>> getAllHoldings() async {
    final db = await instance.database;
    final maps = await db.query(portfolioDb);

    // Convert the List<Map<String, dynamic>> into a List<StockHolding>.
    return List.generate(maps.length, (i) {
      return StockHolding(
        symbol: maps[i]['symbol'] as String,
        companyName: maps[i]['companyName'] as String,
        shares: maps[i]['shares'] as int,
      );
    });
  }

  Future<void> deleteStock(String symbol) async {
    final db = await instance.database;
    await db.delete(portfolioDb, where: 'symbol = ?', whereArgs: [symbol]);
  }
}

const createPortfolioTable = '''
      CREATE TABLE holdings (
        symbol TEXT PRIMARY KEY,
        companyName TEXT NOT NULL,
        shares INTEGER NOT NULL
      )
    ''';
const portfolioDb = "holdings";
