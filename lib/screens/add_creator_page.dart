import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/douyin_api.dart';
import '../services/cookie_service.dart';
import 'browser_login_page.dart';

class AddCreatorPage extends StatefulWidget {
  const AddCreatorPage({super.key});

  @override
  State<AddCreatorPage> createState() => _AddCreatorPageState();
}

class _AddCreatorPageState extends State<AddCreatorPage> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  final CookieService _cookieService = CookieService();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加博主'),
        actions: [
          if (_cookieService.hasCookies)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Chip(
                avatar:
                    Icon(Icons.check_circle, size: 14, color: Colors.green),
                label: Text('已登录', style: TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('输入抖音博主信息',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              '支持以下格式：\n'
              '• 抖音号：zhangsan 或 @zhangsan\n'
              '• 主页链接：https://www.douyin.com/user/...\n'
              '• sec_uid：MS4wLjABAAAA...',
              style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.6),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '输入抖音号或主页链接',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _addCreator(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _addCreator,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add),
                label: Text(_isLoading ? '查询中...' : '添加博主'),
                style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(height: 12),
            // 登录入口
            Center(
              child: TextButton.icon(
                onPressed: () => _openLogin(),
                icon: const Icon(Icons.qr_code, size: 18),
                label: const Text('抖音扫码登录（解决搜索不到的问题）'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
              ),
            ),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('正在查询博主信息...'),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCreator() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      _showSnackBar('请输入抖音号或主页链接');
      return;
    }

    if (!_cookieService.hasCookies) {
      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const BrowserLoginPage()),
      );
      if (ok != true) return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AppState>().addCreator(input);
      if (mounted) {
        _showSnackBar('添加成功！');
        Navigator.pop(context, true);
      }
    } on DouyinApiException catch (e) {
      if (mounted) {
        // 显示带登录选项的错误提示
        _showErrorSheet(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('添加失败: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSheet(String message) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.orange[300]),
            const SizedBox(height: 12),
            Text('添加失败', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BrowserLoginPage()),
                );
                if (ok == true) _addCreator();
              },
              icon: const Icon(Icons.qr_code),
              label: const Text('去扫码登录'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLogin() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const BrowserLoginPage()),
    );
    if (ok == true) {
      _showSnackBar('登录成功，现在可以搜索添加博主了');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ));
  }
}
