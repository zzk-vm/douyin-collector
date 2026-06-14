import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Cookie 管理服务
///
/// 通过 WebView 获取抖音的真实浏览器 cookie，用于后续 API 请求。
class CookieService {
  static final CookieService _instance = CookieService._internal();
  factory CookieService() => _instance;
  CookieService._internal();

  String? _cookieString;
  bool _hasInitialized = false;
  final List<void Function()> _onReadyCallbacks = [];

  bool get hasCookies => _cookieString != null;

  /// 注册 cookie 就绪回调
  void onReady(void Function() callback) {
    if (_hasInitialized) {
      callback();
    } else {
      _onReadyCallbacks.add(callback);
    }
  }

  /// 从 WebView 提取 cookie
  Future<bool> extractCookies(InAppWebViewController controller) async {
    try {
      // 使用 flutter_inappwebview 的 CookieManager 获取所有 cookie
      final cookies = await CookieManager.instance().getCookies(
        url: WebUri('https://www.douyin.com'),
      );

      if (cookies.isEmpty) {
        // 尝试从 JavaScript 获取
        final jsResult = await controller.evaluateJavascript(
          source: 'document.cookie',
        );
        if (jsResult != null && jsResult.isNotEmpty) {
          _cookieString = jsResult;
        } else {
          return false;
        }
      } else {
        // 将所有 cookie 拼接成字符串
        _cookieString =
            cookies.map((c) => '${c.name}=${c.value}').join('; ');
      }

      _hasInitialized = true;
      _notifyReady();
      return true;
    } catch (e) {
      debugPrint('CookieService: 提取 cookie 失败: $e');
      return false;
    }
  }

  /// 手动设置 cookie（用于测试或从存储恢复）
  void setCookies(String cookieStr) {
    _cookieString = cookieStr;
    _hasInitialized = true;
    _notifyReady();
  }

  /// 获取 cookie 字符串
  String? get cookieString => _cookieString;

  /// 获取用于 Dio 请求的 Cookie 头
  String? get cookieHeader => _cookieString;

  /// 清除 cookie
  void clear() {
    _cookieString = null;
    _hasInitialized = false;
  }

  void _notifyReady() {
    for (final cb in _onReadyCallbacks) {
      cb();
    }
    _onReadyCallbacks.clear();
  }
}
