import 'package:flutter/material.dart';
import '../models/mark.dart';
import '../models/user_data.dart';
import '../services/api_service.dart';

GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

class MarksAndProfileScreen extends StatefulWidget {
  final String token;
  const MarksAndProfileScreen({super.key, required this.token});

  @override
  State<MarksAndProfileScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<MarksAndProfileScreen> {
  final _apiService = ApiService();
  late Future<List<Mark>> _marksFuture;
  late Future<UserData> _userFuture;
  final TextEditingController _searchController = TextEditingController();
  List<Mark> _filteredMarks = [];
  List<Mark> _allMarks = [];

  @override
  void initState() {
    super.initState();
    _marksFuture = _apiService.getMarks(widget.token);
    _userFuture = _apiService.getUser(widget.token);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterMarks();
  }

  void _filterMarks() {
    final query = _searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        _filteredMarks = List.from(_allMarks);
      });
      return;
    }

    setState(() {
      _filteredMarks = _allMarks.where((mark) {
        return mark.specName.toLowerCase().contains(query) ||
               mark.lessonTheme.toLowerCase().contains(query) ||
               mark.dateVisit.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _clearSearch() {
    _searchController.clear();
  }

  Widget _buildStatusIcon(int? statusWas) {
    if (statusWas == null) return const SizedBox.shrink();

    IconData icon;
    Color color;
    String tooltipText;

    switch (statusWas) {
      case 0:
        icon = Icons.cancel;
        color = Colors.red.shade700;
        tooltipText = 'Не был(а)';
        break;
      case 1:
        icon = Icons.check_circle;
        color = Colors.green.shade700;
        tooltipText = 'Был(а)';
        break;
      case 2:
        icon = Icons.watch_later;
        color = Colors.orange.shade700;
        tooltipText = 'Опоздал(а)';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Tooltip(
      message: tooltipText,
      child: Icon(
        icon,
        color: color,
        size: 28,
      ),
    );
  }

  Widget _buildMarkChip(int? mark, String type) {
    if (mark == null) return const SizedBox.shrink();

    Color color;
    switch (type) {
      case 'home':
        color = Colors.red.shade700;
        break;
      case 'control':
        color = Colors.green.shade700;
        break;
      case 'lab':
        color = Colors.purple.shade700;
        break;
      case 'class':
        color = Colors.blue.shade700;
        break;
      default:
        color = Colors.white;
    }

    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        mark.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: FutureBuilder<UserData>(
          future: _userFuture,
          builder: (context, snapshot) {
            return Text(
              snapshot.hasData ? snapshot.data!.fullName : 'Профиль',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.5),
                  width: 1.0,
                ),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.filter_alt,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ), // TODO: Фильтр списка: Пары с оценками, без оценок. Пары с пропуском, опазданием. Фильтр оценок 1 - 5
                  IconButton(
                    icon: Icon(
                      Icons.menu,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ), // TODO: Какие предметы посмотреть из списка - список не просто column // row, а матрица !
                  
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: "Поиск по предметам, темам...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: _clearSearch,
                    ),
                  IconButton(
                    icon: Icon(
                      Icons.search,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {
                      // Фокус уже в поле поиска
                    },
                  ),
                ],
              ),
            ),
          ),

          // Список оценок
          Expanded(
            child: FutureBuilder<List<Mark>>(
              future: _marksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Ошибка: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Оценок не найдено'));
                }

                // Сохраняем все оценки и фильтруем их
                if (_allMarks.isEmpty) {
                  _allMarks = snapshot.data!;
                  _filteredMarks = List.from(_allMarks);
                }

                return _filteredMarks.isEmpty && _searchController.text.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Ничего не найдено',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Попробуйте изменить запрос',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredMarks.length,
                        itemBuilder: (context, index) {
                          final mark = _filteredMarks[index];
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12.0),
                                    child: _buildStatusIcon(mark.statusWas),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mark.specName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          mark.lessonTheme,
                                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6.0,
                                          runSpacing: 4.0,
                                          children: [
                                            _buildMarkChip(mark.homeWorkMark, 'home'),
                                            _buildMarkChip(mark.controlWorkMark, 'control'),
                                            _buildMarkChip(mark.labWorkMark, 'lab'),
                                            _buildMarkChip(mark.classWorkMark, 'class'),
                                            
                                            if (mark.homeWorkMark == null && 
                                                mark.controlWorkMark == null && 
                                                mark.labWorkMark == null && 
                                                mark.classWorkMark == null)
                                              const Text('Б/О', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      mark.dateVisit,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}