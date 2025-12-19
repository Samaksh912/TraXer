class Reminder {
  final String id;
  final String title;
  final DateTime scheduledDate;
  final bool isCompleted;

  Reminder({
    required this.id,
    required this.title,
    required this.scheduledDate,
    this.isCompleted = false,
  });
}