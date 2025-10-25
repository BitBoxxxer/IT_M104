import 'package:flutter/material.dart';
import '../models/leaderboard_user.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final String token;
  final bool isGroupLeaderboard;

  const LeaderboardScreen({
    super.key,
    required this.token,
    required this.isGroupLeaderboard,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<LeaderboardUser>> _leadersFuture;

  @override
  void initState() {
    super.initState();
    _loadLeaders();
  }

  void _loadLeaders() {
    setState(() {
      _leadersFuture = widget.isGroupLeaderboard
          ? _apiService.getGroupLeaders(widget.token)
          : _apiService.getStreamLeaders(widget.token);
    });
  }

  Widget _buildRankIcon(int position) {
    if (position == 1) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.amber,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.emoji_events, color: Colors.white, size: 24),
      );
    } else if (position == 2) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.emoji_events, color: Colors.white, size: 24),
      );
    } else if (position == 3) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.orange.shade700,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.emoji_events, color: Colors.white, size: 24),
      );
    } else {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            position.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildLeaderItem(LeaderboardUser user, int index) {
    final displayPosition = user.position > 0 ? user.position : index + 1;
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: _buildRankIcon(displayPosition),
        title: Text(
          user.fullName.trim().isEmpty ? 'Неизвестный пользователь' : user.fullName,
          style: TextStyle(
            fontWeight: user.position <= 3 ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        subtitle: widget.isGroupLeaderboard
            ? null
            : Text(
                user.groupName ?? '',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.monetization_on, size: 16, color: Colors.amber),
              SizedBox(width: 4),
              Text(
                (user.points > 0 ? user.points : user.totalPoints ?? 0).toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<LeaderboardUser> _filterLeaders(List<LeaderboardUser> leaders) {
    return leaders.where((user) => user.fullName.trim().isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isGroupLeaderboard 
              ? 'Лидеры группы' 
              : 'Лидеры потока',
        ),
      ),
      body: FutureBuilder<List<LeaderboardUser>>(
        future: _leadersFuture,
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
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadLeaders,
                    child: Text('Попробовать снова'),
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
                  Icon(Icons.leaderboard_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Нет данных о лидерах',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Информация будет доступна позже',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          final leaders = _filterLeaders(snapshot.data!);
          
          if (leaders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.leaderboard_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Нет данных о лидерах',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              _loadLeaders();
            },
            child: ListView.builder(
              itemCount: leaders.length,
              itemBuilder: (context, index) {
                return _buildLeaderItem(leaders[index], index);
              },
            ),
          );
        },
      ),
    );
  }
}