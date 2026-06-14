import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/creator.dart';
import '../models/post.dart';
import '../services/app_state.dart';
import 'post_detail_page.dart';

/// 博主详情页 - 查看该博主的所有归档作品
class CreatorDetailPage extends StatefulWidget {
  final Creator creator;

  const CreatorDetailPage({super.key, required this.creator});

  @override
  State<CreatorDetailPage> createState() => _CreatorDetailPageState();
}

class _CreatorDetailPageState extends State<CreatorDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadCreatorPosts(widget.creator);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.creator.nickname),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: '移除博主',
                onPressed: () => _confirmRemove(context, state),
              ),
            ],
          ),
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(AppState state) {
    if (state.isLoading && state.creatorPosts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.creatorPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              '暂无作品记录',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => state.syncAll(),
              icon: const Icon(Icons.sync, size: 18),
              label: const Text('立即同步'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => state.refreshCreatorPosts(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: state.creatorPosts.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader(state);
          }
          final post = state.creatorPosts[index - 1];
          return _CreatorPostCard(post: post);
        },
      ),
    );
  }

  Widget _buildHeader(AppState state) {
    final c = widget.creator;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: CachedNetworkImage(
              imageUrl: c.avatarUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.person),
              ),
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.person),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.nickname,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                if (c.uniqueId != null)
                  Text('@${c.uniqueId}',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[500])),
              ],
            ),
          ),
          Text(
            '共 ${state.creatorPosts.length} 篇',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认移除'),
        content: Text('确定要移除「${widget.creator.nickname}」及其所有归档作品吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              state.removeCreator(widget.creator);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('移除'),
          ),
        ],
      ),
    );
  }
}

class _CreatorPostCard extends StatelessWidget {
  final Post post;

  const _CreatorPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostDetailPage(post: post),
            ),
          );
        },
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 缩略图
              if (post.coverUrl != null)
                ClipRRect(
                  child: SizedBox(
                    width: 120,
                    child: CachedNetworkImage(
                      imageUrl: post.coverUrl!,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image,
                            color: Colors.grey),
                      ),
                    ),
                  ),
                ),

              // 文字信息
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.description.isEmpty ? '(无文案)' : post.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, height: 1.3),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          if (post.isImagePost)
                            _miniTag(Icons.photo_library_outlined),
                          if (post.hasVideo) _miniTag(Icons.play_circle_outline),
                          const Spacer(),
                          Text(post.publishTimeFormatted,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[400])),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniTag(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(icon, size: 14, color: Colors.grey[500]),
    );
  }
}
