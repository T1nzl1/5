import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/author.dart';
import '../../repositories/author_repository.dart';

class AuthorListScreen extends StatefulWidget {
  const AuthorListScreen({super.key});

  @override
  State<AuthorListScreen> createState() => _AuthorListScreenState();
}

class _AuthorListScreenState extends State<AuthorListScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AuthorRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Авторы'),
        actions: [
          IconButton(
            onPressed: () => context.go('/authors/new'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder<List<Author>>(
        key: ValueKey(_reload),
        future: repo.all(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const <Author>[];
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final author = items[index];
              return ListTile(
                title: Text(author.fullName),
                subtitle: Text('${author.birthYear} • ${author.country}'),
                onTap: () => context.go('/authors/${author.id}'),
                trailing: Wrap(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => context.go('/authors/${author.id}/edit'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await repo.delete(author.id);
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
