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
    // 执行积压的任务
    for (final task in _pendingTasks) {
      task();
    }
    _pendingTasks.clear();
  }

  /// 通过 WebView 的 fetch 发起 API 请求（同源，天然带 cookie）
  Future<Map<String, dynamic>?> fetchJson(String path,
      {Map<String, String>? queryParams}) async {
    if (_controller == null) return null;

    // 构建 URL
    final buffer = StringBuffer('https://www.douyin.com$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      buffer.write('?');
      buffer.write(queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&'));
    }
    final url = buffer.toString();

    try {
      final result = await _controller!.evaluateJavascript(source: '''
        (async function() {
          try {
            const resp = await fetch('$url', {
              headers: {
                'Accept': 'application/json, text/plain, */*',
                'Referer': 'https://www.douyin.com/'
              }
            });
            return await resp.text();
          } catch(e) {
            return 'FETCH_ERROR: ' + e.toString();
          }
        })()
      ''');

      if (result == null) return null;

      final str = result.toString();
      if (str.startsWith('FETCH_ERROR:')) {
        debugPrint('WebView fetch error: $str');
        return null;
      }

      final data = json.decode(str);
      if (data is Map<String, dynamic>) return data;
      return null;
    } catch (e) {
      debugPrint('WebViewApiController error: $e');
      return null;
    }
  }

  /// 等待 WebView 就绪后执行
  Future<void> onReady(void Function() callback) async {
    if (_ready) {
      callback();
    } else {
      _pendingTasks.add(callback);
    }
  }
}

/// 隐藏的 WebView（放在页面底层，用户看不到）
///
/// 用于在真实浏览器环境中执行 API 请求，获取有效的 cookie 和指纹。
class HiddenWebView extends StatefulWidget {
  const HiddenWebView({super.key});

  @override
  State<HiddenWebView> createState() => _HiddenWebViewState();
}

class _HiddenWebViewState extends State<HiddenWebView> {
  @override
  void initState() {
    super.initState();
    // 5 秒超时就绪通知
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
        // 关闭一切可能弹出 UI 的功能
        useShouldOverrideUrlLoading: false,
        useOnDownloadStart: false,
        disableHorizontalScroll: true,
        disableVerticalScroll: true,
        allowFileAccess: false,
      ),
      onWebViewCreated: (c) {
        // 注册到全局控制器
        WebViewApiController().setController(c);
      },
      onReceivedError: (c, r, e) {
        debugPrint('HiddenWebView error: ${e.description}');
      },
    );
  }
}
