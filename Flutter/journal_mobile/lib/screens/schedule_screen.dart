import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/_system/schedule_note.dart';
import '../models/_widgets/note_dialog.dart';
import '../services/_network/network_service.dart';
import '../services/api_service.dart';

import '../models/days_element.dart';
import '../services/schedule_note_service.dart';

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
  final NetworkService _networkService = NetworkService();
  
  DateTime _currentDate = DateTime.now(); 
  late Future<List<ScheduleElement>> _scheduleFuture;
  late PageController _pageController;
  int _initialPageIndex = 0;
  int _currentPageIndex = 0;
  bool _showNotes = true;

  @override
  void initState() {
    super.initState();
    _calculateInitialPageIndex();
    _currentPageIndex = _initialPageIndex;
    _pageController = PageController(initialPage: _initialPageIndex);
    _scheduleFuture = _loadSchedule();
  }

  void _calculateInitialPageIndex() {
    final today = DateTime.now();
    final monday = getMonday(_currentDate);
    
    final difference = today.difference(monday).inDays;
    
    _initialPageIndex = difference.clamp(0, 6);
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
      _calculateInitialPageIndex();
      _currentPageIndex = _initialPageIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_initialPageIndex);
        }
      });
    });
  }

  void _goToToday() {
    setState(() {
      _currentDate = DateTime.now();
      _scheduleFuture = _loadSchedule();
      _calculateInitialPageIndex();
      _currentPageIndex = _initialPageIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_initialPageIndex);
        }
      });
    });
  }

  Widget _buildScheduleCard(ScheduleElement element) {
  final String roomName = element.roomName;
  
  final String roomLower = roomName.toLowerCase();
  final bool isDistance = roomLower.startsWith('дистант');
  final bool isSrs = roomLower.startsWith('срс');
  final bool isCpc = roomLower.startsWith('cpc');

  IconData locationIcon;
  Color iconColor;
  String locationType = '';
  
  if (isDistance) {
    locationIcon = Icons.computer;
    iconColor = Colors.blue.shade700;
  } else if (isSrs) {
    locationIcon = Icons.auto_stories;
    iconColor = Colors.green.shade700;
  } else if (isCpc) {
    locationIcon = Icons.code;
    iconColor = Colors.orange.shade700;
  } else {
    locationIcon = Icons.location_on_outlined;
    iconColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
  }

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
                Icon(locationIcon, size: 14, color: iconColor),
                const SizedBox(width: 4),
                Text(
                  '$locationType${element.roomName}',
                  style: TextStyle(
                    fontSize: 13,
                    color: iconColor,
                    fontWeight: FontWeight.w500,
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
    
    final isToday = _isSameDay(date, DateTime.now());
    
    return FutureBuilder<List<ScheduleNote>>(
      future: ScheduleNoteService().getNotesForDate(date),
      builder: (context, snapshot) {
        final notes = snapshot.data ?? [];
        
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Заголовок дня
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isToday 
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: isToday
                      ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      '${dayName[0].toUpperCase()}${dayName.substring(1)}${isToday ? ' (Сегодня)' : ''}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 14,
                        color: isToday
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
                            : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Кнопка добавления заметки И переключатель показа заметок
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.note_add, size: 16),
                        label: const Text('Добавить заметку'),
                        onPressed: () => _showAddNoteForDate(context, date),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          _showNotes ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _showNotes = !_showNotes;
                          });
                        },
                        tooltip: _showNotes ? 'Скрыть заметки' : 'Показать заметки',
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              if (notes.isNotEmpty && _showNotes) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Заметки к дню:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '(${notes.length})',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: notes.length,
                    itemBuilder: (context, index) => _buildNoteCard(notes[index]),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
              ],
              
              Expanded(
                child: lessons.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.schedule, size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'Пар нет',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: lessons.length,
                        itemBuilder: (context, index) {
                          return _buildScheduleCard(lessons[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
// ВЫНЕСТИ
Widget _buildNoteCard(ScheduleNote note) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 4),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(
        color: note.noteColor?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Цвет заметки
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: note.noteColor ?? Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          
          // Текст заметки
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.noteText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                if (note.reminderEnabled && note.reminderTime != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.notifications,
                        size: 14,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Напоминание: ${DateFormat('HH:mm').format(note.reminderTime!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, size: 20),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('Редактировать'),
                  ],
                ),
                onTap: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _showEditNoteDialog(context, note);
                  });
                },
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(
                      Icons.delete,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Удалить',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
                onTap: () async {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    await ScheduleNoteService().deleteNote(note.id);
                    if (mounted) setState(() {});
                  });
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// Метод для редактирования заметки
void _showEditNoteDialog(BuildContext context, ScheduleNote note) {
  showDialog(
    context: context,
    builder: (context) => NoteDialog(
      date: note.date,
      existingNote: note,
      onNoteSaved: () {
        if (mounted) setState(() {});
      },
    ),
  );
}
void _showAddNoteForDate(BuildContext context, DateTime date) {
  showDialog(
    context: context,
    builder: (context) => NoteDialog(
      date: date,
      onNoteSaved: () {
        setState(() {}); // Обновляем UI
      },
    ),
  );
}
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monday = getMonday(_currentDate);
    final sunday = getSunday(_currentDate);
    final weekRange = '${DateFormat('dd.MM').format(monday)} - ${DateFormat('dd.MM').format(sunday)}';

    final isCurrentWeek = DateTime.now().isAfter(monday.subtract(const Duration(days: 1))) && 
                         DateTime.now().isBefore(sunday.add(const Duration(days: 1)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Расписание'),
        actions: [
          StreamBuilder<bool>(
              stream: _networkService.connectionStream,
              initialData: _networkService.isConnected,
              builder: (context, snapshot) {
                final isConnected = snapshot.data ?? true;
                
                if (!isConnected) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(
                      Icons.wifi_off,
                      color: Colors.orange,
                      size: 20,
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
          if (!isCurrentWeek)
            IconButton(
              icon: const Icon(Icons.today),
              onPressed: _goToToday,
              tooltip: 'Перейти к сегодняшнему дню',
            ),
        ],
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
                          final isToday = _isSameDay(date, DateTime.now());
                          final isSelected = index == _currentPageIndex;
                          
                          return GestureDetector(
                            onTap: () => {_pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),setState(() {
                              _currentPageIndex = index;
                            }),},
                            
                            child: Container(
                              width: 50,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isToday
                                    ? Theme.of(context).colorScheme.primary
                                    : (hasLessons 
                                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                        : Theme.of(context).colorScheme.surfaceVariant),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
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
                                      color: isToday
                                          ? Colors.white
                                          : (hasLessons
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).colorScheme.onSurfaceVariant),
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd').format(date),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isToday
                                          ? Colors.white
                                          : (hasLessons
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).colorScheme.onSurfaceVariant),
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