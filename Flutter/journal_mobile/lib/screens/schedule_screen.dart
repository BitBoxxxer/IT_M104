import 'package:flutter/material.dart';
import '../models/days_element.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

DateTime getMonday(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  final day = d.weekday;
  final diff = day - 1; 
  return d.subtract(Duration(days: diff));
}

DateTime getSunday(DateTime date) {
  final d = getMonday(date);
  return d.add(const Duration(days: 6));
}

// API (YYYY-MM-DD)
String formatDate(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

class ScheduleScreen extends StatefulWidget {
  final String token;
  const ScheduleScreen({super.key, required this.token});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ApiService _apiService = ApiService();
  DateTime _currentDate = DateTime.now(); 
  late Future<List<ScheduleElement>> _scheduleFuture;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _scheduleFuture = _loadSchedule(); 
  }

  Future<List<ScheduleElement>> _loadSchedule() {
    final monday = getMonday(_currentDate);
    final sunday = getSunday(_currentDate);
    
    return _apiService.getSchedule(
        widget.token,
        formatDate(monday),
        formatDate(sunday),
    );
  }

  void _changeWeek(int delta) {
    setState(() {
      _currentDate = _currentDate.add(Duration(days: delta * 7));
      _scheduleFuture = _loadSchedule(); 
      _pageController.jumpToPage(0);
    });
  }

  Widget _buildScheduleCard(ScheduleElement element) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  '${element.startedAt.substring(0, 5)} - ${element.finishedAt.substring(0, 5)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 14, 
                    color: Theme.of(context).colorScheme.primary
                  ),
                ),
                const Spacer(),
                Text(
                  'Пара ${element.lesson}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              element.subjectName,
              style: TextStyle(
                fontSize: 15, 
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 6),
            
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    element.teacherName,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                const SizedBox(width: 4),
                Text(
                  element.roomName,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayPage(List<ScheduleElement> lessons, String dayKey) {
    final date = DateTime.parse(dayKey);
    final dayName = DateFormat('EEEE', 'ru_RU').format(date);
    final formattedDate = DateFormat('dd.MM.yyyy').format(date);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${dayName[0].toUpperCase()}${dayName.substring(1)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          if (lessons.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'Пар нет',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: lessons.length,
                itemBuilder: (context, index) {
                  return _buildScheduleCard(lessons[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monday = getMonday(_currentDate);
    final sunday = getSunday(_currentDate);
    final weekRange = '${DateFormat('dd.MM').format(monday)} - ${DateFormat('dd.MM').format(sunday)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Расписание'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => _changeWeek(-1),
                ),
                Text(
                  weekRange,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () => _changeWeek(1),
                ),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<List<ScheduleElement>>(
              future: _scheduleFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Ошибка загрузки: ${snapshot.error.toString()}',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  );
                }
                
                final schedule = snapshot.data ?? [];
                
                final groupedSchedule = <String, List<ScheduleElement>>{};
                for (var element in schedule) {
                  if (!groupedSchedule.containsKey(element.date)) {
                    groupedSchedule[element.date] = [];
                  }
                  groupedSchedule[element.date]!.add(element);
                }
                
                final allDays = <String>[];
                DateTime currentDay = monday;
                while (currentDay.isBefore(sunday.add(const Duration(days: 1)))) {
                  final dayKey = formatDate(currentDay);
                  allDays.add(dayKey);
                  currentDay = currentDay.add(const Duration(days: 1));
                }

                return Column(
                  children: [
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: allDays.length,
                        itemBuilder: (context, index) {
                          final dayKey = allDays[index];
                          final date = DateTime.parse(dayKey);
                          final dayName = DateFormat('E', 'ru_RU').format(date);
                          final hasLessons = groupedSchedule.containsKey(dayKey);
                          
                          return GestureDetector(
                            onTap: () => _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                            child: Container(
                              width: 50,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: hasLessons 
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                    : Theme.of(context).colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _pageController.hasClients && _pageController.page?.round() == index
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    dayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: hasLessons
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd').format(date),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: hasLessons
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: allDays.length,
                        itemBuilder: (context, index) {
                          final dayKey = allDays[index];
                          final lessons = groupedSchedule[dayKey] ?? [];
                          return _buildDayPage(lessons, dayKey);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}