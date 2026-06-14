import 'dart:convert';
import 'package:dio/dio.dart';
import 'cookie_service.dart';

/// 抖音公开 API 服务
///
/// 通过模拟浏览器请求，获取抖音博主的公开信息。
/// 注意：抖音 API 随时可能变更，请保持更新。
class DouyinApiService {
  static const String _baseUrl = 'https://www.douyin.com';
  static const String _aid = '6383';

  late final Dio _dio;
  final CookieService _cookieService = CookieService();

  DouyinApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
  }

  /// 获取含动态 cookie 的请求头
  Map<String, dynamic> _buildHeaders({String? referer}) {
    final headers = <String, dynamic>{
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      'Origin': _baseUrl,
    };
    if (referer != null) {
      headers['Referer'] = referer;
    } else {
      headers['Referer'] = '$_baseUrl/';
    }
    // 注入 WebView 获取到的真实 cookie
    final cookie = _cookieService.cookieHeader;
    if (cookie != null && cookie.isNotEmpty) {
      headers['Cookie'] = cookie;
    }
    return headers;
  }

  /// 初始化
  Future<bool> initialize() async {
    return _cookieService.hasCookies;
  }

  // ==================== 用户信息 ====================

  /// 通过 sec_uid 获取博主信息
  Future<Map<String, dynamic>?> getUserInfo(String secUid) async {
    try {
      // 先访问用户主页获取 cookie
      try {
        await _dio.get('/user/$secUid',
            options: Options(headers: {'Referer': '$_baseUrl/'}));
      } catch (_) {
        // 忽略页面加载错误，可能部分内容需要 JS
      }

      final response = await _dio.get(
        '/aweme/v1/web/user/profile/other/',
        queryParameters: {
          'sec_user_id': secUid,
          'aid': _aid,
          'device_platform': 'webapp',
        },
        options: Options(
            headers: _buildHeaders(referer: '$_baseUrl/user/$secUid')),
      );

      final data = _parseResponse(response);
      if (data == null) {
        throw DouyinApiException('抖音返回了异常数据，可能被限制访问');
      }

      // 尝试多种字段名解析用户数据
      Map<String, dynamic>? user;
      user = data['user_info'] as Map<String, dynamic>?;
      if (user == null) {
        user = data['user'] as Map<String, dynamic>?;
      }
      if (user == null) {
        // 嵌套在 data 字段里
        final innerData = data['data'] as Map<String, dynamic>?;
        if (innerData != null) {
          user = innerData['user_info'] as Map<String, dynamic>? ??
              innerData['user'] as Map<String, dynamic>?;
        }
      }
      if (user == null) {
        final errMsg = data['status_msg'] as String? ??
            data['status_code']?.toString() ??
            '未知错误';
        throw DouyinApiException('抖音API错误: $errMsg');
      }

      return _extractUserInfo(user);
    } on DioException catch (e) {
      throw DouyinApiException('获取用户信息失败: ${e.message}');
    }
  }

  /// 通过 unique_id（抖音号）查找用户
  Future<Map<String, dynamic>?> searchUserByUniqueId(String uniqueId) async {
    try {
      final cleanId = uniqueId.replaceFirst('@', '');

      // 先用搜索 API 查找
      try {
        final result = await searchUser(cleanId);
        if (result != null) return result;
      } catch (_) {
        // 搜索失败，走 fallback
      }

      // 备用：直接访问用户主页
      try {
        final response = await _dio.get(
          '/user/$cleanId',
          options: Options(
            followRedirects: false,
            headers: _buildHeaders(),
          ),
        );

        final html = response.data as String?;
        if (html != null) {
          final secUidMatch =
              RegExp(r'''sec_uid["']?\s*[:=]\s*["']([^"']+)''')
                  .firstMatch(html);
          if (secUidMatch != null) {
            return getUserInfo(secUidMatch.group(1)!);
          }

          // 尝试从 RENDER_DATA 中提取
          final jsonMatch =
              RegExp(r'''<script[^>]*id=["']RENDER_DATA["'][^>]*>([^<]+)''')
                  .firstMatch(html);
          if (jsonMatch != null) {
            final decoded = utf8.decode(base64Decode(jsonMatch.group(1)!));
            final data = json.decode(decoded) as Map<String, dynamic>;
            final secUid = _extractSecUidFromRenderData(data);
            if (secUid != null) return getUserInfo(secUid);
          }
        }
      } catch (_) {}

      throw DouyinApiException('找不到该用户，请检查抖音号是否正确');
    } on DioException catch (e) {
      throw DouyinApiException('查找用户失败: ${e.message}');
    }
  }

  /// 通过搜索 API 查找用户
  Future<Map<String, dynamic>?> searchUser(String keyword) async {
    try {
      final response = await _dio.get(
        '/aweme/v1/web/discover/search/',
        queryParameters: {
          'keyword': keyword,
          'offset': '0',
          'count': '10',
          'aid': _aid,
          'device_platform': 'webapp',
        },
        options: Options(headers: _buildHeaders()),
      );

      final data = _parseResponse(response);
      if (data == null) return null;

      // 搜索API返回的字段名可能不同，尝试多种格式
      var userList = data['user_list'] as List<dynamic>?;
      // 有时搜索结果在 data 字段里
      if (userList == null) {
        final innerData = data['data'] as Map<String, dynamic>?;
        if (innerData != null) {
          userList = innerData['user_list'] as List<dynamic>?;
        }
      }
      if (userList == null || userList.isEmpty) return null;

      // 精确匹配 unique_id
      for (final item in userList) {
        final userInfo = item['user_info'] as Map<String, dynamic>?;
        if (userInfo == null) continue;
        final uid = userInfo['unique_id']?.toString() ?? '';
        final shortId = userInfo['short_id']?.toString() ?? '';
        if (uid == keyword || shortId == keyword) {
          return _extractUserInfo(userInfo);
        }
      }

      // 没找到精确匹配，返回第一个结果
      final first = userList.first['user_info'] as Map<String, dynamic>?;
      if (first != null) {
        return _extractUserInfo(first);
      }

      return null;
    } on DioException {
      return null;
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
        options: Options(
            headers: _buildHeaders(referer: '$_baseUrl/user/$secUid')),
      );

      final data = _parseResponse(response);
      if (data == null) {
        throw DouyinApiException('获取作品列表失败：API返回异常数据');
      }

      final awemeList = data['aweme_list'] as List<dynamic>?;
      if (awemeList == null) {
        // 尝试从嵌套 data 中取值
        final inner = data['data'] as Map<String, dynamic>?;
        if (inner != null) {
          final innerList = inner['aweme_list'] as List<dynamic>?;
          if (innerList != null) {
            return _parsePostList(innerList, data);
          }
        }
        return DouyinPostListResult(posts: [], hasMore: false);
      }

      return _parsePostList(awemeList, data);
    } on DioException catch (e) {
      throw DouyinApiException('获取作品列表失败: ${e.message}');
    }
  }

  DouyinPostListResult _parsePostList(
      List<dynamic> list, Map<String, dynamic> rootData) {
    final hasMore = rootData['has_more'] == true;
    final maxCursor = rootData['max_cursor'] as int? ?? 0;
    final posts = list
        .map((item) => _extractPost(item as Map<String, dynamic>))
        .where((p) => p != null)
        .cast<Map<String, dynamic>>()
        .toList();
    return DouyinPostListResult(
        posts: posts, hasMore: hasMore, maxCursor: maxCursor);
  }

  // ==================== 数据提取 ====================

  Map<String, dynamic> _extractUserInfo(Map<String, dynamic> user) {
    // 安全转换：处理字段可能是 String/Int/null 的情况
    String? _safeStr(dynamic v) => v?.toString();
    int _safeInt(dynamic v, {int def = 0}) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? def;
    }
    String? _safeUrl(dynamic v) {
      if (v is Map<String, dynamic>) return _extractUrl(v);
      return null;
    }

    return {
      'secUid': _safeStr(user['sec_uid']) ?? '',
      'uniqueId': _safeStr(user['unique_id']),
      'nickname': _safeStr(user['nickname']) ?? '未知',
      'avatarUrl': _safeUrl(user['avatar_larger']) ??
          _safeUrl(user['avatar_medium']) ??
          '',
      'signature': _safeStr(user['signature']),
      'followerCount': _safeInt(user['follower_count']),
      'followingCount': _safeInt(user['following_count']),
      'totalFavorited': _safeInt(user['total_favorited']),
    };
  }

  Map<String, dynamic>? _extractPost(Map<String, dynamic> item) {
    try {
      final awemeId = item['aweme_id'] as String?;
      if (awemeId == null) return null;

      final desc = (item['desc'] as String?) ?? '';
      final createTime = (item['create_time'] as int?) ?? 0;
      final images = item['images'] as List<dynamic>?;
      final video = item['video'] as Map<String, dynamic>?;
      final statistics = item['statistics'] as Map<String, dynamic>?;

      final isImagePost = images != null && images.isNotEmpty;

      List<String> imageUrls = [];
      if (isImagePost) {
        for (final img in images) {
          final url = _extractUrl(img as Map<String, dynamic>?);
          if (url != null) imageUrls.add(url);
        }
      }

      String? videoCoverUrl;
      String? videoUrl;
      if (video != null) {
        final cover = video['cover'] as Map<String, dynamic>?;
        videoCoverUrl = _extractUrl(cover);

        final playAddr = video['play_addr'] as Map<String, dynamic>?;
        videoUrl = _extractUrl(playAddr);
      }

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
        'viewCount': (statistics?['view_count'] as int?) ?? 0,
        'likeCount': (statistics?['digg_count'] as int?) ?? 0,
        'commentCount': (statistics?['comment_count'] as int?) ?? 0,
        'shareCount': (statistics?['share_count'] as int?) ?? 0,
        'shareUrl': 'https://www.douyin.com/video/$awemeId',
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
