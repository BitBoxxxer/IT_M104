import 'package:flutter/material.dart';

import '../../_rabbits/homework_utilitss.dart';
import 'homework.dart';

class HomeworkCard extends StatelessWidget {
  final Homework homework;
  final Function(Homework, bool)? onDownloadRequested;

  const HomeworkCard({
    super.key,
    required this.homework,
    this.onDownloadRequested,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final isDownloadAvailable = _isDownloadAvailable();
    final isStudentDownloadAvailable = _isStudentDownloadAvailable();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              statusColor.withOpacity(0.1),
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(statusColor),
              const SizedBox(width: 12),
              _buildContent(statusColor, isDownloadAvailable, isStudentDownloadAvailable),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Color statusColor) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: statusColor,
          width: 2,
        ),
      ),
      child: Icon(
        _getStatusIcon(),
        color: statusColor,
        size: 24,
      ),
    );
  }

  Widget _buildContent(Color statusColor, bool isDownloadAvailable, bool isStudentDownloadAvailable) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(statusColor),
          const SizedBox(height: 6),
          _buildTheme(),
          if (homework.description != null && homework.description!.isNotEmpty) 
            _buildDescription(),
          const SizedBox(height: 12),
          _buildInfoRows(),
          const SizedBox(height: 12),
          _buildBadges(statusColor, isDownloadAvailable, isStudentDownloadAvailable),
          if (isStudentDownloadAvailable) _buildStudentDownloadButton(statusColor),
          if (isDownloadAvailable) _buildDownloadButton(statusColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            homework.subjectName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: statusColor,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getStatusIcon(),
                size: 12,
                color: statusColor,
              ),
              const SizedBox(width: 4),
              Text(
                _getStatusText(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTheme() {
    return Text(
      homework.theme,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade700,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription() {
    return Column(
      children: [
        const SizedBox(height: 6),
        Text(
          homework.description!,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildInfoRows() {
    final isUrgent = homework.completionTime.isBefore(DateTime.now()) && 
                    !homework.isDone && 
                    !homework.isInspection &&
                    !homework.isDeletedStatus;

    return Column(
      children: [
        _buildInfoRow('Преподаватель', homework.teacherName, Icons.person),
        _buildInfoRow('Выдано', HomeworkUtils.formatDate(homework.creationTime), Icons.calendar_today),
        _buildInfoRow(
          'Срок сдачи', 
          HomeworkUtils.formatDate(homework.completionTime),
          Icons.access_time,
          isUrgent: isUrgent,
        ),
        
        if (homework.homeworkStud?.filename != null && homework.homeworkStud!.filename!.isNotEmpty)
          _buildInfoRow('Сданный файл', homework.homeworkStud!.filename!, Icons.assignment_turned_in),
        
        if (homework.homeworkStud?.creationTime != null)
          _buildInfoRow('Сдано', HomeworkUtils.formatDate(homework.homeworkStud!.creationTime), Icons.schedule),
        
        if (homework.homeworkStud?.mark != null)
          _buildInfoRow('Оценка', homework.homeworkStud!.mark!.toStringAsFixed(1), Icons.grade),
        
        if (homework.filename != null && homework.filename!.isNotEmpty)
          _buildInfoRow('Файл задания', homework.filename!, Icons.attach_file),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {bool isUrgent = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 14,
            color: isUrgent ? Colors.red : Colors.grey.shade500,
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
                color: isUrgent ? Colors.red : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadges(Color statusColor, bool isDownloadAvailable, bool isStudentDownloadAvailable) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (homework.isDeletedStatus)
          _buildBadge(Icons.delete, 'Удалено', Colors.grey),
        
        if (homework.isExpired)
          _buildBadge(Icons.warning, 'Просрочено', Colors.red),
        
        if (homework.isDone && homework.homeworkStud?.mark != null)
          _buildBadge(Icons.star, 'Оценка: ${homework.homeworkStud!.mark!.toStringAsFixed(1)}', Colors.green),

        if (isDownloadAvailable)
          _buildBadge(Icons.download, 'Файл задания доступен', Colors.purple),

        if (isStudentDownloadAvailable)
          _buildBadge(Icons.assignment_turned_in, 'Работа сдана', Colors.teal),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentDownloadButton(Color statusColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OutlinedButton.icon(
        onPressed: () {
          _downloadStudentFile();
        },
        icon: const Icon(Icons.download_done, size: 16),
        label: Text(_getStudentDownloadButtonText()),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.teal,
          side: const BorderSide(color: Colors.teal),
          backgroundColor: Colors.teal.withOpacity(0.05),
        ),
      ),
    );
  }

  Widget _buildDownloadButton(Color statusColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OutlinedButton.icon(
        onPressed: () {
          _downloadTeacherFile();
        },
        icon: const Icon(Icons.download, size: 16),
        label: Text(_getDownloadButtonText()),
        style: OutlinedButton.styleFrom(
          foregroundColor: statusColor,
          side: BorderSide(color: statusColor),
        ),
      ),
    );
  }

  /// Скачивание задания ДЛЯ студента - 17.12.25
   Future<void> _downloadTeacherFile() async {
    print('🔄 Попытка скачать файл задания _downloadTeacherFile');
    print('📎 Файл: ${homework.safeFilename}');
    print('🔗 URL: ${homework.downloadUrl}');
    
    if (onDownloadRequested != null && homework.downloadUrl != null) {
      print('✅ Вызываю коллбек скачивания файла _downloadTeacherFile');
      onDownloadRequested!(homework, false);
    } else {
      print('Не выполнены условия для скачивания файла _downloadTeacherFile');
      print('   downloadUrl: ${homework.downloadUrl}');
      print('   onDownloadRequested: ${onDownloadRequested != null}');
    }
  }

  /// Скачать уже СДАННЫЙ файл от студента - 17.12.25
  Future<void> _downloadStudentFile() async {
    print('🔄 Попытка скачать _downloadStudentFile файл');
    print('📎 Файл: ${homework.safeStudentFilename}');
    print('🔗 URL: ${homework.studentDownloadUrl}');
    
    if (onDownloadRequested != null && 
        homework.studentDownloadUrl != null && 
        homework.safeStudentFilename != null) {
      print('✅ Вызываю коллбек скачивания _downloadStudentFile файла');
      onDownloadRequested!(homework, true);
    } else {
      print('❌ Не выполнены условия для скачивания _downloadStudentFile файла');
      print('   studentDownloadUrl: ${homework.studentDownloadUrl}');
      print('   onDownloadRequested: ${onDownloadRequested != null}');
    }
  }

  Color _getStatusColor() {
    if (homework.isDeletedStatus) return Colors.grey.shade700;
    if (homework.isExpired) return Colors.red.shade700;
    if (homework.isDone) return Colors.green.shade700;
    if (homework.isInspection) return Colors.blue.shade700;
    if (homework.isOpened) return Colors.orange.shade700;
    return Colors.grey.shade700;
  }

  String _getStatusText() {
    if (homework.isDeletedStatus) return 'Удалено';
    if (homework.isExpired) return 'Просрочено';
    if (homework.isDone) return 'Проверено';
    if (homework.isInspection) return 'На проверке';
    if (homework.isOpened) return 'Активно';
    return 'Неизвестно';
  }

  IconData _getStatusIcon() {
    if (homework.isDeletedStatus) return Icons.delete_rounded;
    if (homework.isExpired) return Icons.warning_rounded;
    if (homework.isDone) return Icons.check_circle_rounded;
    if (homework.isInspection) return Icons.hourglass_top_rounded;
    if (homework.isOpened) return Icons.assignment_rounded;
    return Icons.help_rounded;
  }

  bool _isDownloadAvailable() {
    return homework.filePath != null && 
           homework.filePath!.isNotEmpty &&
           homework.downloadUrl != null &&
           homework.downloadUrl!.isNotEmpty;
  }

  bool _isStudentDownloadAvailable() {
    return homework.homeworkStud?.filePath != null && 
           homework.homeworkStud!.filePath!.isNotEmpty &&
           homework.studentDownloadUrl != null &&
           homework.studentDownloadUrl!.isNotEmpty;
  }

  String _getDownloadButtonText() {
    if (homework.isDeletedStatus) return 'Скачать задание (удалено)';
    if (homework.isDone) return 'Скачать задание (оценено)';
    if (homework.isInspection) return 'Скачать задание (на проверке)';
    if (homework.isExpired) return 'Скачать задание (просрочено)';
    return 'Скачать задание';
  }

  String _getStudentDownloadButtonText() {
    if (homework.isDeletedStatus) return 'Скачать сданную работу (удалено)';
    if (homework.isDone) return 'Скачать сданную работу (оценено)';
    if (homework.isInspection) return 'Скачать сданную работу (на проверке)';
    if (homework.isExpired) return 'Скачать сданную работу (просрочено)';
    return 'Скачать сданную работу';
  }
}