import '../models/publisher.dart';
abstract interface class PublisherRepository { Future<List<Publisher>> all({bool includeDeleted=false}); Future<Publisher?> findById(int id); Future<Publisher> create(Publisher value); Future<Publisher> update(Publisher value); Future<void> delete(int id); }
