import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../models/author.dart';
import '../models/book.dart';
import '../models/genre.dart';
import '../models/publisher.dart';
import '../models/reader.dart';
import 'author_repository.dart'; import 'book_repository.dart'; import 'genre_repository.dart'; import 'publisher_repository.dart'; import 'reader_repository.dart';

List<Map<String,dynamic>> _items(dynamic data) {
  final raw = data is Map ? data['items'] : data;
  return (raw is List ? raw : const []).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();
}
Map<String,dynamic> _map(dynamic data)=>Map<String,dynamic>.from(data as Map);

abstract class _ApiBase {
  final Dio dio; final String path; _ApiBase(this.dio,this.path);
  Future<void> hardDelete(int id)=>guard(()=>dio.delete('$path/$id',queryParameters:{'hard':true}));
  Future<void> restore(int id)=>guard(()=>dio.post('$path/$id/restore'));
  Future<int> deleteMany(List<int> ids)=>guard(() async { final r=await dio.post('$path/bulk-delete',data:{'ids':ids}); return (_map(r.data)['deleted'] as num?)?.toInt()??0; });
}

class ApiAuthorRepository extends _ApiBase implements AuthorRepository {
  ApiAuthorRepository(Dio d):super(d,'/authors');
  @override Future<List<Author>> all({bool includeDeleted=false})=>guard(() async=>(_items((await dio.get(path,queryParameters:{if(includeDeleted)'includeDeleted':true})).data)).map(Author.fromJson).toList());
  @override Future<Author?> findById(int id)=>guard(() async { try{return Author.fromJson(_map((await dio.get('$path/$id')).data));} on NotFoundException{return null;} });
  @override Future<Author> create(Author v)=>guard(() async=>Author.fromJson(_map((await dio.post(path,data:{'fullName':v.fullName,'birthYear':v.birthYear,'country':v.country})).data)));
  @override Future<Author> update(Author v)=>guard(() async=>Author.fromJson(_map((await dio.put('$path/${v.id}',data:{'fullName':v.fullName,'birthYear':v.birthYear,'country':v.country})).data)));
  @override Future<void> delete(int id)=>guard(()=>dio.delete('$path/$id'));
}
class ApiGenreRepository extends _ApiBase implements GenreRepository {
  ApiGenreRepository(Dio d):super(d,'/genres');
  @override Future<List<Genre>> all({bool includeDeleted=false})=>guard(() async=>(_items((await dio.get(path,queryParameters:{if(includeDeleted)'includeDeleted':true})).data)).map(Genre.fromJson).toList());
  @override Future<Genre?> findById(int id)=>guard(() async { try{return Genre.fromJson(_map((await dio.get('$path/$id')).data));} on NotFoundException{return null;} });
  @override Future<Genre> create(Genre v)=>guard(() async=>Genre.fromJson(_map((await dio.post(path,data:{'name':v.name,'description':v.description})).data)));
  @override Future<Genre> update(Genre v)=>guard(() async=>Genre.fromJson(_map((await dio.put('$path/${v.id}',data:{'name':v.name,'description':v.description})).data)));
  @override Future<void> delete(int id)=>guard(()=>dio.delete('$path/$id'));
}
class ApiPublisherRepository extends _ApiBase implements PublisherRepository {
  ApiPublisherRepository(Dio d):super(d,'/publishers');
  @override Future<List<Publisher>> all({bool includeDeleted=false})=>guard(() async=>(_items((await dio.get(path,queryParameters:{if(includeDeleted)'includeDeleted':true})).data)).map(Publisher.fromJson).toList());
  @override Future<Publisher?> findById(int id)=>guard(() async { try{return Publisher.fromJson(_map((await dio.get('$path/$id')).data));} on NotFoundException{return null;} });
  @override Future<Publisher> create(Publisher v)=>guard(() async=>Publisher.fromJson(_map((await dio.post(path,data:{'name':v.name,'city':v.city,'foundedYear':v.foundedYear})).data)));
  @override Future<Publisher> update(Publisher v)=>guard(() async=>Publisher.fromJson(_map((await dio.put('$path/${v.id}',data:{'name':v.name,'city':v.city,'foundedYear':v.foundedYear})).data)));
  @override Future<void> delete(int id)=>guard(()=>dio.delete('$path/$id'));
}
class ApiReaderRepository extends _ApiBase implements ReaderRepository {
  ApiReaderRepository(Dio d):super(d,'/readers');
  @override Future<List<Reader>> all({bool includeDeleted=false})=>guard(() async=>(_items((await dio.get(path,queryParameters:{if(includeDeleted)'includeDeleted':true})).data)).map(Reader.fromJson).toList());
  @override Future<Reader?> findById(int id)=>guard(() async { try{return Reader.fromJson(_map((await dio.get('$path/$id')).data));} on NotFoundException{return null;} });
  Map<String,dynamic> body(Reader v)=>{'fullName':v.fullName,'email':v.email,'phone':v.phone,'card':v.card.toJson()};
  @override Future<Reader> create(Reader v)=>guard(() async=>Reader.fromJson(_map((await dio.post(path,data:body(v))).data)));
  @override Future<Reader> update(Reader v)=>guard(() async=>Reader.fromJson(_map((await dio.put('$path/${v.id}',data:body(v))).data)));
  @override Future<void> delete(int id)=>guard(()=>dio.delete('$path/$id'));
  @override Future<bool> isEmailUnique(String email,{int? exceptId}) async { final allReaders=await all(includeDeleted:true); return !allReaders.any((r)=>r.email.toLowerCase()==email.trim().toLowerCase() && r.id!=exceptId); }
}
class ApiBookRepository extends _ApiBase implements BookRepository {
  ApiBookRepository(Dio d):super(d,'/books');
  Book parse(Map<String,dynamic> j) {
    final p=j['publisher']; final authors=j['authors']; final genres=j['genres'];
    return Book(id:(j['id'] as num?)?.toInt()??0,title:j['title'] as String? ?? '',isbn:j['isbn'] as String? ?? '',year:(j['year'] as num?)?.toInt()??0,pages:(j['pages'] as num?)?.toInt()??0,
      publisherId:(j['publisherId'] as num?)?.toInt() ?? (p is Map ? (p['id'] as num?)?.toInt()??0:0),
      authorIds:j['authorIds'] is List ? (j['authorIds'] as List).map((e)=>(e as num).toInt()).toList() : (authors is List ? authors.whereType<Map>().map((e)=>(e['id'] as num).toInt()).toList():[]),
      genreIds:j['genreIds'] is List ? (j['genreIds'] as List).map((e)=>(e as num).toInt()).toList() : (genres is List ? genres.whereType<Map>().map((e)=>(e['id'] as num).toInt()).toList():[]),
      copiesTotal:(j['copiesTotal'] as num?)?.toInt()??0,copiesAvailable:(j['copiesAvailable'] as num?)?.toInt()??0,createdAt:DateTime.tryParse('${j['createdAt']??''}')??DateTime.now(),deletedAt:j['deletedAt']==null?null:DateTime.tryParse('${j['deletedAt']}'));
  }
  Map<String,dynamic> body(Book b)=>{'title':b.title,'isbn':b.isbn,'year':b.year,'pages':b.pages,'publisherId':b.publisherId,'authorIds':b.authorIds,'genreIds':b.genreIds,'copiesTotal':b.copiesTotal};
  @override Future<List<Book>> all({bool includeDeleted=false})=>guard(() async=>(_items((await dio.get(path,queryParameters:{if(includeDeleted)'includeDeleted':true,'size':100})).data)).map(parse).toList());
  @override Future<Book?> findById(int id)=>guard(() async { try{return parse(_map((await dio.get('$path/$id')).data));} on NotFoundException{return null;} });
  @override Future<Book> create(Book b)=>guard(() async=>parse(_map((await dio.post(path,data:body(b))).data)));
  @override Future<Book> update(Book b)=>guard(() async=>parse(_map((await dio.put('$path/${b.id}',data:body(b))).data)));
  @override Future<void> delete(int id)=>guard(()=>dio.delete('$path/$id'));
  @override Future<bool> isIsbnUnique(String isbn,{int? exceptId}) async { final books=await all(includeDeleted:true); return !books.any((b)=>b.isbn.toLowerCase()==isbn.trim().toLowerCase() && b.id!=exceptId); }
  @override Future<int> countByPublisher(int publisherId) async => (await all()).where((b)=>b.publisherId==publisherId).length;
}
