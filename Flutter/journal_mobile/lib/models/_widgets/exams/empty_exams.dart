import 'package:flutter/material.dart';

class EmptyExams extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyExams({
    super.key,
    required this.message,
    this.icon = Icons.assignment,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}