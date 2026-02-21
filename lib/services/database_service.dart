import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/deposito.dart';
import '../utils/logger.dart';
import '../config/app_config.dart';

class DatabaseService {
  static Database? _database;
  static WebDatabaseImpl? _webDb;
  static const String _dbName = AppConfig.dbName;
  static const int _dbVersion = AppConfig.dbVersion;

  // Tablas
  static const String depositosTable = 'depositos';
  static const String configTable = 'config';

  // Singleton
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  Future<dynamic> get database async {
    if (kIsWeb) {
      if (_webDb == null) {
        _webDb = WebDatabaseImpl();
        await _webDb!.init();
      }
      return _webDb!;
    }
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String dbPath;

    if (!kIsWeb && io.Platform.isWindows) {
      final appDir = await getApplicationDocumentsDirectory();
      dbPath = p.join(appDir.path, _dbName);
    } else {
      dbPath = p.join(await getDatabasesPath(), _dbName);
    }

    return await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Crear tabla de depósitos
    await db.execute('''
      CREATE TABLE $depositosTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        ui_amount REAL NOT NULL,
        deposit_date TEXT NOT NULL,
        ui_value REAL NOT NULL,
        registration_date TEXT NOT NULL
      )
    ''');

    // Crear tabla de configuración
    await db.execute('''
      CREATE TABLE $configTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Insertar configuración por defecto
    await _insertDefaultConfig(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Para futuras actualizaciones
  }

  Future<void> _insertDefaultConfig(dynamic db) async {
    final defaultConfig = {
      'current_ui_value': AppConfig.defaultUiValue.toString(),
      'ui_source': 'Manual',
      'ui_last_update': DateTime.now().toIso8601String(),
      'formato_fecha': 'dd-MM-yyyy',
      'simbolo_moneda': '\$',
      'separador_miles': '.',
      'separador_decimal': ',',
      'decimales_ui': '4',
      'decimales_moneda': '2',
    };

    for (String key in defaultConfig.keys) {
      await db.insert(configTable, {'key': key, 'value': defaultConfig[key]!});
    }
  }

  // ===== OPERACIONES DE DEPÓSITOS =====

  Future<int> insertDeposito(Deposito deposito) async {
    final db = await database;
    if (kIsWeb) {
      return await (db as WebDatabaseImpl)
          .insert(depositosTable, deposito.toMap());
    }
    return await (db as Database).transaction((txn) async {
      return await txn.insert(depositosTable, deposito.toMap());
    });
  }

  Future<List<Deposito>> getAllDepositos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      depositosTable,
      orderBy: 'deposit_date DESC',
    );

    return List.generate(maps.length, (i) {
      return Deposito.fromMap(maps[i]);
    });
  }

  Future<Deposito?> getDepositoById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      depositosTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Deposito.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateDeposito(Deposito deposito) async {
    final db = await database;
    if (kIsWeb) {
      return await (db as WebDatabaseImpl).update(
        depositosTable,
        deposito.toMap(),
        where: 'id = ?',
        whereArgs: [deposito.id],
      );
    }
    return await (db as Database).transaction((txn) async {
      return await txn.update(
        depositosTable,
        deposito.toMap(),
        where: 'id = ?',
        whereArgs: [deposito.id],
      );
    });
  }

  Future<int> deleteDeposito(int id) async {
    final db = await database;
    if (kIsWeb) {
      return await (db as WebDatabaseImpl)
          .delete(depositosTable, where: 'id = ?', whereArgs: [id]);
    }
    return await (db as Database).transaction((txn) async {
      return await txn.delete(depositosTable, where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<int> getDepositosCount() async {
    final db = await database;
    if (kIsWeb) {
      return (db as WebDatabaseImpl).query(depositosTable).length;
    }
    final result =
        await (db as Database).rawQuery('SELECT COUNT(*) FROM $depositosTable');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ===== OPERACIONES DE CONFIGURACIÓN =====

  Future<String?> getConfig(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      configTable,
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }

  Future<void> setConfig(String key, String value) async {
    final db = await database;
    if (kIsWeb) {
      await (db as WebDatabaseImpl).insert(
        configTable,
        {'key': key, 'value': value},
      );
    } else {
      await (db as Database).transaction((txn) async {
        await txn.insert(
            configTable,
            {
              'key': key,
              'value': value,
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
      });
    }
  }

  Future<Map<String, String>> getAllConfig() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(configTable);

    Map<String, String> config = {};
    for (var map in maps) {
      config[map['key'] as String] = map['value'] as String;
    }
    return config;
  }

  // ===== MÉTODOS DE UTILIDAD =====

  Future<double> getTotalAmount() async {
    final db = await database;
    if (kIsWeb) {
      final rows = (db as WebDatabaseImpl).query(depositosTable);
      double total = 0;
      for (var row in rows) {
        total += (row['amount'] as num).toDouble();
      }
      return total;
    }
    final result = await (db as Database)
        .rawQuery('SELECT SUM(amount) FROM $depositosTable');
    return (result.first.values.first as double?) ?? 0.0;
  }

  Future<double> getTotalUiAmount() async {
    final db = await database;
    if (kIsWeb) {
      final rows = (db as WebDatabaseImpl).query(depositosTable);
      double total = 0;
      for (var row in rows) {
        total += (row['ui_amount'] as num).toDouble();
      }
      return total;
    }
    final result = await (db as Database).rawQuery(
      'SELECT SUM(ui_amount) FROM $depositosTable',
    );
    return (result.first.values.first as double?) ?? 0.0;
  }

  Future<double> getTotalCurrentValue(double currentUiValue) async {
    final depositos = await getAllDepositos();

    double total = 0.0;
    for (final deposito in depositos) {
      total += deposito.uiAmount * currentUiValue;
    }
    return total;
  }

  Future<double> getProfit(double currentUiValue) async {
    final totalAmount = await getTotalAmount();
    final totalCurrentValue = await getTotalCurrentValue(currentUiValue);
    return totalCurrentValue - totalAmount;
  }

  // ===== IMPORTACIÓN JSON =====

  Future<bool> importFromJson() async {
    try {
      AppLogger.i('Iniciando importFromJson con file_selector...');

      const typeGroup = XTypeGroup(
        label: 'JSON files',
        extensions: ['json'],
      );

      final file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file == null) {
        AppLogger.w('file_selector cancelado');
        return false;
      }

      AppLogger.i('Archivo seleccionado: ${file.name}');

      if (kIsWeb) {
        final content = await file.readAsString();
        return await importFromJsonString(content);
      }

      final path = file.path;
      if (path == null || path.isEmpty) {
        AppLogger.w('file_selector path es null o vacío');
        return false;
      }

      final jsonFile = io.File(path);
      if (!await jsonFile.exists()) {
        AppLogger.e('El archivo no existe: $path');
        return false;
      }

      AppLogger.i('Archivo existe, iniciando importación...');
      return await _importFromFile(jsonFile);
    } catch (e, stackTrace) {
      AppLogger.e('Error importando JSON: $e', e, stackTrace);
      return false;
    }
  }

  // Método para importación desde Android Download folder
  Future<bool> importFromJsonFixedPath() async {
    if (kIsWeb) return false;
    try {
      io.Directory? downloadsDir;
      if (!kIsWeb && io.Platform.isAndroid) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          downloadsDir = io.Directory(
              '${externalDir.parent.parent.parent.parent.path}/Download');
        }
      }

      if (downloadsDir == null) {
        throw Exception('No se pudo acceder al directorio de Downloads');
      }

      AppLogger.i('Buscando archivo en: ${downloadsDir.path}');
      final file = io.File('${downloadsDir.path}/bhu_datos.json');

      if (!await file.exists()) {
        throw Exception('Archivo JSON no encontrado en: ${file.path}');
      }

      return await _importFromFile(file);
    } catch (e) {
      AppLogger.e('Error importando JSON desde ruta fija', e);
      return false;
    }
  }

  // Importar desde string JSON (pegar directamente)
  Future<bool> importFromJsonString(String jsonString) async {
    try {
      AppLogger.i('Importando desde string JSON...');
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final db = await database;

      if (kIsWeb) {
        await (db as WebDatabaseImpl).importData(data);
        return true;
      }

      await (db as Database).transaction((txn) async {
        await txn.delete(depositosTable);
        await _importUiConfig(txn, data);
        await _importDepositosBatch(txn, data);
      });

      AppLogger.i('Importación exitosa desde string JSON');
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('Error importando desde string JSON: $e', e, stackTrace);
      return false;
    }
  }

  // Método privado auxiliar para importar desde un archivo específico (refactorizado)
  Future<bool> _importFromFile(io.File file) async {
    Database? db;
    try {
      AppLogger.i('Leyendo archivo JSON: ${file.path}');
      final content = await file.readAsString();
      final data = json.decode(content) as Map<String, dynamic>;
      db = await database as Database;

      await db.transaction((txn) async {
        await txn.delete(depositosTable);
        await _importUiConfig(txn, data);
        await _importDepositosBatch(txn, data);
      }).timeout(AppConfig.dbTimeout);

      AppLogger.i('Importación exitosa desde: ${file.path}');
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('Error importando desde archivo: $e', e, stackTrace);
      return false;
    } finally {
      if (db != null) {
        await db.close();
        _database = null;
      }
    }
  }

  // Método privado para importar configuración UI
  Future<void> _importUiConfig(
    dynamic txn,
    Map<String, dynamic> data,
  ) async {
    if (data['ui_actual'] != null) {
      await txn.insert(
          configTable,
          {
            'key': 'current_ui_value',
            'value': data['ui_actual'].toString(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    if (data['ui_fuente'] != null) {
      String source = data['ui_fuente'].toString();
      if (source.contains('-') && source.contains('T')) {
        await txn.insert(
            configTable,
            {
              'key': 'ui_source',
              'value': 'DolarApi.com',
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
        await txn.insert(
            configTable,
            {
              'key': 'ui_last_update',
              'value': source,
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
        await txn.insert(
            configTable,
            {
              'key': 'ui_source',
              'value': source,
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    if (data['ui_ultima_actualizacion'] != null) {
      await txn.insert(
          configTable,
          {
            'key': 'ui_last_update',
            'value': data['ui_ultima_actualizacion'].toString(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // Método privado para importar depósitos en batch
  Future<void> _importDepositosBatch(
    dynamic txn,
    Map<String, dynamic> data,
  ) async {
    if (data['depositos'] != null) {
      final depositosList = data['depositos'] as List;
      final batch = txn.batch();

      for (final depositoJson in depositosList) {
        batch.insert(depositosTable, {
          'amount': depositoJson['amount'],
          'ui_amount': depositoJson['ui_amount'],
          'deposit_date': depositoJson['deposit_date'],
          'ui_value': depositoJson['ui_value'],
          'registration_date': depositoJson['registration_date'],
        });
      }

      await batch.commit(noResult: true);
    }
  }

  // ===== RECUPERACIÓN DE BLOQUEOS =====

  Future<void> resetConnection() async {
    try {
      if (!kIsWeb && _database != null && _database!.isOpen) {
        await _database!.close();
      }
      _database = null;
    } catch (e) {
      AppLogger.e('Error reseteando conexión', e);
      _database = null;
    }
  }

  Future<bool> isLocked() async {
    if (kIsWeb) return false;
    try {
      final db = await database as Database;
      await db.rawQuery('SELECT 1');
      return false;
    } catch (e) {
      if (e.toString().contains('locked')) {
        return true;
      }
      return false;
    }
  }

  Future<void> waitForUnlock({
    Duration timeout = AppConfig.dbTimeout,
  }) async {
    if (kIsWeb) return;
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      if (!await isLocked()) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    throw TimeoutException(
      'Base de datos bloqueada por más de ${timeout.inSeconds} segundos',
      timeout,
    );
  }

  // ===== LIMPIEZA =====

  Future<void> closeDatabase() async {
    try {
      if (!kIsWeb && _database != null && _database!.isOpen) {
        await _database!.close();
      }
      _database = null;
    } catch (e) {
      AppLogger.e('Error cerrando base de datos', e);
      _database = null;
    }
  }

  Future<void> deleteDatabase() async {
    try {
      await closeDatabase();
      if (kIsWeb) {
        await (_webDb ?? WebDatabaseImpl()).clear();
        return;
      }
      String dbPath;
      if (!kIsWeb && io.Platform.isWindows) {
        final appDir = await getApplicationDocumentsDirectory();
        dbPath = p.join(appDir.path, _dbName);
      } else {
        dbPath = p.join(await getDatabasesPath(), _dbName);
      }
      await databaseFactory.deleteDatabase(dbPath);
    } catch (e) {
      AppLogger.e('Error eliminando base de datos', e);
      rethrow;
    }
  }

  // ===== EXPORTAR A CSV =====

  Future<io.File> exportToCsv(double currentUiValue) async {
    if (kIsWeb)
      throw UnsupportedError(
          'Exportación a CSV no soportada en web mediante File');
    try {
      final depositos = await getAllDepositos();

      final buffer = StringBuffer();
      buffer.writeln('ID,Fecha,Monto (\$),UI,Valor UI,Valor Actual (\$)');

      for (final deposito in depositos) {
        final currentValue = deposito.uiAmount * currentUiValue;
        buffer.writeln(
          '${deposito.id},'
          '${deposito.depositDate},'
          '${deposito.amount.toStringAsFixed(2)},'
          '${deposito.uiAmount.toStringAsFixed(4)},'
          '${deposito.uiValue.toStringAsFixed(4)},'
          '${currentValue.toStringAsFixed(2)}',
        );
      }

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      final file = io.File('${directory.path}/bhu_depositos_$timestamp.csv');
      await file.writeAsString(buffer.toString());

      AppLogger.i('CSV exportado: ${file.path}');
      return file;
    } catch (e) {
      AppLogger.e('Error exportando CSV', e);
      rethrow;
    }
  }

  // ===== CREAR BACKUP =====

  Future<io.File> createBackup() async {
    if (kIsWeb)
      throw UnsupportedError(
          'Creación de backup no soportada en web mediante File');
    try {
      final depositos = await getAllDepositos();
      final config = await getAllConfig();

      final backupData = {
        'ui_actual': double.tryParse(
            config['current_ui_value'] ?? AppConfig.defaultUiValue.toString()),
        'ui_fuente': config['ui_source'],
        'ui_ultima_actualizacion': config['ui_last_update'],
        'depositos': depositos.map((d) => d.toMap()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      final file = io.File('${directory.path}/bhu_backup_$timestamp.json');
      await file.writeAsString(jsonString);

      AppLogger.i('Backup creado: ${file.path}');
      return file;
    } catch (e) {
      AppLogger.e('Error creando backup', e);
      rethrow;
    }
  }

  // ===== CREAR BACKUP WEB (GitHub Pages) =====

  Future<String> createBackupWeb() async {
    try {
      final depositos = await getAllDepositos();
      final config = await getAllConfig();

      final backupData = {
        'ui_actual': double.tryParse(
            config['current_ui_value'] ?? AppConfig.defaultUiValue.toString()),
        'ui_fuente': config['ui_source'],
        'ui_ultima_actualizacion': config['ui_last_update'],
        'depositos': depositos.map((d) => d.toMap()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      AppLogger.i('Backup web generado');
      return jsonString;
    } catch (e) {
      AppLogger.e('Error creando backup web', e);
      rethrow;
    }
  }
}

class WebDatabaseImpl {
  bool _initialized = false;
  final Map<String, List<Map<String, dynamic>>> _tables = {};
  int _nextIdDeposito = 1;
  static const String _storageKey = 'bhucontrol_db';
  SharedPreferences? _prefs;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _tables['depositos'] = [];
    _tables['config'] = [];

    _prefs = await SharedPreferences.getInstance();
    await _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final data = _prefs?.getString(_storageKey);
      if (data != null && data.isNotEmpty) {
        final Map<String, dynamic> parsed = jsonDecode(data);
        _tables['depositos'] =
            List<Map<String, dynamic>>.from(parsed['depositos'] ?? []);
        _tables['config'] =
            List<Map<String, dynamic>>.from(parsed['config'] ?? []);

        if (_tables['depositos']!.isNotEmpty) {
          _nextIdDeposito = _tables['depositos']!
                  .map((e) => e['id'] as int)
                  .reduce((a, b) => a > b ? a : b) +
              1;
        }
      }
    } catch (e) {
      AppLogger.e('Error loading from storage', e);
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final data = jsonEncode({
        'depositos': _tables['depositos'],
        'config': _tables['config'],
      });
      await _prefs?.setString(_storageKey, data);
    } catch (e) {
      AppLogger.e('Save storage error', e);
    }
  }

  List<Map<String, dynamic>> query(String table,
      {String? where, List<dynamic>? whereArgs, String? orderBy}) {
    var results = List<Map<String, dynamic>>.from(_tables[table] ?? []);

    if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
      final column = where.split('=')[0].trim().toLowerCase();
      final value = whereArgs[0];
      results = results.where((row) => row[column] == value).toList();
    }

    if (orderBy != null) {
      final column = orderBy.split(' ')[0].toLowerCase();
      final descending = orderBy.toLowerCase().contains('desc');
      results.sort((a, b) {
        final aVal = a[column];
        final bVal = b[column];
        if (aVal is Comparable && bVal is Comparable) {
          return descending ? bVal.compareTo(aVal) : aVal.compareTo(bVal);
        }
        return 0;
      });
    }
    return results;
  }

  Future<int> insert(String table, Map<String, dynamic> values,
      {ConflictAlgorithm? conflictAlgorithm}) async {
    final normalized = <String, dynamic>{};
    values.forEach((key, value) => normalized[key.toLowerCase()] = value);

    if (table == 'config') {
      final key = normalized['key'];
      _tables['config']?.removeWhere((row) => row['key'] == key);
      _tables['config']?.add(normalized);
    } else {
      if (normalized['id'] == null) {
        normalized['id'] = _nextIdDeposito++;
      }
      _tables[table]?.add(normalized);
    }
    await _saveToStorage();
    return normalized['id'] ?? 1;
  }

  Future<int> update(String table, Map<String, dynamic> values,
      {String? where, List<dynamic>? whereArgs}) async {
    final column = where?.split('=')[0].trim().toLowerCase();
    final value = whereArgs?[0];
    int count = 0;

    for (int i = 0; i < (_tables[table]?.length ?? 0); i++) {
      if (_tables[table]![i][column] == value) {
        values.forEach((k, v) => _tables[table]![i][k.toLowerCase()] = v);
        count++;
      }
    }
    if (count > 0) await _saveToStorage();
    return count;
  }

  Future<int> delete(String table,
      {String? where, List<dynamic>? whereArgs}) async {
    final column = where?.split('=')[0].trim().toLowerCase();
    final value = whereArgs?[0];
    final originalLength = _tables[table]?.length ?? 0;
    _tables[table]?.removeWhere((row) => row[column] == value);
    final deleted = originalLength - (_tables[table]?.length ?? 0);
    if (deleted > 0) await _saveToStorage();
    return deleted;
  }

  WebBatch batch() => WebBatch(this);

  Future<void> importData(Map<String, dynamic> data) async {
    _tables['config'] = [
      if (data['ui_actual'] != null)
        {'key': 'current_ui_value', 'value': data['ui_actual'].toString()},
      if (data['ui_fuente'] != null)
        {'key': 'ui_source', 'value': data['ui_fuente'].toString()},
      if (data['ui_ultima_actualizacion'] != null)
        {
          'key': 'ui_last_update',
          'value': data['ui_ultima_actualizacion'].toString()
        },
    ];

    if (data['depositos'] != null) {
      _tables['depositos'] = List<Map<String, dynamic>>.from(data['depositos']);
      if (_tables['depositos']!.isNotEmpty) {
        _nextIdDeposito = _tables['depositos']!
                .map((e) => e['id'] as int)
                .reduce((a, b) => a > b ? a : b) +
            1;
      }
    }
    await _saveToStorage();
  }

  Future<void> clear() async {
    _tables['depositos'] = [];
    _tables['config'] = [];
    _nextIdDeposito = 1;
    await _saveToStorage();
  }
}

class WebBatch {
  final WebDatabaseImpl _db;
  final List<Future Function()> _ops = [];

  WebBatch(this._db);

  void insert(String table, Map<String, dynamic> values) {
    _ops.add(() => _db.insert(table, values));
  }

  Future<void> commit({bool? noResult}) async {
    for (var op in _ops) {
      await op();
    }
  }
}
