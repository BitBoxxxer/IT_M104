import 'package:flutter/material.dart';
import 'homework.dart';
import 'homework_stat_item.dart';

class HomeworkStatsCard extends StatelessWidget {
  final List<Homework> homeworks;
  final String tabStatus;
  final int currentPage;
  final int Function(int) getCounterByStatus;
  final int Function() getCounterForDeletedTab;
  final Map<String, dynamic> tabData;

  const HomeworkStatsCard({
    super.key,
    required this.homeworks,
    required this.tabStatus,
    required this.currentPage,
    required this.getCounterByStatus,
    required this.getCounterForDeletedTab,
    required this.tabData,
  });

  @override
  Widget build(BuildContext context) {
    final totalCounter = tabStatus == 'deleted' 
      ? getCounterForDeletedTab()
      : getCounterByStatus(tabData['counterType']);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tabData['icon'], size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '${tabData['label']} задания',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                HomeworkStatItem(
                  title: 'Всего',
                  value: totalCounter.toString(),
                  icon: Icons.assignment,
                  color: Colors.blue,
                ),
                HomeworkStatItem(
                  title: 'Найдено',
                  value: homeworks.length.toString(),
                  icon: Icons.search,
                  color: Colors.green,
                ),
                if (homeworks.isNotEmpty)
                  HomeworkStatItem(
                    title: 'Страница',
                    value: '$currentPage',
                    icon: Icons.numbers,
                    color: Colors.orange,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (totalCounter > homeworks.length)
              Text(
                'Загружено ${homeworks.length} из $totalCounter работ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}