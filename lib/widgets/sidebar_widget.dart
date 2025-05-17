
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_management/providers/auth_provider.dart';

class SidebarWidget extends StatefulWidget {
  final Function(int)? onItemTapped;
  final int selectedIndex;

  const SidebarWidget({
    Key? key,
    this.onItemTapped,
    this.selectedIndex = 0,
  }) : super(key: key);

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
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final isAdmin = authProvider.isAdmin;
                return ListView(
                  children: isAdmin
                      ? [
                          _buildMenuItem(
                            icon: Icons.dashboard,
                            title: 'Tableau de bord',
                            index: 0,
                            isSelected: widget.selectedIndex == 0,
                            isExpanded: !isVerySmallScreen && _isExpanded,
                          ),
                          _buildMenuItem(
                            icon: Icons.list_alt_outlined,
                            title: 'Produits',
                            index: 1,
                            isSelected: widget.selectedIndex == 1,
                            isExpanded: !isVerySmallScreen && _isExpanded,
                          ),
                          _buildMenuItem(
                            icon: Icons.input,
                            title: 'Entrées',
                            index: 2,
                            isSelected: widget.selectedIndex == 2,
                            isExpanded: !isVerySmallScreen && _isExpanded,
                          ),
                          _buildMenuItem(
                            icon: Icons.output,
                            title: 'Sorties',
                            index: 3,
                            isSelected: widget.selectedIndex == 3,
                            isExpanded: !isVerySmallScreen && _isExpanded,
                          ),
                          _buildMenuItem(
                            icon: Icons.folder_open_outlined,
                            title: 'Inventaire',
                            index: 4,
                            isSelected: widget.selectedIndex == 4,
                            isExpanded: !isVerySmallScreen && _isExpanded,
                          ),
                          _buildMenuItem(
                            icon: Icons.business,
                            title: 'Fournisseurs',
                            index: 5,
                            isSelected: widget.selectedIndex == 5,
                            isExpanded: !isVerySmallScreen && _isExpanded,
                          ),
                          _buildMenuItem(
                            icon: Icons.people,
                            title: 'Utilisateurs',
                            index: 6,
                            isSelected: widget.selectedIndex == 6,
                            isExpanded: !isVerySmallScreen && _isExpanded,
                          ),
                          _buildMenuItem(
                            icon: Icons.account_balance_outlined,
                            title: 'Gestion des ventes et des clients',
                            index: 7,
                            isSelected: widget.selectedIndex == 7,
                            isExpanded: !isVerySmallScreen && _isExpanded,
                          ),
                          _buildMenuItem(
                            icon: Icons.notifications,
                            title: 'Alertes',
                            index: 8,
                            isSelected: widget.selectedIndex == 8,
                            isExpanded: !isVerySmallScreen && _isExpanded,
                          ),
                          _buildMenuItem(
                            icon: Icons.settings,
                            title: 'Paramètres',
                            index: 9,
                            isSelected: widget.selectedIndex == 9,
                            isExpanded: !isVerySmallScreen && _isExpanded,
                          ),
                          _buildMenuItem(
                            icon: Icons.history,
                            title: 'Historique des avaries',
                            index: 10,
                            isSelected: widget.selectedIndex == 10,
                            isExpanded: !isVerySmallScreen && _isExpanded,
                          ),
                          _buildMenuItem(
                            icon: Icons.logout,
                            title: 'Déconnexion',
                            index: -1,
                            isSelected: false,
                            isExpanded: !isVerySmallScreen && _isExpanded,
                            onTap: () {
                              authProvider.logout();
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                          ),
                        ]
                      : [
                          _buildMenuItem(
                            icon: Icons.dashboard,
                            title: 'Tableau de bord',
                            index: 0,
                            isSelected: widget.selectedIndex == 0,
                            isExpanded: !isVerySmallScreen && _isExpanded,
                          ),
                          _buildMenuItem(
                            icon: Icons.add_shopping_cart,
                            title: 'Gestion des ventes',
                            index: 1,
                            isSelected: widget.selectedIndex == 1,
                            isExpanded: !isVerySmallScreen && _isExpanded,
                          ),
                          _buildMenuItem(
                            icon: Icons.history,
                            title: 'Historique des avaries',
                            index: 2,
                            isSelected: widget.selectedIndex == 2,
                            isExpanded: !isVerySmallScreen && _isExpanded,
                          ),
                          _buildMenuItem(
                            icon: Icons.notifications,
                            title: 'Alertes',
                            index: 3,
                            isSelected: widget.selectedIndex == 3,
                            isExpanded: !isVerySmallScreen && _isExpanded,
                          ),
                          _buildMenuItem(
                            icon: Icons.settings,
                            title: 'Paramètres',
                            index: 4,
                            isSelected: widget.selectedIndex == 4,
                            isExpanded: !isVerySmallScreen && _isExpanded,
                          ),
                          _buildMenuItem(
                            icon: Icons.logout,
                            title: 'Déconnexion',
                            index: -1,
                            isSelected: false,
                            isExpanded: !isVerySmallScreen && _isExpanded,
                            onTap: () {
                              authProvider.logout();
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                          ),
                        ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required int index,
    required bool isSelected,
    required bool isExpanded,
    VoidCallback? onTap,
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
        onTap: onTap ?? () {
          if (widget.onItemTapped != null && index >= 0) {
            widget.onItemTapped!(index);
          }
        },
      ),
    );
  }
}
