import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/product.dart';
import 'product_detail_screen.dart';
import 'package:intl/intl.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Product> wishlist = [];

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final wishlistJson = prefs.getStringList('wishlist') ?? [];
    setState(() {
      wishlist = wishlistJson
          .map((item) => Product.fromJson(json.decode(item)))
          .toList();
    });
  }

  Future<void> _removeFromWishlist(Product product) async {
    final prefs = await SharedPreferences.getInstance();
    final wishlistJson = prefs.getStringList('wishlist') ?? [];

    wishlistJson.removeWhere((item) {
      final decoded = json.decode(item);
      return decoded['id'].toString() == product.id.toString();
    });

    await prefs.setStringList('wishlist', wishlistJson);
    _loadWishlist();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} dihapus dari wishlist')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: wishlist.isEmpty
          ? const Center(child: Text('Wishlist kosong.'))
          : ListView.builder(
        itemCount: wishlist.length,
        itemBuilder: (context, index) {
          final product = wishlist[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              leading: Image.network(
                product.image,
                width: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image),
              ),
              title: Text(product.name),
              subtitle: Text(currencyFormatter.format(product.price)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _removeFromWishlist(product),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(
                      product: product,
                      isInWishlist: true,
                      onToggleWishlist: () => _removeFromWishlist(product),
                    ),
                  ),
                ).then((_) => _loadWishlist());
              },
            ),
          );
        },
      ),
    );
  }
}