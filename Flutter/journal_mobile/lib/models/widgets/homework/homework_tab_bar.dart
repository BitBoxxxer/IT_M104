import 'package:flutter/material.dart';

class HomeworkTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;
  final List<Map<String, dynamic>> tabs;
  final int Function(int) getCounterByStatus;
  final int Function() getCounterForDeletedTab;

  const HomeworkTabBar({
    super.key,
    required this.tabController,
    required this.tabs,
    required this.getCounterByStatus,
    required this.getCounterForDeletedTab,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: tabController,
      isScrollable: true,
      tabs: tabs.map((tab) {
        final counter = tab['status'] == 'deleted' 
          ? getCounterForDeletedTab()
          : getCounterByStatus(tab['counterType']);
        return Tab(
          icon: Badge(
            label: Text(counter.toString()),
            isLabelVisible: counter > 0,
            smallSize: 18,
            child: Icon(tab['icon'], size: 20),
          ),
          text: tab['label'],
        );
      }).toList(),
    );
  }
}