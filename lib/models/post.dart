class Post {
  final int? id;
  final String awemeId; // 抖音作品ID
  final int creatorId; // 外键 -> Creator.id
  final String? creatorSecUid; // 冗余，方便查询
  final String description; // 文案描述
  final String? videoCoverUrl; // 视频封面URL
  final String? videoUrl; // 视频播放URL
  final List<String> imageUrls; // 图文作品的图片URL列表
  final int publishTime; // 发布时间 (Unix 秒)
  final DateTime fetchedAt; // 抓取时间
  final bool isImagePost; // 是否为图文作品
  final int viewCount; // 播放数
  final int likeCount; // 点赞数
  final int commentCount; // 评论数
  final int shareCount; // 分享数
  final String? shareUrl; // 分享链接

  Post({
    this.id,
    required this.awemeId,
    required this.creatorId,
    this.creatorSecUid,
    required this.description,
    this.videoCoverUrl,
    this.videoUrl,
    this.imageUrls = const [],
    required this.publishTime,
    DateTime? fetchedAt,
    this.isImagePost = false,
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.shareUrl,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  /// 发布时间格式化显示
  String get publishTimeFormatted {
    final dt = DateTime.fromMillisecondsSinceEpoch(publishTime * 1000);
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 30) return '${diff.inDays}天前';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}个月前';

    return '${dt.year}/${dt.month}/${dt.day}';
  }

  /// 是否有图片可展示
  bool get hasImages => imageUrls.isNotEmpty;
  bool get hasVideo => videoCoverUrl != null;

  /// 封面图（优先取图片第一张，没有则取视频封面）
  String? get coverUrl =>
      imageUrls.isNotEmpty ? imageUrls.first : videoCoverUrl;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'awemeId': awemeId,
      'creatorId': creatorId,
      'creatorSecUid': creatorSecUid,
      'description': description,
      'videoCoverUrl': videoCoverUrl,
      'videoUrl': videoUrl,
      'imageUrls': imageUrls.join(','),
      'publishTime': publishTime,
      'fetchedAt': fetchedAt.toIso8601String(),
      'isImagePost': isImagePost ? 1 : 0,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'shareUrl': shareUrl,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as int?,
      awemeId: map['awemeId'] as String,
      creatorId: map['creatorId'] as int,
      creatorSecUid: map['creatorSecUid'] as String?,
      description: map['description'] as String? ?? '',
      videoCoverUrl: map['videoCoverUrl'] as String?,
      videoUrl: map['videoUrl'] as String?,
      imageUrls: (map['imageUrls'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      publishTime: map['publishTime'] as int,
      fetchedAt: map['fetchedAt'] != null
          ? DateTime.parse(map['fetchedAt'] as String)
          : DateTime.now(),
      isImagePost: (map['isImagePost'] as int?) == 1,
      viewCount: map['viewCount'] as int? ?? 0,
      likeCount: map['likeCount'] as int? ?? 0,
      commentCount: map['commentCount'] as int? ?? 0,
      shareCount: map['shareCount'] as int? ?? 0,
      shareUrl: map['shareUrl'] as String?,
    );
  }

  @override
  String toString() =>
      'Post($awemeId, ${description.length > 20 ? '${description.substring(0, 20)}...' : description})';
}
