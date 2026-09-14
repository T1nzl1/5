import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'main.dart' show MainScreen;
import 'state_auth.dart';
import 'screens/auth/auth_screens.dart';
import 'screens/role/role_screens.dart';
import 'screens/book/book_list_screen.dart';
import 'screens/book/book_detail_screen.dart';
import 'screens/book/book_form_screen.dart';
import 'screens/author/author_list_screen.dart';
import 'screens/author/author_detail_screen.dart';
import 'screens/author/author_form_screen.dart';
import 'screens/genre/genre_screens.dart';
import 'screens/publisher/publisher_screens.dart';
import 'screens/reader/reader_screens.dart';

class AppRouter {
  static GoRouter build(AuthNotifier auth) => GoRouter(
        initialLocation: '/',
        refreshListenable: auth,
        redirect: (context, state) {
          final p = state.uri.path;
          final isPublic = p == '/login' || p == '/register';
          if (!auth.isAuthenticated && !isPublic) {
            return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
          }
          if (auth.isAuthenticated && isPublic) return '/';

          // Защита закрытых маршрутов при ручном вводе URL
          if (p.startsWith('/admin') && !auth.isAdmin) {
            return '/forbidden';
          }
          if (p.startsWith('/loans/manage') && !auth.isLibrarian) {
            return '/forbidden';
          }
          if ((p.startsWith('/authors') || p.startsWith('/genres') || p.startsWith('/publishers') || p.startsWith('/readers')) && !auth.isLibrarian) {
            return '/forbidden';
          }

          return null;
        },
        routes: [
          GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
          GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
          GoRoute(path: '/forbidden', builder: (c, s) => const ForbiddenScreen()),

          GoRoute(path: '/', builder: (c, s) => const MainScreen(child: BookListScreen())),
          GoRoute(
            path: '/books/new',
            redirect: (c, s) => auth.isLibrarian ? null : '/forbidden',
            builder: (c, s) => const MainScreen(child: BookFormScreen()),
          ),
          GoRoute(
            path: '/books/:id',
            builder: (c, s) => MainScreen(child: BookDetailScreen(bookId: int.parse(s.pathParameters['id']!))),
          ),
          GoRoute(
            path: '/books/:id/edit',
            redirect: (c, s) => auth.isLibrarian ? null : '/forbidden',
            builder: (c, s) => MainScreen(child: BookFormScreen(id: int.parse(s.pathParameters['id']!))),
          ),

          GoRoute(path: '/authors', redirect: (c, s) => auth.isLibrarian ? null : '/forbidden', builder: (c, s) => const MainScreen(child: AuthorListScreen())),
          GoRoute(path: '/authors/new', redirect: (c, s) => auth.isLibrarian ? null : '/forbidden', builder: (c, s) => const MainScreen(child: AuthorFormScreen())),
          GoRoute(path: '/authors/:id', redirect: (c, s) => auth.isLibrarian ? null : '/forbidden', builder: (c, s) => MainScreen(child: AuthorDetailScreen(authorId: int.parse(s.pathParameters['id']!)))),
          GoRoute(path: '/authors/:id/edit', redirect: (c, s) => auth.isLibrarian ? null : '/forbidden', builder: (c, s) => MainScreen(child: AuthorFormScreen(id: int.parse(s.pathParameters['id']!)))),

          GoRoute(path: '/genres', redirect: (c, s) => auth.isLibrarian ? null : '/forbidden', builder: (c, s) => const MainScreen(child: GenreListScreen())),
          GoRoute(path: '/genres/new', redirect: (c, s) => auth.isLibrarian ? null : '/forbidden', builder: (c, s) => const MainScreen(child: GenreFormScreen())),
          GoRoute(path: '/genres/:id', redirect: (c, s) => auth.isLibrarian ? null : '/forbidden', builder: (c, s) => MainScreen(child: GenreDetailScreen(id: int.parse(s.pathParameters['id']!)))),
          GoRoute(path: '/genres/:id/edit', redirect: (c, s) => auth.isLibrarian ? null : '/forbidden', builder: (c, s) => MainScreen(child: GenreFormScreen(id: int.parse(s.pathParameters['id']!)))),

          GoRoute(path: '/publishers', redirect: (c, s) => auth.isLibrarian ? null : '/forbidden', builder: (c, s) => const MainScreen(child: PublisherListScreen())),
          GoRoute(path: '/publishers/new', redirect: (c, s) => auth.isLibrarian ? null : '/forbidden', builder: (c, s) => const MainScreen(child: PublisherFormScreen())),
          GoRoute(path: '/publishers/:id', redirect: (c, s) => auth.isLibrarian ? null : '/forbidden', builder: (c, s) => MainScreen(child: PublisherDetailScreen(id: int.parse(s.pathParameters['id']!)))),
          GoRoute(path: '/publishers/:id/edit', redirect: (c, s) => auth.isLibrarian ? null : '/forbidden', builder: (c, s) => MainScreen(child: PublisherFormScreen(id: int.parse(s.pathParameters['id']!)))),

          GoRoute(path: '/readers', redirect: (c, s) => auth.isLibrarian ? null : '/forbidden', builder: (c, s) => const MainScreen(child: ReaderListScreen())),
          GoRoute(path: '/readers/new', redirect: (c, s) => auth.isLibrarian ? null : '/forbidden', builder: (c, s) => const MainScreen(child: ReaderFormScreen())),
          GoRoute(path: '/readers/:id', redirect: (c, s) => auth.isLibrarian ? null : '/forbidden', builder: (c, s) => MainScreen(child: ReaderDetailScreen(id: int.parse(s.pathParameters['id']!)))),
          GoRoute(path: '/readers/:id/edit', redirect: (c, s) => auth.isLibrarian ? null : '/forbidden', builder: (c, s) => MainScreen(child: ReaderFormScreen(id: int.parse(s.pathParameters['id']!)))),

          GoRoute(path: '/my-loans', redirect: (c, s) => auth.isReader ? null : '/forbidden', builder: (c, s) => const MainScreen(child: ReaderLoansScreen())),
          GoRoute(path: '/loans/manage', redirect: (c, s) => auth.isLibrarian ? null : '/forbidden', builder: (c, s) => const MainScreen(child: LibrarianLoansScreen())),
          GoRoute(path: '/admin/users', redirect: (c, s) => auth.isAdmin ? null : '/forbidden', builder: (c, s) => const MainScreen(child: AdminUsersScreen())),
        ],
        errorBuilder: (c, s) => Scaffold(body: Center(child: Text('Страница не найдена: ${s.uri.path}'))),
      );
}
