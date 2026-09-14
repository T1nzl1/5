import 'package:flutter/material.dart';

class EntityCards<T> extends StatelessWidget {
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final Widget Function(T item) buildCardContent;
  final List<Widget> Function(T item)? actions;
  final bool selectable;

  const EntityCards({
    super.key,
    required this.items,
    required this.idOf,
    required this.buildCardContent,
    this.selected = const {},
    this.onToggleSelect,
    this.actions,
    this.selectable = true,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Нет данных'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final id = idOf(item);
        final isSelected = selected.contains(id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? Colors.blue.shade50 : null,
          child: selectable && onToggleSelect != null
              ? CheckboxListTile(
                  value: isSelected,
                  onChanged: (_) => onToggleSelect!(id),
                  title: buildCardContent(item),
                  secondary: actions != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions!(item),
                        )
                      : null,
                  controlAffinity: ListTileControlAffinity.leading,
                )
              : ListTile(
                  title: buildCardContent(item),
                  trailing: actions != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions!(item),
                        )
                      : null,
                ),
        );
      },
    );
  }
}