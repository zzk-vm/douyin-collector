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

  bool get hasCookies => _cookieString != null;
  String? get cookieHeader => _cookieString;

  /// 从 WebView 提取 cookie
  /// 等待 [delayMs] 毫秒让 JS 执行完毕后再提取
  Future<bool> extractCookies(InAppWebViewController controller,
      {int delayMs = 2000}) async {
    // 先延迟一下，等 JavaScript 设置完 cookie
    await Future.delayed(Duration(milliseconds: delayMs));

    try {
      // 方法1: 用 flutter_inappwebview 的 CookieManager（能获取 HttpOnly cookie）
      try {
        final cookies = await CookieManager.instance().getCookies(
              url: WebUri('https://www.douyin.com'),
            );
        if (cookies.isNotEmpty) {
          _cookieString =
              cookies.map((c) => '${c.name}=${c.value}').join('; ');
          _hasInitialized = true;
          debugPrint('CookieService: CookieManager 获取到 ${cookies.length} 个 cookie');
          return true;
        }
      } catch (e) {
        debugPrint('CookieService: CookieManager 失败: $e');
      }

      // 方法2: 尝试 .douyin.com 域
      try {
        final cookies = await CookieManager.instance().getCookies(
              url: WebUri('https://.douyin.com'),
            );
        if (cookies.isNotEmpty) {
          _cookieString =
              cookies.map((c) => '${c.name}=${c.value}').join('; ');
          _hasInitialized = true;
          debugPrint('CookieService: .douyin.com 获取到 ${cookies.length} 个 cookie');
          return true;
        }
      } catch (_) {}

      // 方法3: 尝试从 JavaScript document.cookie 获取
      try {
        final jsResult = await controller.evaluateJavascript(
          source: 'document.cookie',
        );
        if (jsResult != null &&
            jsResult is String &&
            jsResult.isNotEmpty &&
            jsResult.contains('=')) {
          _cookieString = jsResult;
          _hasInitialized = true;
          debugPrint('CookieService: JS 获取到 cookie: $jsResult');
          return true;
        }
      } catch (e) {
        debugPrint('CookieService: JS 获取 cookie 失败: $e');
      }

      // 方法4: 尝试跳转到 douyin.com 再试（重定向可能会设置 cookie）
      try {
        await controller.loadUrl(
          urlRequest: URLRequest(url: WebUri('https://www.douyin.com/')),
        );
        await Future.delayed(const Duration(seconds: 3));
        final cookies = await CookieManager.instance().getCookies(
              url: WebUri('https://www.douyin.com'),
            );
        if (cookies.isNotEmpty) {
          _cookieString =
              cookies.map((c) => '${c.name}=${c.value}').join('; ');
          _hasInitialized = true;
          return true;
        }
      } catch (_) {}

      return false;
    } catch (e) {
      debugPrint('CookieService: 总体失败: $e');
      return false;
    }
  }

  /// 手动设置 cookie
  void setCookies(String cookieStr) {
    _cookieString = cookieStr;
    _hasInitialized = true;
    debugPrint('CookieService: 手动设置为: $cookieStr');
  }

  /// 清除 cookie
  void clear() {
    _cookieString = null;
    _hasInitialized = false;
  }
}
