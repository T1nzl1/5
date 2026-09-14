import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/reader.dart';
import '../../repositories/reader_repository.dart';
import '../../utils/validators.dart';

class ReaderListScreen extends StatefulWidget {
  const ReaderListScreen({super.key});

  @override
  State<ReaderListScreen> createState() => _ReaderListScreenState();
}

class _ReaderListScreenState extends State<ReaderListScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ReaderRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Читатели'),
        actions: [
          IconButton(
            onPressed: () => context.go('/readers/new'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder<List<Reader>>(
        key: ValueKey(_reload),
        future: repo.all(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const <Reader>[];
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final reader = items[index];
              return ListTile(
                title: Text(reader.fullName),
                subtitle: Text('${reader.email} • ${reader.card.number}'),
                onTap: () => context.go('/readers/${reader.id}'),
                trailing: Wrap(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => context.go('/readers/${reader.id}/edit'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await repo.delete(reader.id);
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

class ReaderDetailScreen extends StatelessWidget {
  final int id;
  const ReaderDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Reader?>(
      future: context.read<ReaderRepository>().findById(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final reader = snapshot.data;
        if (reader == null) {
          return const Center(child: Text('Читатель не найден'));
        }
        String date(DateTime value) => value.toIso8601String().substring(0, 10);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Карточка читателя'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.go('/readers/${reader.id}/edit'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(reader.fullName, style: Theme.of(context).textTheme.headlineMedium),
              Card(
                child: ListTile(
                  title: const Text('Email'),
                  subtitle: Text(reader.email),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Телефон'),
                  subtitle: Text(reader.phone),
                ),
              ),
              const SizedBox(height: 12),
              Text('Читательский билет', style: Theme.of(context).textTheme.titleLarge),
              Card(
                child: ListTile(
                  title: Text(reader.card.number),
                  subtitle: Text(
                    'Выдан: ${date(reader.card.issuedAt)}\n'
                    'Действует до: ${date(reader.card.expiresAt)}',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ReaderFormScreen extends StatefulWidget {
  final int? id;
  const ReaderFormScreen({super.key, this.id});

  @override
  State<ReaderFormScreen> createState() => _ReaderFormScreenState();
}

class _ReaderFormScreenState extends State<ReaderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _number = TextEditingController();
  final _issued = TextEditingController();
  final _expires = TextEditingController();
  bool _loading = true;
  bool _duplicateEmail = false;
  Reader? _original;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<ReaderRepository>();
    if (widget.id != null) {
      _original = await repo.findById(widget.id!);
      final reader = _original;
      if (reader != null) {
        _name.text = reader.fullName;
        _email.text = reader.email;
        _phone.text = reader.phone;
        _number.text = reader.card.number;
        _issued.text = reader.card.issuedAt.toIso8601String().substring(0, 10);
        _expires.text = reader.card.expiresAt.toIso8601String().substring(0, 10);
      }
    } else {
      final now = DateTime.now();
      _issued.text = now.toIso8601String().substring(0, 10);
      _expires.text = DateTime(now.year + 1, now.month, now.day)
          .toIso8601String()
          .substring(0, 10);
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _phone,
      _number,
      _issued,
      _expires,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'Новый читатель' : 'Редактирование читателя'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'ФИО',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  Validators.requiredText(v, label: 'ФИО', maxLength: 120),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              validator: (v) => _duplicateEmail
                  ? 'Email уже используется'
                  : Validators.email(v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(
                labelText: 'Телефон',
                border: OutlineInputBorder(),
              ),
              validator: (v) => Validators.requiredText(
                v,
                label: 'Телефон',
                maxLength: 30,
              ),
            ),
            const SizedBox(height: 20),
            Text('Читательский билет', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            TextFormField(
              controller: _number,
              decoration: const InputDecoration(
                labelText: 'Номер билета',
                border: OutlineInputBorder(),
              ),
              validator: (v) => Validators.requiredText(
                v,
                label: 'Номер билета',
                maxLength: 30,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _issued,
                    decoration: const InputDecoration(
                      labelText: 'Выдан, ГГГГ-ММ-ДД',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => Validators.date(v, label: 'Дата выдачи'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _expires,
                    decoration: const InputDecoration(
                      labelText: 'До, ГГГГ-ММ-ДД',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final error = Validators.date(v, label: 'Срок действия');
                      if (error != null) return error;
                      final issued = DateTime.tryParse(_issued.text);
                      final expires = DateTime.tryParse(v!);
                      if (issued != null &&
                          expires != null &&
                          !expires.isAfter(issued)) {
                        return 'Должна быть позже даты выдачи';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('Сохранить')),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    _duplicateEmail = false;
    if (!_formKey.currentState!.validate()) return;

    final repo = context.read<ReaderRepository>();
    final unique = await repo.isEmailUnique(_email.text, exceptId: widget.id);
    if (!mounted) return;

    if (!unique) {
      setState(() => _duplicateEmail = true);
      _formKey.currentState!.validate();
      return;
    }

    final reader = Reader(
      id: widget.id ?? 0,
      fullName: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      card: LibraryCard(
        id: _original?.card.id ?? 0,
        number: _number.text.trim(),
        issuedAt: DateTime.parse(_issued.text),
        expiresAt: DateTime.parse(_expires.text),
      ),
    );

    if (widget.id == null) {
      await repo.create(reader);
    } else {
      await repo.update(reader);
    }
    if (!mounted) return;
    context.go('/readers');
  }
}
