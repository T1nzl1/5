import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/genre.dart';
import '../../repositories/genre_repository.dart';
import '../../utils/validators.dart';

class GenreListScreen extends StatefulWidget {
  const GenreListScreen({super.key});

  @override
  State<GenreListScreen> createState() => _GenreListScreenState();
}

class _GenreListScreenState extends State<GenreListScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<GenreRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Жанры'),
        actions: [
          IconButton(
            onPressed: () => context.go('/genres/new'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder<List<Genre>>(
        key: ValueKey(_reload),
        future: repo.all(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const <Genre>[];
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final genre = items[index];
              return ListTile(
                title: Text(genre.name),
                subtitle: Text(genre.description),
                onTap: () => context.go('/genres/${genre.id}'),
                trailing: Wrap(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => context.go('/genres/${genre.id}/edit'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await repo.delete(genre.id);
                        if (!context.mounted) return;
                        setState(() => _reload++);
                      },
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
}

class GenreDetailScreen extends StatelessWidget {
  final int id;
  const GenreDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Genre?>(
      future: context.read<GenreRepository>().findById(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final genre = snapshot.data;
        if (genre == null) {
          return const Center(child: Text('Жанр не найден'));
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Карточка жанра'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.go('/genres/${genre.id}/edit'),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(genre.name, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                Text(genre.description),
              ],
            ),
          ),
        );
      },
    );
  }
}

class GenreFormScreen extends StatefulWidget {
  final int? id;
  const GenreFormScreen({super.key, this.id});

  @override
  State<GenreFormScreen> createState() => _GenreFormScreenState();
}

class _GenreFormScreenState extends State<GenreFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<GenreRepository>();
    if (widget.id != null) {
      final genre = await repo.findById(widget.id!);
      if (genre != null) {
        _name.text = genre.name;
        _description.text = genre.description;
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'Новый жанр' : 'Редактирование жанра'),
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
                maxLength: 80,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
              ),
              validator: (v) => Validators.requiredText(
                v,
                label: 'Описание',
                maxLength: 300,
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
    final repo = context.read<GenreRepository>();
    final genre = Genre(
      id: widget.id ?? 0,
      name: _name.text.trim(),
      description: _description.text.trim(),
    );
    if (widget.id == null) {
      await repo.create(genre);
    } else {
      await repo.update(genre);
    }
    if (!mounted) return;
    context.go('/genres');
  }
}
