import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';

/// 抖音公开 API 服务
///
/// 通过模拟浏览器请求，获取抖音博主的公开信息。
/// 注意：抖音 API 随时可能变更，请保持更新。
class DouyinApiService {
  static const String _baseUrl = 'https://www.douyin.com';
  static const String _aid = '6383';
  static const String _appName = 'aweme_list';

  late final Dio _dio;
  late final CookieJar _cookieJar;

  DouyinApiService() {
    _cookieJar = CookieJar();
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      headers: _defaultHeaders,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  Map<String, dynamic> get _defaultHeaders => {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Accept':
            'application/json, text/plain, */*',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
        'Referer': '$_baseUrl/',
        'Origin': _baseUrl,
        'sec-ch-ua':
            '"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"',
        'sec-ch-ua-mobile': '?1',
        'sec-ch-ua-platform': '"Android"',
      };

  /// 初始化：获取匿名 session cookie
  Future<bool> initialize() async {
    try {
      final response = await _dio.get('/');
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ==================== 用户信息 ====================

  /// 通过 sec_uid 获取博主信息
  Future<Map<String, dynamic>?> getUserInfo(String secUid) async {
    try {
      final response = await _dio.get(
        '/aweme/v1/web/user/profile/other/',
        queryParameters: {
          'sec_user_id': secUid,
          'aid': _aid,
          'device_platform': 'webapp',
        },
      );

      final data = _parseResponse(response);
      if (data == null) return null;

      final user = data['user_info'] as Map<String, dynamic>?;
      if (user == null) return null;

      return _extractUserInfo(user);
    } on DioException catch (e) {
      throw DouyinApiException('获取用户信息失败: ${e.message}');
    }
  }

  /// 通过 unique_id（抖音号）查找用户
  /// 注：此方法通过访问用户主页来获取 sec_uid
  Future<Map<String, dynamic>?> searchUserByUniqueId(String uniqueId) async {
    try {
      // 尝试直接访问用户主页
      final cleanId = uniqueId.replaceFirst('@', '');
      final response = await _dio.get(
        '/user/$cleanId',
        options: Options(
          followRedirects: false,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36',
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'zh-CN,zh;q=0.9',
          },
        ),
      );

      // 从 HTML 中提取 sec_uid
      final html = response.data as String?;
      if (html == null) return null;

      // 尝试从 HTML 中提取 sec_uid
      final secUidMatch =
          RegExp(r'''sec_uid["']?\s*[:=]\s*["']([^"']+)''')
              .firstMatch(html);
      if (secUidMatch != null) {
        final secUid = secUidMatch.group(1)!;
        return getUserInfo(secUid);
      }

      // 尝试从页面 JSON 数据中提取
      final jsonMatch =
          RegExp(r'''<script[^>]*id=["']RENDER_DATA["'][^>]*>([^<]+)''')
              .firstMatch(html);
      if (jsonMatch != null) {
        final decoded = utf8.decode(base64Decode(jsonMatch.group(1)!));
        final data = json.decode(decoded) as Map<String, dynamic>;
        // 复杂的嵌套提取逻辑
        final secUid = _extractSecUidFromRenderData(data);
        if (secUid != null) {
          return getUserInfo(secUid);
        }
      }

      return null;
    } on DioException catch (e) {
      throw DouyinApiException('查找用户失败: ${e.message}');
    }
  }

  // ==================== 作品列表 ====================

  /// 获取博主的作品列表
  ///
  /// [secUid] 抖音用户sec_uid
  /// [minCursor] 分页游标，首次传0
  /// [count] 每页数量，最大18
  Future<DouyinPostListResult> getUserPosts(
    String secUid, {
    int minCursor = 0,
    int count = 18,
  }) async {
    try {
      final response = await _dio.get(
        '/aweme/v1/web/aweme/post/',
        queryParameters: {
          'sec_user_id': secUid,
          'count': count.toString(),
          'max_cursor': minCursor.toString(),
          'min_cursor': '0',
          'aid': _aid,
          'device_platform': 'webapp',
        },
      );

      final data = _parseResponse(response);
      if (data == null) {
        return DouyinPostListResult(posts: [], hasMore: false);
      }

      final awemeList = data['aweme_list'] as List<dynamic>? ?? [];
      final hasMore = data['has_more'] == true;
      final maxCursor = data['max_cursor'] as int? ?? 0;

      final posts = awemeList
          .map((item) => _extractPost(item as Map<String, dynamic>))
          .where((p) => p != null)
          .cast<Map<String, dynamic>>()
          .toList();

      return DouyinPostListResult(
        posts: posts,
        hasMore: hasMore,
        maxCursor: maxCursor,
      );
    } on DioException catch (e) {
      throw DouyinApiException('获取作品列表失败: ${e.message}');
    }
  }

  // ==================== 数据提取 ====================

  Map<String, dynamic> _extractUserInfo(Map<String, dynamic> user) {
    return {
      'secUid': user['sec_uid'] as String? ?? '',
      'uniqueId': user['unique_id'] as String?,
      'nickname': user['nickname'] as String? ?? '未知',
      'avatarUrl': _extractUrl(user['avatar_larger'] as Map<String, dynamic>? ??
          user['avatar_medium'] as Map<String, dynamic>?),
      'signature': user['signature'] as String?,
      'followerCount': user['follower_count'] as int? ?? 0,
      'followingCount': user['following_count'] as int? ?? 0,
      'totalFavorited': int.tryParse(
              (user['total_favorited'] as String?) ?? '0') ??
          0,
    };
  }

  Map<String, dynamic>? _extractPost(Map<String, dynamic> item) {
    try {
      final awemeId = item['aweme_id'] as String?;
      if (awemeId == null) return null;

      final desc = item['desc'] as String? ?? '';
      final createTime = item['create_time'] as int? ?? 0;
      final images = item['images'] as List<dynamic>?;
      final video = item['video'] as Map<String, dynamic>?;
      final statistics = item['statistics'] as Map<String, dynamic>?;

      final isImagePost = images != null && images.isNotEmpty;

      // 提取图片URL
      List<String> imageUrls = [];
      if (isImagePost) {
        for (final img in images) {
          final url = _extractUrl(img as Map<String, dynamic>?);
          if (url != null) imageUrls.add(url);
        }
      }

      // 提取视频信息
      String? videoCoverUrl;
      String? videoUrl;
      if (video != null) {
        final cover = video['cover'] as Map<String, dynamic>?;
        videoCoverUrl = _extractUrl(cover);

        final playAddr = video['play_addr'] as Map<String, dynamic>?;
        videoUrl = _extractUrl(playAddr);
      }

      // 如果图文没有单独封面，用第一张图代替
      if (isImagePost && videoCoverUrl == null && imageUrls.isNotEmpty) {
        videoCoverUrl = imageUrls.first;
      }

      return {
        'awemeId': awemeId,
        'description': desc,
        'publishTime': createTime,
        'isImagePost': isImagePost,
        'imageUrls': imageUrls,
        'videoCoverUrl': videoCoverUrl,
        'videoUrl': videoUrl,
        'viewCount': statistics?['view_count'] as int? ?? 0,
        'likeCount': statistics?['digg_count'] as int? ?? 0,
        'commentCount': statistics?['comment_count'] as int? ?? 0,
        'shareCount': statistics?['share_count'] as int? ?? 0,
        'shareUrl':
            'https://www.douyin.com/video/$awemeId',
      };
    } catch (e) {
      return null;
    }
  }

  String? _extractUrl(Map<String, dynamic>? mediaItem) {
    if (mediaItem == null) return null;
    final urlList = mediaItem['url_list'] as List<dynamic>?;
    if (urlList == null || urlList.isEmpty) return null;

    // 取第一个可用URL（通常是最高质量）
    final url = urlList.first as String?;
    if (url == null || url.isEmpty) return null;

    // 有些URL是 webp 格式，尝试转成更通用的格式
    return url.replaceAll(RegExp(r'~tplv.*'), '');
  }

  String? _extractSecUidFromRenderData(Map<String, dynamic> data) {
    // RENDER_DATA 结构复杂，递归搜索 sec_uid
    try {
      return _deepSearch(data, 'sec_uid');
    } catch (_) {
      return null;
    }
  }

  String? _deepSearch(Map<String, dynamic> map, String key) {
    if (map.containsKey(key)) {
      final value = map[key];
      if (value is String && value.length > 10) return value;
    }
    for (final value in map.values) {
      if (value is Map<String, dynamic>) {
        final result = _deepSearch(value, key);
        if (result != null) return result;
      } else if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            final result = _deepSearch(item, key);
            if (result != null) return result;
          }
        }
      }
    }
    return null;
  }

  Map<String, dynamic>? _parseResponse(Response response) {
    if (response.statusCode != 200) return null;
    final data = response.data;
    if (data is String) {
      try {
        return json.decode(data) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    if (data is Map<String, dynamic>) {
      // 检查错误码
      final statusCode = data['status_code'] as int?;
      if (statusCode != null && statusCode != 0) {
        throw DouyinApiException(
            'API返回错误: status_code=$statusCode, msg=${data['status_msg']}');
      }
      return data;
    }
    return null;
  }

  /// 从用户输入中提取 sec_uid
  static String? extractSecUidFromInput(String input) {
    // 直接是 sec_uid 格式（长字符串）
    if (input.length > 20 && !input.contains('/') && !input.contains('.')) {
      return input;
    }

    // 从URL中提取
    // https://www.douyin.com/user/MS4wLjABAAAA...
    final urlMatch =
        RegExp(r'douyin\.com/(?:user|share/user)/([^/?&#]+)').firstMatch(input);
    if (urlMatch != null) {
      return urlMatch.group(1)!;
    }

    // 从分享链接中提取
    // https://v.douyin.com/xxxx/
    final shortMatch =
        RegExp(r'douyin\.com/(?:video|note)/(\d+)').firstMatch(input);
    if (shortMatch != null) {
      return shortMatch.group(1); // 这是 aweme_id, 不是 sec_uid
    }

    return null;
  }

  /// 判断输入是否为抖音号（非 sec_uid）
  static bool isUniqueId(String input) {
    return extractSecUidFromInput(input) == null;
  }
}

class DouyinApiException implements Exception {
  final String message;
  DouyinApiException(this.message);

  @override
  String toString() => 'DouyinApiException: $message';
}

class DouyinPostListResult {
  final List<Map<String, dynamic>> posts;
  final bool hasMore;
  final int maxCursor;

  DouyinPostListResult({
    required this.posts,
    this.hasMore = false,
    this.maxCursor = 0,
  });
}
