class NoticeItem {
  NoticeItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  static NoticeItem fromMap(Map<String, dynamic> map) {
    return NoticeItem(
      id: (map['id'] as num).toInt(),
      type: map['type'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      isRead: ((map['is_read'] as num?) ?? 0).toInt() == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
