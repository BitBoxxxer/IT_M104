import 'package:flutter/material.dart';

class FilterChips extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final bool isGridView;
  final VoidCallback? onViewToggle;

  const FilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.isGridView = true,
    this.onViewToggle,
  });

  @override
  Widget build(BuildContext context) {
    const filterOptions = ['Все', 'ТопКоины', 'ТопГемы'];
    const filterValues = ['all', 'coins', 'gems'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          if (onViewToggle != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    isGridView ? Icons.grid_view : Icons.view_list,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isGridView ? 'Сетка' : 'Список',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
      Wrap(
        spacing: 8,
        children: filterOptions.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final filterValue = filterValues[index];
          final isSelected = selectedFilter == filterValue;
          
          return FilterChip(
            label: Text(option),
            selected: isSelected,
            onSelected: (selected) {
              onFilterChanged(filterValue);
            },
            backgroundColor: Colors.grey.shade200,
            selectedColor: Colors.blue.shade100,
            checkmarkColor: Colors.blue,
            labelStyle: TextStyle(
              color: isSelected ? Colors.blue.shade800 : Colors.grey.shade700,
            ),
          );
        }).toList(),
      ),
      ],
      ),
    );
  }
}