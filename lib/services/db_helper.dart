import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:vision_medical_system_app/screens/chat_screen.dart';

class ChatDatabaseHelper {
  static final ChatDatabaseHelper instance = ChatDatabaseHelper._init();
  static Database? _database;

  ChatDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chat_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE conversations (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        lastMessage TEXT,
        time TEXT,
        unreadCount INTEGER DEFAULT 0,
        isGroup INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY,
        conversationId INTEGER NOT NULL,
        senderName TEXT NOT NULL,
        isMe INTEGER NOT NULL,
        body TEXT NOT NULL,
        time TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'sent'
      )
    ''');

    await db.execute('''
      CREATE TABLE api_cache (
        key TEXT PRIMARY KEY,
        json_data TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS api_cache (
          key TEXT PRIMARY KEY,
          json_data TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
    }
  }

  // Conversation operations
  Future<void> upsertConversation(ChatConversation conversation) async {
    final db = await instance.database;
    await db.insert(
      'conversations',
      {
        'id': conversation.id,
        'name': conversation.name,
        'lastMessage': conversation.lastMessage,
        'time': conversation.time,
        'unreadCount': conversation.unreadCount,
        'isGroup': conversation.isGroup ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChatConversation>> getConversations() async {
    final db = await instance.database;
    final result = await db.query('conversations');
    
    return result.map((json) => ChatConversation(
      id: json['id'] as int,
      name: json['name'] as String,
      lastMessage: json['lastMessage'] as String? ?? '',
      time: json['time'] as String? ?? '',
      unreadCount: json['unreadCount'] as int? ?? 0,
      isGroup: (json['isGroup'] as int? ?? 0) == 1,
    )).toList();
  }

  // Message operations
  Future<void> upsertMessage(ChatMessage message) async {
    final db = await instance.database;
    await db.insert(
      'messages',
      {
        'id': message.id,
        'conversationId': message.conversationId,
        'senderName': message.senderName,
        'isMe': message.isMe ? 1 : 0,
        'body': message.body,
        'time': message.time,
        'status': message.status,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChatMessage>> getMessages(int conversationId) async {
    final db = await instance.database;
    final result = await db.query(
      'messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'id ASC',
    );

    return result.map((json) => ChatMessage(
      id: json['id'] as int,
      conversationId: json['conversationId'] as int,
      senderName: json['senderName'] as String,
      isMe: (json['isMe'] as int) == 1,
      body: json['body'] as String,
      time: json['time'] as String,
      status: json['status'] as String? ?? 'sent',
    )).toList();
  }

  Future<List<ChatMessage>> getPendingMessages() async {
    final db = await instance.database;
    final result = await db.query(
      'messages',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'id ASC',
    );

    return result.map((json) => ChatMessage(
      id: json['id'] as int,
      conversationId: json['conversationId'] as int,
      senderName: json['senderName'] as String,
      isMe: (json['isMe'] as int) == 1,
      body: json['body'] as String,
      time: json['time'] as String,
      status: json['status'] as String? ?? 'pending',
    )).toList();
  }

  Future<void> updateMessageIdAndStatus(int tempId, int serverId, String newTime, String newStatus) async {
    final db = await instance.database;
    await db.update(
      'messages',
      {
        'id': serverId,
        'status': newStatus,
        'time': newTime,
      },
      where: 'id = ?',
      whereArgs: [tempId],
    );
  }

  Future<void> deleteMessage(int id) async {
    final db = await instance.database;
    await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAll() async {
    final db = await instance.database;
    await db.delete('conversations');
    await db.delete('messages');
  }

  Future<void> saveToCache(String key, String jsonData) async {
    try {
      final db = await instance.database;
      await db.insert(
        'api_cache',
        {
          'key': key,
          'json_data': jsonData,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  Future<String?> getFromCache(String key) async {
    try {
      final db = await instance.database;
      final result = await db.query(
        'api_cache',
        columns: ['json_data'],
        where: 'key = ?',
        whereArgs: [key],
      );
      if (result.isNotEmpty) {
        return result.first['json_data'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<void> deleteFromCache(String key) async {
    try {
      final db = await instance.database;
      await db.delete(
        'api_cache',
        where: 'key = ?',
        whereArgs: [key],
      );
    } catch (_) {}
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
