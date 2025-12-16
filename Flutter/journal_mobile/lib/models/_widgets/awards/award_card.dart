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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              _getPointColor(award.pointTypesId).withOpacity(0.08),
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(isAchievement),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 2),
                    
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    _buildCompactInfo(source, isAchievement),
                  ],
                ),
              ),
              _buildCompactDate(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(bool isAchievement) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getPointColor(award.pointTypesId).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getPointColor(award.pointTypesId).withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Icon(
        isAchievement 
            ? AwardUtils.getAchievementIcon(award.achievementsType, award.achievementsName)
            : AwardUtils.getPointTypeIcon(award.pointTypesId),
        color: _getPointColor(award.pointTypesId),
        size: 20,
      ),
    );
  }

  Widget _buildCompactInfo(String source, bool isAchievement) {
    return Row(
      children: [
        Icon(Icons.class_, size: 12, color: Colors.grey.shade500),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            source,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (award.currentPoint > 0)
          Container(
            margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getPointColor(award.pointTypesId).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _getPointColor(award.pointTypesId).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
                  AwardUtils.getPointTypeIcon(award.pointTypesId),
                  size: 10,
                  color: _getPointColor(award.pointTypesId),
                ),
                const SizedBox(width: 3),
                Text(
                  '+${award.currentPoint}',
                  style: TextStyle(
                    color: _getPointColor(award.pointTypesId),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
    );
  }

  Widget _buildCompactDate() {
    final formattedDate = AwardUtils.formatDate(award.date);
    return Container(
      margin: const EdgeInsets.only(left: 6),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          formattedDate.split(' ')[0],
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          formattedDate.split(' ')[1],
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ],
      ),
    );
  }

  Color _getPointColor(int pointTypesId) {
    final originalColor = AwardUtils.getPointTypeColor(pointTypesId);
    
    if (pointTypesId == 2) {
      return Color.lerp(originalColor, Colors.white, 0.3) ?? 
             const Color.fromARGB(255, 180, 100, 220);
    }
    
    return originalColor;
  }
}