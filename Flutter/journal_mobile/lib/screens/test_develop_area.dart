import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart'; // на потом, для работы с токенами и пр API запросами.

// TODO: Добавить список логинов разработчиков, чтобы не показывать этот экран в продакшн сборке.
class AreaDevelopScreen extends StatefulWidget {
  const AreaDevelopScreen({super.key});

  @override
  State<AreaDevelopScreen> createState() => _AreaDevelopScreenState();
}

class _AreaDevelopScreenState extends State<AreaDevelopScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Арена разработки')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),

            const Text(
              'Тестовые функции:',
              style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: 250,
              child: ElevatedButton.icon(
                icon: Icon(Icons.bug_report, color: Colors.red),
                label: Text('Симулировать ошибку токена', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  final apiService = ApiService();
                  await apiService.simulateTokenError();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ошибка токена симулирована! Перезайдите в приложение'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                ),
              ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              width: 250,
              child: ElevatedButton.icon(
                icon: Icon(Icons.delete, color: Colors.purple),
                label: Text('Очистить токен', style: TextStyle(color: Colors.purple)),
                onPressed: () async {
                  final apiService = ApiService();
                  await apiService.clearTokenForTesting();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Токен очищен! Перезайдите в приложение'),
                      backgroundColor: Colors.purple,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade50,
                ),
              ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              width: 250,
              child: ElevatedButton.icon(
                icon: Icon(Icons.security, color: Colors.blue),
                label: Text('Проверить текущий токен', style: TextStyle(color: Colors.blue)),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('token');
                  final username = prefs.getString('username');
                  
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Информация о токене'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Токен: ${token?.substring(0, 20)}...'),
                          Text('Длина: ${token?.length ?? 0} символов'),
                          Text('Username: $username'),
                          SizedBox(height: 10),
                          Text(
                            token == null || token.isEmpty ? 'Токен отсутствует' : 'Токен есть',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: token == null || token.isEmpty ? Colors.red : Colors.green
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}