import 'package:flutter/material.dart';

class ExamTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;
  final List<Widget> tabs;

  const ExamTabBar({
    super.key,
    required this.tabController,
    required this.tabs,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: tabController,
      tabs: tabs,
    );
  }
}