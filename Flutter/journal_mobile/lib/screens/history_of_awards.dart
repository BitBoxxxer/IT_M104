import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/secure_storage_service.dart';

import '../models/widgets/awards/award_card.dart';
import '../models/widgets/awards/empty_awards.dart';
import '../models/widgets/awards/error_awards.dart';
import '../models/widgets/awards/filter_chips.dart';
import '../models/widgets/awards/loading_awards.dart';
import '../models/widgets/awards/stats_card.dart';
import '../models/activity_record.dart';

class HistoryOfAwardsScreen extends StatefulWidget {
  @override
  State<HistoryOfAwardsScreen> createState() => _HistoryOfAwardsScreenState();
}

class _HistoryOfAwardsScreenState extends State<HistoryOfAwardsScreen> {
  final ApiService _apiService = ApiService();
  final SecureStorageService _secureStorage = SecureStorageService();
  
  late Future<List<ActivityRecord>> _awardsFuture;
  bool _isLoading = true;
  String _errorMessage = '';
  
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadAwards();
  }

  Future<void> _loadAwards() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final token = await _secureStorage.getToken();
      if (token == null) {
        throw Exception('Токен не найден');
      }

      final awards = await _apiService.getProgressActivity(token);
      
      setState(() {
        _awardsFuture = Future.value(awards);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки: $e';
        _isLoading = false;
      });
      print('Error loading awards: $e');
    }
  }

  List<ActivityRecord> _filterAwards(List<ActivityRecord> awards) {
    switch (_selectedFilter) {
      case 'coins':
        return awards.where((award) => award.pointTypesId == 1).toList();
      case 'gems':
        return awards.where((award) => award.pointTypesId == 2).toList();
      default:
        return awards;
    }
  }

  void _handleFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История наград студента'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAwards,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingAwards()
          : _errorMessage.isNotEmpty
              ? ErrorAwards(
                  errorMessage: _errorMessage,
                  onRetry: _loadAwards,
                )
              : FutureBuilder<List<ActivityRecord>>(
                  future: _awardsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red),
                            SizedBox(height: 16),
                            Text(
                              'Ошибка загрузки данных',
                              style: TextStyle(fontSize: 16, color: Colors.red),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const EmptyAwards();
                    }
                    
                    final allAwards = snapshot.data!;
                    final filteredAwards = _filterAwards(allAwards);
                    
                    return Column(
                      children: [
                        StatsCard(awards: allAwards),
                        FilterChips(
                          selectedFilter: _selectedFilter,
                          onFilterChanged: _handleFilterChanged,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Найдено записей: ${filteredAwards.length}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadAwards,
                            child: ListView.builder(
                              itemCount: filteredAwards.length,
                              itemBuilder: (context, index) {
                                return AwardCard(award: filteredAwards[index]);
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}