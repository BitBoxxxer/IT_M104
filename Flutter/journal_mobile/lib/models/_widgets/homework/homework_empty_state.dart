import 'package:flutter/material.dart';
import '../../_rabbits/homework_utilitss.dart';

class HomeworkEmptyState extends StatelessWidget {
  final String tabStatus;

  const HomeworkEmptyState({
    super.key,
    required this.tabStatus,
  });

  @override
  Widget build(BuildContext context) {
    final icon = HomeworkUtils.getStatusIcon(tabStatus);
    final label = _getTabLabel();
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            '$label отсутствуют',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            HomeworkUtils.getEmptyStateDescription(tabStatus),
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getTabLabel() {
    switch (tabStatus) {
      case 'opened': return 'Активные задания';
      case 'inspection': return 'Работы на проверке';
      case 'done': return 'Проверенные работы';
      case 'expired': return 'Просроченные работы';
      case 'deleted': return 'Удаленные работы';
      default: return 'Задания';
    }
  }
}