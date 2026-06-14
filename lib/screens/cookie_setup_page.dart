import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/cookie_service.dart';

/// Cookie 设置页面
///
/// 通过加载抖音首页来获取真实的浏览器 cookie。
class CookieSetupPage extends StatefulWidget {
  const CookieSetupPage({super.key});

  @override
  State<CookieSetupPage> createState() => _CookieSetupPageState();
}

class _CookieSetupPageState extends State<CookieSetupPage> {
  final CookieService _cookieService = CookieService();
  InAppWebViewController? _controller;
  bool _isLoading = true;
  bool _success = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    // 10 秒超时
    Future.delayed(const Duration(seconds: 10), () {
      if (!_success && mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _errorMsg = '加载超时，请检查网络后重试';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('获取抖音访问权限'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Column(
        children: [
          _buildStatusBar(),
          if (_isLoading && !_success) const LinearProgressIndicator(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    Color bgColor;
    Color iconColor;
    String text;
    IconData icon;

    if (_success) {
      bgColor = Colors.green[50]!;
      iconColor = Colors.green;
      icon = Icons.check_circle;
      text = '获取成功！正在返回...';
    } else if (_errorMsg != null) {
      bgColor = Colors.orange[50]!;
      iconColor = Colors.orange;
      icon = Icons.warning_amber;
      text = _errorMsg!;
    } else {
      bgColor = Colors.blue[50]!;
      iconColor = Colors.blue;
      icon = Icons.info_outline;
      text = '正在加载抖音页面，请稍候...';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: bgColor,
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(color: iconColor.withOpacity(0.9))),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_success) {
      return const Center(child: Icon(Icons.check_circle, size: 80, color: Colors.green));
    }
    if (_errorMsg != null) {
      return _buildRetryView();
    }
    return _buildWebView();
  }

  Widget _buildWebView() {
    return InAppWebView(
      initialUrlRequest:
          URLRequest(url: WebUri('https://www.douyin.com/')),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        userAgent:
            'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        cacheEnabled: true,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
      ),
      onWebViewCreated: (c) => _controller = c,
      onLoadStop: (c, url) async {
        if (url != null && url.host.contains('douyin.com')) {
          _isLoading = false;
          setState(() {});

          // 尝试提取 cookie（内置延迟和多方法重试）
          final ok = await _cookieService.extractCookies(c);
          if (ok && mounted) {
            _success = true;
            setState(() {});
            await Future.delayed(const Duration(seconds: 1));
            if (mounted) Navigator.pop(context, true);
          } else if (mounted) {
            setState(() {
              _errorMsg = '无法获取到有效的访问凭证，请检查后重试';
            });
          }
        }
      },
      onReceivedError: (c, r, e) {
        debugPrint('WebView error: ${e.message}');
      },
    );
  }

  Widget _buildRetryView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange[300]),
            const SizedBox(height: 16),
            const Text(
              '获取访问凭证失败',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              '这可能是因为：\n'
              '1. 手机网络无法访问抖音服务器\n'
              '2. 抖音服务器暂时繁忙\n'
              '3. 需要登录后获取凭证',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _errorMsg = null;
                  _isLoading = true;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消返回'),
            ),
          ],
        ),
      ),
    );
  }
}
