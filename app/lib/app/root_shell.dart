import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home/home_screen.dart';
import '../journal/journal_screen.dart';
import '../more/more_screen.dart';
import '../reader/reader_screen.dart';
import 'app_model.dart';

/// The tab shell: Home · Bible · Journal · More. A bottom bar on phones, a
/// side rail on wide screens; every tab stays alive between visits.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  final _tabsKey = GlobalKey();
  final _moreNav = GlobalKey<NavigatorState>();
  int _moreReset = 0;

  static const _destinations = [
    (AppTab.home, 'Home', Icons.home_outlined, Icons.home),
    (AppTab.bible, 'Bible', Icons.menu_book_outlined, Icons.menu_book),
    (AppTab.journal, 'Journal', Icons.bookmark_border, Icons.bookmark),
    (AppTab.more, 'More', Icons.grid_view_outlined, Icons.grid_view),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppModel>();
    if (app.moreReset != _moreReset) {
      _moreReset = app.moreReset;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _moreNav.currentState?.popUntil((r) => r.isFirst),
      );
    }
    final tabs = IndexedStack(
      key: _tabsKey,
      index: app.tab.index,
      children: [
        const HomeScreen(),
        const ReaderScreen(),
        const JournalScreen(),
        Navigator(
          key: _moreNav,
          onGenerateRoute: (_) =>
              MaterialPageRoute<void>(builder: (_) => const MoreScreen()),
        ),
      ],
    );
    void select(int i) => app.selectTab(AppTab.values[i]);

    if (MediaQuery.sizeOf(context).width >= 840) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: app.tab.index,
              onDestinationSelected: select,
              labelType: NavigationRailLabelType.all,
              groupAlignment: -0.85,
              destinations: [
                for (final (_, label, icon, selected) in _destinations)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: Text(label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: tabs),
          ],
        ),
      );
    }
    return Scaffold(
      body: tabs,
      bottomNavigationBar: NavigationBar(
        selectedIndex: app.tab.index,
        onDestinationSelected: select,
        height: 64,
        destinations: [
          for (final (_, label, icon, selected) in _destinations)
            NavigationDestination(
              icon: Icon(icon),
              selectedIcon: Icon(selected),
              label: label,
            ),
        ],
      ),
    );
  }
}
