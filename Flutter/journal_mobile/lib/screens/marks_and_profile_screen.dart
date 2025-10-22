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

Widget _buildStatusIcon(int? statusWas) {
    if (statusWas == null) return const SizedBox.shrink();

    IconData icon;
    Color color;
    String tooltipText;

    switch (statusWas) {
      case 0:
        icon = Icons.cancel;
        color = Colors.red.shade700;
        tooltipText = 'Не был';
        break;
      case 1:
        icon = Icons.check_circle;
        color = Colors.green.shade700;
        tooltipText = 'Был';
        break;
      case 2:
        icon = Icons.watch_later;
        color = Colors.orange.shade700;
        tooltipText = 'Опоздал';
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

class _HomeScreenState extends State<MarksAndProfileScreen> {
  final _apiService = ApiService();
  late Future<List<Mark>> _marksFuture;
  late Future<UserData> _userFuture;

  @override
  void initState() {
    super.initState();
    _marksFuture = _apiService.getMarks(widget.token);
    _userFuture = _apiService.getUser(widget.token);
  }

  Widget _buildMarkChip(int? mark, String type) {
  if (mark == null) return const SizedBox.shrink();

  Color color;
  switch (type) {
    case 'home':
      color = Colors.red.shade700; // Домашняя работа
      break;
    case 'control':
      color = Colors.green.shade700; // Контрольная
      break;
    case 'lab':
      color = Colors.purple.shade700; // Лабораторная
      break;
    case 'class':
      color = Colors.blue.shade700; // В классе
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
      appBar: AppBar(
        title: FutureBuilder<UserData>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data!.fullName);
            }
            return const Text('Профиль');
          },
        ),
      ),
      body: FutureBuilder<List<Mark>>(
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
          final marks = snapshot.data!;
          return ListView.builder(
            itemCount: marks.length,
            itemBuilder: (context, index) {
              final mark = marks[index];
              
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
    );
  }
}