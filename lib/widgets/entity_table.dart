import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;
  final bool selectable;

  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columnSpacing: 16,
          horizontalMargin: 12,
          columns: _buildColumns(),
          rows: _buildRows(context),
          sortColumnIndex: _sortColumnIndex(),
          sortAscending: sortAscending,
          border: TableBorder.all(
            color: Colors.grey.shade300,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
          headingRowColor: WidgetStatePropertyAll(
            Colors.grey.shade200,
          ),
        ),
      ),
    );
  }


  int? _sortColumnIndex() {
    final index = columns.indexWhere((col) => col.sortField == sortField);
    if (index < 0) return null;

    final selectionOffset = selectable && onToggleSelect != null ? 1 : 0;
    return index + selectionOffset;
  }

  List<DataColumn> _buildColumns() {
    final cols = <DataColumn>[];

    if (selectable && onToggleSelect != null) {
      cols.add(
        const DataColumn(
          label: Text(''),
          numeric: false,
        ),
      );
    }

    cols.addAll(columns.map((col) {
      return DataColumn(
        label: Text(
          col.label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        numeric: col.numeric,
        onSort: col.sortField != null && onSort != null
            ? (_, __) => onSort!(col.sortField!)
            : null,
      );
    }).toList());

    if (actions != null) {
      cols.add(
        const DataColumn(
          label: Text('Действия'),
          numeric: false,
        ),
      );
    }

    return cols;
  }

  List<DataRow> _buildRows(BuildContext context) {
    return items.map((item) {
      final id = idOf(item);
      final isSelected = selected.contains(id);

      final cells = <DataCell>[];

      if (selectable && onToggleSelect != null) {
        cells.add(
          DataCell(
            Checkbox(
              value: isSelected,
              onChanged: (_) => onToggleSelect!(id),
            ),
          ),
        );
      }

      cells.addAll(columns.map((col) {
        return DataCell(col.build(item));
      }).toList());

      if (actions != null) {
        cells.add(
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!(item),
            ),
          ),
        );
      }

      return DataRow(
        selected: isSelected,
        onSelectChanged: selectable && onToggleSelect != null
            ? (_) => onToggleSelect!(id)
            : null,
        cells: cells,
      );
    }).toList();
  }
}