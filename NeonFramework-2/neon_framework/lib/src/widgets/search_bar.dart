import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

class SearchBar extends NeonWidget {
  final String hintText;
  final String value;
  final NeonWidget? leading;
  final NeonWidget? trailing;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool enabled;

  const SearchBar({
    super.key,
    this.hintText = 'Search...',
    this.value = '',
    this.leading,
    this.trailing,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(type: 'SearchBar', key: key);
  }
}

class SearchAnchor extends NeonWidget {
  final SearchBar searchBar;
  final bool isFullScreen;
  final bool expanded;
  final List<NeonWidget> suggestions;
  final void Function(String)? onSearch;
  final void Function()? onToggle;

  const SearchAnchor({
    super.key,
    required this.searchBar,
    this.isFullScreen = false,
    this.expanded = false,
    this.suggestions = const [],
    this.onSearch,
    this.onToggle,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(type: 'SearchAnchor', key: key);
  }
}
