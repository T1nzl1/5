import 'package:flutter_test/flutter_test.dart';
import 'package:libraryden/state_auth.dart';
import 'package:libraryden/utils/access_policy.dart';

void main() {
  group('AccessPolicy', () {
    test('reader cannot open admin', () => expect(AccessPolicy.canOpen(Role.reader, '/admin/users'), isFalse));
    test('admin can open admin', () => expect(AccessPolicy.canOpen(Role.admin, '/admin/users'), isTrue));
    test('reader can open own loans', () => expect(AccessPolicy.canOpen(Role.reader, '/my-loans'), isTrue));
    test('librarian can manage loans', () => expect(AccessPolicy.canOpen(Role.librarian, '/loans/manage'), isTrue));
    test('reader cannot edit a book', () => expect(AccessPolicy.canOpen(Role.reader, '/books/1/edit'), isFalse));
    test('librarian can edit a book', () => expect(AccessPolicy.canOpen(Role.librarian, '/books/1/edit'), isTrue));
  });
}
