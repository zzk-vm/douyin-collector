import '../models/creator.dart';
import '../models/post.dart';
import 'database.dart';
import 'douyin_api.dart';

/// 同步结果
class SyncResult {
  final int totalCreators;
  final int successCreators;
  final int newPosts;
  final List<String> errors;

  SyncResult({
    required this.totalCreators,
    required this.successCreators,
    required this.newPosts,
    this.errors = const [],
  });

  bool get hasError => errors.isNotEmpty;
  String get summary {
    final parts = <String>[
      '检查了 $totalCreators 位博主',
      '成功获取 $successCreators 位',
    ];
    if (newPosts > 0) {
      parts.add('新增 $newPosts 篇作品');
    } else {
      parts.add('暂无新内容');
    }
    if (errors.isNotEmpty) {
      parts.add('${errors.length} 个错误');
    }
    return parts.join('，');
  }
}

/// 同步服务
///
/// 负责自动抓取所有博主的最新作品。
class SyncService {
  final DatabaseHelper _db = DatabaseHelper();
  final DouyinApiService _api = DouyinApiService();

  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  /// 执行一次完整同步
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      return SyncResult(
        totalCreators: 0,
        successCreators: 0,
        newPosts: 0,
        errors: ['正在同步中，请稍后再试'],
      );
    }

    _isSyncing = true;
    final errors = <String>[];
    int newPosts = 0;
    int successCreators = 0;

    try {
      // 1. 初始化 API（获取session）
      try {
        await _api.initialize();
      } catch (e) {
        _isSyncing = false;
        return SyncResult(
          totalCreators: 0,
          successCreators: 0,
          newPosts: 0,
          errors: ['连接抖音失败: $e'],
        );
      }

      // 2. 获取所有博主
      final creators = await _db.getAllCreators();
      if (creators.isEmpty) {
        _isSyncing = false;
        return SyncResult(
          totalCreators: 0,
          successCreators: 0,
          newPosts: 0,
        );
      }

      // 3. 逐个同步
      for (final creator in creators) {
        try {
          final count = await _syncCreator(creator);
          if (count > 0) {
            newPosts += count;
          }
          successCreators++;
        } catch (e) {
          errors.add('${creator.nickname}: $e');
        }
      }

      return SyncResult(
        totalCreators: creators.length,
        successCreators: successCreators,
        newPosts: newPosts,
        errors: errors,
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// 同步单个博主
  Future<int> _syncCreator(Creator creator) async {
    int newCount = 0;
    int cursor = 0;
    bool hasMore = true;
    int fetchCount = 0;
    const maxPages = 5; // 最多抓取5页（约90篇）

    while (hasMore && fetchCount < maxPages) {
      final result = await _api.getUserPosts(
        creator.secUid,
        minCursor: cursor,
      );

      for (final postData in result.posts) {
        final awemeId = postData['awemeId'] as String;
        // 检查是否已存在
        if (await _db.postExists(awemeId)) {
          continue;
        }

        final post = Post(
          awemeId: awemeId,
          creatorId: creator.id!,
          creatorSecUid: creator.secUid,
          description: postData['description'] as String? ?? '',
          videoCoverUrl: postData['videoCoverUrl'] as String?,
          videoUrl: postData['videoUrl'] as String?,
          imageUrls: (postData['imageUrls'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          publishTime: postData['publishTime'] as int? ?? 0,
          isImagePost: postData['isImagePost'] as bool? ?? false,
          viewCount: postData['viewCount'] as int? ?? 0,
          likeCount: postData['likeCount'] as int? ?? 0,
          commentCount: postData['commentCount'] as int? ?? 0,
          shareCount: postData['shareCount'] as int? ?? 0,
          shareUrl: postData['shareUrl'] as String?,
        );

        await _db.insertPost(post);
        newCount++;
      }

      hasMore = result.hasMore;
      cursor = result.maxCursor;
      fetchCount++;
    }

    // 更新最后抓取时间
    if (newCount > 0 || fetchCount > 0) {
      await _db.updateCreatorFetchedAt(creator.id!);
    }

    return newCount;
  }

  /// 添加新博主
  Future<Creator> addCreator(String input) async {
    // 先初始化 session，否则抖音 API 会拒绝请求
    await _api.initialize();

    Map<String, dynamic> userInfo;

    // 尝试从输入中提取 sec_uid
    final secUid = DouyinApiService.extractSecUidFromInput(input);

    if (secUid != null) {
      userInfo = (await _api.getUserInfo(secUid))!;
    } else {
      // 尝试通过抖音号查找
      final result = await _api.searchUserByUniqueId(input);
      if (result == null) {
        throw DouyinApiException('找不到该用户，请检查输入是否正确');
      }
      userInfo = result;
    }

    // 检查是否已存在
    final existing =
        await _db.getCreatorBySecUid(userInfo['secUid'] as String);
    if (existing != null) {
      throw DouyinApiException('博主 ${existing.nickname} 已在列表中');
    }

    final creator = Creator(
      secUid: userInfo['secUid'] as String,
      uniqueId: userInfo['uniqueId'] as String?,
      nickname: userInfo['nickname'] as String,
      avatarUrl: userInfo['avatarUrl'] as String? ?? '',
      signature: userInfo['signature'] as String?,
      followerCount: userInfo['followerCount'] as int? ?? 0,
      followingCount: userInfo['followingCount'] as int? ?? 0,
      totalFavorited: userInfo['totalFavorited'] as int? ?? 0,
    );

    final id = await _db.insertCreator(creator);
    return creator.copyWith(id: id);
  }
}
