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

    final bool hasValidAvatar = user.photoPath.isNotEmpty && 
                              user.photoPath.startsWith('http');

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
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: hasValidAvatar 
                    ? null
                    : Border.all(
                        color: isCurrentUser ? Colors.blue.shade400 : Colors.grey.shade300,
                        width: isCurrentUser ? 2 : 1.5,
                      ),
                boxShadow: hasValidAvatar
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(hasValidAvatar ? 26 : 25),
                child: hasValidAvatar
                    ? Image.network(
                        user.photoPath,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                              color: Colors.blue.shade400,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isCurrentUser ? Colors.blue.shade400 : Colors.grey.shade300,
                                width: isCurrentUser ? 2 : 1.5,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.person,
                                color: isCurrentUser ? Colors.blue.shade400 : Colors.grey.shade400,
                                size: 28,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCurrentUser ? Colors.blue.shade400 : Colors.grey.shade300,
                            width: isCurrentUser ? 2 : 1.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.person,
                            color: isCurrentUser ? Colors.blue.shade400 : Colors.grey.shade400,
                            size: 28,
                          ),
                        ),
                      ),
              ),
            ),
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
                  SizedBox(width: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.lightBlue.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      'Вы',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: widget.isGroupLeaderboard
                ? null
                : Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      user.groupName,
                      style: TextStyle(
                        fontSize: 12, 
                        color: isCurrentUser ? Colors.blue.shade600 : Colors.grey.shade600
                      ),
                    ),
                  ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCurrentUser ? Colors.blue.shade50 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCurrentUser ? Colors.blue.shade200 : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monetization_on, 
                        size: 14, 
                        color: Colors.amber.shade700,
                      ),
                      SizedBox(width: 4),
                      Text(
                        (user.points > 0 ? user.points : user.totalPoints ?? 0).toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(width: 8),
                
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getRankColor(displayPosition),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      displayPosition.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int position) {
    if (position == 1) {
      return Colors.amber.shade600;
    } else if (position == 2) {
      return Colors.grey.shade500;
    } else if (position == 3) {
      return Colors.orange.shade700;
    } else {
      return Colors.blue.shade400;
    }
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