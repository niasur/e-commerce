import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/product.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final bool isInWishlist;
  final VoidCallback onToggleWishlist;

  const ProductDetailScreen({
    required this.product,
    required this.isInWishlist,
    required this.onToggleWishlist,
  });

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  late bool isWishlisted;
  String? selectedVariant;

  @override
  void initState() {
    super.initState();
    isWishlisted = widget.isInWishlist;
  }

  void toggleWishlist() {
    widget.onToggleWishlist();
    setState(() {
      isWishlisted = !isWishlisted;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isWishlisted
              ? '${widget.product.name} ditambahkan ke wishlist'
              : '${widget.product.name} dihapus dari wishlist',
        ),
      ),
    );
  }

  void showDetailBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const Text(
                  'Detail Produk',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Divider(thickness: 1, color: Colors.grey),
                const SizedBox(height: 12),
                const Text(
                  'Deskripsi Produk',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.product.description,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showAddToCartBottomSheet() {
    String? tempSelectedVariant = selectedVariant;
    int tempQuantity = quantity;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const Text(
                      'Pilih Varian',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Pilih varian'),
                      value: tempSelectedVariant,
                      onChanged: (value) {
                        setModalState(() => tempSelectedVariant = value);
                      },
                      items: widget.product.variants.map((v) {
                        return DropdownMenuItem<String>(
                          value: v,
                          child: Text(v),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Jumlah',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: tempQuantity > 1
                              ? () => setModalState(() => tempQuantity--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('$tempQuantity',
                            style: const TextStyle(fontSize: 18)),
                        IconButton(
                          onPressed: () => setModalState(() => tempQuantity++),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (tempSelectedVariant == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                  Text('Silakan pilih varian terlebih dahulu')),
                            );
                            return;
                          }

                          final prefs =
                          await SharedPreferences.getInstance();
                          List<String> cartData =
                              prefs.getStringList('cart') ?? [];
                          List<Map<String, dynamic>> cartItems = cartData
                              .map((item) =>
                          json.decode(item) as Map<String, dynamic>)
                              .toList();

                          bool found = false;
                          for (var item in cartItems) {
                            if (item['id'] == widget.product.id &&
                                item['selectedVariant'] ==
                                    tempSelectedVariant) {
                              item['quantity'] =
                                  (item['quantity'] ?? 1) + tempQuantity;
                              found = true;
                              break;
                            }
                          }

                          if (!found) {
                            cartItems.add({
                              ...widget.product.toJson(),
                              'quantity': tempQuantity,
                              'selectedVariant': tempSelectedVariant,
                            });
                          }

                          List<String> updatedCart = cartItems
                              .map((item) => json.encode(item))
                              .toList();
                          await prefs.setStringList('cart', updatedCart);

                          if (mounted) {
                            Navigator.pop(context);
                            setState(() {
                              selectedVariant = null;
                              quantity = 1;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      '${widget.product.name} ditambahkan ke keranjang')),
                            );
                          }
                        },
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Add to Cart'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
        actions: [
          IconButton(
            onPressed: toggleWishlist,
            icon: Icon(
              isWishlisted ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            tooltip: 'Wishlist',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            p.image.isNotEmpty
                ? Hero(
              tag: widget.product.id,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  p.image,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image,
                      size: 150, color: Colors.grey),
                ),
              ),
            )
                : const Icon(Icons.image_not_supported,
                size: 150, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              p.name,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              currencyFormatter.format(p.price),
              style: TextStyle(fontSize: 20, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Deskripsi Produk',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                p.description.length > 60
                    ? '${p.description.substring(0, 60)}...'
                    : p.description,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: showDetailBottomSheet,
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Selengkapnya',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => showAddToCartBottomSheet(),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add to Cart'),
              style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}