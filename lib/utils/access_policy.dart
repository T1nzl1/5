import '../state_auth.dart';

/// Pure role-access rules. Kept separate so they are easy to unit-test.
class AccessPolicy {
  static bool canOpen(Role role, String path) {
    if (path.startsWith('/admin')) return role == Role.admin;
    if (path.startsWith('/loans/manage')) return role == Role.librarian;
    if (path.startsWith('/my-loans')) return role == Role.reader;
    if (path == '/books/new' || path.endsWith('/edit')) {
      return role == Role.librarian;
    }
    if (path.startsWith('/authors') ||
        path.startsWith('/genres') ||
        path.startsWith('/publishers') ||
        path.startsWith('/readers')) {
      return role == Role.librarian;
    }
    return true;
  }
}
