import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../models/author.dart';
import '../models/genre.dart';
import '../models/publisher.dart';
import '../models/reader.dart';
import 'book_repository.dart';
import 'author_repository.dart';
import 'genre_repository.dart';
import 'publisher_repository.dart';
import 'reader_repository.dart';

final seedAuthors = <Author>[
  const Author(id:1,fullName:'Толстой Л. Н.',birthYear:1828,country:'Россия'),
  const Author(id:2,fullName:'Достоевский Ф. М.',birthYear:1821,country:'Россия'),
  const Author(id:3,fullName:'Булгаков М. А.',birthYear:1891,country:'Россия'),
  const Author(id:4,fullName:'Оруэлл Дж.',birthYear:1903,country:'Великобритания'),
  const Author(id:5,fullName:'Роулинг Дж. К.',birthYear:1965,country:'Великобритания'),
  const Author(id:6,fullName:'Толкин Дж. Р. Р.',birthYear:1892,country:'Великобритания'),
  const Author(id:7,fullName:'Сент-Экзюпери А.',birthYear:1900,country:'Франция'),
  const Author(id:8,fullName:'Герберт Ф.',birthYear:1920,country:'США'),
];
final seedGenres = <Genre>[
  const Genre(id:1,name:'Роман',description:'Крупная форма повествования'),
  const Genre(id:2,name:'Классика',description:'Классическая литература'),
  const Genre(id:3,name:'Фантастика',description:'Фантастическая литература'),
  const Genre(id:4,name:'Фэнтези',description:'Фэнтезийная литература'),
  const Genre(id:5,name:'Антиутопия',description:'Общество с негативным будущим'),
  const Genre(id:6,name:'Детектив',description:'Расследование и тайна'),
];
final seedPublishers = <Publisher>[
  const Publisher(id:1,name:'АСТ',city:'Москва',foundedYear:1990),
  const Publisher(id:2,name:'Эксмо',city:'Москва',foundedYear:1991),
  const Publisher(id:3,name:'Азбука',city:'Санкт-Петербург',foundedYear:1995),
  const Publisher(id:4,name:'Альпина',city:'Москва',foundedYear:1998),
];
final seedBooks = <Book>[
  Book(id:1,title:'Война и мир',isbn:'978-5-17-118366-4',year:1869,pages:1300,publisherId:1,authorIds:[1],genreIds:[1,2],copiesTotal:4,copiesAvailable:2,createdAt:DateTime.utc(2026,8,1,9)),
  Book(id:2,title:'Преступление и наказание',isbn:'978-5-04-116506-6',year:1866,pages:672,publisherId:2,authorIds:[2],genreIds:[1,2],copiesTotal:5,copiesAvailable:3,createdAt:DateTime.utc(2026,8,1,9)),
  Book(id:3,title:'Мастер и Маргарита',isbn:'978-5-17-090172-8',year:1967,pages:480,publisherId:1,authorIds:[3],genreIds:[1,3],copiesTotal:6,copiesAvailable:4,createdAt:DateTime.utc(2026,8,1,9)),
  Book(id:4,title:'1984',isbn:'978-5-17-148557-8',year:1949,pages:320,publisherId:1,authorIds:[4],genreIds:[5],copiesTotal:3,copiesAvailable:1,createdAt:DateTime.utc(2026,8,1,9)),
  Book(id:5,title:'Гарри Поттер и философский камень',isbn:'978-5-389-07435-4',year:1997,pages:432,publisherId:3,authorIds:[5],genreIds:[4],copiesTotal:8,copiesAvailable:6,createdAt:DateTime.utc(2026,8,1,9)),
  Book(id:6,title:'Властелин колец',isbn:'978-5-17-153353-8',year:1954,pages:1120,publisherId:1,authorIds:[6],genreIds:[4],copiesTotal:5,copiesAvailable:2,createdAt:DateTime.utc(2026,8,1,9)),
  Book(id:7,title:'Маленький принц',isbn:'978-5-17-151962-4',year:1943,pages:112,publisherId:1,authorIds:[7],genreIds:[2],copiesTotal:7,copiesAvailable:5,createdAt:DateTime.utc(2026,8,1,9)),
  Book(id:8,title:'Дюна',isbn:'978-5-17-110897-3',year:1965,pages:704,publisherId:1,authorIds:[8],genreIds:[3],copiesTotal:4,copiesAvailable:3,createdAt:DateTime.utc(2026,8,1,9)),
  Book(id:9,title:'Анна Каренина',isbn:'978-5-04-117780-9',year:1878,pages:864,publisherId:2,authorIds:[1],genreIds:[1,2],copiesTotal:4,copiesAvailable:2,createdAt:DateTime.utc(2026,8,1,9)),
  Book(id:10,title:'Идиот',isbn:'978-5-04-089859-0',year:1869,pages:640,publisherId:2,authorIds:[2],genreIds:[1,2],copiesTotal:3,copiesAvailable:1,createdAt:DateTime.utc(2026,8,1,9)),
  Book(id:11,title:'Собачье сердце',isbn:'978-5-17-112471-1',year:1925,pages:256,publisherId:1,authorIds:[3],genreIds:[1,3],copiesTotal:5,copiesAvailable:5,createdAt:DateTime.utc(2026,8,1,9)),
  Book(id:12,title:'Скотный двор',isbn:'978-5-17-148553-0',year:1945,pages:160,publisherId:1,authorIds:[4],genreIds:[5],copiesTotal:4,copiesAvailable:2,createdAt:DateTime.utc(2026,8,1,9)),
  Book(id:13,title:'Гарри Поттер и Тайная комната',isbn:'978-5-389-07781-2',year:1998,pages:480,publisherId:3,authorIds:[5],genreIds:[4],copiesTotal:7,copiesAvailable:4,createdAt:DateTime.utc(2026,8,1,9)),
  Book(id:14,title:'Хоббит',isbn:'978-5-17-152784-1',year:1937,pages:352,publisherId:1,authorIds:[6],genreIds:[4],copiesTotal:6,copiesAvailable:4,createdAt:DateTime.utc(2026,8,1,9)),
  Book(id:15,title:'Планета людей',isbn:'978-5-389-18814-3',year:1939,pages:224,publisherId:3,authorIds:[7],genreIds:[2],copiesTotal:3,copiesAvailable:2,createdAt:DateTime.utc(2026,8,1,9)),
  Book(id:16,title:'Мессия Дюны',isbn:'978-5-17-126631-2',year:1969,pages:352,publisherId:1,authorIds:[8],genreIds:[3],copiesTotal:4,copiesAvailable:2,createdAt:DateTime.utc(2026,8,1,9)),
  Book(id:17,title:'Воскресение',isbn:'978-5-04-119532-2',year:1899,pages:544,publisherId:2,authorIds:[1],genreIds:[1],copiesTotal:2,copiesAvailable:1,createdAt:DateTime.utc(2026,8,1,9)),
  Book(id:18,title:'Братья Карамазовы',isbn:'978-5-04-116507-3',year:1880,pages:832,publisherId:2,authorIds:[2],genreIds:[1],copiesTotal:5,copiesAvailable:3,createdAt:DateTime.utc(2026,8,1,9)),
  Book(id:19,title:'Белая гвардия',isbn:'978-5-17-107733-0',year:1925,pages:416,publisherId:1,authorIds:[3],genreIds:[1],copiesTotal:4,copiesAvailable:2,createdAt:DateTime.utc(2026,8,1,9)),
  Book(id:20,title:'Ферма Кепвелл',isbn:'978-5-17-000020-0',year:1950,pages:300,publisherId:4,authorIds:[4],genreIds:[5],copiesTotal:3,copiesAvailable:2,createdAt:DateTime.utc(2026,8,1,9)),
];
final seedReaders = <Reader>[
  Reader(id:1,fullName:'Смирнов П. А.',email:'smirnov@example.com',phone:'+7 900 000-00-00',card:LibraryCard(id:1,number:'RC-000001',issuedAt:DateTime(2026,1,15),expiresAt:DateTime(2027,1,15))),
  Reader(id:2,fullName:'Иванова А. С.',email:'ivanova@example.com',phone:'+7 900 000-00-01',card:LibraryCard(id:2,number:'RC-000002',issuedAt:DateTime(2026,2,1),expiresAt:DateTime(2027,2,1))),
];

abstract class _JsonRepo<T> {
  final SharedPreferences prefs; final String key; List<T> items=[];
  _JsonRepo(this.prefs,this.key);
  T fromJson(Map<String,dynamic> j); Map<String,dynamic> toJson(T value); List<T> seeds(); int idOf(T value);
  void restore(){ final raw=prefs.getString(key); if(raw==null){items=[...seeds()]; persist(); return;} try{ final list=jsonDecode(raw) as List; items=list.map((e)=>fromJson(Map<String,dynamic>.from(e as Map))).toList(); }catch(_){ items=[...seeds()]; persist(); } }
  Future<void> persist()=>prefs.setString(key,jsonEncode(items.map(toJson).toList()));
  int nextId()=>items.isEmpty?1:items.map(idOf).reduce((a,b)=>a>b?a:b)+1;
}

class PersistentBookRepository extends _JsonRepo<Book> implements BookRepository {
  PersistentBookRepository(SharedPreferences p):super(p,'books_v2'){restore();}
  @override Book fromJson(Map<String,dynamic> j)=>Book.fromJson(j); @override Map<String,dynamic> toJson(Book v)=>v.toJson(); @override List<Book> seeds()=>seedBooks; @override int idOf(Book v)=>v.id;
  @override Future<List<Book>> all({bool includeDeleted=false}) async => items.where((e)=>includeDeleted||!e.isDeleted).toList();
  @override Future<Book?> findById(int id) async { for(final e in items){if(e.id==id)return e;} return null; }
  @override Future<Book> create(Book v) async { final n=v.copyWith(id:nextId(),createdAt:DateTime.now()); items.add(n); await persist(); return n; }
  @override Future<Book> update(Book v) async { final i=items.indexWhere((e)=>e.id==v.id); if(i<0)throw StateError('Книга не найдена'); items[i]=v; await persist(); return v; }
  @override Future<void> delete(int id) async { items.removeWhere((e)=>e.id==id); await persist(); }
  @override Future<bool> isIsbnUnique(String isbn,{int? exceptId}) async => !items.any((e)=>e.id!=exceptId && e.isbn.trim().toLowerCase()==isbn.trim().toLowerCase());
  @override Future<int> countByPublisher(int publisherId) async => items.where((e)=>e.publisherId==publisherId && !e.isDeleted).length;
}
class PersistentAuthorRepository extends _JsonRepo<Author> implements AuthorRepository {
  PersistentAuthorRepository(SharedPreferences p):super(p,'authors_v2'){restore();}
  @override Author fromJson(Map<String,dynamic> j)=>Author.fromJson(j); @override Map<String,dynamic> toJson(Author v)=>v.toJson(); @override List<Author> seeds()=>seedAuthors; @override int idOf(Author v)=>v.id;
  @override Future<List<Author>> all({bool includeDeleted=false}) async=>items.where((e)=>includeDeleted||!e.isDeleted).toList(); @override Future<Author?> findById(int id) async{for(final e in items){if(e.id==id)return e;}return null;} @override Future<Author> create(Author v) async{final n=v.copyWith(id:nextId());items.add(n);await persist();return n;} @override Future<Author> update(Author v) async{final i=items.indexWhere((e)=>e.id==v.id);if(i<0)throw StateError('Автор не найден');items[i]=v;await persist();return v;} @override Future<void> delete(int id) async{items.removeWhere((e)=>e.id==id);await persist();}
}
class PersistentGenreRepository extends _JsonRepo<Genre> implements GenreRepository {
  PersistentGenreRepository(SharedPreferences p):super(p,'genres_v1'){restore();}
  @override Genre fromJson(Map<String,dynamic> j)=>Genre.fromJson(j); @override Map<String,dynamic> toJson(Genre v)=>v.toJson(); @override List<Genre> seeds()=>seedGenres; @override int idOf(Genre v)=>v.id;
  @override Future<List<Genre>> all({bool includeDeleted=false}) async=>items.where((e)=>includeDeleted||!e.isDeleted).toList(); @override Future<Genre?> findById(int id) async{for(final e in items){if(e.id==id)return e;}return null;} @override Future<Genre> create(Genre v) async{final n=v.copyWith(id:nextId());items.add(n);await persist();return n;} @override Future<Genre> update(Genre v) async{final i=items.indexWhere((e)=>e.id==v.id);if(i<0)throw StateError('Жанр не найден');items[i]=v;await persist();return v;} @override Future<void> delete(int id) async{items.removeWhere((e)=>e.id==id);await persist();}
}
class PersistentPublisherRepository extends _JsonRepo<Publisher> implements PublisherRepository {
  PersistentPublisherRepository(SharedPreferences p):super(p,'publishers_v1'){restore();}
  @override Publisher fromJson(Map<String,dynamic> j)=>Publisher.fromJson(j); @override Map<String,dynamic> toJson(Publisher v)=>v.toJson(); @override List<Publisher> seeds()=>seedPublishers; @override int idOf(Publisher v)=>v.id;
  @override Future<List<Publisher>> all({bool includeDeleted=false}) async=>items.where((e)=>includeDeleted||!e.isDeleted).toList(); @override Future<Publisher?> findById(int id) async{for(final e in items){if(e.id==id)return e;}return null;} @override Future<Publisher> create(Publisher v) async{final n=v.copyWith(id:nextId());items.add(n);await persist();return n;} @override Future<Publisher> update(Publisher v) async{final i=items.indexWhere((e)=>e.id==v.id);if(i<0)throw StateError('Издательство не найдено');items[i]=v;await persist();return v;} @override Future<void> delete(int id) async{items.removeWhere((e)=>e.id==id);await persist();}
}
class PersistentReaderRepository extends _JsonRepo<Reader> implements ReaderRepository {
  PersistentReaderRepository(SharedPreferences p):super(p,'readers_v1'){restore();}
  @override Reader fromJson(Map<String,dynamic> j)=>Reader.fromJson(j); @override Map<String,dynamic> toJson(Reader v)=>v.toJson(); @override List<Reader> seeds()=>seedReaders; @override int idOf(Reader v)=>v.id;
  @override Future<List<Reader>> all({bool includeDeleted=false}) async=>items.where((e)=>includeDeleted||!e.isDeleted).toList(); @override Future<Reader?> findById(int id) async{for(final e in items){if(e.id==id)return e;}return null;} @override Future<Reader> create(Reader v) async{final id=nextId();final n=v.copyWith(id:id,card:LibraryCard(id:id,number:v.card.number,issuedAt:v.card.issuedAt,expiresAt:v.card.expiresAt));items.add(n);await persist();return n;} @override Future<Reader> update(Reader v) async{final i=items.indexWhere((e)=>e.id==v.id);if(i<0)throw StateError('Читатель не найден');items[i]=v;await persist();return v;} @override Future<void> delete(int id) async{items.removeWhere((e)=>e.id==id);await persist();} @override Future<bool> isEmailUnique(String email,{int? exceptId}) async=>!items.any((e)=>e.id!=exceptId&&e.email.trim().toLowerCase()==email.trim().toLowerCase());
}
