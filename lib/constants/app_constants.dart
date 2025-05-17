
class AppConstants {
  static const List<String> USER_ROLES = ['Administrateur', 'Employé'];
  
  static const String ROLE_ADMIN = 'Administrateur';
  static const String ROLE_EMPLOYEE = 'Employé';
  
  static bool isValidRole(String role) {
    return USER_ROLES.contains(role);
  }
}
