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
  final GlobalKey _webViewKey = GlobalKey();
  InAppWebViewController? _controller;
  bool _isLoading = true;
  bool _success = false;
  String? _error;

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
          // 说明区域
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _success
                ? Colors.green[50]
                : _error != null
                    ? Colors.red[50]
                    : Colors.blue[50],
            child: Row(
              children: [
                Icon(
                  _success
                      ? Icons.check_circle
                      : _error != null
                          ? Icons.error
                          : Icons.info_outline,
                  color: _success
                      ? Colors.green
                      : _error != null
                          ? Colors.red
                          : Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _success
                        ? 'Cookie 获取成功！即将返回...'
                        : _error ?? '正在加载抖音页面以获取访问权限...',
                    style: TextStyle(
                      color: _success
                          ? Colors.green[800]
                          : _error != null
                              ? Colors.red[800]
                              : Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 进度指示
          if (_isLoading && !_success)
            const LinearProgressIndicator(),

          // WebView（隐藏边界）
          Expanded(
            child: _error != null && !_success
                ? _buildRetryButton()
                : InAppWebView(
                    key: _webViewKey,
                    initialUrlRequest: URLRequest(
                      url: WebUri('https://www.douyin.com/'),
                    ),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      userAgent:
                          'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                      cacheEnabled: true,
                      mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                    ),
                    onWebViewCreated: (controller) {
                      _controller = controller;
                    },
                    onLoadStop: (controller, url) async {
                      if (url != null && url.host.contains('douyin.com')) {
                        _isLoading = false;
                        setState(() {});

                        // 页面加载完成后提取 cookie
                        final ok = await _cookieService.extractCookies(controller);
                        if (ok) {
                          _success = true;
                          setState(() {});
                          await Future.delayed(const Duration(milliseconds: 800));
                          if (mounted) Navigator.pop(context, true);
                        } else {
                          // 等待几秒再试一次
                          await Future.delayed(const Duration(seconds: 2));
                          final retry = await _cookieService.extractCookies(controller);
                          if (retry) {
                            _success = true;
                            setState(() {});
                            await Future.delayed(const Duration(milliseconds: 800));
                            if (mounted) Navigator.pop(context, true);
                          }
                        }
                      }
                    },
                    onReceivedError: (controller, request, error) {
                      // 忽略部分加载错误
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '获取 Cookie 失败',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              setState(() {
                _error = null;
                _isLoading = true;
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
