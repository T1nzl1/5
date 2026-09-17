import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_exceptions.dart';

String _date(dynamic value) {
  if (value == null) return '—';
  final d = DateTime.tryParse(value.toString())?.toLocal();
  if (d == null) return value.toString();
  return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

void _showError(BuildContext context, Object error) {
  final text =
      error is DioException ? mapDioError(error).toString() : error.toString();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class ReaderLoansScreen extends StatefulWidget {
  const ReaderLoansScreen({super.key});
  @override
  State<ReaderLoansScreen> createState() => _ReaderLoansScreenState();
}

class _ReaderLoansScreenState extends State<ReaderLoansScreen> {
  int reload = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои выдачи'),
        actions: [
          IconButton(
              onPressed: () => setState(() => reload++),
              icon: const Icon(Icons.refresh))
        ],
      ),
      body: FutureBuilder<Response<dynamic>>(
        key: ValueKey(reload),
        future: context.read<Dio>().get('/loans'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          final items = ((snapshot.data?.data['items'] as List?) ?? const [])
              .cast<dynamic>();
          if (items.isEmpty) {
            return const Center(child: Text('У вас пока нет выдач'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final x = Map<String, dynamic>.from(items[index]);
              final active = x['returnedAt'] == null;
              return Card(
                child: ListTile(
                  leading: Icon(active ? Icons.menu_book : Icons.task_alt),
                  title: Text(
                      ((x['book'] as Map?)?['title'])?.toString() ?? 'Книга'),
                  subtitle: Text(
                    'Выдано: ${_date(x['issuedAt'])}\n'
                    'Вернуть до: ${_date(x['dueAt'])}\n'
                    'Статус: ${active ? 'активна' : 'возвращена'}',
                  ),
                  isThreeLine: true,
                  trailing: active
                      ? FilledButton.tonalIcon(
                          onPressed: () => _renew(context, x['id'] as int),
                          icon: const Icon(Icons.update),
                          label: const Text('Продлить'),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _renew(BuildContext context, int id) async {
    try {
      await context.read<Dio>().post('/loans/$id/renew');
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Срок выдачи продлён на 14 дней')));
      setState(() => reload++);
    } catch (e) {
      if (context.mounted) {
        _showError(context, e);
      }
    }
  }
}

class LibrarianLoansScreen extends StatefulWidget {
  const LibrarianLoansScreen({super.key});
  @override
  State<LibrarianLoansScreen> createState() => _LibrarianLoansScreenState();
}

class _LibrarianLoansScreenState extends State<LibrarianLoansScreen> {
  int reload = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оформление выдач'),
        actions: [
          FilledButton.icon(
            onPressed: () => _issueDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Оформить выдачу'),
          ),
          const SizedBox(width: 8),
          IconButton(
              onPressed: () => setState(() => reload++),
              icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<Response<dynamic>>(
        key: ValueKey(reload),
        future: context.read<Dio>().get('/loans'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          final items = ((snapshot.data?.data['items'] as List?) ?? const [])
              .cast<dynamic>();
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.assignment_outlined, size: 56),
                  const SizedBox(height: 12),
                  const Text('Выдач пока нет'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                      onPressed: () => _issueDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Оформить первую выдачу')),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final x = Map<String, dynamic>.from(items[index]);
              final active = x['returnedAt'] == null;
              return Card(
                child: ListTile(
                  leading: Icon(
                      active ? Icons.assignment : Icons.assignment_turned_in),
                  title: Text(
                      ((x['book'] as Map?)?['title'])?.toString() ?? 'Книга'),
                  subtitle: Text(
                    'Читатель: ${(x['reader'] as Map?)?['fullName'] ?? '—'}\n'
                    'Выдано: ${_date(x['issuedAt'])} • до ${_date(x['dueAt'])}\n'
                    'Статус: ${active ? 'активна' : 'закрыта'}',
                  ),
                  isThreeLine: true,
                  trailing: active
                      ? FilledButton.tonalIcon(
                          onPressed: () => _returnLoan(context, x['id'] as int),
                          icon: const Icon(Icons.keyboard_return),
                          label: const Text('Закрыть'),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _issueDialog(BuildContext context) async {
    try {
      final dio = context.read<Dio>();
      final results = await Future.wait([
        dio.get('/readers', queryParameters: {'size': 100}),
        dio.get('/books', queryParameters: {'size': 100}),
      ]);
      if (!context.mounted) {
        return;
      }
      final readers =
          ((results[0].data['items'] as List?) ?? const []).cast<dynamic>();
      final books =
          ((results[1].data['items'] as List?) ?? const []).cast<dynamic>();
      if (readers.isEmpty || books.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Для выдачи нужны хотя бы один читатель и одна книга')));
        return;
      }
      int readerId = readers.first['id'] as int;
      int bookId = books.first['id'] as int;
      int days = 14;
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Новая выдача'),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: readerId,
                    decoration: const InputDecoration(
                        labelText: 'Читатель', border: OutlineInputBorder()),
                    items: readers
                        .map<DropdownMenuItem<int>>((r) => DropdownMenuItem(
                            value: r['id'] as int,
                            child: Text(r['fullName'].toString())))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => readerId = v);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: bookId,
                    decoration: const InputDecoration(
                        labelText: 'Книга', border: OutlineInputBorder()),
                    items: books
                        .map<DropdownMenuItem<int>>((b) => DropdownMenuItem(
                              value: b['id'] as int,
                              child: Text(
                                  '${b['title']} (доступно ${b['copiesAvailable']}/${b['copiesTotal']})'),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => bookId = v);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: days,
                    decoration: const InputDecoration(
                        labelText: 'Срок', border: OutlineInputBorder()),
                    items: const [7, 14, 21, 30]
                        .map((d) =>
                            DropdownMenuItem(value: d, child: Text('$d дней')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => days = v);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Отмена')),
              FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Оформить')),
            ],
          ),
        ),
      );
      if (ok != true || !context.mounted) {
        return;
      }
      await dio.post('/loans', data: {
        'readerId': readerId,
        'bookId': bookId,
        'days': days,
      });
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Выдача успешно оформлена')));
      setState(() => reload++);
    } catch (e) {
      if (context.mounted) {
        _showError(context, e);
      }
    }
  }

  Future<void> _returnLoan(BuildContext context, int id) async {
    final dio = context.read<Dio>();

    try {
      await dio.post('/loans/$id/return');

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выдача закрыта, экземпляр возвращён'),
        ),
      );

      setState(() => reload++);
    } catch (e) {
      if (context.mounted) {
        _showError(context, e);
      }
    }
  }
}

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  int reload = 0;
  static const resources = <String, String>{
    'books': 'Книги',
    'authors': 'Авторы',
    'genres': 'Жанры',
    'publishers': 'Издательства',
    'readers': 'Читатели',
  };

  Future<Map<String, dynamic>> _load(Dio dio) async {
    final calls = <Future<Response<dynamic>>>[
      dio.get('/admin/users'),
      dio.get('/admin/stats'),
      ...resources.keys.map((r) => dio
          .get('/$r', queryParameters: {'includeDeleted': true, 'size': 100})),
    ];
    final data = await Future.wait(calls);
    final deleted = <Map<String, dynamic>>[];
    var i = 2;
    for (final entry in resources.entries) {
      final items =
          ((data[i++].data['items'] as List?) ?? const []).cast<dynamic>();
      for (final x in items) {
        if (x['deletedAt'] != null) {
          deleted.add({
            'resource': entry.key,
            'resourceLabel': entry.value,
            'item': x,
          });
        }
      }
    }
    return {
      'users': data[0].data as List,
      'stats': Map<String, dynamic>.from(data[1].data),
      'deleted': deleted
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Администрирование'),
        actions: [
          IconButton(
              onPressed: () => setState(() => reload++),
              icon: const Icon(Icons.refresh))
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        key: ValueKey(reload),
        future: _load(context.read<Dio>()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          final data = snapshot.data!;
          final users = (data['users'] as List).cast<dynamic>();
          final stats = data['stats'] as Map<String, dynamic>;
          final deleted =
              (data['deleted'] as List).cast<Map<String, dynamic>>();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Статистика', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _Stat(
                      label: 'Пользователей',
                      value: '${stats['users'] ?? 0}',
                      icon: Icons.people),
                  _Stat(
                      label: 'Читателей',
                      value: '${stats['readers'] ?? 0}',
                      icon: Icons.badge),
                  _Stat(
                      label: 'Книг',
                      value: '${stats['books'] ?? 0}',
                      icon: Icons.menu_book),
                  _Stat(
                      label: 'Активных выдач',
                      value: '${stats['activeLoans'] ?? 0}',
                      icon: Icons.assignment),
                  _Stat(
                      label: 'Удалённых записей',
                      value: '${stats['deleted'] ?? 0}',
                      icon: Icons.delete_outline),
                ],
              ),
              const SizedBox(height: 24),
              Text('Пользователи и роли',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: users
                      .map((x) => ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(x['name'].toString()),
                            subtitle: Text('${x['username']} • ${x['role']}'),
                            trailing: DropdownButton<String>(
                              value: x['role'].toString(),
                              items: const ['reader', 'librarian', 'admin']
                                  .map((r) => DropdownMenuItem(
                                      value: r, child: Text(r)))
                                  .toList(),
                              onChanged: (v) =>
                                  _changeRole(context, x['id'] as int, v),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
              Text('Удалённые записи',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (deleted.isEmpty)
                const Card(
                    child: ListTile(
                        leading: Icon(Icons.check_circle_outline),
                        title: Text('Удалённых записей нет')))
              else
                ...deleted.map((row) {
                  final item = row['item'] as dynamic;
                  final label = item['title'] ??
                      item['fullName'] ??
                      item['name'] ??
                      'Запись #${item['id']}';
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: Text(label.toString()),
                      subtitle: Text(
                          '${row['resourceLabel']} • удалено ${_date(item['deletedAt'])}'),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () => _restore(context,
                                row['resource'] as String, item['id'] as int),
                            icon: const Icon(Icons.restore),
                            label: const Text('Восстановить'),
                          ),
                          IconButton(
                            tooltip: 'Удалить физически',
                            onPressed: () => _hardDelete(
                                context,
                                row['resource'] as String,
                                item['id'] as int,
                                label.toString()),
                            icon: const Icon(Icons.delete_forever),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Future<void> _changeRole(BuildContext context, int id, String? role) async {
    if (role == null) {
      return;
    }
    try {
      await context
          .read<Dio>()
          .put('/admin/users/$id/role', data: {'role': role});
      if (context.mounted) {
        setState(() => reload++);
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, e);
      }
    }
  }

  Future<void> _restore(BuildContext context, String resource, int id) async {
    try {
      await context.read<Dio>().post('/$resource/$id/restore');
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Запись восстановлена')));
      setState(() => reload++);
    } catch (e) {
      if (context.mounted) {
        _showError(context, e);
      }
    }
  }

  Future<void> _hardDelete(
      BuildContext context, String resource, int id, String label) async {
    final dio = context.read<Dio>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Удалить физически?'),
        content: Text('$label будет удалён без возможности восстановления.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Отмена')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Удалить навсегда')),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await dio.delete(
        '/$resource/$id',
        queryParameters: {'hard': true},
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Запись физически удалена')));
      setState(() => reload++);
    } catch (e) {
      if (context.mounted) {
        _showError(context, e);
      }
    }
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Stat({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Card(
        child: SizedBox(
          width: 180,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, size: 30),
                const SizedBox(height: 8),
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
                Text(label, textAlign: TextAlign.center)
              ],
            ),
          ),
        ),
      );
}
