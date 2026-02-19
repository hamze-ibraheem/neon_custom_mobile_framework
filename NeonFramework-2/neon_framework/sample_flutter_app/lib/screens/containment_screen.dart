import 'package:neon_framework/neon.dart';

class ContainmentScreen extends StatefulWidget {
  const ContainmentScreen({super.key});

  @override
  NeonState<ContainmentScreen> createState() => ContainmentScreenState();
}

class ContainmentScreenState extends NeonState<ContainmentScreen> {
  bool showDialog = false;
  bool showFullscreenDialog = false;
  bool showBottomSheet = false;
  int menuIndex = -1;
  bool menuExpanded = false;

  @override
  NeonWidget build(NeonBuildContext context) {
    final widgets = <NeonWidget>[
      const Text('Cards',
          style: NeonTextStyle(fontSize: 18, fontWeight: NeonFontWeight.bold)),
      const SizedBox(height: 8),
      const Card(
        key: 'card_elevated',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Elevated Card',
                style: NeonTextStyle(
                    fontSize: 16, fontWeight: NeonFontWeight.bold)),
            SizedBox(height: 4),
            Text('This card has a shadow elevation.',
                style: NeonTextStyle(fontSize: 14)),
          ],
        ),
      ),
      const Card.filled(
        key: 'card_filled',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filled Card',
                style: NeonTextStyle(
                    fontSize: 16, fontWeight: NeonFontWeight.bold)),
            SizedBox(height: 4),
            Text('This card has a solid fill background.',
                style: NeonTextStyle(fontSize: 14)),
          ],
        ),
      ),
      const Card.outlined(
        key: 'card_outlined',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Outlined Card',
                style: NeonTextStyle(
                    fontSize: 16, fontWeight: NeonFontWeight.bold)),
            SizedBox(height: 4),
            Text('This card has a visible border.',
                style: NeonTextStyle(fontSize: 14)),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const Text('Dialogs & Sheets',
          style: NeonTextStyle(fontSize: 18, fontWeight: NeonFontWeight.bold)),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FilledButton(
            key: 'btn_show_dialog',
            onPressed: () => setState(() => showDialog = true),
            child: const Text('Dialog'),
          ),
          OutlinedButton(
            key: 'btn_show_fullscreen',
            onPressed: () => setState(() => showFullscreenDialog = true),
            child: const Text('Fullscreen'),
          ),
          FilledTonalButton(
            key: 'btn_show_sheet',
            onPressed: () => setState(() => showBottomSheet = true),
            child: const Text('Sheet'),
          ),
        ],
      ),
      const SizedBox(height: 16),
      const Text('Menu',
          style: NeonTextStyle(fontSize: 18, fontWeight: NeonFontWeight.bold)),
      const SizedBox(height: 8),
      MenuAnchor(
        key: 'menu_demo',
        expanded: menuExpanded,
        onOpen: () => setState(() => menuExpanded = true),
        onClose: () => setState(() => menuExpanded = false),
        menuItems: [
          MenuItem(
            label: 'Cut',
            onPressed: () => setState(() {
              menuExpanded = false;
              menuIndex = 0;
            }),
          ),
          MenuItem(
            label: 'Copy',
            onPressed: () => setState(() {
              menuExpanded = false;
              menuIndex = 1;
            }),
          ),
          MenuItem(
            label: 'Paste',
            onPressed: () => setState(() {
              menuExpanded = false;
              menuIndex = 2;
            }),
          ),
        ],
        child: OutlinedButton(
          key: 'menu_trigger',
          onPressed: () {},
          child: Text(menuIndex >= 0
              ? 'Selected: ${['Cut', 'Copy', 'Paste'][menuIndex]}'
              : 'Open Menu'),
        ),
      ),
      Dialog(
        key: 'demo_dialog',
        visible: showDialog,
        title: const Text('Confirm Action'),
        content: const Text(
            'Are you sure you want to proceed? This action cannot be undone.'),
        actions: [
          TextButton(
            key: 'dialog_cancel',
            onPressed: () => setState(() => showDialog = false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: 'dialog_confirm',
            onPressed: () => setState(() => showDialog = false),
            child: const Text('Confirm'),
          ),
        ],
        onDismiss: () => setState(() => showDialog = false),
      ),
      Dialog.fullscreen(
        key: 'demo_fullscreen_dialog',
        visible: showFullscreenDialog,
        title: const Text('Full Screen Dialog'),
        content: const Text(
            'This dialog takes over the entire screen. Perfect for complex workflows on mobile.'),
        onDismiss: () => setState(() => showFullscreenDialog = false),
      ),
      BottomSheet(
        key: 'demo_bottom_sheet',
        visible: showBottomSheet,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bottom Sheet',
                style: NeonTextStyle(
                    fontSize: 20, fontWeight: NeonFontWeight.bold)),
            SizedBox(height: 12),
            Text('Share this content via:',
                style: NeonTextStyle(fontSize: 14)),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('📧 Email'),
                Text('💬 Message'),
                Text('🔗 Link'),
              ],
            ),
          ],
        ),
        onDismiss: () => setState(() => showBottomSheet = false),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
