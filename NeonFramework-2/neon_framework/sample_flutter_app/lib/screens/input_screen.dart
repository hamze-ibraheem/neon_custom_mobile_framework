import 'package:neon_framework/neon.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  NeonState<InputScreen> createState() => InputScreenState();
}

class InputScreenState extends NeonState<InputScreen> {
  String nameValue = '';
  String emailValue = '';
  String bioValue = '';
  String searchValue = '';
  bool searchExpanded = false;
  int menuBarIndex = -1;

  @override
  NeonWidget build(NeonBuildContext context) {
    final allItems = ['Apple', 'Banana', 'Cherry', 'Date', 'Elderberry', 'Fig', 'Grape'];
    final filtered = searchValue.isEmpty
        ? <String>[]
        : allItems
            .where((item) =>
                item.toLowerCase().contains(searchValue.toLowerCase()))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Text Fields',
            style: NeonTextStyle(fontSize: 18, fontWeight: NeonFontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          key: 'tf_name',
          value: nameValue,
          labelText: 'Name',
          hintText: 'Enter your name',
          helperText: 'First and last name',
          onChanged: (v) => setState(() => nameValue = v),
        ),
        const SizedBox(height: 8),
        TextField.outlined(
          key: 'tf_email',
          value: emailValue,
          labelText: 'Email',
          hintText: 'user@example.com',
          errorText: emailValue.isNotEmpty && !emailValue.contains('@')
              ? 'Please enter a valid email'
              : null,
          onChanged: (v) => setState(() => emailValue = v),
        ),
        const SizedBox(height: 8),
        TextField(
          key: 'tf_bio',
          value: bioValue,
          labelText: 'Bio',
          hintText: 'Tell us about yourself...',
          maxLines: 3,
          onChanged: (v) => setState(() => bioValue = v),
        ),
        const SizedBox(height: 16),
        const Text('Search',
            style: NeonTextStyle(fontSize: 18, fontWeight: NeonFontWeight.bold)),
        const SizedBox(height: 8),
        SearchAnchor(
          key: 'search_fruits',
          expanded: searchExpanded,
          searchBar: SearchBar(
            hintText: 'Search fruits...',
            value: searchValue,
          ),
          suggestions: filtered.map((f) => Text(f)).toList(),
          onSearch: (v) => setState(() {
            searchValue = v;
            searchExpanded = v.isNotEmpty;
          }),
          onToggle: () => setState(() => searchExpanded = !searchExpanded),
        ),
        const SizedBox(height: 16),
        const Text('Menu Bar',
            style: NeonTextStyle(fontSize: 18, fontWeight: NeonFontWeight.bold)),
        const SizedBox(height: 8),
        MenuBar(
          key: 'menubar_demo',
          selectedIndex: menuBarIndex,
          items: [
            MenuItem(
              label: 'File',
              onPressed: () => setState(() => menuBarIndex = 0),
            ),
            MenuItem(
              label: 'Edit',
              onPressed: () => setState(() => menuBarIndex = 1),
            ),
            MenuItem(
              label: 'View',
              onPressed: () => setState(() => menuBarIndex = 2),
            ),
            MenuItem(
              label: 'Help',
              onPressed: () => setState(() => menuBarIndex = 3),
            ),
          ],
          onItemSelected: (i) => setState(() => menuBarIndex = i),
        ),
        if (menuBarIndex >= 0)
          Card.filled(
            child: Text('Selected: ${['File', 'Edit', 'View', 'Help'][menuBarIndex]}',
                style: const NeonTextStyle(fontSize: 14)),
          ),
        if (nameValue.isNotEmpty || emailValue.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('Preview',
                  style: NeonTextStyle(
                      fontSize: 18, fontWeight: NeonFontWeight.bold)),
              const SizedBox(height: 8),
              Card.outlined(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (nameValue.isNotEmpty)
                      Text('Name: $nameValue',
                          style: const NeonTextStyle(fontSize: 14)),
                    if (emailValue.isNotEmpty)
                      Text('Email: $emailValue',
                          style: const NeonTextStyle(fontSize: 14)),
                    if (bioValue.isNotEmpty)
                      Text('Bio: $bioValue',
                          style: const NeonTextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}
