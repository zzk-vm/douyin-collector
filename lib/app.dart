import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'services/webview_api_provider.dart';
import 'models/view_style.dart';
import 'screens/home_page.dart';
import 'screens/creators_page.dart';

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
    const seedColor = Color(0xFFE8838A);

    switch (style) {
      case ViewStyle.minimal:
        final cs = ColorScheme.fromSeed(
            seedColor: seedColor, brightness: Brightness.dark);
        return ThemeData(
          useMaterial3: true,
          colorScheme: cs,
          scaffoldBackgroundColor: Colors.black,
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.black,
            indicatorColor: cs.primary.withOpacity(0.2),
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
        );
      default:
        final cs = ColorScheme.fromSeed(
            seedColor: seedColor, brightness: Brightness.light);
        return ThemeData(
          useMaterial3: true,
          colorScheme: cs,
          appBarTheme: AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: cs.surface,
            foregroundColor: cs.onSurface,
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: cs.surface,
            indicatorColor: cs.primaryContainer,
          ),
        );
    }
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  final _pages = const [HomePage(), CreatorsPage()];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.viewStyle == ViewStyle.minimal;

    return Stack(
      children: [
        const Positioned.fill(child: HiddenWebView()),
        Scaffold(
          body: IndexedStack(index: _currentIndex, children: _pages),
          bottomNavigationBar: NavigationBar(
            backgroundColor: isDark ? Colors.black : null,
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
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
