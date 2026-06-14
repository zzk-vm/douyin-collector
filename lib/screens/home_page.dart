import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/post.dart';
import '../models/view_style.dart';
import 'post_card.dart';
import 'post_detail_page.dart';

/// 信息流首页
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _initialLoad = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialLoad) {
      _initialLoad = false;
      context.read<AppState>().loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final style = state.viewStyle;
        return Scaffold(
          // 极简模式用纯黑背景
          backgroundColor:
              style == ViewStyle.minimal ? Colors.black : null,

          // 顶部栏 + 视图切换
          appBar: AppBar(
            title: const Text('信息流'),
            actions: [
              _ViewToggle(
                current: style,
                onChanged: (s) => state.setViewStyle(s),
              ),
              const SizedBox(width: 4),
            ],
          ),

          body: RefreshIndicator(
            color: style == ViewStyle.minimal ? Colors.white : null,
            onRefresh: () async {
              final result = await state.syncAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(SnackBar(
                    content: Text(
                        result.hasError ? result.errorDetail : result.summary),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 5),
                  ));
              }
            },
            child: _buildBody(state),
          ),
        );
      },
    );
  }

  Widget _buildBody(AppState state) {
    if (state.isLoading && state.feedPosts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.feedPosts.isEmpty) {
      return _buildEmptyState(state);
    }

    // 三种风格都使用 ListView，但卡片不同
    final edgeInsets = state.viewStyle == ViewStyle.news
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 0)
        : EdgeInsets.zero;

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: state.feedPosts.length,
      itemBuilder: (context, index) {
        final post = state.feedPosts[index];
        return Padding(
          padding: edgeInsets,
          child: PostCard(
            post: post,
            style: state.viewStyle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PostDetailPage(post: post)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(AppState state) {
    final isDark = state.viewStyle == ViewStyle.minimal ||
        state.viewStyle == ViewStyle.glass;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rss_feed_outlined,
                size: 80, color: isDark ? Colors.white24 : Colors.grey[400]),
            const SizedBox(height: 16),
            Text('还没有内容',
                style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('去"博主"页面添加你关注的抖音博主吧\n然后下拉刷新获取最新内容',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey[500])),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: state.isSyncing ? null : () async {
                final result = await state.syncAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(SnackBar(
                      content: Text(result.hasError
                          ? result.errorDetail
                          : result.summary),
                      behavior: SnackBarBehavior.floating,
                    ));
                }
              },
              icon: state.isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(state.isSyncing ? '同步中...' : '立即同步'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 视图风格切换按钮（三档循环切换）
class _ViewToggle extends StatelessWidget {
  final ViewStyle current;
  final ValueChanged<ViewStyle> onChanged;

  const _ViewToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ViewStyle>(
      tooltip: '切换视图',
      icon: Icon(_iconForStyle(current)),
      onSelected: onChanged,
      itemBuilder: (_) => ViewStyle.values.map((style) {
        return PopupMenuItem(
          value: style,
          child: Row(
            children: [
              Icon(_iconForStyle(style),
                  size: 20,
                  color: style == current ? null : Colors.grey),
              const SizedBox(width: 12),
              Text(style.label,
                  style: TextStyle(
                      fontWeight:
                          style == current ? FontWeight.w600 : FontWeight.normal,
                      color: style == current ? null : null)),
              if (style == current) ...[
                const Spacer(),
                const Icon(Icons.check, size: 16),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _iconForStyle(ViewStyle style) {
    switch (style) {
      case ViewStyle.news:
        return Icons.article_outlined;
      case ViewStyle.minimal:
        return Icons.dark_mode_outlined;
      case ViewStyle.glass:
        return Icons.blur_on_outlined;
    }
  }
}
