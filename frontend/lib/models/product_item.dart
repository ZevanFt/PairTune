class ProductItem {
  ProductItem({
    required this.id,
    required this.publisher,
    required this.name,
    this.description,
    required this.pointsCost,
    required this.stock,
  });

  final int id;
  final String publisher;
  final String name;
  final String? description;
  final int pointsCost;
  final int stock;

  static ProductItem fromMap(Map<String, dynamic> map) {
    return ProductItem(
      id: (map['id'] as num).toInt(),
      publisher: map['publisher'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      pointsCost: (map['points_cost'] as num).toInt(),
      stock: (map['stock'] as num).toInt(),
    );
  }
}
