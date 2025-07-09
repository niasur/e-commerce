import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> _cartItems = [];
  Set<int> _selectedIndexes = {};
  bool _selectAll = false;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = prefs.getStringList('cart') ?? [];
    setState(() {
      _cartItems = cartData
          .map((item) => json.decode(item) as Map<String, dynamic>)
          .toList();
    });
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final updatedCart = _cartItems.map((item) => json.encode(item)).toList();
    await prefs.setStringList('cart', updatedCart);
  }

  double get _selectedTotal {
    return _selectedIndexes.fold(0.0, (total, index) {
      final item = _cartItems[index];
      final price = (item['price'] as num).toDouble();
      final qty = item['quantity'] ?? 1;
      return total + (price * qty);
    });
  }

  Future<void> _changeQuantity(int index, int delta) async {
    final item = _cartItems[index];
    final qty = (item['quantity'] ?? 1) + delta;
    if (qty <= 0) {
      _showDeleteDialog(index);
    } else {
      setState(() => item['quantity'] = qty);
      await _saveCart();
    }
  }

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFEEEEE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Hapus produk dari Keranjang?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12),
            Text(
              'Yakin ingin menghapus produk ini?',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
        actionsPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  setState(() {
                    _cartItems.removeAt(index);
                    _selectedIndexes.remove(index);
                  });
                  await _saveCart();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text('Ya, Hapus'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSelected() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus produk terpilih?'),
        content: const Text('Yakin ingin menghapus produk yang dipilih?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteSelected();
            },
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
  }

  void _deleteSelected() async {
    setState(() {
      _cartItems = _cartItems
          .asMap()
          .entries
          .where((e) => !_selectedIndexes.contains(e.key))
          .map((e) => e.value)
          .toList();
      _selectedIndexes.clear();
      _selectAll = false;
    });
    await _saveCart();
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      _selectedIndexes = _selectAll
          ? Set.from(List.generate(_cartItems.length, (i) => i))
          : {};
    });
  }

  void _showProductDetail(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item['name'] ?? 'Detail Produk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['description'] ?? '',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Image.network(item['image'] ?? '',
                height: 100,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
            const SizedBox(height: 10),
            Text('Harga: ${_currencyFormat.format(item['price'])}'),
            const SizedBox(height: 5),
            Text('Jumlah: ${item['quantity'] ?? 1}'),
            const SizedBox(height: 16),
            if ((item['variants'] as List).isNotEmpty) ...[
              const Text(
                'Pilih Varian',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 5),
              StatefulBuilder(
                builder: (context, setState) => DropdownButton<String>(
                  isExpanded: true,
                  value: item['selectedVariant'],
                  onChanged: (newValue) async {
                    if (newValue == null || newValue == item['selectedVariant']) return;

                    final prefs = await SharedPreferences.getInstance();
                    List<String> cartData = prefs.getStringList('cart') ?? [];
                    List<Map<String, dynamic>> cartItems = cartData
                        .map((e) => json.decode(e) as Map<String, dynamic>)
                        .toList();

                    final oldVariant = item['selectedVariant'];
                    final productId = item['id'];

                    // 1. Cek apakah varian baru sudah ada
                    int? existingIndex = cartItems.indexWhere((cartItem) =>
                    cartItem['id'] == productId &&
                        cartItem['selectedVariant'] == newValue);

                    // 2. Temukan index item lama (yang sedang diubah)
                    int oldIndex = cartItems.indexWhere((cartItem) =>
                    cartItem['id'] == productId &&
                        cartItem['selectedVariant'] == oldVariant);

                    if (oldIndex == -1) return; // error safeguard

                    if (existingIndex != -1) {
                      // 3a. Jika varian baru sudah ada → gabungkan quantity
                      cartItems[existingIndex]['quantity'] =
                          (cartItems[existingIndex]['quantity'] ?? 1) +
                              (cartItems[oldIndex]['quantity'] ?? 1);

                      // 3b. Hapus item lama
                      cartItems.removeAt(oldIndex);
                    } else {
                      // 4. Kalau belum ada → cukup update variannya
                      cartItems[oldIndex]['selectedVariant'] = newValue;
                    }

                    // 5. Simpan kembali
                    List<String> updatedCart =
                    cartItems.map((e) => json.encode(e)).toList();
                    await prefs.setStringList('cart', updatedCart);

                    if (context.mounted) {
                      Navigator.pop(context);
                      _loadCart(); // reload tampilan cart
                    }
                  },
                  items: (item['variants'] as List).map<DropdownMenuItem<String>>((v) {
                    return DropdownMenuItem<String>(
                      value: v,
                      child: Text(v),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    final name = item['name'] ?? '';
    final image = item['image'] ?? '';
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final qty = item['quantity'] ?? 1;
    final isSelected = _selectedIndexes.contains(index);

    return GestureDetector(
      onTap: () => _showProductDetail(item),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 1.0, end: isSelected ? 1.03 : 1.0),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.grey.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : [],
              ),
              child: child,
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  value == true
                      ? _selectedIndexes.add(index)
                      : _selectedIndexes.remove(index);
                  _selectAll = _selectedIndexes.length == _cartItems.length;
                });
              },
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                image,
                width: 80,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, size: 50),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 16)),
                  Text(_currencyFormat.format(price),
                      style: const TextStyle(fontSize: 14)),
                  if (item['selectedVariant'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Varian: ${item['selectedVariant']}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => _changeQuantity(index, -1),
                ),
                Text('$qty', style: const TextStyle(fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _changeQuantity(index, 1),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteDialog(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _cartItems.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang')),
      body: isEmpty
          ? const Center(child: Text('Keranjang kosong'))
          : Column(
        children: [
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: _selectAll,
                  onChanged: _toggleSelectAll,
                ),
                const Text(
                  'Pilih Semua',
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                if (_selectedIndexes.isNotEmpty)
                  TextButton.icon(
                    onPressed: _confirmDeleteSelected,
                    icon:
                    const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Hapus Terpilih',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _cartItems.length,
              itemBuilder: (_, i) =>
                  _buildCartItem(_cartItems[i], i),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Total: ${_currencyFormat.format(_selectedTotal)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _selectedIndexes.isNotEmpty
                      ? () {
                    final selectedItems = _selectedIndexes
                        .map((i) => _cartItems[i])
                        .toList();
                    final total = _selectedTotal;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckoutPage(
                          selectedItems: selectedItems,
                          total: total,
                          onPaymentSuccess: () async {
                            setState(() {
                              _cartItems = _cartItems
                                  .asMap()
                                  .entries
                                  .where((e) => !_selectedIndexes.contains(e.key))
                                  .map((e) => e.value)
                                  .toList();
                              _selectedIndexes.clear();
                              _selectAll = false;
                            });
                            await _saveCart();
                          },
                        ),
                      ),
                    );
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Checkout'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}