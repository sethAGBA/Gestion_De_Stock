import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/screen_permissions.dart';

class SidebarWidget extends StatefulWidget {
  final Function(int)? onItemTapped;
  final int selectedIndex;
  final Set<String> allowedKeys;

  const SidebarWidget({Key? key, this.onItemTapped, required this.selectedIndex, required this.allowedKeys}) : super(key: key);

  @override
  _SidebarWidgetState createState() => _SidebarWidgetState();
}

class _SidebarWidgetState extends State<SidebarWidget> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallScreen = screenWidth < 800;

    double sidebarWidth = isVerySmallScreen ? 60.0 : 260.0;
    if (!_isExpanded && !isVerySmallScreen) {
      sidebarWidth = 60.0;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: sidebarWidth,
      color: const Color(0xFF1C3144),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isVerySmallScreen || !_isExpanded ? 8.0 : 12.0,
              24.0,
              isVerySmallScreen || !_isExpanded ? 8.0 : 12.0,
              32.0,
            ),
            child: Row(
              mainAxisAlignment: isVerySmallScreen || !_isExpanded ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  CupertinoIcons.cube,
                  color: Colors.white,
                  size: isVerySmallScreen || !_isExpanded ? 24.0 : 28.0,
                ),
                if (!isVerySmallScreen && _isExpanded) ...[
                  const SizedBox(width: 8.0),
                  const Expanded(
                    child: Text(
                      'GESTION DE STOCK',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isVerySmallScreen)
            IconButton(
              icon: Icon(
                _isExpanded ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
          Expanded(
            child: ListView(
              children: [
                for (final entry in appScreenPermissions.asMap().entries)
                  if (entry.value.key != 'settings')
                    _buildMenuItem(
                      icon: entry.value.icon,
                      title: entry.value.label,
                      index: entry.key,
                      isSelected: widget.selectedIndex == entry.key,
                      isExpanded: !isVerySmallScreen && _isExpanded,
                      enabled: widget.allowedKeys.contains(entry.value.key),
                    ),
              ],
            ),
          ),
          Builder(builder: (context) {
            final settingsIndex = appScreenPermissions.indexWhere((item) => item.key == 'settings');
            if (settingsIndex == -1) {
              return const SizedBox.shrink();
            }
            return _buildMenuItem(
              icon: Icons.settings,
              title: 'Paramètres',
              index: settingsIndex,
              isSelected: widget.selectedIndex == settingsIndex,
              isExpanded: !isVerySmallScreen && _isExpanded,
              enabled: widget.allowedKeys.contains('settings'),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required int index,
    required bool enabled,
    bool isSelected = false,
    required bool isExpanded,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isExpanded ? 16.0 : 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: enabled ? Colors.white : Colors.white.withOpacity(0.4),
        ),
        minLeadingWidth: isExpanded ? 40.0 : 0.0,
        contentPadding: EdgeInsets.symmetric(horizontal: isExpanded ? 16.0 : 8.0),
        title: isExpanded
            ? Text(
                title,
                style: TextStyle(color: enabled ? Colors.white : Colors.white.withOpacity(0.4)),
              )
            : null,
        selected: isSelected,
        enabled: enabled,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        onTap: () {
          if (widget.onItemTapped != null && enabled) {
            widget.onItemTapped!(index);
          }
        },
        trailing: !enabled && isExpanded
            ? const Icon(
                Icons.lock_outline,
                color: Colors.white,
                size: 16,
              )
            : null,
      ),
    );
  }
}
