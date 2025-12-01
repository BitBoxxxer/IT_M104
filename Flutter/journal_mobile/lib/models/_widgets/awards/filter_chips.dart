import 'package:flutter/material.dart';

class FilterChips extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const FilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    const filterOptions = ['Все', 'ТопКоины', 'ТопГемы'];
    const filterValues = ['all', 'coins', 'gems'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
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
    );
  }
}