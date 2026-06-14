import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/cookie_service.dart';

/// 浏览器页面 - 用于扫码登录抖音获取完整权限
class BrowserLoginPage extends StatefulWidget {
  const BrowserLoginPage({super.key});

  @override
  State<BrowserLoginPage> createState() => _BrowserLoginPageState();
}

class _BrowserLoginPageState extends State<BrowserLoginPage> {
  final CookieService _cookieService = CookieService();
  InAppWebViewController? _controller;
  bool _isLoading = true;
  String? _currentUrl;
  double _progress = 0;
  bool _gotCookies = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('抖音登录'),
        actions: [
          // Cookie 状态指示
          if (_gotCookies)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Chip(
                avatar: Icon(Icons.check_circle, size: 16, color: Colors.green),
                label: Text('已登录', style: TextStyle(fontSize: 12)),
                visualDensity: VisualDensity.compact,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: '使用当前登录状态',
            onPressed: _gotCookies ? () => Navigator.pop(context, true) : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // 顶部提示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: _gotCookies
                ? Colors.green[50]
                : Colors.blue[50],
            child: Row(
              children: [
                Icon(
                  _gotCookies ? Icons.check_circle : Icons.info_outline,
                  size: 20,
                  color: _gotCookies ? Colors.green : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _gotCookies
                        ? '登录成功！点击 ✓ 使用当前状态'
                        : '请登录抖音账号以获得完整访问权限',
                    style: TextStyle(
                        fontSize: 13,
                        color:
                            _gotCookies ? Colors.green[800] : Colors.blue[800]),
                  ),
                ),
              ],
            ),
          ),

          // 进度条
          if (_isLoading) LinearProgressIndicator(value: _progress),

          // 地址栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.grey[100],
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 16),
                  onPressed: () => _controller?.goBack(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: () => _controller?.goForward(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _currentUrl ?? '加载中...',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: () => _controller?.reload(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // WebView
          Expanded(
            child: InAppWebView(
              initialUrlRequest:
                  URLRequest(url: WebUri('https://www.douyin.com/')),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                userAgent:
                    'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                useWideViewPort: true,
                supportZoom: true,
              ),
              onWebViewCreated: (c) => _controller = c,
              onLoadStart: (c, url) {
                setState(() {
                  _currentUrl = url?.toString();
                  _isLoading = true;
                });
              },
              onLoadStop: (c, url) async {
                setState(() {
                  _currentUrl = url?.toString();
                  _isLoading = false;
                });
                // 每次页面加载完都尝试获取 cookie
                await _tryGetCookies(c);
              },
              onProgressChanged: (c, p) {
                setState(() => _progress = p / 100.0);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _tryGetCookies(InAppWebViewController c) async {
    if (_gotCookies) return;

    try {
      final ok = await _cookieService.extractCookies(c);
      if (ok && _cookieService.hasCookies) {
        // 检查是否包含关键 cookie（登录态通常有 s_v_web_id, passport_csrf 等）
        final ck = _cookieService.cookieHeader ?? '';
        if (ck.contains('=') && ck.length > 30) {
          setState(() => _gotCookies = true);
        }
      }
    } catch (_) {}
  }
}
