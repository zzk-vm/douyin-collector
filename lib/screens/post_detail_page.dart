import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post.dart';

/// 作品详情页
class PostDetailPage extends StatelessWidget {
  final Post post;

  const PostDetailPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('作品详情'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 媒体内容
            _buildMediaSection(context),

            // 互动数据
            _buildStatsRow(),

            const Divider(height: 1),

            // 文案
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '作品文案',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.description.isEmpty ? '(暂无文案)' : post.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // 作品信息
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '作品信息',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _infoRow('作品ID', post.awemeId),
                  _infoRow('作品类型', post.isImagePost ? '图文' : '视频'),
                  _infoRow(
                    '发布时间',
                    DateTime.fromMillisecondsSinceEpoch(
                      post.publishTime * 1000,
                    ).toString().substring(0, 19),
                  ),
                  _infoRow('抓取时间', post.fetchedAt.toString().substring(0, 19)),
                  if (post.shareUrl != null)
                    _infoRow('分享链接', post.shareUrl!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection(BuildContext context) {
    if (post.isImagePost && post.imageUrls.isNotEmpty) {
      // 图文模式：使用 PageView 多图滑动
      return _buildImageGallery(context);
    } else if (post.videoCoverUrl != null) {
      // 视频模式：显示封面
      return _buildVideoCover();
    }
    return const SizedBox.shrink();
  }

  Widget _buildImageGallery(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.width * 1.2,
      child: PageView.builder(
        itemCount: post.imageUrls.length,
        itemBuilder: (context, index) {
          return Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: post.imageUrls[index],
                  fit: BoxFit.contain,
                  placeholder: (_, __) => Container(
                    color: Colors.grey[100],
                    child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[100],
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('图片加载失败',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // 页码指示器
              if (post.imageUrls.length > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${index + 1} / ${post.imageUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVideoCover() {
    return Stack(
      alignment: Alignment.center,
      children: [
        CachedNetworkImage(
          imageUrl: post.videoCoverUrl!,
          width: double.infinity,
          height: 300,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: Colors.grey[200],
            height: 300,
            child:
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (_, __, ___) => Container(
            color: Colors.grey[200],
            height: 300,
            child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
          ),
        ),
        // 播放按钮
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.black38,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _statItem(Icons.favorite_border, post.likeCount),
          const SizedBox(width: 24),
          _statItem(Icons.chat_bubble_outline, post.commentCount),
          const SizedBox(width: 24),
          _statItem(Icons.reply_outlined, post.shareCount),
          const SizedBox(width: 24),
          _statItem(Icons.visibility_outlined, post.viewCount),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          _formatCount(count),
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
