import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/app_state.dart';
import '../models/creator.dart';
import 'creator_detail_page.dart';
import 'add_creator_page.dart';

/// 博主列表页
class CreatorsPage extends StatefulWidget {
  const CreatorsPage({super.key});

  @override
  State<CreatorsPage> createState() => _CreatorsPageState();
}

class _CreatorsPageState extends State<CreatorsPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return Scaffold(
          body: _buildBody(state),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addCreator(context),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('添加博主'),
          ),
        );
      },
    );
  }

  Widget _buildBody(AppState state) {
    if (state.isLoading && state.creators.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.creators.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => state.syncAll(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
        itemCount: state.creators.length,
        itemBuilder: (context, index) {
          final creator = state.creators[index];
          return _CreatorCard(creator: creator);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '还没有添加博主',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击下方按钮，添加你想追踪的抖音博主',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  void _addCreator(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCreatorPage()),
    );
  }
}

class _CreatorCard extends StatelessWidget {
  final Creator creator;

  const _CreatorCard({required this.creator});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreatorDetailPage(creator: creator),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 头像
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: CachedNetworkImage(
                  imageUrl: creator.avatarUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creator.nickname,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (creator.uniqueId != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@${creator.uniqueId}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStatItem(
                            Icons.favorite_border, creator.totalFavorited),
                        const SizedBox(width: 12),
                        _buildStatItem(
                            Icons.people_outline, creator.followerCount),
                      ],
                    ),
                  ],
                ),
              ),

              // 箭头
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, int count) {
    final formatted = count >= 10000
        ? '${(count / 10000).toStringAsFixed(1)}w'
        : count.toString();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 2),
        Text(formatted, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }
}
