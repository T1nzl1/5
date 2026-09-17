import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/author.dart';
import '../../repositories/author_repository.dart';
import '../../utils/validators.dart';

class AuthorFormScreen extends StatefulWidget {
  final int? id;
  const AuthorFormScreen({super.key, this.id});

  @override
  State<AuthorFormScreen> createState() => _AuthorFormScreenState();
}

class _AuthorFormScreenState extends State<AuthorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _year = TextEditingController();
  final _country = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<AuthorRepository>();
    if (widget.id != null) {
      final author = await repo.findById(widget.id!);
      if (author != null) {
        _name.text = author.fullName;
        _year.text = '${author.birthYear}';
        _country.text = author.country;
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _year.dispose();
    _country.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'Новый автор' : 'Редактирование автора'),
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
                labelText: 'ФИО',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  Validators.requiredText(v, label: 'ФИО', maxLength: 120),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _year,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Год рождения',
                border: OutlineInputBorder(),
              ),
              validator: (v) => Validators.intRange(
                v,
                label: 'Год рождения',
                min: 1000,
                max: 2026,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _country,
              decoration: const InputDecoration(
                labelText: 'Страна',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  Validators.requiredText(v, label: 'Страна', maxLength: 80),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ))),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = context.read<AuthorRepository>();
    final author = Author(
      id: widget.id ?? 0,
      fullName: _name.text.trim(),
      birthYear: int.parse(_year.text),
      country: _country.text.trim(),
    );

    if (widget.id == null) {
      await repo.create(author);
    } else {
      await repo.update(author);
    }

    if (!mounted) return;
    context.go('/authors');
  }
}
