import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

class PopupMenuDemoPage extends StatefulWidget {
  const PopupMenuDemoPage({super.key});

  @override
  State<PopupMenuDemoPage> createState() => _PopupMenuDemoPageState();
}

class _PopupMenuDemoPageState extends State<PopupMenuDemoPage> {
  String _selectedAction = 'No selection';
  String _selectedValue = '';

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Popup Menu Demo',
      destinations: const [],
      selectedIndex: 0,
      onDestinationSelected: (_) {},
      children: [
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: _buildContent(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildContent() {
    return [
      // Selection status
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PlatformInfo.isIOS
              ? CupertinoColors.systemGrey6
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Selection:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: PlatformInfo.isIOS
                    ? CupertinoColors.systemGrey
                    : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _selectedAction,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_selectedValue.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Value: $_selectedValue',
                style: TextStyle(
                  fontSize: 14,
                  color: PlatformInfo.isIOS
                      ? CupertinoColors.systemGrey
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 24),

      // Text Button Examples
      _buildSection('Text Buttons', [
              _buildDemo(
                'Plain Style',
                AdaptivePopupMenuButton.text<String>(
                  label: 'Options',
                  items: _basicMenuItems(),
                  onSelected: (index, item) {
                    setState(() {
                      _selectedAction = item.label;
                      _selectedValue = item.value ?? '';
                    });
                  },
                  buttonStyle: PopupButtonStyle.plain,
                ),
              ),
              _buildDemo(
                'Gray Style',
                AdaptivePopupMenuButton.text<String>(
                  label: 'Actions',
                  items: _basicMenuItems(),
                  onSelected: (index, item) {
                    setState(() {
                      _selectedAction = item.label;
                      _selectedValue = item.value ?? '';
                    });
                  },
                  buttonStyle: PopupButtonStyle.gray,
                ),
              ),
              _buildDemo(
                'Tinted Style',
                AdaptivePopupMenuButton.text<String>(
                  label: 'More',
                  items: _basicMenuItems(),
                  onSelected: (index, item) {
                    setState(() {
                      _selectedAction = item.label;
                      _selectedValue = item.value ?? '';
                    });
                  },
                  buttonStyle: PopupButtonStyle.tinted,
                  tint: CupertinoColors.systemBlue,
                ),
              ),
              _buildDemo(
                'Bordered Style',
                AdaptivePopupMenuButton.text<String>(
                  label: 'Menu',
                  items: _basicMenuItems(),
                  onSelected: (index, item) {
                    setState(() {
                      _selectedAction = item.label;
                      _selectedValue = item.value ?? '';
                    });
                  },
                  buttonStyle: PopupButtonStyle.bordered,
                ),
              ),
              _buildDemo(
                'Filled Style',
                AdaptivePopupMenuButton.text<String>(
                  label: 'Select',
                  items: _basicMenuItems(),
                  onSelected: (index, item) {
                    setState(() {
                      _selectedAction = item.label;
                      _selectedValue = item.value ?? '';
                    });
                  },
                  buttonStyle: PopupButtonStyle.filled,
                  tint: CupertinoColors.systemGreen,
                ),
              ),
              _buildDemo(
                'Glass Style (iOS 26+)',
                AdaptivePopupMenuButton.text<String>(
                  label: 'Glass',
                  items: _basicMenuItems(),
                  onSelected: (index, item) {
                    setState(() {
                      _selectedAction = item.label;
                      _selectedValue = item.value ?? '';
                    });
                  },
                  buttonStyle: PopupButtonStyle.glass,
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // Icon Button Examples
            _buildSection('Icon Buttons', [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      AdaptivePopupMenuButton.icon<String>(
                        icon: 'ellipsis.circle',
                        items: _iconMenuItems(),
                        onSelected: (index, item) {
                          setState(() {
                            _selectedAction = item.label;
                            _selectedValue = item.value ?? '';
                          });
                        },
                        buttonStyle: PopupButtonStyle.glass,
                      ),
                      const SizedBox(height: 8),
                      const Text('Glass', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      AdaptivePopupMenuButton.icon<String>(
                        icon: 'gear',
                        items: _iconMenuItems(),
                        onSelected: (index, item) {
                          setState(() {
                            _selectedAction = item.label;
                            _selectedValue = item.value ?? '';
                          });
                        },
                        buttonStyle: PopupButtonStyle.tinted,
                        tint: CupertinoColors.systemBlue,
                      ),
                      const SizedBox(height: 8),
                      const Text('Tinted', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      AdaptivePopupMenuButton.icon<String>(
                        icon: 'square.and.arrow.up',
                        items: _iconMenuItems(),
                        onSelected: (index, item) {
                          setState(() {
                            _selectedAction = item.label;
                            _selectedValue = item.value ?? '';
                          });
                        },
                        buttonStyle: PopupButtonStyle.filled,
                        tint: CupertinoColors.systemPurple,
                      ),
                      const SizedBox(height: 8),
                      const Text('Filled', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      AdaptivePopupMenuButton.icon<String>(
                        icon: 'star.fill',
                        items: _iconMenuItems(),
                        onSelected: (index, item) {
                          setState(() {
                            _selectedAction = item.label;
                            _selectedValue = item.value ?? '';
                          });
                        },
                        buttonStyle: PopupButtonStyle.prominentGlass,
                      ),
                      const SizedBox(height: 8),
                      const Text('Prominent', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ]),
            const SizedBox(height: 24),

            // Advanced Examples
            _buildSection('Advanced Examples', [
              _buildDemo(
                'With Dividers',
                AdaptivePopupMenuButton.text<String>(
                  label: 'File',
                  items: const [
                    AdaptivePopupMenuItem(
                      label: 'New',
                      icon: 'doc.badge.plus',
                      value: 'new',
                    ),
                    AdaptivePopupMenuItem(
                      label: 'Open',
                      icon: 'folder',
                      value: 'open',
                    ),
                    AdaptivePopupMenuDivider(),
                    AdaptivePopupMenuItem(
                      label: 'Save',
                      icon: 'square.and.arrow.down',
                      value: 'save',
                    ),
                    AdaptivePopupMenuItem(
                      label: 'Save As...',
                      icon: 'square.and.arrow.down.on.square',
                      value: 'save_as',
                    ),
                    AdaptivePopupMenuDivider(),
                    AdaptivePopupMenuItem(
                      label: 'Close',
                      icon: 'xmark',
                      value: 'close',
                    ),
                  ],
                  onSelected: (index, item) {
                    setState(() {
                      _selectedAction = item.label;
                      _selectedValue = item.value ?? '';
                    });
                  },
                  buttonStyle: PopupButtonStyle.bordered,
                ),
              ),
              _buildDemo(
                'With Disabled Items',
                AdaptivePopupMenuButton.text<String>(
                  label: 'Edit',
                  items: const [
                    AdaptivePopupMenuItem(
                      label: 'Cut',
                      icon: 'scissors',
                      value: 'cut',
                    ),
                    AdaptivePopupMenuItem(
                      label: 'Copy',
                      icon: 'doc.on.doc',
                      value: 'copy',
                    ),
                    AdaptivePopupMenuItem(
                      label: 'Paste',
                      icon: 'doc.on.clipboard',
                      value: 'paste',
                      enabled: false,
                    ),
                    AdaptivePopupMenuDivider(),
                    AdaptivePopupMenuItem(
                      label: 'Select All',
                      icon: 'selection.pin.in.out',
                      value: 'select_all',
                    ),
                    AdaptivePopupMenuItem(
                      label: 'Undo',
                      icon: 'arrow.uturn.backward',
                      value: 'undo',
                      enabled: false,
                    ),
                  ],
                  onSelected: (index, item) {
                    setState(() {
                      _selectedAction = item.label;
                      _selectedValue = item.value ?? '';
                    });
                  },
                  buttonStyle: PopupButtonStyle.tinted,
                ),
              ),
              _buildDemo(
                'System Actions',
                AdaptivePopupMenuButton.icon<String>(
                  icon: 'ellipsis',
                  items: const [
                    AdaptivePopupMenuItem(
                      label: 'Share',
                      icon: 'square.and.arrow.up',
                      value: 'share',
                    ),
                    AdaptivePopupMenuItem(
                      label: 'Favorite',
                      icon: 'heart',
                      value: 'favorite',
                    ),
                    AdaptivePopupMenuItem(
                      label: 'Add to Reading List',
                      icon: 'book',
                      value: 'reading_list',
                    ),
                    AdaptivePopupMenuDivider(),
                    AdaptivePopupMenuItem(
                      label: 'Report',
                      icon: 'exclamationmark.triangle',
                      value: 'report',
                    ),
                    AdaptivePopupMenuItem(
                      label: 'Block',
                      icon: 'nosign',
                      value: 'block',
                    ),
                  ],
                  onSelected: (index, item) {
                    setState(() {
                      _selectedAction = item.label;
                      _selectedValue = item.value ?? '';
                    });
                  },
                  buttonStyle: PopupButtonStyle.glass,
                  size: 36,
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // Custom Tint Colors
            _buildSection('Custom Tint Colors', [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  AdaptivePopupMenuButton.text<String>(
                    label: 'Red',
                    items: _basicMenuItems(),
                    onSelected: (index, item) {
                      setState(() {
                        _selectedAction = item.label;
                        _selectedValue = item.value ?? '';
                      });
                    },
                    buttonStyle: PopupButtonStyle.tinted,
                    tint: CupertinoColors.systemRed,
                    height: 36,
                  ),
                  AdaptivePopupMenuButton.text<String>(
                    label: 'Orange',
                    items: _basicMenuItems(),
                    onSelected: (index, item) {
                      setState(() {
                        _selectedAction = item.label;
                        _selectedValue = item.value ?? '';
                      });
                    },
                    buttonStyle: PopupButtonStyle.tinted,
                    tint: CupertinoColors.systemOrange,
                    height: 36,
                  ),
                  AdaptivePopupMenuButton.text<String>(
                    label: 'Green',
                    items: _basicMenuItems(),
                    onSelected: (index, item) {
                      setState(() {
                        _selectedAction = item.label;
                        _selectedValue = item.value ?? '';
                      });
                    },
                    buttonStyle: PopupButtonStyle.tinted,
                    tint: CupertinoColors.systemGreen,
                    height: 36,
                  ),
                  AdaptivePopupMenuButton.text<String>(
                    label: 'Purple',
                    items: _basicMenuItems(),
                    onSelected: (index, item) {
                      setState(() {
                        _selectedAction = item.label;
                        _selectedValue = item.value ?? '';
                      });
                    },
                    buttonStyle: PopupButtonStyle.tinted,
                    tint: CupertinoColors.systemPurple,
                    height: 36,
                  ),
                ],
              ),
      ]),
      const SizedBox(height: 40),
    ];
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDemo(String title, Widget widget) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(title, style: const TextStyle(fontSize: 15)),
          ),
          Flexible(child: widget),
        ],
      ),
    );
  }

  List<AdaptivePopupMenuEntry> _basicMenuItems() {
    return const [
      AdaptivePopupMenuItem(label: 'Option 1', value: 'opt1'),
      AdaptivePopupMenuItem(
        label: 'Option  Option  Option  Option 2',
        value: 'Option  Option  Option 2',
      ),
      AdaptivePopupMenuItem(label: 'Option 3', value: 'opt3'),
    ];
  }

  List<AdaptivePopupMenuEntry> _iconMenuItems() {
    return const [
      AdaptivePopupMenuItem(label: 'Copy', icon: 'doc.on.doc', value: 'copy'),
      AdaptivePopupMenuItem(
        label: 'Share',
        icon: 'square.and.arrow.up',
        value: 'share',
      ),
      AdaptivePopupMenuItem(label: 'Delete', icon: 'trash', value: 'delete'),
      AdaptivePopupMenuDivider(),
      AdaptivePopupMenuItem(label: 'Info', icon: 'info.circle', value: 'info'),
    ];
  }
}
