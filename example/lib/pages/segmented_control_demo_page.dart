import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

enum ViewMode { list, grid, compact }

enum SortOrder { nameAsc, nameDesc, dateAsc, dateDesc }

enum FilterOption { all, active, completed, archived }

enum TextAlignOption { left, center, right, justify }

enum FontSizeOption { small, medium, large, extraLarge }

/// Demo page showcasing AdaptiveSegmentedControl features
class SegmentedControlDemoPage extends StatefulWidget {
  const SegmentedControlDemoPage({super.key});

  @override
  State<SegmentedControlDemoPage> createState() =>
      _SegmentedControlDemoPageState();
}

class _SegmentedControlDemoPageState extends State<SegmentedControlDemoPage> {
  ViewMode _viewMode = ViewMode.list;
  SortOrder _sortOrder = SortOrder.nameAsc;
  FilterOption _filter = FilterOption.all;
  TextAlignOption _textAlign = TextAlignOption.left;
  FontSizeOption _fontSize = FontSizeOption.medium;
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Segmented Control',
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final topPadding = PlatformInfo.isIOS ? 100.0 : 16.0;

    return ListView(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: topPadding,
        bottom: 16.0,
      ),
      children: [
        _buildSection(
          context,
          title: 'Basic Controls',
          children: [
            const Text(
              'View Mode',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            AdaptiveSegmentedControl<ViewMode>(
              groupValue: _viewMode,
              onValueChanged: (value) => setState(() => _viewMode = value),
              children: {
                ViewMode.list: _buildSegment(
                  icon: PlatformInfo.isIOS
                      ? CupertinoIcons.list_bullet
                      : Icons.list,
                  label: 'List',
                ),
                ViewMode.grid: _buildSegment(
                  icon: PlatformInfo.isIOS
                      ? CupertinoIcons.square_grid_2x2
                      : Icons.grid_view,
                  label: 'Grid',
                ),
                ViewMode.compact: _buildSegment(
                  icon: PlatformInfo.isIOS
                      ? CupertinoIcons.rectangle_stack
                      : Icons.view_compact,
                  label: 'Compact',
                ),
              },
            ),
            const SizedBox(height: 16),
            _buildPreview('Current view: ${_viewMode.name}'),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          context,
          title: 'Sort & Filter',
          children: [
            const Text(
              'Sort Order',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            AdaptiveSegmentedControl<SortOrder>(
              groupValue: _sortOrder,
              onValueChanged: (value) => setState(() => _sortOrder = value),
              children: {
                SortOrder.nameAsc: _buildTextSegment('Name ↑'),
                SortOrder.nameDesc: _buildTextSegment('Name ↓'),
                SortOrder.dateAsc: _buildTextSegment('Date ↑'),
                SortOrder.dateDesc: _buildTextSegment('Date ↓'),
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Filter',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            AdaptiveSegmentedControl<FilterOption>(
              groupValue: _filter,
              onValueChanged: (value) => setState(() => _filter = value),
              children: {
                FilterOption.all: _buildTextSegment('All'),
                FilterOption.active: _buildTextSegment('Active'),
                FilterOption.completed: _buildTextSegment('Done'),
                FilterOption.archived: _buildTextSegment('Archived'),
              },
            ),
            const SizedBox(height: 16),
            _buildPreview(
              'Sorting: ${_sortOrder.name}\nFilter: ${_filter.name}',
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          context,
          title: 'Text Formatting',
          children: [
            const Text(
              'Text Alignment',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            AdaptiveSegmentedControl<TextAlignOption>(
              groupValue: _textAlign,
              onValueChanged: (value) => setState(() => _textAlign = value),
              children: {
                TextAlignOption.left: _buildIconOnlySegment(
                  PlatformInfo.isIOS
                      ? CupertinoIcons.text_alignleft
                      : Icons.format_align_left,
                ),
                TextAlignOption.center: _buildIconOnlySegment(
                  PlatformInfo.isIOS
                      ? CupertinoIcons.text_aligncenter
                      : Icons.format_align_center,
                ),
                TextAlignOption.right: _buildIconOnlySegment(
                  PlatformInfo.isIOS
                      ? CupertinoIcons.text_alignright
                      : Icons.format_align_right,
                ),
                TextAlignOption.justify: _buildIconOnlySegment(
                  PlatformInfo.isIOS
                      ? CupertinoIcons.text_justify
                      : Icons.format_align_justify,
                ),
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Font Size',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            AdaptiveSegmentedControl<FontSizeOption>(
              groupValue: _fontSize,
              onValueChanged: (value) => setState(() => _fontSize = value),
              children: {
                FontSizeOption.small: _buildTextSegment('S'),
                FontSizeOption.medium: _buildTextSegment('M'),
                FontSizeOption.large: _buildTextSegment('L'),
                FontSizeOption.extraLarge: _buildTextSegment('XL'),
              },
            ),
            const SizedBox(height: 16),
            _buildFormattedTextPreview(),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          context,
          title: 'Tab Navigation',
          children: [
            AdaptiveSegmentedControl<int>(
              groupValue: _selectedTab,
              onValueChanged: (value) => setState(() => _selectedTab = value),
              children: {
                0: _buildSegment(
                  icon: PlatformInfo.isIOS ? CupertinoIcons.home : Icons.home,
                  label: 'Home',
                ),
                1: _buildSegment(
                  icon: PlatformInfo.isIOS
                      ? CupertinoIcons.search
                      : Icons.search,
                  label: 'Search',
                ),
                2: _buildSegment(
                  icon: PlatformInfo.isIOS
                      ? CupertinoIcons.person
                      : Icons.person,
                  label: 'Profile',
                ),
              },
            ),
            const SizedBox(height: 16),
            _buildTabContent(),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          context,
          title: 'Two Segments',
          children: [
            const Text(
              'Simple Toggle',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            AdaptiveSegmentedControl<bool>(
              groupValue: true,
              onValueChanged: (value) {},
              children: {
                true: _buildTextSegment('Enabled'),
                false: _buildTextSegment('Disabled'),
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PlatformInfo.isIOS
            ? CupertinoColors.systemBackground
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PlatformInfo.isIOS
              ? CupertinoColors.separator
              : Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: PlatformInfo.isIOS
                  ? CupertinoColors.label
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSegment({required IconData icon, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTextSegment(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildIconOnlySegment(IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Icon(icon, size: 20),
    );
  }

  Widget _buildPreview(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PlatformInfo.isIOS
            ? CupertinoColors.systemGrey6
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: PlatformInfo.isIOS
              ? CupertinoColors.secondaryLabel
              : Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildFormattedTextPreview() {
    double fontSize;
    switch (_fontSize) {
      case FontSizeOption.small:
        fontSize = 12;
        break;
      case FontSizeOption.medium:
        fontSize = 16;
        break;
      case FontSizeOption.large:
        fontSize = 20;
        break;
      case FontSizeOption.extraLarge:
        fontSize = 24;
        break;
    }

    TextAlign alignment;
    switch (_textAlign) {
      case TextAlignOption.left:
        alignment = TextAlign.left;
        break;
      case TextAlignOption.center:
        alignment = TextAlign.center;
        break;
      case TextAlignOption.right:
        alignment = TextAlign.right;
        break;
      case TextAlignOption.justify:
        alignment = TextAlign.justify;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PlatformInfo.isIOS
            ? CupertinoColors.systemGrey6
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'This is a sample text to demonstrate the text formatting options. You can change the alignment and font size using the segmented controls above.',
        textAlign: alignment,
        style: TextStyle(fontSize: fontSize),
      ),
    );
  }

  Widget _buildTabContent() {
    String content;
    IconData icon;

    switch (_selectedTab) {
      case 0:
        content =
            'Welcome to the Home tab! This is where you\'ll find your main content.';
        icon = PlatformInfo.isIOS ? CupertinoIcons.home : Icons.home;
        break;
      case 1:
        content = 'Search tab is selected. You can search for anything here.';
        icon = PlatformInfo.isIOS ? CupertinoIcons.search : Icons.search;
        break;
      case 2:
        content =
            'Profile tab is active. View and edit your profile information.';
        icon = PlatformInfo.isIOS ? CupertinoIcons.person : Icons.person;
        break;
      default:
        content = 'Unknown tab';
        icon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PlatformInfo.isIOS
            ? CupertinoColors.systemGrey6
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: PlatformInfo.isIOS
                ? CupertinoColors.systemBlue
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            content,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
