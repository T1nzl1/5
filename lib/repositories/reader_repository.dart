import '../models/reader.dart';
abstract interface class ReaderRepository { Future<List<Reader>> all({bool includeDeleted=false}); Future<Reader?> findById(int id); Future<Reader> create(Reader value); Future<Reader> update(Reader value); Future<void> delete(int id); Future<bool> isEmailUnique(String email,{int? exceptId}); }
