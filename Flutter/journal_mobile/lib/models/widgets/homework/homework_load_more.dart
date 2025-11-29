import 'package:flutter/material.dart';

class HomeworkLoadMore extends StatelessWidget {
  final bool isLoadingMore;
  final bool hasMoreData;
  final VoidCallback onLoadMore;

  const HomeworkLoadMore({
    super.key,
    required this.isLoadingMore,
    required this.hasMoreData,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: isLoadingMore 
            ? const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Загрузка следующих заданий...'),
                ],
              )
            : hasMoreData
                ? TextButton(
                    onPressed: onLoadMore,
                    child: const Text('Загрузить еще'),
                  )
                : const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Все задания загружены',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
      ),
    );
  }
}