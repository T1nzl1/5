import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/publisher.dart';
import '../../repositories/book_repository.dart';
import '../../repositories/publisher_repository.dart';
import '../../utils/validators.dart';

class PublisherListScreen extends StatefulWidget {
  const PublisherListScreen({super.key});

  @override
  State<PublisherListScreen> createState() => _PublisherListScreenState();
}

class _PublisherListScreenState extends State<PublisherListScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<PublisherRepository>();
    final bookRepo = context.read<BookRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Издательства'),
        actions: [
          IconButton(
            onPressed: () => context.go('/publishers/new'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder<List<Publisher>>(
        key: ValueKey(_reload),
        future: repo.all(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const <Publisher>[];
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final publisher = items[index];
              return ListTile(
                title: Text(publisher.name),
                subtitle: Text('${publisher.city} • ${publisher.foundedYear}'),
                onTap: () => context.go('/publishers/${publisher.id}'),
                trailing: Wrap(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          context.go('/publishers/${publisher.id}/edit'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deletePublisher(
                        context,
                        repo,
                        bookRepo,
                        publisher,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deletePublisher(
    BuildContext context,
    PublisherRepository repo,
    BookRepository bookRepo,
    Publisher publisher,
  ) async {
    final count = await bookRepo.countByPublisher(publisher.id);
    if (!context.mounted) return;

    if (count > 0) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Удаление невозможно'),
          content: Text(
            'На издательство «${publisher.name}» ссылаются книги: $count шт.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Понятно'),
            ),
          ],
        ),
      );
      return;
    }

    await repo.delete(publisher.id);
    if (!context.mounted) return;
    setState(() => _reload++);
  }
}

class PublisherDetailScreen extends StatelessWidget {
  final int id;
  const PublisherDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Publisher?>(
      future: context.read<PublisherRepository>().findById(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final publisher = snapshot.data;
        if (publisher == null) {
          return const Center(child: Text('Издательство не найдено'));
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Карточка издательства'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () =>
                    context.go('/publishers/${publisher.id}/edit'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                publisher.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Card(
                child: ListTile(
                  title: const Text('Город'),
                  subtitle: Text(publisher.city),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Год основания'),
                  subtitle: Text('${publisher.foundedYear}'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PublisherFormScreen extends StatefulWidget {
  final int? id;
  const PublisherFormScreen({super.key, this.id});

  @override
  State<PublisherFormScreen> createState() => _PublisherFormScreenState();
}

class _PublisherFormScreenState extends State<PublisherFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _year = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<PublisherRepository>();
    if (widget.id != null) {
      final publisher = await repo.findById(widget.id!);
      if (publisher != null) {
        _name.text = publisher.name;
        _city.text = publisher.city;
        _year.text = '${publisher.foundedYear}';
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _year.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.id == null ? 'Новое издательство' : 'Редактирование издательства',
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Название',
                border: OutlineInputBorder(),
              ),
              validator: (v) => Validators.requiredText(
                v,
                label: 'Название',
                maxLength: 100,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _city,
              decoration: const InputDecoration(
                labelText: 'Город',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  Validators.requiredText(v, label: 'Город', maxLength: 80),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _year,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Год основания',
                border: OutlineInputBorder(),
              ),
              validator: (v) => Validators.intRange(
                v,
                label: 'Год основания',
                min: 1000,
                max: 2026,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('Сохранить')),
          ],
        ),
      ))),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = context.read<PublisherRepository>();
    final publisher = Publisher(
      id: widget.id ?? 0,
      name: _name.text.trim(),
      city: _city.text.trim(),
      foundedYear: int.parse(_year.text),
    );
    if (widget.id == null) {
      await repo.create(publisher);
    } else {
      await repo.update(publisher);
    }
    if (!mounted) return;
    context.go('/publishers');
  }
}
