import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'services/webview_api_provider.dart';
import 'screens/home_page.dart';
import 'screens/creators_page.dart';

/// 抖音内容收集器 - Material App
class DouyinCollectorApp extends StatelessWidget {
  const DouyinCollectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '抖音内容收集器',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const MainScaffold(),
    );
  }

  ThemeData _buildTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1E88E5),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
    );
  }
}

/// 主框架：底部导航 + 页面切换
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final _pages = const [
    HomePage(),
    CreatorsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Stack(
      children: [
        // 隐藏的 WebView（在底层，用于浏览器级 API 请求）
        const Positioned.fill(child: HiddenWebView()),

        // 正式 UI
        Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: [
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: state.isSyncing,
                  child: const Icon(Icons.rss_feed_outlined),
                ),
                selectedIcon: const Icon(Icons.rss_feed),
                label: '信息流',
              ),
              const NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: '博主',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
