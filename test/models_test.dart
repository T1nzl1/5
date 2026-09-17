import 'package:flutter_test/flutter_test.dart';
import 'package:libraryden/models/book.dart';

void main() {
  test('Book.fromJson tolerates missing fields', () {
    final book = Book.fromJson({'id': 1});
    expect(book.id, 1);
    expect(book.title, '');
    expect(book.authorIds, isEmpty);
  });
  test('Book.fromJson parses relation ids', () {
    final book = Book.fromJson({'id': 2, 'authorIds': [3, 4], 'genreIds': [7]});
    expect(book.authorIds, [3, 4]);
    expect(book.genreIds, [7]);
  });
}
