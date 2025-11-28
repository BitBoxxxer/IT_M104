import 'package:flutter/material.dart';

class EmptyAwards extends StatelessWidget {
  const EmptyAwards({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Наград пока нет',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Зарабатывайте баллы и достижения в процессе обучения',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}