/// (Ди - Кейси: все записывать в одну модель homework - ужасно... по сути,
///  поэтому это - существует!) [по факту для читаблеьности.])
class HomeworkCounter {
  static const int HOMEWORK_TYPE_HOMEWORK = 0;
  static const int HOMEWORK_TYPE_LABORATORY = 1;
  final int counterType;
  final int counter;

  HomeworkCounter({
    required this.counterType,
    required this.counter,
  });

  factory HomeworkCounter.fromJson(Map<String, dynamic> json) {
    return HomeworkCounter(
      counterType: json['counter_type'] as int,
      counter: json['counter'] as int,
    );
  }

  static const int HOMEWORK_STATUS_EXPIRED = 0;
  static const int HOMEWORK_STATUS_DONE = 1;
  static const int HOMEWORK_STATUS_INSPECTION = 2;
  static const int HOMEWORK_STATUS_OPENED = 3;
  static const int HOMEWORK_STATUS_COMMON_OPENED = 4;
  static const int HOMEWORK_STATUS_ALL = 5;
  static const int HOMEWORK_STATUS_DELETED = 6;

  Map<String, dynamic> toJson() {
    return {
      'counter_type': counterType,
      'counter': counter,
    };
  }
}