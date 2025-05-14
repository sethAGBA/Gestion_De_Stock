import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SidebarWidget extends StatefulWidget {
  final Function(int)? onItemTapped;

  const SidebarWidget({Key? key, this.onItemTapped}) : super(key: key);

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
              isVerySmallScreen || !_isExpanded ? 8.0 : 16.0,
              24.0,
              isVerySmallScreen || !_isExpanded ? 8.0 : 16.0,
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
                  const SizedBox(width: 12.0),
                  const Text(
                    'GESTION DE STOCK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
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
                _buildMenuItem(
                  icon: Icons.dashboard,
                  title: 'Tableau de bord',
                  index: 0,
                  isSelected: true,
                  isExpanded: !isVerySmallScreen && _isExpanded,
                ),
                _buildMenuItem(
                  icon: Icons.list_alt_outlined,
                  title: 'Produits',
                  index: 1,
                  isExpanded: !isVerySmallScreen && _isExpanded,
                ),
                _buildMenuItem(
                  icon: Icons.input,
                  title: 'Entrées',
                  index: 2,
                  isExpanded: !isVerySmallScreen && _isExpanded,
                ),
                _buildMenuItem(
                  icon: Icons.output,
                  title: 'Sorties',
                  index: 3,
                  isExpanded: !isVerySmallScreen && _isExpanded,
                ),
                _buildMenuItem(
                  icon: Icons.folder_open_outlined,
                  title: 'Inventaire',
                  index: 4,
                  isExpanded: !isVerySmallScreen && _isExpanded,
                ),
                _buildMenuItem(
                  icon: Icons.business,
                  title: 'Fournisseurs',
                  index: 5,
                  isExpanded: !isVerySmallScreen && _isExpanded,
                ),
                _buildMenuItem(
                  icon: Icons.people,
                  title: 'Utilisateurs',
                  index: 6,
                  isExpanded: !isVerySmallScreen && _isExpanded,
                ),
                _buildMenuItem(
                  icon: Icons.account_balance_outlined,
                  title: 'Gestion des ventes et des clients',
                  index: 7,
                  isExpanded: !isVerySmallScreen && _isExpanded,
                ),
                _buildMenuItem(
                  icon: Icons.notifications,
                  title: 'Alertes',
                  index: 8,
                  isExpanded: !isVerySmallScreen && _isExpanded,
                ),
                _buildMenuItem(
                  icon: Icons.history,
                  title: 'Historique des avaries',
                  index: 10,
                  isExpanded: !isVerySmallScreen && _isExpanded,
                ),
              ],
            ),
          ),
          _buildMenuItem(
            icon: Icons.settings,
            title: 'Paramètres',
            index: 9,
            isExpanded: !isVerySmallScreen && _isExpanded,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required int index,
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
        leading: Icon(icon, color: Colors.white),
        title: isExpanded
            ? Text(
                title,
                style: const TextStyle(color: Colors.white),
              )
            : null,
        selected: isSelected,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        onTap: () {
          if (widget.onItemTapped != null) {
            widget.onItemTapped!(index);
          }
        },
      ),
    );
  }
}