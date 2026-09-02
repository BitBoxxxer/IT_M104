import 'package:flutter/material.dart';
import '../../activity_record.dart';
import '../../_rabbits/award_utilits.dart';

class CompactAwardCard extends StatelessWidget {
  final ActivityRecord award;

  const CompactAwardCard({
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
      margin: const EdgeInsets.all(4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    child: IntrinsicHeight(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _getPointColor(award.pointTypesId).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getPointColor(award.pointTypesId).withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isAchievement 
                          ? AwardUtils.getAchievementIcon(award.achievementsType, award.achievementsName)
                          : AwardUtils.getPointTypeIcon(award.pointTypesId),
                      color: _getPointColor(award.pointTypesId),
                      size: 20,
                    ),
                  ),
                  if (award.currentPoint > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPointColor(award.pointTypesId).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
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
                            size: 14,
                            color: _getPointColor(award.pointTypesId),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+${award.currentPoint}',
                            style: TextStyle(
                              color: _getPointColor(award.pointTypesId),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Flexible(
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 6),
              
              Flexible(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const Spacer(),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Icon(Icons.class_, size: 12, color: Colors.grey.shade600), // Увеличиваем
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            source,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildCompactDate(),
                ],
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPointColor(int pointTypesId) {
    final originalColor = AwardUtils.getPointTypeColor(pointTypesId);
    
    if (pointTypesId == 2) {
      return Color.lerp(originalColor, Colors.white, 0.3) ?? 
             Color.fromARGB(255, 180, 100, 220); // как давно оно было таким темным... 17.12.25
    }
    
    return originalColor;
  }

  Widget _buildCompactDate() {
    final formattedDate = AwardUtils.formatDate(award.date);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          formattedDate.split(' ')[0],
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          formattedDate.split(' ')[1],
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}