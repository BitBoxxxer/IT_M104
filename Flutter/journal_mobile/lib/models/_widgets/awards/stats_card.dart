import 'package:flutter/material.dart';
import '../../activity_record.dart';
import 'stat_item.dart';

class StatsCard extends StatelessWidget {
  final List<ActivityRecord> awards;

  const StatsCard({
    super.key,
    required this.awards,
  });

  @override
  Widget build(BuildContext context) {
    final totalAwards = awards.length;
    final totalCoins = awards
        .where((a) => a.pointTypesId == 1)
        .fold(0, (sum, a) => sum + a.currentPoint);
    final totalGems = awards
        .where((a) => a.pointTypesId == 2)
        .fold(0, (sum, a) => sum + a.currentPoint);
    final totalAchievements = awards.where((a) => a.achievementsId != null).length;
    final totalPoints = totalCoins + totalGems;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Общая статистика',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StatItem(
                  title: 'Всего наград',
                  value: totalAwards.toString(),
                  icon: Icons.card_giftcard,
                  color: Colors.blue,
                ),
                StatItem(
                  title: 'ТопКоины',
                  value: totalCoins.toString(),
                  icon: Icons.monetization_on,
                  color: Colors.amber,
                ),
                StatItem(
                  title: 'ТопГемы',
                  value: totalGems.toString(),
                  icon: Icons.diamond,
                  color: Colors.purple,
                ),
                StatItem(
                  title: 'Всего баллов',
                  value: totalPoints.toString(),
                  icon: Icons.star,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (totalAchievements > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Достижений: $totalAchievements',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}