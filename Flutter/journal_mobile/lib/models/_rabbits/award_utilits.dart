import 'package:flutter/material.dart';

class AwardUtils {
  static String getPointTypeName(int? pointTypesId) {
    switch (pointTypesId) {
      case 1:
        return 'ТопКоины';
      case 2:
        return 'ТопГемы';
      default:
        return 'Баллы';
    }
  }

  static Color getPointTypeColor(int? pointTypesId) {
    switch (pointTypesId) {
      case 1:
        return Colors.amber.shade700;
      case 2:
        return Colors.purple.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  static IconData getPointTypeIcon(int? pointTypesId) {
    switch (pointTypesId) {
      case 1:
        return Icons.monetization_on;
      case 2:
        return Icons.diamond;
      default:
        return Icons.star;
    }
  }

  static String getAchievementDisplayName(String? achievementName) {
    switch (achievementName) {
      case 'ASSESMENT':
        return 'Оценка за работу';
      case 'EVALUATION_LESSON_MARK':
        return 'Оценка за урок';
      case 'PAIR_VISIT':
        return 'Посещение пары';
      case 'HOMEWORK':
        return 'Домашняя работа';
      case 'TEST':
        return 'Тестирование';
      case 'EXAM':
        return 'Экзамен';
      case 'ACTIVITY':
        return 'Активность на уроке';
      case 'PROJECT':
        return 'Учебный проект';
      case 'PARTICIPATION':
        return 'Участие в мероприятии';
      case 'HELP':
        return 'Помощь одногруппникам';
      case 'HOMETASK_INTIME':
        return 'Вовремя выполненная работа';
      case 'AUTO_MARK_EXPIRED_HOMEWORK':
        return 'Балл за просроченную работу';
      default:
        return achievementName ?? 'Достижение';
    }
  }

  static String getAchievementDescription(String? achievementName) {
    switch (achievementName) {
      case 'ASSESMENT':
        return 'За учебную работу';
      case 'EVALUATION_LESSON_MARK':
        return 'За работу на уроке';
      case 'PAIR_VISIT':
        return 'Посещение учебной пары';
      case 'HOMEWORK':
        return 'Выполнение домашнего задания';
      case 'TEST':
        return 'Прохождение тестирования';
      case 'EXAM':
        return 'Сдача экзамена';
      case 'ACTIVITY':
        return 'Активная работа на занятии';
      case 'PROJECT':
        return 'Защита учебного проекта';
      case 'PARTICIPATION':
        return 'Участие в учебном мероприятии';
      case 'HELP':
        return 'Помощь другим студентам';
      case 'HOMETASK_INTIME':
        return 'Сдана до срока';
      case 'AUTO_MARK_EXPIRED_HOMEWORK':
        return 'Сдана после срока';
      default:
        return 'Учебное достижение';
    }
  }

  static String getAchievementSource(String? achievementName) {
    switch (achievementName) {
      case 'ASSESMENT':
      case 'EVALUATION_LESSON_MARK':
        return 'Учебное занятие';
      case 'PAIR_VISIT':
        return 'Посещение';
      case 'HOMEWORK':
        return 'Домашняя работа';
      case 'TEST':
        return 'Контрольная работа';
      case 'EXAM':
        return 'Экзамен';
      case 'ACTIVITY':
        return 'Активность';
      case 'PROJECT':
        return 'Проектная работа';
      case 'PARTICIPATION':
        return 'Мероприятие';
      case 'HELP':
        return 'Взаимопомощь';
      default:
        return 'Учебный процесс';
    }
  }

  static IconData getAchievementIcon(int? achievementsType, String? achievementName) {
    if (achievementName != null) {
      switch (achievementName) {
        case 'ASSESMENT':
        case 'EVALUATION_LESSON_MARK':
          return Icons.assignment_turned_in;
        case 'PAIR_VISIT':
          return Icons.school;
        case 'HOMEWORK':
          return Icons.home_work;
        case 'TEST':
          return Icons.quiz;
        case 'EXAM':
          return Icons.assignment;
        case 'ACTIVITY':
          return Icons.psychology;
        case 'PROJECT':
          return Icons.work;
        case 'PARTICIPATION':
          return Icons.people;
        case 'HELP':
          return Icons.help;
        default:
          return Icons.emoji_events;
      }
    }
    
    switch (achievementsType) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.workspace_premium;
      case 3:
        return Icons.flag;
      default:
        return Icons.card_giftcard;
    }
  }

  static String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}