import 'package:flutter/material.dart';

class ErrorNotifications extends StatelessWidget {
  final VoidCallback onRetry;

  const ErrorNotifications({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Ошибка загрузки уведомлений',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Попробовать снова'),
          ),
        ],
      ),
    );
  }
}