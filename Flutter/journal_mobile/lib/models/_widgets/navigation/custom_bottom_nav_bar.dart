import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;
  
  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPulsatingNavItem(context, 0, Icons.school, 'Оценки'),
          _buildPulsatingNavItem(context, 1, Icons.assignment, 'Задания'),
          _buildCenterNavItem(context),
          _buildPulsatingNavItem(context, 3, Icons.library_books, 'Экзамены'),
          _buildPulsatingNavItem(context, 4, Icons.leaderboard, 'Лидеры'),
        ],
      ),
    );
  }

  Widget _buildPulsatingNavItem(
    BuildContext context, 
    int index, 
    IconData icon, 
    String label
  ) {
    final isSelected = selectedIndex == index;
    
    return GestureDetector(
      onTap: () => onIndexChanged(index),
      child: Container(
        width: 60,
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutBack,
              width: isSelected ? 45 : 35,
              height: isSelected ? 45 : 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isSelected 
                    ? Border.all(color: Colors.white, width: 2)
                    : Border.all(color: Colors.white.withOpacity(0), width: 0),
                color: isSelected 
                    ? Colors.white.withOpacity(0.1) 
                    : Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: isSelected 
                        ? Colors.white.withOpacity(0.5)
                        : Colors.white.withOpacity(0.2),
                    spreadRadius: isSelected ? 5 : 0,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isSelected ? 24 : 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNavItem(BuildContext context) {
    final isSelected = selectedIndex == 2;
    
    return GestureDetector(
      onTap: () => onIndexChanged(2),
      child: Container(
        width: 70,
        height: 70,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutBack,
              width: isSelected ? 50 : 40,
              height: isSelected ? 50 : 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(isSelected ? 0.5 : 0.2),
                    blurRadius: isSelected ? 15 : 8,
                    spreadRadius: isSelected ? 5 : 2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.home,
                  color: Theme.of(context).primaryColor,
                  size: isSelected ? 26 : 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}