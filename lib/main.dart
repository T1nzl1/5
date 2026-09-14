import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_router.dart';
import 'core/api_client.dart';
import 'state_auth.dart';
import 'repositories/api_repositories.dart';
import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/publisher_repository.dart';
import 'repositories/reader_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  AuthNotifier? auth;
  final dio = buildDio(tokenProvider: () => auth?.accessToken);
  auth = AuthNotifier(prefs, dio);
  await auth.restore();
  runApp(MultiProvider(
    providers: [
      Provider<Dio>.value(value: dio),
      ChangeNotifierProvider<AuthNotifier>.value(value: auth),
      Provider<BookRepository>(create: (_) => ApiBookRepository(dio)),
      Provider<AuthorRepository>(create: (_) => ApiAuthorRepository(dio)),
      Provider<GenreRepository>(create: (_) => ApiGenreRepository(dio)),
      Provider<PublisherRepository>(create: (_) => ApiPublisherRepository(dio)),
      Provider<ReaderRepository>(create: (_) => ApiReaderRepository(dio)),
    ],
    child: LibraryApp(auth: auth),
  ));
}

class LibraryApp extends StatelessWidget {
  final AuthNotifier auth;
  const LibraryApp({super.key, required this.auth});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'LibraryDen',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
        routerConfig: AppRouter.build(auth),
      );
}

class MainScreen extends StatelessWidget {
  final Widget child;
  const MainScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final path = GoRouterState.of(context).uri.path;
    final destinations = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.book), label: 'Книги'),
    ];
    final routes = <String>['/'];

    if (auth.isReader) {
      destinations.add(const NavigationDestination(icon: Icon(Icons.assignment), label: 'Мои выдачи'));
      routes.add('/my-loans');
    }
    if (auth.isLibrarian) {
      destinations.addAll(const [
        NavigationDestination(icon: Icon(Icons.people), label: 'Авторы'),
        NavigationDestination(icon: Icon(Icons.category), label: 'Жанры'),
        NavigationDestination(icon: Icon(Icons.apartment), label: 'Издательства'),
        NavigationDestination(icon: Icon(Icons.badge), label: 'Читатели'),
        NavigationDestination(icon: Icon(Icons.assignment), label: 'Выдачи'),
      ]);
      routes.addAll(['/authors', '/genres', '/publishers', '/readers', '/loans/manage']);
    }
    if (auth.isAdmin) {
      destinations.add(const NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: 'Админ'));
      routes.add('/admin/users');
    }

    var index = 0;
    for (var i = 1; i < routes.length; i++) {
      if (path.startsWith(routes[i])) index = i;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('LibraryDen • ${auth.user?.name ?? ''} (${auth.user?.role.label ?? ''})'),
        actions: [
          IconButton(tooltip: 'Выйти', onPressed: () async => auth.logout(), icon: const Icon(Icons.logout)),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(routes[i]),
        destinations: destinations,
      ),
    );
  }
}
