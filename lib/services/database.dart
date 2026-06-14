import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/creator.dart';
import '../models/post.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'douyin_collector.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE creators (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        secUid TEXT UNIQUE NOT NULL,
        uniqueId TEXT,
        nickname TEXT NOT NULL,
        avatarUrl TEXT,
        signature TEXT,
        followerCount INTEGER DEFAULT 0,
        followingCount INTEGER DEFAULT 0,
        totalFavorited INTEGER DEFAULT 0,
        addedAt TEXT NOT NULL,
        lastFetchedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        awemeId TEXT UNIQUE NOT NULL,
        creatorId INTEGER NOT NULL,
        creatorSecUid TEXT,
        description TEXT,
        videoCoverUrl TEXT,
        videoUrl TEXT,
        imageUrls TEXT,
        publishTime INTEGER NOT NULL,
        fetchedAt TEXT NOT NULL,
        isImagePost INTEGER DEFAULT 0,
        viewCount INTEGER DEFAULT 0,
        likeCount INTEGER DEFAULT 0,
        commentCount INTEGER DEFAULT 0,
        shareCount INTEGER DEFAULT 0,
        shareUrl TEXT,
        FOREIGN KEY (creatorId) REFERENCES creators(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_posts_creatorId ON posts(creatorId)
    ''');

    await db.execute('''
      CREATE INDEX idx_posts_publishTime ON posts(publishTime)
    ''');

    await db.execute('''
      CREATE INDEX idx_posts_awemeId ON posts(awemeId)
    ''');
  }

  // ==================== 博主 CRUD ====================

  Future<int> insertCreator(Creator creator) async {
    final db = await database;
    return await db.insert('creators', creator.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateCreator(Creator creator) async {
    final db = await database;
    return await db.update(
      'creators',
      creator.toMap(),
      where: 'id = ?',
      whereArgs: [creator.id],
    );
  }

  Future<int> updateCreatorFetchedAt(int creatorId) async {
    final db = await database;
    return await db.update(
      'creators',
      {'lastFetchedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [creatorId],
    );
  }

  Future<int> deleteCreator(int id) async {
    final db = await database;
    // 级联删除该博主的所有作品
    await db.delete('posts', where: 'creatorId = ?', whereArgs: [id]);
    return await db.delete('creators', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Creator>> getAllCreators() async {
    final db = await database;
    final maps = await db.query('creators', orderBy: 'addedAt DESC');
    return maps.map((m) => Creator.fromMap(m)).toList();
  }

  Future<Creator?> getCreatorById(int id) async {
    final db = await database;
    final maps = await db.query('creators', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Creator.fromMap(maps.first);
  }

  Future<Creator?> getCreatorBySecUid(String secUid) async {
    final db = await database;
    final maps =
        await db.query('creators', where: 'secUid = ?', whereArgs: [secUid]);
    if (maps.isEmpty) return null;
    return Creator.fromMap(maps.first);
  }

  /// 获取某个博主的总作品数（本地已存）
  Future<int> getCreatorPostCount(int creatorId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM posts WHERE creatorId = ?',
      [creatorId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  // ==================== 作品 CRUD ====================

  Future<int> insertPost(Post post) async {
    final db = await database;
    return await db.insert('posts', post.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<int> insertPostsBatch(List<Post> posts) async {
    if (posts.isEmpty) return 0;
    final db = await database;
    int count = 0;
    final batch = db.batch();
    for (final post in posts) {
      batch.insert('posts', post.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    final results = await batch.commit(noResult: false);
    return results.where((r) => r is int && r > 0).length;
  }

  Future<int> deletePost(int id) async {
    final db = await database;
    return await db.delete('posts', where: 'id = ?', whereArgs: [id]);
  }

  /// 获取所有作品（信息流用），按发布时间倒序
  Future<List<Post>> getAllPosts({int limit = 50, int offset = 0}) async {
    final db = await database;
    final maps = await db.query(
      'posts',
      orderBy: 'publishTime DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => Post.fromMap(m)).toList();
  }

  /// 获取某个博主的所有作品
  Future<List<Post>> getPostsByCreator(int creatorId,
      {int limit = 50, int offset = 0}) async {
    final db = await database;
    final maps = await db.query(
      'posts',
      where: 'creatorId = ?',
      whereArgs: [creatorId],
      orderBy: 'publishTime DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => Post.fromMap(m)).toList();
  }

  /// 检查某个作品是否已存在
  Future<bool> postExists(String awemeId) async {
    final db = await database;
    final result = await db.query('posts',
        where: 'awemeId = ?', whereArgs: [awemeId], limit: 1);
    return result.isNotEmpty;
  }

  /// 获取作品总数
  Future<int> getPostsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM posts');
    return (result.first['count'] as int?) ?? 0;
  }

  /// 获取最后抓取的作品发布时间（用于增量更新）
  Future<int?> getLatestPublishTime(int creatorId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MAX(publishTime) as maxTime FROM posts WHERE creatorId = ?',
      [creatorId],
    );
    return result.first['maxTime'] as int?;
  }
}
