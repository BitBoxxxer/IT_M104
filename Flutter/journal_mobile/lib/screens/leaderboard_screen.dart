import 'package:flutter/material.dart';
import '../models/leaderboard_user.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final String token;
  final bool isGroupLeaderboard;
  final int? currentUserId;
  final String? currentUserName;

  const LeaderboardScreen({
    super.key,
    required this.token,
    required this.isGroupLeaderboard,
    required this.currentUserId,
    this.currentUserName,
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

  String _normalizeName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Widget _buildLeaderItem(LeaderboardUser user, int index) {
    final displayPosition = user.position > 0 ? user.position : index + 1;
    
    bool isCurrentUserById = widget.currentUserId != null && 
                            user.studentId == widget.currentUserId &&
                            user.studentId != 0;
    
    bool isCurrentUserByName = widget.currentUserName != null &&
                              user.fullName.trim().isNotEmpty &&
                              _normalizeName(user.fullName) == _normalizeName(widget.currentUserName!);
    
    final isCurrentUser = isCurrentUserById || isCurrentUserByName;

    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: isCurrentUser ? 8 : 2,
        shadowColor: isCurrentUser ? Colors.blue.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isCurrentUser 
              ? BorderSide(
                  color: Colors.blue.shade400.withOpacity(0.6),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignOutside,
                )
              : BorderSide.none,
        ),
        child: Container(
          decoration: isCurrentUser
              ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade50.withOpacity(0.3),
                      Colors.lightBlue.shade50.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                )
              : null,
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: _buildRankIcon(displayPosition),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    user.fullName.trim().isEmpty ? 'Неизвестный пользователь' : user.fullName,
                    style: TextStyle(
                      fontWeight: user.position <= 3 ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCurrentUser) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.lightBlue.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Вы',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            subtitle: widget.isGroupLeaderboard
                ? null
                : Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      user.groupName,
                      style: TextStyle(
                        fontSize: 12, 
                        color: isCurrentUser ? Colors.blue.shade600 : Colors.grey.shade600
                      ),
                    ),
                  ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: isCurrentUser 
                    ? LinearGradient(
                        colors: [Colors.blue.shade100, Colors.lightBlue.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.blue.shade50, Colors.lightBlue.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCurrentUser 
                      ? Colors.blue.shade300 
                      : Colors.blue.shade200,
                  width: 1.5,
                ),
                boxShadow: [
                  if (isCurrentUser)
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.monetization_on, 
                    size: 16, 
                    color: isCurrentUser ? Colors.orange.shade600 : Colors.amber.shade600,
                  ),
                  SizedBox(width: 6),
                  Text(
                    (user.points > 0 ? user.points : user.totalPoints ?? 0).toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCurrentUser ? Colors.blue.shade900 : Colors.blue.shade800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Загрузка рейтинга...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
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
                    'Попробуйте обновить',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh),
                    label: Text('Обновить'),
                    onPressed: _loadLeaders,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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