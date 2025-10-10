import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

class SegmentedControlDemoPage extends StatefulWidget {
  const SegmentedControlDemoPage({super.key});

  @override
  State<SegmentedControlDemoPage> createState() => _SegmentedControlDemoPageState();
}

enum FilterOption { all, active, completed }
enum ViewMode { list, grid, table }
enum TimeRange { day, week, month, year }
enum Priority { low, medium, high }

class _SegmentedControlDemoPageState extends State<SegmentedControlDemoPage> {
  FilterOption _filterOption = FilterOption.all;
  ViewMode _viewMode = ViewMode.list;
  TimeRange _timeRange = TimeRange.week;
  Priority _priority = Priority.medium;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'AdaptiveSegmentedControl Demo',
      destinations: const [],
      selectedIndex: 0,
      onDestinationSelected: (_) {},
      children: [
        SafeArea(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Platform Information
        _buildSection(
          'Platform Information',
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PlatformInfo.isIOS
                  ? CupertinoColors.systemGrey6
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              PlatformInfo.platformDescription,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: PlatformInfo.isIOS
                    ? CupertinoColors.label
                    : Colors.black87,
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Filter Options
        _buildSection(
          'Filter Options',
          Column(
            children: [
              AdaptiveSegmentedControl<FilterOption>(
                groupValue: _filterOption,
                onValueChanged: (value) {
                  setState(() => _filterOption = value);
                },
                children: const {
                  FilterOption.all: Text('All'),
                  FilterOption.active: Text('Active'),
                  FilterOption.completed: Text('Completed'),
                },
              ),
              const SizedBox(height: 16),
              _buildResultCard('Selected: ${_filterOption.name}'),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // View Mode Selection
        _buildSection(
          'View Mode',
          Column(
            children: [
              AdaptiveSegmentedControl<ViewMode>(
                groupValue: _viewMode,
                onValueChanged: (value) {
                  setState(() => _viewMode = value);
                },
                children: const {
                  ViewMode.list: Text('List'),
                  ViewMode.grid: Text('Grid'),
                  ViewMode.table: Text('Table'),
                },
              ),
              const SizedBox(height: 16),
              _buildResultCard('Current view: ${_viewMode.name}'),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Time Range Selection
        _buildSection(
          'Time Range',
          Column(
            children: [
              AdaptiveSegmentedControl<TimeRange>(
                groupValue: _timeRange,
                onValueChanged: (value) {
                  setState(() => _timeRange = value);
                },
                children: const {
                  TimeRange.day: Text('Day'),
                  TimeRange.week: Text('Week'),
                  TimeRange.month: Text('Month'),
                  TimeRange.year: Text('Year'),
                },
              ),
              const SizedBox(height: 16),
              _buildResultCard('Viewing: ${_timeRange.name}'),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Priority Selection
        _buildSection(
          'Priority Level',
          Column(
            children: [
              AdaptiveSegmentedControl<Priority>(
                groupValue: _priority,
                onValueChanged: (value) {
                  setState(() => _priority = value);
                },
                children: const {
                  Priority.low: Text('Low'),
                  Priority.medium: Text('Medium'),
                  Priority.high: Text('High'),
                },
              ),
              const SizedBox(height: 16),
              _buildResultCard(
                'Priority: ${_priority.name}',
                color: _getPriorityColor(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Two Segments Example
        _buildSection(
          'Binary Choice',
          Column(
            children: [
              AdaptiveSegmentedControl<bool>(
                groupValue: true,
                onValueChanged: (value) {},
                children: const {
                  false: Text('Off'),
                  true: Text('On'),
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Description
        _buildSection(
          'About',
          Text(
            'The AdaptiveSegmentedControl automatically uses:\n\n'
            '• Native iOS 26 UISegmentedControl on iOS 26+\n'
            '• CupertinoSegmentedControl on iOS 25 and below\n'
            '• Material SegmentedButton on Android\n\n'
            'Features:\n'
            '• Native Liquid Glass design on iOS 26\n'
            '• Support for 2-4 segments recommended\n'
            '• Automatic light/dark mode\n'
            '• Hot reload support\n'
            '• Type-safe enum support',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: PlatformInfo.isIOS
                  ? CupertinoColors.secondaryLabel
                  : Colors.black54,
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Usage Examples
        _buildSection(
          'Common Use Cases',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUseCaseItem('Filtering content (All, Active, Done)'),
              _buildUseCaseItem('Switching views (List, Grid, Map)'),
              _buildUseCaseItem('Time period selection (Day, Week, Month)'),
              _buildUseCaseItem('Category selection'),
              _buildUseCaseItem('Mode toggles (Edit, Preview)'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: PlatformInfo.isIOS ? CupertinoColors.label : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildResultCard(String text, {Color? color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.1) ??
            (PlatformInfo.isIOS
                ? CupertinoColors.systemGrey5
                : Colors.grey.shade100),
        border: Border.all(
          color: color ??
              (PlatformInfo.isIOS
                  ? CupertinoColors.systemGrey4
                  : Colors.grey.shade300),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color ??
              (PlatformInfo.isIOS
                  ? CupertinoColors.label
                  : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildUseCaseItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            PlatformInfo.isIOS
                ? CupertinoIcons.checkmark_circle_fill
                : Icons.check_circle,
            size: 16,
            color: PlatformInfo.isIOS
                ? CupertinoColors.systemGreen
                : Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: PlatformInfo.isIOS
                    ? CupertinoColors.secondaryLabel
                    : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor() {
    switch (_priority) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.orange;
      case Priority.high:
        return Colors.red;
    }
  }
}
