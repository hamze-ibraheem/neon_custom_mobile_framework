import 'package:neon_framework/neon.dart';
import 'containment_screen.dart';
import 'input_screen.dart';

class ShowcaseApp extends StatefulWidget {
  const ShowcaseApp({super.key});

  @override
  NeonState<ShowcaseApp> createState() => ShowcaseAppState();
}

class ShowcaseAppState extends NeonState<ShowcaseApp> {
  int currentIndex = 0;

  @override
  NeonWidget build(NeonBuildContext context) {
    return Column(
      children: [
        AppBar(
          title: Text(_getTitle(currentIndex)),
          variant: AppBarVariant.large,
          actions: [
            Badge(
              label: const Text('3'),
              child: const IconButton(
                icon: Text('🔔'),
                variant: IconButtonVariant.standard,
              ),
            ),
          ],
        ),
        Expanded(
          child: Container(
            color: NeonColor.grey,
            padding: const NeonEdgeInsets.all(16),
            child: _getScreen(currentIndex),
          ),
        ),
        NavigationBar(
          key: 'main_nav',
          selectedIndex: currentIndex,
          destinations: const [
            NavigationDestination(icon: Text('🏠'), label: 'Home'),
            NavigationDestination(icon: Text('🔘'), label: 'Interact'),
            NavigationDestination(icon: Text('⚙️'), label: 'Controls'),
            NavigationDestination(icon: Text('📊'), label: 'Values'),
            NavigationDestination(icon: Text('🚀'), label: 'Advanced'),
            NavigationDestination(icon: Text('🃏'), label: 'Cards'),
            NavigationDestination(icon: Text('📝'), label: 'Input'),
          ],
          onDestinationSelected: (index) {
            setState(() {
              currentIndex = index;
            });
          },
        ),
      ],
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Interaction';
      case 2:
        return 'Selection Controls';
      case 3:
        return 'Input Values';
      case 4:
        return 'Advanced Features';
      case 5:
        return 'Containment';
      case 6:
        return 'Input & Search';
      default:
        return 'Showcase';
    }
  }

  NeonWidget _getScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const InteractionScreen();
      case 2:
        return const ControlsScreen();
      case 3:
        return const ValuesScreen();
      case 4:
        return const AdvancedScreen();
      case 5:
        return const ContainmentScreen();
      case 6:
        return const InputScreen();
      default:
        return const Center(child: Text('Coming Soon'));
    }
  }
}

class DashboardScreen extends NeonWidget {
  const DashboardScreen({super.key});

  @override
  NeonWidget build(NeonBuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Welcome back, Hamza!',
            style:
                NeonTextStyle(fontSize: 22, fontWeight: NeonFontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatCard('Tasks', '12', NeonColor.blue),
            _buildStatCard('Alerts', '3', NeonColor.red),
            _buildStatCard('Mails', '8', NeonColor.green),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Recent Activity',
            style:
                NeonTextStyle(fontSize: 18, fontWeight: NeonFontWeight.bold)),
        const SizedBox(height: 8),
        const Container(
          color: NeonColor(0xFFF5F5F5),
          padding: NeonEdgeInsets.all(12),
          width: double.infinity,
          child: Text('System Update: Neon Framework v0.2.0 is now live!'),
        ),
      ],
    );
  }

  NeonWidget _buildStatCard(String title, String value, NeonColor color) {
    return Container(
      width: 100,
      padding: const NeonEdgeInsets.all(12),
      color: color,
      child: Column(
        children: [
          Text(value,
              style: const NeonTextStyle(
                  fontSize: 24,
                  color: NeonColor.white,
                  fontWeight: NeonFontWeight.bold)),
          Text(title,
              style: const NeonTextStyle(fontSize: 12, color: NeonColor.white)),
        ],
      ),
    );
  }
}

class InteractionScreen extends StatefulWidget {
  const InteractionScreen({super.key});

  @override
  NeonState<InteractionScreen> createState() => InteractionScreenState();
}

class InteractionScreenState extends NeonState<InteractionScreen> {
  int segmentedIndex = 0;
  bool isFilterSelected = false;

  @override
  NeonWidget build(NeonBuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FilledButton(
              key: 'btn_filled',
              onPressed: () => print('Filled button pressed'),
              child: const Text('Filled'),
            ),
            ElevatedButton(
              key: 'btn_elevated',
              onPressed: () => print('Elevated button pressed'),
              child: const Text('Elevated'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton(
              key: 'btn_outlined',
              onPressed: () => print('Outlined button pressed'),
              child: const Text('Outlined'),
            ),
            TextButton(
              key: 'btn_text',
              onPressed: () => print('Text button pressed'),
              child: const Text('Text'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Chips',
            style: NeonTextStyle(fontWeight: NeonFontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ActionChip(
              key: 'action_chip',
              label: const Text('Action'),
              onPressed: () => print('Action Chip Pressed'),
            ),
            const SizedBox(width: 8),
            FilterChip(
              key: 'filter_chip',
              label: const Text('Filter'),
              selected: isFilterSelected,
              onSelected: (val) => setState(() => isFilterSelected = val),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SegmentedButton(
          key: 'segmented_btn',
          segments: const [Text('Day'), Text('Week'), Text('Month')],
          selectedIndex: segmentedIndex,
          onSelectionChanged: (i) => setState(() => segmentedIndex = i),
        ),
      ],
    );
  }
}

class ControlsScreen extends StatefulWidget {
  const ControlsScreen({super.key});

  @override
  NeonState<ControlsScreen> createState() => ControlsScreenState();
}

class ControlsScreenState extends NeonState<ControlsScreen> {
  bool switchVal = true;
  bool checkboxVal = false;
  int radioVal = 1;

  @override
  NeonWidget build(NeonBuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Enable Notifications'),
            const Spacer(),
            Switch(
                key: 'switch_notifications',
                value: switchVal,
                onChanged: (val) => setState(() => switchVal = val)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
                key: 'checkbox_terms',
                value: checkboxVal,
                onChanged: (val) => setState(() => checkboxVal = val ?? false)),
            const SizedBox(width: 8),
            const Text('Accept Terms and Conditions'),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Select Theme',
            style: NeonTextStyle(fontWeight: NeonFontWeight.bold)),
        Row(
          children: [
            Radio<int>(
                key: 'radio_light',
                value: 1,
                groupValue: radioVal,
                onChanged: (v) => setState(() => radioVal = v!)),
            const Text('Light'),
            const SizedBox(width: 16),
            Radio<int>(
                key: 'radio_dark',
                value: 2,
                groupValue: radioVal,
                onChanged: (v) => setState(() => radioVal = v!)),
            const Text('Dark'),
          ],
        ),
      ],
    );
  }
}

class ValuesScreen extends StatefulWidget {
  const ValuesScreen({super.key});

  @override
  NeonState<ValuesScreen> createState() => ValuesScreenState();
}

class ValuesScreenState extends NeonState<ValuesScreen> {
  double sliderVal = 0.5;
  NeonRangeValues rangeValues = const NeonRangeValues(0.2, 0.8);

  @override
  NeonWidget build(NeonBuildContext context) {
    return Column(
      children: [
        const Text('Volume'),
        Slider(
          key: 'slider_volume',
          value: sliderVal,
          onChanged: (v) => setState(() => sliderVal = v),
          label: '${(sliderVal * 100).toInt()}%',
        ),
        const SizedBox(height: 32),
        const Text('Price Range'),
        RangeSlider(
          key: 'range_slider_price',
          values: rangeValues,
          onChanged: (v) => setState(() => rangeValues = v),
          min: 0.0,
          max: 100.0,
        ),
        Text(
            'Range: ${rangeValues.start.toInt()} - ${rangeValues.end.toInt()}'),
      ],
    );
  }
}

class AdvancedScreen extends NeonWidget {
  const AdvancedScreen({super.key});

  @override
  NeonWidget build(NeonBuildContext context) {
    return Column(
      children: [
        const Text('Layered Layout (Stack)',
            style: NeonTextStyle(fontWeight: NeonFontWeight.bold)),
        const SizedBox(height: 16),
        Stack(
          children: [
            Container(width: 200, height: 100, color: NeonColor.blue),
            Positioned(
              left: 20,
              top: 20,
              child: Container(width: 50, height: 50, color: NeonColor.red),
            ),
            const Center(
                child: Text('Layered',
                    style: NeonTextStyle(color: NeonColor.white))),
          ],
        ),
        const SizedBox(height: 32),
        const Text('Remote SDUI Component',
            style: NeonTextStyle(fontWeight: NeonFontWeight.bold)),
        const SizedBox(height: 8),
        const RemoteWidget(url: 'http://localhost:8080/remote-demo'),
      ],
    );
  }
}
