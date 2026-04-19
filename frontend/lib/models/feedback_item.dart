class FeedbackItem {
  FeedbackItem({
    required this.id,
    required this.owner,
    required this.category,
    required this.title,
    required this.detail,
    this.contact,
    required this.createdAt,
  });

  final int id;
  final String owner;
  final String category;
  final String title;
  final String detail;
  final String? contact;
  final DateTime createdAt;

  static FeedbackItem fromMap(Map<String, dynamic> map) {
    return FeedbackItem(
      id: (map['id'] as num).toInt(),
      owner: map['owner'] as String,
      category: map['category'] as String,
      title: map['title'] as String,
      detail: map['detail'] as String,
      contact: map['contact'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
