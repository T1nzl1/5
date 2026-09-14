import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/book.dart';
import '../../models/genre.dart';
import '../../models/publisher.dart';
import '../../repositories/book_repository.dart';
import '../../repositories/genre_repository.dart';
import '../../repositories/publisher_repository.dart';
import '../../widgets/entity_table.dart';
import '../../state_auth.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final _searchController = TextEditingController();
  final _yearFromController = TextEditingController();
  final _yearToController = TextEditingController();

  int? _genreId;
  int? _publisherId;
  String _sortField = 'title';
  bool _sortAscending = true;
  int _reload = 0;

  @override
  void dispose() {
    _searchController.dispose();
    _yearFromController.dispose();
    _yearToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookRepo = context.read<BookRepository>();
    final genreRepo = context.read<GenreRepository>();
    final publisherRepo = context.read<PublisherRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог книг'),
        actions: [
          if (context.watch<AuthNotifier>().has(Role.librarian)) IconButton(
            tooltip: 'Добавить книгу',
            onPressed: () => context.go('/books/new'),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Обновить',
            onPressed: () => setState(() => _reload++),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearch(),
          FutureBuilder<(List<Genre>, List<Publisher>)>(
            key: ValueKey('filters-$_reload'),
            future: _loadFilters(genreRepo, publisherRepo),
            builder: (context, snapshot) {
              final genres = snapshot.data?.$1 ?? const <Genre>[];
              final publishers = snapshot.data?.$2 ?? const <Publisher>[];
              return _buildFilters(genres, publishers);
            },
          ),
          Expanded(
            child: FutureBuilder<List<Book>>(
              key: ValueKey('books-$_reload'),
              future: bookRepo.all(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.cloud_off, size: 48),
                      const SizedBox(height: 12),
                      Text('Ошибка загрузки: ${snapshot.error}', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton.icon(onPressed: () => setState(() => _reload++), icon: const Icon(Icons.refresh), label: const Text('Повторить')),
                    ]),
                  ));
                }

                final rows = _applyQuery(snapshot.data ?? const <Book>[]);
                if (rows.isEmpty) {
                  return const Center(child: Text('Ничего не найдено'));
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 600) {
                      return EntityTable<Book>(
                        selectable: false,
                        items: rows,
                        idOf: (b) => b.id,
                        sortField: _sortField,
                        sortAscending: _sortAscending,
                        onSort: _changeSort,
                        columns: [
                          TableColumnSpec<Book>(
                            label: 'Название',
                            sortField: 'title',
                            build: (b) => Text(b.title),
                          ),
                          TableColumnSpec<Book>(
                            label: 'ISBN',
                            build: (b) => Text(b.isbn),
                          ),
                          TableColumnSpec<Book>(
                            label: 'Год',
                            sortField: 'year',
                            numeric: true,
                            build: (b) => Text('${b.year}'),
                          ),
                          TableColumnSpec<Book>(
                            label: 'Страниц',
                            sortField: 'pages',
                            numeric: true,
                            build: (b) => Text('${b.pages}'),
                          ),
                          TableColumnSpec<Book>(
                            label: 'Доступно',
                            numeric: true,
                            build: (b) => Text(
                              '${b.copiesAvailable}/${b.copiesTotal}',
                            ),
                          ),
                        ],
                        actions: (b) => _actions(context, bookRepo, b),
                      );
                    }

                    return ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final b = rows[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text(b.title),
                            subtitle: Text(
                              '${b.year} • ${b.pages} стр. • ISBN ${b.isbn}\n'
                              'Доступно: ${b.copiesAvailable}/${b.copiesTotal}',
                            ),
                            isThreeLine: true,
                            onTap: () => context.go('/books/${b.id}'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'view') {
                                  context.go('/books/${b.id}');
                                } else if (value == 'edit') {
                                  context.go('/books/${b.id}/edit');
                                } else if (value == 'delete') {
                                  _deleteBook(context, bookRepo, b);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'view', child: Text('Просмотр')),
                                if (context.read<AuthNotifier>().has(Role.librarian)) const PopupMenuItem(value: 'edit', child: Text('Изменить')),
                                if (context.read<AuthNotifier>().has(Role.librarian)) const PopupMenuItem(value: 'delete', child: Text('Удалить')),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<(List<Genre>, List<Publisher>)> _loadFilters(
    GenreRepository genreRepo,
    PublisherRepository publisherRepo,
  ) async {
    final results = await Future.wait([genreRepo.all(), publisherRepo.all()]);
    return (
      results[0] as List<Genre>,
      results[1] as List<Publisher>,
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Поиск по названию или ISBN',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildFilters(List<Genre> genres, List<Publisher> publishers) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<int?>(
                initialValue: _genreId,
                decoration: const InputDecoration(
                  labelText: 'Жанр',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Все жанры'),
                  ),
                  ...genres.map(
                    (g) => DropdownMenuItem<int?>(
                      value: g.id,
                      child: Text(g.name),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _genreId = value),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<int?>(
                initialValue: _publisherId,
                decoration: const InputDecoration(
                  labelText: 'Издательство',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Все издательства'),
                  ),
                  ...publishers.map(
                    (p) => DropdownMenuItem<int?>(
                      value: p.id,
                      child: Text(p.name),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _publisherId = value),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 110,
              child: TextField(
                controller: _yearFromController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Год от',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 110,
              child: TextField(
                controller: _yearToController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Год до',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Сбросить'),
            ),
          ],
        ),
      ),
    );
  }

  List<Book> _applyQuery(List<Book> source) {
    var rows = [...source];
    final search = _searchController.text.trim().toLowerCase();
    final yearFrom = int.tryParse(_yearFromController.text.trim());
    final yearTo = int.tryParse(_yearToController.text.trim());

    if (search.isNotEmpty) {
      rows = rows
          .where(
            (b) =>
                b.title.toLowerCase().contains(search) ||
                b.isbn.toLowerCase().contains(search),
          )
          .toList();
    }
    if (_genreId != null) {
      rows = rows.where((b) => b.genreIds.contains(_genreId)).toList();
    }
    if (_publisherId != null) {
      rows = rows.where((b) => b.publisherId == _publisherId).toList();
    }
    if (yearFrom != null) {
      rows = rows.where((b) => b.year >= yearFrom).toList();
    }
    if (yearTo != null) {
      rows = rows.where((b) => b.year <= yearTo).toList();
    }

    rows.sort((a, b) {
      final result = switch (_sortField) {
        'year' => a.year.compareTo(b.year),
        'pages' => a.pages.compareTo(b.pages),
        _ => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      };
      return _sortAscending ? result : -result;
    });

    return rows;
  }

  void _changeSort(String field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = true;
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _yearFromController.clear();
      _yearToController.clear();
      _genreId = null;
      _publisherId = null;
      _sortField = 'title';
      _sortAscending = true;
    });
  }

  List<Widget> _actions(
    BuildContext context,
    BookRepository repo,
    Book book,
  ) {
    return [
      IconButton(
        tooltip: 'Просмотр',
        icon: const Icon(Icons.visibility),
        onPressed: () => context.go('/books/${book.id}'),
      ),
      if (context.read<AuthNotifier>().has(Role.librarian)) IconButton(
        tooltip: 'Изменить',
        icon: const Icon(Icons.edit),
        onPressed: () => context.go('/books/${book.id}/edit'),
      ),
      if (context.read<AuthNotifier>().has(Role.librarian)) IconButton(
        tooltip: 'Удалить',
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _deleteBook(context, repo, book),
      ),
    ];
  }

  Future<void> _deleteBook(
    BuildContext context,
    BookRepository repo,
    Book book,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить книгу?'),
        content: Text(book.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    await repo.delete(book.id);
    if (!context.mounted) return;
    setState(() => _reload++);
  }
}
