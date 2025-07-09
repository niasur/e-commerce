import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductService {
  final String baseUrl = 'http://localhost:3000';

  // Fetch product list from API
  Future<List<Product>> fetchProducts() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/products'));

      if (res.statusCode == 200) {
        final List data = json.decode(res.body);

        return data.map((e) => Product.fromJson(e)).toList();
      } else {
        // Error response dari server
        throw Exception("Status ${res.statusCode}: ${res.body}");
      }
    } catch (e) {
      debugPrint('Fetch error: $e');
      throw Exception("Gagal memuat produk. Pastikan koneksi internet aktif.");
    }
  }
}