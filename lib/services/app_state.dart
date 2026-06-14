import 'package:flutter/foundation.dart';
import '../models/creator.dart';
import '../models/post.dart';
import '../models/view_style.dart';
import 'database.dart';
import 'sync_service.dart';

/// 全局应用状态
class AppState extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final SyncService _sync = SyncService();

  List<Creator> _creators = [];
  List<Post> _feedPosts = [];
  bool _isLoading = false;
  String? _statusMessage;

  // 当前在看的博主详情
  List<Post> _creatorPosts = [];
  Creator? _currentCreator;

  // 视图风格
  ViewStyle _viewStyle = ViewStyle.news;

  List<Creator> get creators => _creators;
  List<Post> get feedPosts => _feedPosts;
  bool get isLoading => _isLoading;
  String? get statusMessage => _statusMessage;
  List<Post> get creatorPosts => _creatorPosts;
  Creator? get currentCreator => _currentCreator;
  bool get isSyncing => _sync.isSyncing;
  ViewStyle get viewStyle => _viewStyle;

  void setViewStyle(ViewStyle style) {
    _viewStyle = style;
    notifyListeners();
  }

  // ==================== 初始化 ====================

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _creators = await _db.getAllCreators();
      _feedPosts = await _db.getAllPosts();
    } catch (e) {
      _statusMessage = '加载数据失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ==================== 同步 ====================

  Future<SyncResult> syncAll() async {
    _isLoading = true;
    _statusMessage = '正在同步...';
    notifyListeners();

    final result = await _sync.syncAll();

    _creators = await _db.getAllCreators();
    _feedPosts = await _db.getAllPosts();

    _isLoading = false;
    _statusMessage = result.hasError
        ? '同步完成，${result.summary}'
        : result.summary;

    notifyListeners();
    return result;
  }

  // ==================== 博主管理 ====================

  Future<Creator> addCreator(String input) async {
    final creator = await _sync.addCreator(input);
    _creators = await _db.getAllCreators();
    notifyListeners();
    return creator;
  }

  Future<void> removeCreator(Creator creator) async {
    if (creator.id == null) return;
    await _db.deleteCreator(creator.id!);
    _creators = await _db.getAllCreators();
    _feedPosts = await _db.getAllPosts();
    notifyListeners();
  }

  // ==================== 博主详情 ====================

  Future<void> loadCreatorPosts(Creator creator) async {
    _currentCreator = creator;
    _creatorPosts = [];
    _isLoading = true;
    notifyListeners();

    _creatorPosts = await _db.getPostsByCreator(creator.id!);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshCreatorPosts() async {
    if (_currentCreator == null) return;
    final creator = _currentCreator!;

    try {
      await syncAll();
    } catch (_) {}

    _creatorPosts = await _db.getPostsByCreator(creator.id!);
    notifyListeners();
  }

  // ==================== 清除状态消息 ====================

  void clearStatus() {
    _statusMessage = null;
    notifyListeners();
  }
}
