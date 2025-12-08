import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/call_log.dart';

/// 数据库服务类
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

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'call_logs.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE call_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone_number TEXT NOT NULL,
        call_type TEXT DEFAULT '高清语音',
        location TEXT DEFAULT '福建福州',
        connect_time TEXT NOT NULL,
        call_duration INTEGER DEFAULT 0,
        billing_minutes INTEGER DEFAULT 0,
        call_fee REAL DEFAULT 0.0,
        call_date TEXT NOT NULL,
        call_time TEXT NOT NULL,
        is_hd_voice INTEGER DEFAULT 1,
        is_outgoing INTEGER DEFAULT 1,
        weekday TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE config (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    
    // 插入默认配置
    await db.insert('config', {'key': 'top_phone_number', 'value': '175****8164'});
  }

  /// 获取所有通话记录
  Future<List<CallLog>> getAllLogs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'call_logs',
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) => CallLog.fromMap(maps[i]));
  }

  /// 添加通话记录
  Future<int> addLog(CallLog log) async {
    final db = await database;
    return await db.insert('call_logs', log.toMap());
  }

  /// 更新通话记录
  Future<int> updateLog(CallLog log) async {
    final db = await database;
    return await db.update(
      'call_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  /// 删除通话记录
  Future<int> deleteLog(int id) async {
    final db = await database;
    return await db.delete(
      'call_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 清空所有通话记录
  Future<int> clearAllLogs() async {
    final db = await database;
    return await db.delete('call_logs');
  }

  /// 获取通话费用总计
  Future<double> getTotalFee() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(call_fee) as total FROM call_logs');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// 获取配置项
  Future<String?> getConfig(String key) async {
    final db = await database;
    final result = await db.query(
      'config',
      where: 'key = ?',
      whereArgs: [key],
    );
    return result.isNotEmpty ? result.first['value'] as String : null;
  }

  /// 设置配置项
  Future<int> setConfig(String key, String value) async {
    final db = await database;
    return await db.insert(
      'config',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 初始化示例数据
  Future<void> initSampleData() async {
    final logs = await getAllLogs();
    if (logs.isNotEmpty) return; // 已有数据，不重复初始化

    await addLog(CallLog(
      phoneNumber: '059138167112',
      location: '福建福州',
      connectTime: '16:43',
      callDuration: 5,
      billingMinutes: 1,
      callFee: 0.00,
      callDate: '12.02',
      callTime: '16:43',
      isOutgoing: true,
      weekday: '星期二',
    ));

    await addLog(CallLog(
      phoneNumber: '17673619243',
      location: '湖南长沙',
      connectTime: '14:30',
      callDuration: 125,
      billingMinutes: 3,
      callFee: 0.00,
      callDate: '12.01',
      callTime: '14:30',
      isOutgoing: false,
      weekday: '星期一',
    ));
  }
}


