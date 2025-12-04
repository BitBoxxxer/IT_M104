import 'package:flutter/material.dart';

import 'homework.dart';
import 'homework_loading_state.dart'; // Добавить этот импорт
import 'homework_error_state.dart';   // Добавить этот импорт  
import 'homework_empty_state.dart';   // Добавить этот импорт
import 'homework_stats_card.dart';
import 'homework_card.dart';
import 'homework_load_more.dart';

class HomeworkContent extends StatelessWidget {
  final String tabStatus;
  final List<Homework> homeworks;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMoreData;
  final String errorMessage;
  final int currentPage;
  final int Function(int) getCounterByStatus;
  final int Function() getCounterForDeletedTab;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final Map<String, dynamic> tabData;

  const HomeworkContent({
    super.key,
    required this.tabStatus,
    required this.homeworks,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMoreData,
    required this.errorMessage,
    required this.currentPage,
    required this.getCounterByStatus,
    required this.getCounterForDeletedTab,
    required this.onRefresh,
    required this.onLoadMore,
    required this.tabData,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && homeworks.isEmpty) {
      return HomeworkLoadingState( // Теперь этот виджет распознается
        tabLabel: tabData['label'],
        counter: getCounterByStatus(tabData['counterType']),
      );
    }

    if (errorMessage.isNotEmpty) {
      return HomeworkErrorState( // Теперь этот виджет распознается
        errorMessage: errorMessage,
        onRetry: onRefresh,
      );
    }

    if (homeworks.isEmpty) {
      return HomeworkEmptyState( // Теперь этот виджет распознается
        tabStatus: tabStatus,
      );
    }

    return Column(
      children: [
        HomeworkStatsCard(
          homeworks: homeworks,
          tabStatus: tabStatus,
          currentPage: currentPage,
          getCounterByStatus: getCounterByStatus,
          getCounterForDeletedTab: getCounterForDeletedTab,
          tabData: tabData,
        ),
        
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo is ScrollUpdateNotification) {
                  final metrics = scrollInfo.metrics;
                  if (metrics.maxScrollExtent - metrics.pixels < 200 && 
                      !isLoadingMore && 
                      hasMoreData) {
                    onLoadMore();
                  }
                }
                return false;
              },
              child: ListView.builder(
                itemCount: homeworks.length + (hasMoreData ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == homeworks.length) {
                    return HomeworkLoadMore(
                      isLoadingMore: isLoadingMore,
                      hasMoreData: hasMoreData,
                      onLoadMore: onLoadMore,
                    );
                  }
                  return HomeworkCard(homework: homeworks[index]);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}