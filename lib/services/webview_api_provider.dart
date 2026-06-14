import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// WebView API 控制器（单例）
class WebViewApiController {
  static final WebViewApiController _instance = WebViewApiController._();
  factory WebViewApiController() => _instance;
  WebViewApiController._();

  InAppWebViewController? _controller;
  bool _ready = false;
  bool _loading = false; // 防止并发导航

  bool get isReady => _ready;

  void setController(InAppWebViewController c) {
    _controller = c;
    _ready = true;
  }

  /// 从博主页面提取内嵌数据（自动重试）
  Future<Map<String, dynamic>?> extractPageData(String secUid) async {
    if (_controller == null) return null;

    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        // 导航
        await _controller!.loadUrl(
          urlRequest: URLRequest(
            url: WebUri('https://www.douyin.com/user/$secUid'),
          ),
        );

        // 等待加载
        await Future.delayed(Duration(seconds: attempt == 0 ? 6 : 10));

        // 提取数据
        final result = await _controller!.evaluateJavascript(source: '''
          (function() {
            try {
              var s = document.querySelector('script#RENDER_DATA');
              if (s && s.textContent && s.textContent.length > 200) return s.textContent;

              var all = document.querySelectorAll('script');
              for (var i = 0; i < all.length; i++) {
                var t = all[i].textContent || '';
                if (t.includes('aweme_list') && t.length > 1000) return t;
                if (t.includes('userInfo') && t.length > 1000) return t;
              }
              return document.body ? 'LOADED' : 'EMPTY';
            } catch(e) { return 'ERR'; }
          })()
        ''');

        if (result == null) continue;
        final raw = result.toString().trim();

        if (raw == 'LOADED' || raw == 'EMPTY' || raw == 'ERR') {
          if (attempt == 0) continue;
          // 尝试 fetch API 方式
          return await fetchJson('/aweme/v1/web/aweme/post/', queryParams: {
            'sec_user_id': secUid,
            'count': '18',
            'max_cursor': '0',
            'aid': '6383',
            'device_platform': 'webapp',
          });
        }

        // JSON 解析
        try {
          return json.decode(raw) as Map<String, dynamic>;
        } catch (_) {}
        try {
          return json.decode(utf8.decode(base64Decode(raw))) as Map<String, dynamic>;
        } catch (_) {}

        return null;
      } catch (e) {
        debugPrint('extractPageData attempt $attempt: $e');
      }
    }
    return null;
  }

  /// 通过 JavaScript fetch() 发起 API 请求
  Future<Map<String, dynamic>?> fetchJson(String path,
      {Map<String, String>? queryParams}) async {
    if (_controller == null) return null;

    final buffer = StringBuffer('https://www.douyin.com$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      buffer.write('?');
      buffer.write(queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&'));
    }

    try {
      final result = await _controller!.evaluateJavascript(source: '''
        (async function() {
          try {
            var r = await fetch('${buffer.toString()}', {
              headers: {'Accept': 'application/json'}
            });
            return await r.text();
          } catch(e) { return 'FETCH_ERR'; }
        })()
      ''');

      if (result == null) return null;
      final str = result.toString().trim();
      if (str == 'FETCH_ERR') return null;

      return json.decode(str) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}

/// 隐藏的 WebView（放在页面底层）
class HiddenWebView extends StatefulWidget {
  const HiddenWebView({super.key});

  @override
  State<HiddenWebView> createState() => _HiddenWebViewState();
}

class _HiddenWebViewState extends State<HiddenWebView> {
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
