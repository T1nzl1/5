import '../models/author.dart';
abstract interface class AuthorRepository { Future<List<Author>> all({bool includeDeleted=false}); Future<Author?> findById(int id); Future<Author> create(Author value); Future<Author> update(Author value); Future<void> delete(int id); }
