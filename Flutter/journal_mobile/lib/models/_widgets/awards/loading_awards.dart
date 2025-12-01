import 'package:flutter/material.dart';

class LoadingAwards extends StatelessWidget {
  const LoadingAwards({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Загрузка истории наград...'),
        ],
      ),
    );
  }
}