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
      margin: const EdgeInsets.all(0),
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
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _getPointColor(award.pointTypesId).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
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
                      size: 18,
                    ),
                  ),
                  if (award.currentPoint > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                            size: 12,
                            color: _getPointColor(award.pointTypesId),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '+${award.currentPoint}',
                            style: TextStyle(
                              color: _getPointColor(award.pointTypesId),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const Spacer(),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Icon(Icons.class_, size: 10, color: Colors.grey.shade600),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            source,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
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