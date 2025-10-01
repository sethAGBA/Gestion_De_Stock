import 'package:flutter/material.dart';

class AppScreenPermission {
  final String key;
  final String label;
  final IconData icon;

  const AppScreenPermission({
    required this.key,
    required this.label,
    required this.icon,
  });
}

const List<AppScreenPermission> appScreenPermissions = [
  AppScreenPermission(key: 'dashboard', label: 'Tableau de bord', icon: Icons.dashboard),
  AppScreenPermission(key: 'products', label: 'Produits', icon: Icons.list_alt_outlined),
  AppScreenPermission(key: 'entries', label: 'Entrées', icon: Icons.input),
  AppScreenPermission(key: 'exits', label: 'Sorties', icon: Icons.output),
  AppScreenPermission(key: 'inventory', label: 'Inventaire', icon: Icons.folder_open_outlined),
  AppScreenPermission(key: 'suppliers', label: 'Fournisseurs', icon: Icons.business),
  AppScreenPermission(key: 'users', label: 'Utilisateurs', icon: Icons.people),
  AppScreenPermission(key: 'sales', label: 'Gestion des ventes et des clients', icon: Icons.account_balance_outlined),
  AppScreenPermission(key: 'alerts', label: 'Alertes', icon: Icons.notifications),
  AppScreenPermission(key: 'settings', label: 'Paramètres', icon: Icons.settings),
  AppScreenPermission(key: 'damaged_history', label: 'Historique des avaries', icon: Icons.history),
];
