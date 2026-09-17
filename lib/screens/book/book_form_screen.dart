import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_exceptions.dart';
import '../../models/author.dart';
import '../../models/book.dart';
import '../../models/genre.dart';
import '../../models/publisher.dart';
import '../../repositories/author_repository.dart';
import '../../repositories/book_repository.dart';
import '../../repositories/genre_repository.dart';
import '../../repositories/publisher_repository.dart';
import '../../utils/validators.dart';

class BookFormScreen extends StatefulWidget {
  final int? id;
  const BookFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _isbn = TextEditingController();
  final _year = TextEditingController();
  final _pages = TextEditingController();
  final _total = TextEditingController();
  final _available = TextEditingController();

  int? _publisherId;
  List<int> _authorIds = [];
  List<int> _genreIds = [];
  List<Author> _authors = [];
  List<Genre> _genres = [];
  List<Publisher> _publishers = [];
  Book? _original;
  bool _loading = true;
  bool _saving = false;
  Map<String, String> _serverErrors = {};
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final authorRepo = context.read<AuthorRepository>();
    final genreRepo = context.read<GenreRepository>();
    final publisherRepo = context.read<PublisherRepository>();
    final bookRepo = context.read<BookRepository>();

    final results = await Future.wait([
      authorRepo.all(),
      genreRepo.all(),
      publisherRepo.all(),
    ]);

    _authors = results[0] as List<Author>;
    _genres = results[1] as List<Genre>;
    _publishers = results[2] as List<Publisher>;

    if (widget.id != null) {
      _original = await bookRepo.findById(widget.id!);
      final book = _original;
      if (book != null) {
        _title.text = book.title;
        _isbn.text = book.isbn;
        _year.text = '${book.year}';
        _pages.text = '${book.pages}';
        _total.text = '${book.copiesTotal}';
        _available.text = '${book.copiesAvailable}';
        _publisherId = book.publisherId;
        _authorIds = [...book.authorIds];
        _genreIds = [...book.genreIds];
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _isbn,
      _year,
      _pages,
      _total,
      _available,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() { _serverErrors = {}; _submitError = null; });
    if (!_formKey.currentState!.validate()) return;
    if (_publisherId == null || _authorIds.isEmpty || _genreIds.isEmpty) {
      _formKey.currentState!.validate();
      return;
    }
    setState(() => _saving = true);
    final repo = context.read<BookRepository>();
    final book = Book(
      id: widget.id ?? 0, title: _title.text.trim(), isbn: _isbn.text.trim(),
      year: int.parse(_year.text), pages: int.parse(_pages.text), publisherId: _publisherId!,
      authorIds: [..._authorIds], genreIds: [..._genreIds], copiesTotal: int.parse(_total.text),
      copiesAvailable: int.parse(_available.text), createdAt: _original?.createdAt ?? DateTime.now(), deletedAt: _original?.deletedAt,
    );
    try {
      if (widget.isEditing) { await repo.update(book); } else { await repo.create(book); }
      if (!mounted) return;
      context.go('/');
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() => _serverErrors = e.errors);
      _formKey.currentState!.validate();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitError = e.message);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Редактирование книги' : 'Новая книга'),
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
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Название',
                border: OutlineInputBorder(),
              ),
              validator: (v) => Validators.requiredText(
                v,
                label: 'Название',
                maxLength: 200,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _isbn,
              decoration: const InputDecoration(
                labelText: 'ISBN',
                border: OutlineInputBorder(),
              ),
              validator: (v) => _serverErrors['isbn'] ?? Validators.requiredText(v, label: 'ISBN', maxLength: 30),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _year,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Год',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => Validators.intRange(
                      v,
                      label: 'Год',
                      min: 1000,
                      max: 2100,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _pages,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Страниц',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => Validators.positive(v, label: 'Страниц'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _publisherId,
              decoration: const InputDecoration(
                labelText: 'Издательство',
                border: OutlineInputBorder(),
              ),
              items: _publishers
                  .map(
                    (publisher) => DropdownMenuItem<int>(
                      value: publisher.id,
                      child: Text(publisher.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _publisherId = value),
              validator: (value) =>
                  value == null ? 'Выберите издательство' : null,
            ),
            const SizedBox(height: 16),
            _buildChips<Author>(
              'Авторы',
              _authors,
              _authorIds,
              (author) => author.id,
              (author) => author.fullName,
              (next) => _authorIds = next,
            ),
            const SizedBox(height: 16),
            _buildChips<Genre>(
              'Жанры',
              _genres,
              _genreIds,
              (genre) => genre.id,
              (genre) => genre.name,
              (next) => _genreIds = next,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _total,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Всего экземпляров',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        Validators.nonNegative(v, label: 'Количество'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _available,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Доступно',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final error =
                          Validators.nonNegative(v, label: 'Доступно');
                      if (error != null) return error;
                      final available = int.parse(v!);
                      final total = int.tryParse(_total.text) ?? 0;
                      return available > total
                          ? 'Не может быть больше общего количества'
                          : null;
                    },
                  ),
                ),
              ],
            ),
            if (_submitError != null) ...[
              Text(_submitError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(_saving ? 'Сохранение...' : 'Сохранить'),
            ),
          ],
        ),
      ))),
    );
  }

  Widget _buildChips<T>(
    String label,
    List<T> values,
    List<int> selected,
    int Function(T) idOf,
    String Function(T) labelOf,
    void Function(List<int>) onChanged,
  ) {
    return FormField<List<int>>(
      initialValue: selected,
      validator: (value) => value == null || value.isEmpty
          ? 'Выберите хотя бы один вариант'
          : null,
      builder: (field) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            errorText: field.errorText,
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((value) {
              final id = idOf(value);
              final isSelected = field.value!.contains(id);
              return FilterChip(
                label: Text(labelOf(value)),
                selected: isSelected,
                onSelected: (_) {
                  final next = [...field.value!];
                  if (isSelected) {
                    next.remove(id);
                  } else {
                    next.add(id);
                  }
                  field.didChange(next);
                  setState(() => onChanged(next));
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
