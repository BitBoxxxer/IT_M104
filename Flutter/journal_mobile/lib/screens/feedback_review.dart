import 'package:flutter/material.dart';

import '../services/_network/network_service.dart';
import '../services/api_service.dart';

import '../models/_widgets/feedback/empty_feedback.dart';
import '../models/_widgets/feedback/error_feedback.dart';
import '../models/_widgets/feedback/feedback_card.dart';
import '../models/_widgets/feedback/loading_feedback.dart';
import '../models/feedback_review.dart';

class FeedbackReviewScreen extends StatefulWidget {
  final String token;

  const FeedbackReviewScreen({super.key, required this.token});

  @override
  State<FeedbackReviewScreen> createState() => _FeedbackReviewScreenState();
}

class _FeedbackReviewScreenState extends State<FeedbackReviewScreen> {
  final ApiService _apiService = ApiService();
  final NetworkService _networkService = NetworkService();
  late Future<List<FeedbackReview>> _feedbackFuture;

  @override
  void initState() {
    super.initState();
    _feedbackFuture = _loadFeedback();
  }

  Future<List<FeedbackReview>> _loadFeedback() async {
    return await _apiService.getFeedbackReview(widget.token);
  }

  void _refreshFeedback() {
    setState(() {
      _feedbackFuture = _loadFeedback();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отзывы о студенте'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
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
        ],
      ),
      body: FutureBuilder<List<FeedbackReview>>(
        future: _feedbackFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingFeedback();
          }
          
          if (snapshot.hasError) {
            return ErrorFeedback(
              error: '${snapshot.error}',
              onRetry: _refreshFeedback,
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyFeedback();
          }
          
          final feedbackList = snapshot.data!;
          
          return RefreshIndicator(
            onRefresh: () async {
              _refreshFeedback();
            },
            child: ListView.builder(
              itemCount: feedbackList.length,
              itemBuilder: (context, index) {
                return FeedbackCard(feedback: feedbackList[index]);
              },
            ),
          );
        },
      ),
    );
  }
}