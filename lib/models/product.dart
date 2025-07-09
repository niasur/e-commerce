class Product {
  final String id;
  final String name;
  final int price;
  final String image;
  final String description;
  final List<String> variants;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.description,
    required this.variants,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'],
      price: json['price'],
      image: json['image'],
      description: json['description'] ?? '',
      variants: List<String>.from(json['variants'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image': image,
      'description': description,
      'variants': variants,
    };
  }
}