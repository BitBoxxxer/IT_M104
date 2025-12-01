import 'package:flutter/material.dart';
import '../../activity_record.dart';
import '../../_rabbits/award_utilits.dart';


class AwardCard extends StatelessWidget {
  final ActivityRecord award;

  const AwardCard({
    super.key,
    required this.award,
  });

  @override
  Widget build(BuildContext context) {
    final isAchievement = award.achievementsId != null;
    final displayName = isAchievement 
        ? AwardUtils.getAchievementDisplayName(award.achievementsName)
        : '${award.currentPoint} ${AwardUtils.getPointTypeName(award.pointTypesId)}';
    final description = isAchievement 
        ? AwardUtils.getAchievementDescription(award.achievementsName)
        : 'Начисление баллов за активность';
    final source = isAchievement 
        ? AwardUtils.getAchievementSource(award.achievementsName)
        : 'Учебная деятельность';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AwardUtils.getPointTypeColor(award.pointTypesId).withOpacity(0.1),
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(isAchievement),
              const SizedBox(width: 12),
              _buildContent(displayName, description, source, isAchievement),
              _buildDate(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(bool isAchievement) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AwardUtils.getPointTypeColor(award.pointTypesId).withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AwardUtils.getPointTypeColor(award.pointTypesId),
          width: 2,
        ),
      ),
      child: Icon(
        isAchievement 
            ? AwardUtils.getAchievementIcon(award.achievementsType, award.achievementsName)
            : AwardUtils.getPointTypeIcon(award.pointTypesId),
        color: AwardUtils.getPointTypeColor(award.pointTypesId),
        size: 24,
      ),
    );
  }

  Widget _buildContent(String displayName, String description, String source, bool isAchievement) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          
          const SizedBox(height: 6),
          
          Row(
            children: [
              Icon(Icons.class_, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                source,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          _buildBadges(isAchievement),
        ],
      ),
    );
  }

  Widget _buildBadges(bool isAchievement) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (award.currentPoint > 0)
          _buildBadge(
            AwardUtils.getPointTypeIcon(award.pointTypesId),
            '+${award.currentPoint}',
            AwardUtils.getPointTypeColor(award.pointTypesId),
          ),
        
        if (award.badge == 1)
          _buildBadge(
            Icons.verified,
            'Значок',
            Colors.orange,
          ),
        
        if (isAchievement)
          _buildBadge(
            Icons.emoji_events,
            'Достижение',
            Colors.green,
          ),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDate() {
    final formattedDate = AwardUtils.formatDate(award.date);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          formattedDate.split(' ')[0],
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          formattedDate.split(' ')[1],
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}