import 'package:flutter/material.dart';
import '../models/mark.dart';
import '../models/user_data.dart';
import '../services/api_service.dart';

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
  
  bool _showOnlyWithMarks = false;
  bool _showOnlyWithAbsence = false;
  bool _showOnlyWithLateness = false;
  int? _selectedMarkFilter;
  Set<String> _selectedSubjects = Set<String>();

  @override
  void initState() {
    super.initState();
    _marksFuture = _apiService.getMarks(widget.token);
    _userFuture = _apiService.getUser(widget.token);
    _searchController.addListener(_onSearchChanged);

    _marksFuture.then((marks) {
      setState(() {
        _allMarks = marks;
        _filteredMarks = List.from(_allMarks);
      });
    });
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
    
    List<Mark> filtered = List.from(_allMarks);

    if (query.isNotEmpty) {
      filtered = filtered.where((mark) {
        return mark.specName.toLowerCase().contains(query) ||
               mark.lessonTheme.toLowerCase().contains(query) ||
               mark.dateVisit.toLowerCase().contains(query);
      }).toList();
    }

    if (_showOnlyWithMarks) {
      filtered = filtered.where((mark) {
        return mark.homeWorkMark != null ||
               mark.controlWorkMark != null ||
               mark.labWorkMark != null ||
               mark.classWorkMark != null ||
               mark.practicalWorkMark != null;
      }).toList();
    }

    if (_showOnlyWithAbsence) {
      filtered = filtered.where((mark) => mark.statusWas == 0).toList();
    }

    if (_showOnlyWithLateness) {
      filtered = filtered.where((mark) => mark.statusWas == 2).toList();
    }

    if (_selectedMarkFilter != null) {
      filtered = filtered.where((mark) {
        return mark.homeWorkMark == _selectedMarkFilter ||
               mark.controlWorkMark == _selectedMarkFilter ||
               mark.labWorkMark == _selectedMarkFilter ||
               mark.classWorkMark == _selectedMarkFilter ||
               mark.practicalWorkMark == _selectedMarkFilter;
      }).toList();
    }

    if (_selectedSubjects.isNotEmpty) {
      filtered = filtered.where((mark) => _selectedSubjects.contains(mark.specName)).toList();
    }

    setState(() {
      _filteredMarks = filtered;
    });
  }

  void _clearSearch() {
    _searchController.clear();
  }

  void _resetFilters() {
    setState(() {
      _showOnlyWithMarks = false;
      _showOnlyWithAbsence = false;
      _showOnlyWithLateness = false;
      _selectedMarkFilter = null;
      _selectedSubjects.clear();
    });
    _filterMarks();
  }

  List<String> _getUniqueSubjects() {
    return _allMarks.map((mark) => mark.specName).toSet().toList();
  }

  void _openFilterDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildFilterDrawerContent(),
    );
  }

  void _openSubjectSelectionDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildSubjectSelectionDrawerContent(),
    );
  }

  Widget _buildFilterDrawerContent() {
    return FutureBuilder<List<Mark>>(
      future: _marksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Center(child: Text('Ошибка загрузки данных')),
          );
        }

        final uniqueSubjects = _getUniqueSubjects();
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Фильтры оценок',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              const Text('Основные фильтры:', style: TextStyle(fontWeight: FontWeight.bold)),
              CheckboxListTile(
                title: const Text('Только с оценками'),
                value: _showOnlyWithMarks,
                onChanged: (value) {
                  setState(() {
                    _showOnlyWithMarks = value!;
                  });
                  _filterMarks();
                  Navigator.pop(context);
                },
              ),
              CheckboxListTile(
                title: const Text('Только с пропусками'),
                value: _showOnlyWithAbsence,
                onChanged: (value) {
                  setState(() {
                    _showOnlyWithAbsence = value!;
                  });
                  _filterMarks();
                  Navigator.pop(context);
                },
              ),
              CheckboxListTile(
                title: const Text('Только с опозданиями'),
                value: _showOnlyWithLateness,
                onChanged: (value) {
                  setState(() {
                    _showOnlyWithLateness = value!;
                  });
                  _filterMarks();
                  Navigator.pop(context);
                },
              ),
              
              const SizedBox(height: 20),
              
              const Text('Оценки:', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: [1, 2, 3, 4, 5].map((mark) {
                  return FilterChip(
                    label: Text('$mark'),
                    selected: _selectedMarkFilter == mark,
                    onSelected: (selected) {
                      setState(() {
                        _selectedMarkFilter = selected ? mark : null;
                      });
                      _filterMarks();
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 20),
              
              const Text('Предметы:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: uniqueSubjects.isEmpty
                    ? Center(child: Text('Предметы не найдены'))
                    : ListView.builder(
                        itemCount: uniqueSubjects.length,
                        itemBuilder: (context, index) {
                          final subject = uniqueSubjects[index];
                          return CheckboxListTile(
                            title: Text(subject),
                            value: _selectedSubjects.contains(subject),
                            onChanged: (value) {
                              setState(() {
                                if (value!) {
                                  _selectedSubjects.add(subject);
                                } else {
                                  _selectedSubjects.remove(subject);
                                }
                              });
                              _filterMarks();
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
              
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    _resetFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Сбросить фильтры'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubjectSelectionDrawerContent() {
    return FutureBuilder<List<Mark>>(
      future: _marksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Center(child: Text('Ошибка загрузки данных')),
          );
        }

        final uniqueSubjects = _getUniqueSubjects();
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Выбор предметов',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Выберите предметы для отображения:',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              
              Expanded(
                child: uniqueSubjects.isEmpty
                    ? Center(child: Text('Предметы не найдены'))
                    : SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: uniqueSubjects.map((subject) {
                            return FilterChip(
                              label: Text(
                                subject,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              selected: _selectedSubjects.contains(subject),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedSubjects.add(subject);
                                  } else {
                                    _selectedSubjects.remove(subject);
                                  }
                                });
                                _filterMarks();
                                Navigator.pop(context);
                              },
                            );
                          }).toList(),
                        ),
                      ),
              ),
              
              const SizedBox(height: 20),
              
              if (uniqueSubjects.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedSubjects.addAll(uniqueSubjects);
                          });
                          _filterMarks();
                          Navigator.pop(context);
                        },
                        child: const Text('Выбрать все'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedSubjects.clear();
                          });
                          _filterMarks();
                          Navigator.pop(context);
                        },
                        child: const Text('Очистить'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
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
      case 3:
        icon = Icons.check_circle;
        color = const Color.fromARGB(255, 0, 172, 114);
        tooltipText = 'Уважительная причина';
        break;
      case 4:
        icon = Icons.watch_later;
        color = const Color.fromARGB(255, 147, 0, 245);
        tooltipText = 'Больничный';
        break;
      case 5:
        icon = Icons.watch_later;
        color = const Color.fromARGB(255, 99, 96, 255);
        tooltipText = 'Практика';
        break;
      case 6:
        icon = Icons.watch_later;
        color = const Color.fromARGB(255, 141, 141, 141);
        tooltipText = 'Другое';
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
      case 'practical':
        color = Colors.orange.shade700;
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
                    onPressed: () => _openFilterDrawer(context),
                  ),                  
                  IconButton(
                    icon: Icon(
                      Icons.menu,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () => _openSubjectSelectionDrawer(context),
                  ),
                  
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
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
                        color: const Color.fromARGB(255, 0, 0, 0),
                      ),
                      onPressed: _clearSearch,
                    ),
                ],
              ),
            ),
          ),

          if (_showOnlyWithMarks || _showOnlyWithAbsence || _showOnlyWithLateness || _selectedMarkFilter != null || _selectedSubjects.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (_showOnlyWithMarks)
                    Chip(
                      label: const Text('С оценками'),
                      onDeleted: () {
                        setState(() {
                          _showOnlyWithMarks = false;
                        });
                        _filterMarks();
                      },
                    ),
                  if (_showOnlyWithAbsence)
                    Chip(
                      label: const Text('С пропусками'),
                      onDeleted: () {
                        setState(() {
                          _showOnlyWithAbsence = false;
                        });
                        _filterMarks();
                      },
                    ),
                  if (_showOnlyWithLateness)
                    Chip(
                      label: const Text('С опозданиями'),
                      onDeleted: () {
                        setState(() {
                          _showOnlyWithLateness = false;
                        });
                        _filterMarks();
                      },
                    ),
                  if (_selectedMarkFilter != null)
                    Chip(
                      label: Text('Оценка: $_selectedMarkFilter'),
                      onDeleted: () {
                        setState(() {
                          _selectedMarkFilter = null;
                        });
                        _filterMarks();
                      },
                    ),
                  ..._selectedSubjects.map((subject) => Chip(
                    label: Text(subject),
                    onDeleted: () {
                      setState(() {
                        _selectedSubjects.remove(subject);
                      });
                      _filterMarks();
                    },
                  )).toList(),
                ],
              ),
            ),

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
                              'Попробуйте изменить запрос или фильтры',
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
                                            _buildMarkChip(mark.practicalWorkMark, 'practical'),
                                            
                                            if (mark.homeWorkMark == null && 
                                                mark.controlWorkMark == null && 
                                                mark.labWorkMark == null && 
                                                mark.classWorkMark == null &&
                                                mark.practicalWorkMark == null)
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