import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/_system/schedule_note.dart';
import '../models/_widgets/note_dialog.dart';
import '../services/_network/network_service.dart';
import '../core/schedule_date_utils.dart';

import '../models/days_element.dart';
import '../services/schedule_note_service.dart';
import '../services/data_manager.dart';
import '../models/_system/futuristic_theme.dart';

// getMonday/getSunday/formatDate теперь в core/schedule_date_utils.dart —
// раньше тут была отдельная копия этих же функций.

class ScheduleScreen extends StatefulWidget {
  final String token;
  const ScheduleScreen({super.key, required this.token});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // Раньше экран сам ходил в ApiService напрямую (network-first, без единого
  // офлайн-слоя), из-за чего вёл себя иначе, чем остальное приложение,
  // которое обновляется через DataManager (SQLite-first + фоновая синхронизация).
  // Теперь расписание тоже идёт через DataManager — и по свежести данных,
  // и по офлайн-логике экран одинаков с остальными.
  final DataManager _dataManager = DataManager();
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

    return _dataManager.getSchedule(
      dateFrom: formatDate(monday),
      dateTo: formatDate(sunday),
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
      iconColor = FuturisticColors.cyan;
    } else if (isSrs) {
      locationIcon = Icons.auto_stories;
      iconColor = FuturisticColors.green;
    } else if (isCpc) {
      locationIcon = Icons.code;
      iconColor = FuturisticColors.amber;
    } else {
      locationIcon = Icons.location_on_outlined;
      iconColor = FuturisticColors.textMid;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
      decoration: glassPanelDecoration(
        glow: FuturisticColors.cyan,
        radius: 14,
        glowOpacity: 0.10,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Акцентная полоса слева — вместо рамки-карточки в стиле Material,
              // читается как "линия времени" на HUD-панели.
              Container(width: 3, color: FuturisticColors.cyan.withOpacity(0.85)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: FuturisticColors.cyan.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: FuturisticColors.cyan.withOpacity(0.4)),
                            ),
                            child: Text(
                              '${element.startedAt.substring(0, 5)}–${element.finishedAt.substring(0, 5)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: FuturisticColors.cyan,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Пара ${element.lesson}',
                            style: futMuted.copyWith(fontSize: 12),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Text(
                        element.subjectName,
                        style: futHeading.copyWith(fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 14, color: FuturisticColors.textLo),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              element.teacherName,
                              style: futMuted.copyWith(fontSize: 13),
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
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
                decoration: glassPanelDecoration(
                  glow: isToday ? FuturisticColors.cyan : FuturisticColors.violet,
                  radius: 14,
                  glowOpacity: isToday ? 0.16 : 0.06,
                ),
                child: Column(
                  children: [
                    Text(
                      '${dayName[0].toUpperCase()}${dayName.substring(1)}${isToday ? ' · Сегодня' : ''}',
                      style: futHeading.copyWith(
                        fontSize: 18,
                        color: isToday ? FuturisticColors.cyan : FuturisticColors.textHi,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: futMuted.copyWith(fontSize: 14),
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
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.note_add, size: 16),
                          label: const Text('Добавить заметку'),
                          onPressed: () => _showAddNoteForDate(context, date),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FuturisticColors.cyan.withOpacity(0.14),
                            foregroundColor: FuturisticColors.cyan,
                            elevation: 0,
                            side: BorderSide(color: FuturisticColors.cyan.withOpacity(0.45)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        height: 44,
                        width: 44,
                        decoration: glassPanelDecoration(
                          glow: FuturisticColors.violet,
                          radius: 12,
                          glowOpacity: 0.10,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _showNotes ? Icons.visibility_off : Icons.visibility,
                            size: 20,
                            color: FuturisticColors.textMid,
                          ),
                          onPressed: () {
                            setState(() {
                              _showNotes = !_showNotes;
                            });
                          },
                          tooltip: _showNotes ? 'Скрыть заметки' : 'Показать заметки',
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  children: [
                    if (notes.isNotEmpty && _showNotes) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Заметки к дню', style: futHeading.copyWith(fontSize: 14)),
                            Text('${notes.length}', style: futMuted),
                          ],
                        ),
                      ),
                      ...notes.map(_buildNoteCard),
                      const SizedBox(height: 6),
                      Divider(color: FuturisticColors.border, height: 1),
                      const SizedBox(height: 6),
                    ],
                    if (lessons.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 48),
                        child: Column(
                          children: [
                            Icon(Icons.schedule, size: 48, color: FuturisticColors.textLo),
                            const SizedBox(height: 16),
                            Text('Пар нет', style: futMuted.copyWith(fontSize: 16)),
                          ],
                        ),
                      )
                    else
                      ...lessons.map(_buildScheduleCard),
                    const SizedBox(height: 16),
                  ],
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
    final Color accent = note.noteColor ?? FuturisticColors.cyan;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: glassPanelDecoration(glow: accent, radius: 12, glowOpacity: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Цвет заметки
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(right: 9, top: 3),
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: accent.withOpacity(0.6), blurRadius: 8, spreadRadius: 1),
                ],
              ),
            ),

            // Текст заметки
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.noteText,
                    style: futBody.copyWith(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (note.reminderEnabled && note.reminderTime != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.notifications, size: 12, color: FuturisticColors.amber),
                        const SizedBox(width: 3),
                        Text(
                          'Напоминание: ${DateFormat('HH:mm').format(note.reminderTime!)}',
                          style: const TextStyle(fontSize: 11, color: FuturisticColors.amber),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            PopupMenuButton(
              icon: const Icon(Icons.more_vert, size: 20, color: FuturisticColors.textMid),
              color: FuturisticColors.panelHi,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: FuturisticColors.border),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showEditNoteDialog(context, note);
                    });
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.edit, size: 16, color: FuturisticColors.cyan),
                      SizedBox(width: 8),
                      Text('Редактировать', style: TextStyle(color: FuturisticColors.textHi)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      await ScheduleNoteService().deleteNote(note.id);
                      if (mounted) setState(() {});
                    });
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: FuturisticColors.red),
                      SizedBox(width: 8),
                      Text('Удалить', style: TextStyle(color: FuturisticColors.red)),
                    ],
                  ),
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

    return Container(
      decoration: futuristicBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Расписание',
            style: futTitle,
          ),
          actions: [
            StreamBuilder<bool>(
              stream: _networkService.connectionStream,
              initialData: _networkService.isConnected,
              builder: (context, snapshot) {
                final isConnected = snapshot.data ?? true;

                if (!isConnected) {
                  return const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(
                      Icons.wifi_off,
                      color: FuturisticColors.amber,
                      size: 20,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            if (!isCurrentWeek)
              IconButton(
                icon: const Icon(Icons.today, color: FuturisticColors.cyan),
                onPressed: _goToToday,
                tooltip: 'Перейти к сегодняшнему дню',
              ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Container(
                decoration: glassPanelDecoration(
                  glow: FuturisticColors.violet,
                  radius: 14,
                  glowOpacity: 0.08,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 16, color: FuturisticColors.textMid),
                      onPressed: () => _changeWeek(-1),
                    ),
                    Text(
                      weekRange,
                      style: futHeading.copyWith(fontSize: 16, letterSpacing: 1.0),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 16, color: FuturisticColors.textMid),
                      onPressed: () => _changeWeek(1),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: FutureBuilder<List<ScheduleElement>>(
                future: _scheduleFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: FuturisticColors.cyan),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Ошибка загрузки: ${snapshot.error.toString()}',
                        style: const TextStyle(color: FuturisticColors.red),
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
                        height: 64,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          itemCount: allDays.length,
                          itemBuilder: (context, index) {
                            final dayKey = allDays[index];
                            final date = DateTime.parse(dayKey);
                            final dayName = DateFormat('E', 'ru_RU').format(date);
                            final hasLessons = groupedSchedule.containsKey(dayKey);
                            final isToday = _isSameDay(date, DateTime.now());
                            final isSelected = index == _currentPageIndex;

                            return GestureDetector(
                              onTap: () {
                                _pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                                setState(() {
                                  _currentPageIndex = index;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 50,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? FuturisticColors.cyan.withOpacity(0.18)
                                      : (hasLessons
                                          ? FuturisticColors.panelHi
                                          : FuturisticColors.panel.withOpacity(0.4)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? FuturisticColors.cyan
                                        : (isToday
                                            ? FuturisticColors.cyan.withOpacity(0.5)
                                            : FuturisticColors.border),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: FuturisticColors.cyan.withOpacity(0.25),
                                            blurRadius: 10,
                                            spreadRadius: -2,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      dayName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isToday || isSelected
                                            ? FuturisticColors.cyan
                                            : (hasLessons ? FuturisticColors.textHi : FuturisticColors.textLo),
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd').format(date),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isToday || isSelected
                                            ? FuturisticColors.cyan
                                            : (hasLessons ? FuturisticColors.textHi : FuturisticColors.textLo),
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
                            onPageChanged: (index) {
                              if (_currentPageIndex != index) {
                                setState(() => _currentPageIndex = index);
                              }
                            },
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
      ),
    );
  }
}
