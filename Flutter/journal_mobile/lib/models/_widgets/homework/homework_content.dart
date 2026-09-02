import 'package:flutter/material.dart';

import 'homework.dart';
import 'homework_loading_state.dart';
import 'homework_error_state.dart';  
import 'homework_empty_state.dart';
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
  final Function(Homework, bool)? onDownloadRequested;
  final bool isOffline;

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
    this.onDownloadRequested,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && homeworks.isEmpty) {
      return HomeworkLoadingState(
        tabLabel: tabData['label'],
        counter: getCounterByStatus(tabData['counterType']),
      );
    }

    if (errorMessage.isNotEmpty) {
      return HomeworkErrorState(
        errorMessage: errorMessage,
        onRetry: onRefresh,
      );
    }

    if (homeworks.isEmpty) {
      return HomeworkEmptyState(
        tabStatus: tabStatus,
      );
    }

    return Column(
      children: [
        if (isOffline)
          Container(
            width: double.infinity,
            color: Colors.orange.withOpacity(0.12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.cloud_off, size: 16, color: Colors.orange.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Офлайн-режим: показаны ранее загруженные задания, скачивание файлов недоступно',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                  ),
                ),
              ],
            ),
          ),
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
                  final homework = homeworks[index];
                  return HomeworkCard(
                    homework: homework,
                    onDownloadRequested: onDownloadRequested,
                    isOffline: isOffline,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}