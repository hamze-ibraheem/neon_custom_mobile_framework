const Map<String, String> flutterToNeonWidgetMap = {
  'Container': 'Container',
  'Text': 'Text',
  'ElevatedButton': 'FilledButton',
  'TextButton': 'TextButton',
  'OutlinedButton': 'OutlinedButton',
  'FilledButton': 'FilledButton',
  'IconButton': 'IconButton',
  'FloatingActionButton': 'FloatingActionButton',
  'Column': 'Column',
  'Row': 'Row',
  'Stack': 'Stack',
  'Center': 'Center',
  'Padding': 'Padding',
  'SizedBox': 'SizedBox',
  'Expanded': 'Expanded',
  'Spacer': 'Spacer',
  'Scaffold': 'Scaffold',
  'AppBar': 'AppBar',
  'NavigationBar': 'NavigationBar',
  'NavigationDestination': 'NavigationDestination',
  'Card': 'Card',
  'Dialog': 'Dialog',
  'AlertDialog': 'Dialog',
  'BottomSheet': 'BottomSheet',
  'TextField': 'NeonTextField',
  'SearchBar': 'NeonSearchBar',
  'ListTile': 'ListTile',
  'ListView': 'ListView',
  'SingleChildScrollView': 'SingleChildScrollView',
  'CustomScrollView': 'CustomScrollView',
  'SliverList': 'SliverList',
  'SliverAppBar': 'SliverAppBar',
  'LinearProgressIndicator': 'LinearProgressIndicator',
  'CircularProgressIndicator': 'CircularProgressIndicator',
  'Tooltip': 'Tooltip',
  'SnackBar': 'SnackBar',
  'Switch': 'Switch',
  'Checkbox': 'Checkbox',
  'Radio': 'Radio',
  'Slider': 'Slider',
  'Chip': 'Chip',
  'ActionChip': 'ActionChip',
  'FilterChip': 'FilterChip',
  'InputChip': 'InputChip',
  'Badge': 'Badge',
  'SegmentedButton': 'SegmentedButton',
  'MenuAnchor': 'MenuAnchor',
  'MenuBar': 'NeonMenuBar',
  'DropdownMenuEntry': 'DropdownMenuEntry',
};

const Map<String, String> flutterToNeonEnumMap = {
  'MainAxisAlignment': 'MainAxisAlignment',
  'CrossAxisAlignment': 'CrossAxisAlignment',
  'MainAxisSize': 'MainAxisSize',
  'TextAlign': 'NeonTextAlign',
  'FontWeight': 'NeonFontWeight',
  'TextStyle': 'NeonTextStyle',
  'EdgeInsets': 'NeonEdgeInsets',
  'BoxDecoration': 'NeonBoxDecoration',
  'BorderRadius': 'NeonBorderRadius',
  'Alignment': 'NeonAlignment',
  'Color': 'NeonColor',
  'Colors': 'NeonColors',
  'Icons': 'NeonIcons',
};

const Map<String, String> flutterToNeonImportMap = {
  "package:flutter/material.dart": "package:neon_framework/neon.dart",
  "package:flutter/widgets.dart": "package:neon_framework/neon.dart",
  "package:flutter/cupertino.dart": "package:neon_framework/neon.dart",
  "package:flutter/foundation.dart": "package:neon_framework/neon.dart",
};

const Set<String> flutterBaseClasses = {
  'StatelessWidget',
  'StatefulWidget',
  'State',
};

const Map<String, String> flutterBaseClassMap = {
  'StatelessWidget': 'StatelessWidget',
  'StatefulWidget': 'StatefulWidget',
  'State': 'NeonState',
};

const Map<String, String> flutterMethodMap = {
  'BuildContext': 'NeonBuildContext',
  'Widget': 'NeonWidget',
  'Key': 'String',
  'ValueKey': 'String',
  'GlobalKey': 'String',
};

const Set<String> skipWidgets = {
  'MaterialApp',
  'WidgetsApp',
  'CupertinoApp',
  'Theme',
  'ThemeData',
  'MediaQuery',
  'Navigator',
  'Route',
  'MaterialPageRoute',
};

const Map<String, String> skipReplacements = {
  'MaterialApp': '/* MaterialApp removed - use NeonApp.run() instead */',
  'Theme.of(context)': '/* Theme not needed in Neon */',
  'Navigator.push': '/* Navigation: use Neon navigation instead */',
  'Navigator.pop': '/* Navigation: use Neon navigation instead */',
};
