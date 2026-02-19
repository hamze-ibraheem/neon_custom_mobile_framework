import 'package:neon_framework/neon.dart';

class InfoProgressScreen extends StatefulWidget {
  const InfoProgressScreen({super.key});

  @override
  NeonState<InfoProgressScreen> createState() => InfoProgressScreenState();
}

class InfoProgressScreenState extends NeonState<InfoProgressScreen> {
  double linearProgress = 0.65;
  double circularProgress = 0.4;
  bool showSnackBar = false;
  String snackMessage = 'Item saved successfully';

  @override
  NeonWidget build(NeonBuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ListTile',
              style: NeonTextStyle(fontSize: 18, fontWeight: NeonFontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            key: 'lt_inbox',
            leading: const Text('📥'),
            title: const Text('Inbox'),
            subtitle: const Text('3 new messages'),
            trailing: const Text('3'),
            onTap: () => setState(() {
              snackMessage = 'Inbox tapped';
              showSnackBar = true;
            }),
          ),
          ListTile(
            key: 'lt_sent',
            leading: const Text('📤'),
            title: const Text('Sent'),
            subtitle: const Text('Last sent 2 hours ago'),
            onTap: () => setState(() {
              snackMessage = 'Sent tapped';
              showSnackBar = true;
            }),
          ),
          ListTile(
            key: 'lt_drafts',
            leading: const Text('📝'),
            title: const Text('Drafts'),
            trailing: const Text('1'),
            dense: true,
            onTap: () => setState(() {
              snackMessage = 'Drafts tapped';
              showSnackBar = true;
            }),
          ),
          const SizedBox(height: 16),
          const Text('Progress Indicators',
              style: NeonTextStyle(fontSize: 18, fontWeight: NeonFontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Linear (determinate)'),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            key: 'lp_determinate',
            value: linearProgress,
          ),
          const SizedBox(height: 12),
          const Text('Linear (indeterminate)'),
          const SizedBox(height: 4),
          const LinearProgressIndicator(
            key: 'lp_indeterminate',
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  CircularProgressIndicator(
                    key: 'cp_determinate',
                    value: circularProgress,
                    size: 48,
                    strokeWidth: 5,
                  ),
                  const SizedBox(height: 4),
                  const Text('40%', style: NeonTextStyle(fontSize: 12)),
                ],
              ),
              const Column(
                children: [
                  CircularProgressIndicator(
                    key: 'cp_indeterminate',
                    size: 48,
                    strokeWidth: 5,
                  ),
                  SizedBox(height: 4),
                  Text('Loading', style: NeonTextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Tooltip',
              style: NeonTextStyle(fontSize: 18, fontWeight: NeonFontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Tooltip(
                key: 'tooltip_save',
                message: 'Save your changes',
                child: FilledButton(
                  key: 'btn_save_tooltip',
                  onPressed: () {},
                  child: const Text('Save'),
                ),
              ),
              Tooltip(
                key: 'tooltip_delete',
                message: 'Delete this item permanently',
                preferBelow: false,
                child: OutlinedButton(
                  key: 'btn_del_tooltip',
                  onPressed: () {},
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('SnackBar',
              style: NeonTextStyle(fontSize: 18, fontWeight: NeonFontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton(
                key: 'btn_show_snack',
                onPressed: () => setState(() {
                  snackMessage = 'Item archived successfully';
                  showSnackBar = true;
                }),
                child: const Text('Show SnackBar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('ListView',
              style: NeonTextStyle(fontSize: 18, fontWeight: NeonFontWeight.bold)),
          const SizedBox(height: 8),
          ListView.builder(
            key: 'lv_demo',
            itemCount: 5,
            shrinkWrap: true,
            itemBuilder: (i) => ListTile(
              key: 'lv_item_$i',
              leading: Text('${i + 1}'),
              title: Text('List Item ${i + 1}'),
              subtitle: const Text('Subtitle text'),
              onTap: () => setState(() {
                snackMessage = 'Tapped item ${i + 1}';
                showSnackBar = true;
              }),
            ),
          ),
          SnackBar(
            key: 'demo_snackbar',
            content: Text(snackMessage),
            visible: showSnackBar,
            actionLabel: 'Undo',
            showCloseIcon: true,
            behavior: SnackBarBehavior.floating,
            onAction: () => setState(() {
              snackMessage = 'Undo pressed!';
            }),
            onDismiss: () => setState(() {
              showSnackBar = false;
            }),
          ),
        ],
      ),
    );
  }
}
