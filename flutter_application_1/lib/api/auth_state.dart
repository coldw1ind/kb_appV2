class AuthState {
  static int? id;
  static String username = '';
  static String email = '';
  static String role = '';
  static String bar = '';

  static void setFromJson(Map<String, dynamic> user) {
    final rawId = user['id'];
    id = rawId is int ? rawId : int.tryParse(rawId.toString());
    username = (user['username'] ?? '').toString();
    email = (user['email'] ?? '').toString();
    role = (user['employee_role'] ?? '').toString();
    bar = (user['bar'] ?? '').toString();
  }

  static void clear() {
    id = null;
    username = '';
    email = '';
    role = '';
    bar = '';
  }

  static bool get isLoggedIn => id != null;
}