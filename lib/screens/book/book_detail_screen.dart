import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/book.dart';
import '../../models/author.dart';
import '../../models/genre.dart';
import '../../models/publisher.dart';
import '../../repositories/book_repository.dart';
import '../../repositories/author_repository.dart';
import '../../repositories/genre_repository.dart';
import '../../repositories/publisher_repository.dart';
import '../../state_auth.dart';
class BookDetailScreen extends StatelessWidget{final int bookId;const BookDetailScreen({super.key,required this.bookId});@override Widget build(BuildContext context){return FutureBuilder<List<dynamic>>(future:Future.wait([context.read<BookRepository>().findById(bookId),context.read<AuthorRepository>().all(),context.read<GenreRepository>().all(),context.read<PublisherRepository>().all()]),builder:(c,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());final b=s.data![0] as Book?;if(b==null)return const Center(child:Text('Книга не найдена'));final authors=s.data![1] as List<Author>;final genres=s.data![2] as List<Genre>;final pubs=s.data![3] as List<Publisher>;String pub=pubs.where((e)=>e.id==b.publisherId).map((e)=>e.name).firstOrNull??'—';String aa=authors.where((e)=>b.authorIds.contains(e.id)).map((e)=>e.fullName).join(', ');String gg=genres.where((e)=>b.genreIds.contains(e.id)).map((e)=>e.name).join(', ');return Scaffold(appBar:AppBar(title:const Text('Карточка книги'),actions:[if(context.watch<AuthNotifier>().isLibrarian) IconButton(icon:const Icon(Icons.edit),onPressed:()=>context.go('/books/${b.id}/edit'))]),body:ListView(padding:const EdgeInsets.all(20),children:[Text(b.title,style:Theme.of(context).textTheme.headlineMedium),const SizedBox(height:20),_r('ISBN',b.isbn),_r('Год','${b.year}'),_r('Страниц','${b.pages}'),_r('Издательство',pub),_r('Авторы',aa),_r('Жанры',gg),_r('Экземпляров','${b.copiesAvailable} из ${b.copiesTotal}'),_r('Создано',b.createdAt.toLocal().toString())]));});}Widget _r(String a,String b)=>Card(child:ListTile(title:Text(a),subtitle:Text(b)));}
extension _FirstOrNull<T> on Iterable<T>{T? get firstOrNull=>isEmpty?null:first;}
