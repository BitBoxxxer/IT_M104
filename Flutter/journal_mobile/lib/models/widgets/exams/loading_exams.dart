import 'package:flutter/material.dart';

class LoadingExams extends StatelessWidget {
  final String debugInfo;

  const LoadingExams({
    super.key,
    this.debugInfo = '',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Загрузка экзаменов...'),
          if (debugInfo.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              debugInfo,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}