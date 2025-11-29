import 'package:flutter/material.dart';

class HomeworkLoadingState extends StatelessWidget {
  final String tabLabel;
  final int counter;

  const HomeworkLoadingState({
    super.key,
    required this.tabLabel,
    required this.counter,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Загрузка ${tabLabel.toLowerCase()}...'),
          const SizedBox(height: 8),
          Text(
            '$counter работ',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}