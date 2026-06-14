import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// WebView API 控制器（单例）
///
/// 通过真实浏览器引擎发请求，绕过抖音的反爬限制。
class WebViewApiController {
  static final WebViewApiController _instance = WebViewApiController._();
  factory WebViewApiController() => _instance;
  WebViewApiController._();

  InAppWebViewController? _controller;
  bool _ready = false;
  final List<void Function()> _pendingTasks = [];

  bool get isReady => _ready;

  /// 由 HiddenWebView 在创建后调用
  void setController(InAppWebViewController c) {
    _controller = c;
    _ready = true;
    for (final task in _pendingTasks) {
      task();
    }
    _pendingTasks.clear();
  }

  /// 从博主页面 HTML 中提取嵌入的数据（RENDER_DATA）
  Future<Map<String, dynamic>?> extractPageData(String secUid) async {
    if (_controller == null) return null;

    try {
      // 1. 导航到博主主页
      await _controller!.loadUrl(
        urlRequest: URLRequest(
          url: WebUri('https://www.douyin.com/user/$secUid'),
        ),
      );

      // 2. 等待页面加载 + JS 执行
      await Future.delayed(const Duration(seconds: 4));

      // 3. 提取 RENDER_DATA
      final result = await _controller!.evaluateJavascript(source: '''
        (function() {
          try {
            var s = document.querySelector('script#RENDER_DATA');
            if (s && s.textContent) return s.textContent;

            var all = document.querySelectorAll('script');
            for (var i = 0; i < all.length; i++) {
              var t = all[i].textContent || '';
              if (t.includes('aweme_list') || t.includes('userInfo')) {
                return t.substring(0, 500000);
              }
            }
            return 'NO_DATA';
          } catch(e) { return 'ERR: ' + e.message; }
        })()
      ''');

      if (result == null) return null;
      final raw = result.toString().trim();
      if (raw == 'NO_DATA' || raw.startsWith('ERR:')) return null;

      // 尝试直接 JSON 解析
      try {
        return json.decode(raw) as Map<String, dynamic>;
      } catch (_) {}

      // 尝试 base64 解码
      try {
        final decoded = utf8.decode(base64Decode(raw));
        return json.decode(decoded) as Map<String, dynamic>;
      } catch (_) {}

      return null;
    } catch (e) {
      debugPrint('extractPageData error: $e');
      return null;
    }
  }

  Future<void> onReady(void Function() callback) async {
    if (_ready) {
      callback();
    } else {
      _pendingTasks.add(callback);
    }
  }
}

/// 隐藏的 WebView（放在页面底层，用户看不到）
class HiddenWebView extends StatefulWidget {
  const HiddenWebView({super.key});

  @override
  State<HiddenWebView> createState() => _HiddenWebViewState();
}

class _HiddenWebViewState extends State<HiddenWebView> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (!WebViewApiController().isReady) {
        debugPrint('HiddenWebView: 加载超时');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrlRequest:
          URLRequest(url: WebUri('https://www.douyin.com/')),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        userAgent:
            'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        cacheEnabled: true,
        useShouldOverrideUrlLoading: false,
        useOnDownloadStart: false,
        disableHorizontalScroll: true,
        disableVerticalScroll: true,
        allowFileAccess: false,
      ),
      onWebViewCreated: (c) {
        WebViewApiController().setController(c);
      },
      onReceivedError: (c, r, e) {
        debugPrint('HiddenWebView error: ${e.description}');
      },
    );
  }
}
