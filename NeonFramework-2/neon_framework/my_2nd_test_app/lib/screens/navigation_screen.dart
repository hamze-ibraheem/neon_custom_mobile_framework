import 'package:neon_framework/neon.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  NeonState<NavigationScreen> createState() => NavigationScreenState();
}

class NavigationScreenState extends NeonState<NavigationScreen> {
  int tabIndex = 0;
  int navIndex = 0;

  @override
  NeonWidget build(NeonBuildContext context) {
    return Column(
      children: [
        const AppBar(
          title: Text('M3 Navigation'),
          variant: AppBarVariant.large,
        ),
        TabBar(
          key: 'tab_bar',
          tabs: const [
            Tab(text: 'Home'),
            Tab(text: 'Search'),
            Tab(text: 'Profile'),
          ],
          selectedIndex: tabIndex,
          onTap: (index) {
            setState(() {
              tabIndex = index;
            });
          },
        ),
        Container(
          height: 300,
          color: NeonColor.white,
          child: Text(_getContentForTab(tabIndex)),
        ),
        NavigationBar(
          key: 'nav_bar',
          selectedIndex: navIndex,
          destinations: const [
            NavigationDestination(
              icon: Text('🏠'),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Text('🔍'),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Text('👤'),
              label: 'Account',
            ),
          ],
          onDestinationSelected: (index) {
            setState(() {
              navIndex = index;
            });
          },
        ),
      ],
    );
  }

  String _getContentForTab(int index) {
    switch (index) {
      case 0:
        return 'Home Content';
      case 1:
        return 'Search Content';
      case 2:
        return 'Profile Content';
      default:
        return 'Content Area';
    }
  }
}
