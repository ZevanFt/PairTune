class OwnedItem {
  OwnedItem({
    required this.id,
    required this.productName,
    required this.pointsSpent,
    required this.createdAt,
  });

  final int id;
  final String productName;
  final int pointsSpent;
  final DateTime createdAt;

  static OwnedItem fromMap(Map<String, dynamic> map) {
    return OwnedItem(
      id: (map['id'] as num).toInt(),
      productName: map['product_name'] as String,
      pointsSpent: (map['points_spent'] as num).toInt(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
