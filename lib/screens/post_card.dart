import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post.dart';
import '../models/view_style.dart';

/// 根据视图风格构建作品卡片
class PostCard extends StatelessWidget {
  final Post post;
  final ViewStyle style;
  final VoidCallback? onTap;

  const PostCard({
    super.key,
    required this.post,
    required this.style,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case ViewStyle.news:
        return _NewsCard(post: post, onTap: onTap);
      case ViewStyle.minimal:
        return _MinimalCard(post: post, onTap: onTap);
      case ViewStyle.glass:
        return _GlassCard(post: post, onTap: onTap);
    }
  }
}

// ─────────────────────────────────────────────
// 方案1: Apple News 风格
// ─────────────────────────────────────────────
class _NewsCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;

  const _NewsCard({required this.post, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 大图铺满
          if (post.coverUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: post.coverUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
            child: Text(
              post.description.isEmpty ? '(无文案)' : post.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // 博主打标 + 时间
          Row(
            children: [
              if (post.isImagePost)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('图文',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey[600])),
                ),
              if (post.isImagePost && post.likeCount > 0)
                const SizedBox(width: 8),
              if (post.likeCount > 0)
                Text('${_formatCount(post.likeCount)} 次赞',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const Spacer(),
              Text(post.publishTimeFormatted,
                  style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            ],
          ),

          const SizedBox(height: 16),
          // 细分割线
          Divider(height: 1, color: Colors.grey[200]),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatCount(int c) =>
      c >= 10000 ? '${(c / 10000).toStringAsFixed(1)}w' : c.toString();
}

// ─────────────────────────────────────────────
// 方案2: 纯黑极简
// ─────────────────────────────────────────────
class _MinimalCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;

  const _MinimalCard({required this.post, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[800]!, width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 小缩略图
            if (post.coverUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: post.coverUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Colors.grey[900],
                    child: const Icon(Icons.image_outlined,
                        color: Colors.white24, size: 24),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[900],
                    child: const Icon(Icons.image_outlined,
                        color: Colors.white24, size: 24),
                  ),
                ),
              ),
            if (post.coverUrl != null) const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.description.isEmpty ? '(无文案)' : post.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.3,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (post.isImagePost)
                        const Text('图文 ',
                            style: TextStyle(
                                fontSize: 11, color: Colors.white38)),
                      Text(post.publishTimeFormatted,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white38)),
                      if (post.likeCount > 0) ...[
                        const SizedBox(width: 12),
                        Text('${_formatCount(post.likeCount)} 次赞',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white38)),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            Icon(Icons.chevron_right, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }

  String _formatCount(int c) =>
      c >= 10000 ? '${(c / 10000).toStringAsFixed(1)}w' : c.toString();
}

// ─────────────────────────────────────────────
// 方案3: 毛玻璃
// ─────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;

  const _GlassCard({required this.post, this.onTap});

  @override
  Widget build(BuildContext context) {
    // 毛玻璃效果：使用半透明背景 + 模糊
    // Flutter 不支持 CSS backdrop-filter，但可以用 Stack 模拟
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 280,
        child: Stack(
          children: [
            // 背景封面图（模糊）
            if (post.coverUrl != null)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: post.coverUrl!,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.5),
                  colorBlendMode: BlendMode.darken,
                  placeholder: (_, __) => Container(color: Colors.grey[900]),
                  errorWidget: (_, __, ___) =>
                      Container(color: Colors.grey[900]),
                ),
              )
            else
              Positioned.fill(child: Container(color: Colors.grey[900])),

            // 玻璃卡片（底部）
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      post.description.isEmpty ? '(无文案)' : post.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (post.isImagePost)
                          const _GlassTag(label: '图文'),
                        if (post.isImagePost) const SizedBox(width: 8),
                        Text(post.publishTimeFormatted,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white70)),
                        const Spacer(),
                        if (post.likeCount > 0)
                          Row(
                            children: [
                              const Icon(Icons.favorite_border,
                                  size: 14, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(_formatCount(post.likeCount),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white70)),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 顶部类型标记
            if (post.isImagePost || post.hasVideo)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        post.isImagePost
                            ? Icons.photo_library_outlined
                            : Icons.play_circle_outline,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.isImagePost ? '图文' : '视频',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int c) =>
      c >= 10000 ? '${(c / 10000).toStringAsFixed(1)}w' : c.toString();
}

class _GlassTag extends StatelessWidget {
  final String label;
  const _GlassTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11, color: Colors.white)),
    );
  }
}
