import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'services/webview_api_provider.dart';
import 'models/view_style.dart';
import 'screens/home_page.dart';
import 'screens/creators_page.dart';

/// 抖音内容收集器 - Material App
class DouyinCollectorApp extends StatelessWidget {
  const DouyinCollectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return MaterialApp(
          title: '抖音内容收集器',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(state.viewStyle),
          home: const MainScaffold(),
        );
      },
    );
  }

  ThemeData _buildTheme(ViewStyle style) {
    // 柔和粉色系主色
    const seedColor = Color(0xFFE8838A); // 玫瑰粉

    switch (style) {
      case ViewStyle.minimal:
        // 纯黑极简模式：深色主题
        final colorScheme = ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        );
        return ThemeData(
          useMaterial3: true,
          colorScheme: colorScheme,
          scaffoldBackgroundColor: Colors.black,
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.black,
            indicatorColor: colorScheme.primary.withOpacity(0.2),
          ),
          appBarTheme: AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          cardTheme: const CardThemeData(
            color: Color(0xFF1A1A1A),
            elevation: 0,
          ),
        );

      default:
        // 杂志 / 玻璃模式：浅色主题
        final colorScheme = ColorScheme.fromSeed(
          seedColor: seedColor,
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
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: colorScheme.surface,
            indicatorColor: colorScheme.primaryContainer,
          ),
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
    }
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
    final isDark = state.viewStyle == ViewStyle.minimal;

    return Stack(
      children: [
        const Positioned.fill(child: HiddenWebView()),
        Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: NavigationBar(
            backgroundColor: isDark ? Colors.black : null,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: [
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: state.isSyncing,
                  child: Icon(Icons.rss_feed_outlined,
                      color: isDark ? Colors.white54 : null),
                ),
                selectedIcon: Icon(Icons.rss_feed,
                    color: isDark ? Colors.white : null),
                label: '信息流',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline,
                    color: isDark ? Colors.white54 : null),
                selectedIcon: Icon(Icons.people,
                    color: isDark ? Colors.white : null),
                label: '博主',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
