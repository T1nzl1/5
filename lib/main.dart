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
    final items = <({IconData icon, String label, String route})>[
      (icon: Icons.book, label: 'Книги', route: '/'),
    ];

    if (auth.isReader) {
      items.add((icon: Icons.assignment, label: 'Мои выдачи', route: '/my-loans'));
    }
    if (auth.isLibrarian) {
      items.addAll([
        (icon: Icons.people, label: 'Авторы', route: '/authors'),
        (icon: Icons.category, label: 'Жанры', route: '/genres'),
        (icon: Icons.apartment, label: 'Издательства', route: '/publishers'),
        (icon: Icons.badge, label: 'Читатели', route: '/readers'),
        (icon: Icons.assignment, label: 'Выдачи', route: '/loans/manage'),
      ]);
    }
    if (auth.isAdmin) {
      items.add((icon: Icons.admin_panel_settings, label: 'Админ', route: '/admin/users'));
    }

    var index = 0;
    for (var i = 1; i < items.length; i++) {
      if (path.startsWith(items[i].route)) index = i;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 768;
        final extendedRail = constraints.maxWidth >= 1280;
        final content = Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: child,
          ),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'LibraryDen • ${auth.user?.name ?? ''} (${auth.user?.role.label ?? ''})',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                tooltip: 'Выйти',
                onPressed: () async => auth.logout(),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: useRail
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: index,
                      extended: extendedRail,
                      labelType: extendedRail ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                      onDestinationSelected: (i) => context.go(items[i].route),
                      destinations: [
                        for (final item in items)
                          NavigationRailDestination(
                            icon: Icon(item.icon),
                            label: Text(item.label),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                )
              : content,
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: index,
                  onDestinationSelected: (i) => context.go(items[i].route),
                  destinations: [
                    for (final item in items)
                      NavigationDestination(icon: Icon(item.icon), label: item.label),
                  ],
                ),
        );
      },
    );
  }
}
