class Creator {
  final int? id;
  final String secUid; // 抖音用户唯一标识
  final String? uniqueId; // 抖音号 @xxx
  final String nickname; // 昵称
  final String avatarUrl; // 头像链接
  final String? signature; // 签名
  final int followerCount; // 粉丝数
  final int followingCount; // 关注数
  final int totalFavorited; // 获赞数
  final DateTime addedAt; // 添加到 app 的时间
  final DateTime? lastFetchedAt; // 最后一次抓取时间

  Creator({
    this.id,
    required this.secUid,
    this.uniqueId,
    required this.nickname,
    required this.avatarUrl,
    this.signature,
    this.followerCount = 0,
    this.followingCount = 0,
    this.totalFavorited = 0,
    DateTime? addedAt,
    this.lastFetchedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'secUid': secUid,
      'uniqueId': uniqueId,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'signature': signature,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'totalFavorited': totalFavorited,
      'addedAt': addedAt.toIso8601String(),
      'lastFetchedAt': lastFetchedAt?.toIso8601String(),
    };
  }

  factory Creator.fromMap(Map<String, dynamic> map) {
    return Creator(
      id: map['id'] as int?,
      secUid: map['secUid'] as String,
      uniqueId: map['uniqueId'] as String?,
      nickname: map['nickname'] as String,
      avatarUrl: map['avatarUrl'] as String? ?? '',
      signature: map['signature'] as String?,
      followerCount: map['followerCount'] as int? ?? 0,
      followingCount: map['followingCount'] as int? ?? 0,
      totalFavorited: map['totalFavorited'] as int? ?? 0,
      addedAt: map['addedAt'] != null
          ? DateTime.parse(map['addedAt'] as String)
          : DateTime.now(),
      lastFetchedAt: map['lastFetchedAt'] != null
          ? DateTime.parse(map['lastFetchedAt'] as String)
          : null,
    );
  }

  Creator copyWith({
    int? id,
    String? secUid,
    String? uniqueId,
    String? nickname,
    String? avatarUrl,
    String? signature,
    int? followerCount,
    int? followingCount,
    int? totalFavorited,
    DateTime? addedAt,
    DateTime? lastFetchedAt,
  }) {
    return Creator(
      id: id ?? this.id,
      secUid: secUid ?? this.secUid,
      uniqueId: uniqueId ?? this.uniqueId,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      signature: signature ?? this.signature,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      totalFavorited: totalFavorited ?? this.totalFavorited,
      addedAt: addedAt ?? this.addedAt,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
    );
  }

  @override
  String toString() => 'Creator($nickname, @$uniqueId)';
}
