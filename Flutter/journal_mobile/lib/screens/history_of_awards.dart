import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';
import '../models/activity_record.dart';

class HistoryOfAwardsScreen extends StatefulWidget {
  @override
  State<HistoryOfAwardsScreen> createState() => _HistoryOfAwardsScreenState();
}

class _HistoryOfAwardsScreenState extends State<HistoryOfAwardsScreen> {
  final ApiService _apiService = ApiService();
  final SecureStorageService _secureStorage = SecureStorageService();
  
  late Future<List<ActivityRecord>> _awardsFuture;
  bool _isLoading = true;
  String _errorMessage = '';
  
  String _selectedFilter = 'all';
  List<String> _filterOptions = ['Все', 'ТопКоины', 'ТопГемы'];

  @override
  void initState() {
    super.initState();
    _loadAwards();
  }

  Future<void> _loadAwards() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final token = await _secureStorage.getToken();
      if (token == null) {
        throw Exception('Токен не найден');
      }

      final awards = await _apiService.getProgressActivity(token);
      
      setState(() {
        _awardsFuture = Future.value(awards);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки: $e';
        _isLoading = false;
      });
      print('Error loading awards: $e');
    }
  }

  List<ActivityRecord> _filterAwards(List<ActivityRecord> awards) {
    switch (_selectedFilter) {
      case 'coins':
        return awards.where((award) => award.pointTypesId == 1).toList();
      case 'gems':
        return awards.where((award) => award.pointTypesId == 2).toList();
      default:
        return awards;
    }
  }

  String _getPointTypeName(int? pointTypesId) {
    switch (pointTypesId) {
      case 1:
        return 'ТопКоины';
      case 2:
        return 'ТопГемы';
      default:
        return 'Баллы';
    }
  }

  Color _getPointTypeColor(int? pointTypesId) {
    switch (pointTypesId) {
      case 1:
        return Colors.amber.shade700;
      case 2:
        return Colors.purple.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  IconData _getPointTypeIcon(int? pointTypesId) {
    switch (pointTypesId) {
      case 1:
        return Icons.monetization_on;
      case 2:
        return Icons.diamond;
      default:
        return Icons.star;
    }
  }

  /// Преобразование системных названий в читаемые
  String _getAchievementDisplayName(String? achievementName) {
    switch (achievementName) {
      case 'ASSESMENT':
        return 'Оценка за работу';
      case 'EVALUATION_LESSON_MARK':
        return 'Оценка за урок';
      case 'PAIR_VISIT':
        return 'Посещение пары';
      case 'HOMEWORK':
        return 'Домашняя работа';
      case 'TEST':
        return 'Тестирование';
      case 'EXAM':
        return 'Экзамен';
      case 'ACTIVITY':
        return 'Активность на уроке';
      case 'PROJECT':
        return 'Учебный проект';
      case 'PARTICIPATION':
        return 'Участие в мероприятии';
      case 'HELP':
        return 'Помощь одногруппникам';
      default:
        return achievementName ?? 'Достижение';
    }
  }

  /// Описание для достижений
  String _getAchievementDescription(ActivityRecord award) {
    if (award.achievementsName != null) {
      switch (award.achievementsName) {
        case 'ASSESMENT':
          return 'Получена оценка за учебную работу';
        case 'EVALUATION_LESSON_MARK':
          return 'Оценка за работу на уроке';
        case 'PAIR_VISIT':
          return 'Посещение учебной пары';
        case 'HOMEWORK':
          return 'Выполнение домашнего задания';
        case 'TEST':
          return 'Прохождение тестирования';
        case 'EXAM':
          return 'Сдача экзамена';
        case 'ACTIVITY':
          return 'Активная работа на занятии';
        case 'PROJECT':
          return 'Защита учебного проекта';
        case 'PARTICIPATION':
          return 'Участие в учебном мероприятии';
        case 'HELP':
          return 'Помощь другим студентам';
        default:
          return 'Учебное достижение';
      }
    } else {
      return 'Начисление баллов за активность';
    }
  }

  /// Получение названия предмета/источника из данных
  String _getAchievementSource(ActivityRecord award) {
    if (award.achievementsName != null) {
      switch (award.achievementsName) {
        case 'ASSESMENT':
        case 'EVALUATION_LESSON_MARK':
          return 'Учебное занятие';
        case 'PAIR_VISIT':
          return 'Посещение';
        case 'HOMEWORK':
          return 'Домашняя работа';
        case 'TEST':
          return 'Контрольная работа';
        case 'EXAM':
          return 'Экзамен';
        case 'ACTIVITY':
          return 'Активность';
        case 'PROJECT':
          return 'Проектная работа';
        case 'PARTICIPATION':
          return 'Мероприятие';
        case 'HELP':
          return 'Взаимопомощь';
        default:
          return 'Учебный процесс';
      }
    }
    return 'Учебная деятельность';
  }

  IconData _getAchievementIcon(int? achievementsType, String? achievementName) {
    if (achievementName != null) {
      switch (achievementName) {
        case 'ASSESMENT':
        case 'EVALUATION_LESSON_MARK':
          return Icons.assignment_turned_in;
        case 'PAIR_VISIT':
          return Icons.school;
        case 'HOMEWORK':
          return Icons.home_work;
        case 'TEST':
          return Icons.quiz;
        case 'EXAM':
          return Icons.assignment;
        case 'ACTIVITY':
          return Icons.psychology;
        case 'PROJECT':
          return Icons.work;
        case 'PARTICIPATION':
          return Icons.people;
        case 'HELP':
          return Icons.help;
        default:
          return Icons.emoji_events;
      }
    }
    
    switch (achievementsType) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.workspace_premium;
      case 3:
        return Icons.flag;
      default:
        return Icons.card_giftcard;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildAwardCard(ActivityRecord award, int index) {
    final isAchievement = award.achievementsId != null;
    final displayName = isAchievement 
        ? _getAchievementDisplayName(award.achievementsName)
        : '${award.currentPoint} ${_getPointTypeName(award.pointTypesId)}';
    final description = _getAchievementDescription(award);
    final source = _getAchievementSource(award);
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              _getPointTypeColor(award.pointTypesId).withOpacity(0.1),
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getPointTypeColor(award.pointTypesId).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: _getPointTypeColor(award.pointTypesId),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isAchievement 
                      ? _getAchievementIcon(award.achievementsType, award.achievementsName)
                      : _getPointTypeIcon(award.pointTypesId),
                  color: _getPointTypeColor(award.pointTypesId),
                  size: 24,
                ),
              ),
              
              SizedBox(width: 12),
              
              Expanded(
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
                    
                    SizedBox(height: 4),
                    
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    
                    SizedBox(height: 6),
                    
                    Row(
                      children: [
                        Icon(Icons.class_, size: 14, color: Colors.grey.shade500),
                        SizedBox(width: 4),
                        Text(
                          source,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 8),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (award.currentPoint > 0)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPointTypeColor(award.pointTypesId).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getPointTypeColor(award.pointTypesId),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getPointTypeIcon(award.pointTypesId),
                                  size: 12,
                                  color: _getPointTypeColor(award.pointTypesId),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '+${award.currentPoint}',
                                  style: TextStyle(
                                    color: _getPointTypeColor(award.pointTypesId),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        if (award.badge == 1)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, size: 12, color: Colors.orange),
                                SizedBox(width: 4),
                                Text(
                                  'Значок',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        if (isAchievement)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.emoji_events, size: 12, color: Colors.green),
                                SizedBox(width: 4),
                                Text(
                                  'Достижение',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Дата
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDate(award.date).split(' ')[0],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _formatDate(award.date).split(' ')[1],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: _filterOptions.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final filterValue = ['all', 'coins', 'gems'][index];
          final isSelected = _selectedFilter == filterValue;
          
          return FilterChip(
            label: Text(option),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedFilter = filterValue;
              });
            },
            backgroundColor: Colors.grey.shade200,
            selectedColor: Colors.blue.shade100,
            checkmarkColor: Colors.blue,
            labelStyle: TextStyle(
              color: isSelected ? Colors.blue.shade800 : Colors.grey.shade700,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsCard(List<ActivityRecord> awards) {
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
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Общая статистика',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Всего наград', totalAwards.toString(), Icons.card_giftcard, Colors.blue),
                _buildStatItem('ТопКоины', totalCoins.toString(), Icons.monetization_on, Colors.amber),
                _buildStatItem('ТопГемы', totalGems.toString(), Icons.diamond, Colors.purple),
                _buildStatItem('Всего баллов', totalPoints.toString(), Icons.star, Colors.green),
              ],
            ),
            SizedBox(height: 8),
            if (totalAchievements > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
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

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('История наград студента'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAwards,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Загрузка истории наград...'),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAwards,
                        child: Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : FutureBuilder<List<ActivityRecord>>(
                  future: _awardsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red),
                            SizedBox(height: 16),
                            Text(
                              'Ошибка загрузки данных',
                              style: TextStyle(fontSize: 16, color: Colors.red),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.card_giftcard, size: 64, color: Colors.grey.shade400),
                            SizedBox(height: 16),
                            Text(
                              'Наград пока нет',
                              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Зарабатывайте баллы и достижения в процессе обучения',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    
                    final allAwards = snapshot.data!;
                    final filteredAwards = _filterAwards(allAwards);
                    
                    return Column(
                      children: [
                        _buildStatsCard(allAwards),
                        _buildFilterChips(),
                        SizedBox(height: 8),
                        Text(
                          'Найдено записей: ${filteredAwards.length}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadAwards,
                            child: ListView.builder(
                              itemCount: filteredAwards.length,
                              itemBuilder: (context, index) {
                                return _buildAwardCard(filteredAwards[index], index);
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}