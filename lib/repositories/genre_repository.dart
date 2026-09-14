import '../models/genre.dart';
abstract interface class GenreRepository { Future<List<Genre>> all({bool includeDeleted=false}); Future<Genre?> findById(int id); Future<Genre> create(Genre value); Future<Genre> update(Genre value); Future<void> delete(int id); }
