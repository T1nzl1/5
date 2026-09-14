import '../models/book.dart';
abstract interface class BookRepository {
  Future<List<Book>> all({bool includeDeleted = false});
  Future<Book?> findById(int id);
  Future<Book> create(Book book);
  Future<Book> update(Book book);
  Future<void> delete(int id);
  Future<bool> isIsbnUnique(String isbn,{int? exceptId});
  Future<int> countByPublisher(int publisherId);
}
