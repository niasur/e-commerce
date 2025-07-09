import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(bool) onThemeToggle;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService apiService = ProductService();
  int _currentIndex = 0;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _searchQuery = '';
  bool _sortAscending = true;
  bool _isLoading = true;
  String? _error;

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);
  String? _username;
  List<String> _orderHistory = [];
  List<String> _wishlist = [];
  int cartItemCount = 0;

  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProducts();
    _loadCartCount();
    _loadAccountData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'User';
      _orderHistory = prefs.getStringList('orderHistory') ?? [];
      _wishlist = prefs.getStringList('wishlist') ?? [];
    });
  }

  Future<void> _loadAccountData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullNameCtrl.text = prefs.getString('fullName') ?? '';
      _usernameCtrl.text = prefs.getString('username') ?? '';
      _passwordCtrl.text = prefs.getString('password') ?? '';
      _addressCtrl.text = prefs.getString('address') ?? '';
    });
  }

  void _showAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kelola Akun'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _fullNameCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
              TextField(controller: _usernameCtrl, decoration: const InputDecoration(labelText: 'Username')),
              TextField(controller: _passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
              TextField(controller: _addressCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Alamat')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('fullName', _fullNameCtrl.text);
              await prefs.setString('username', _usernameCtrl.text);
              await prefs.setString('password', _passwordCtrl.text);
              await prefs.setString('address', _addressCtrl.text);
              setState(() {
                _username = _usernameCtrl.text;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data akun berhasil disimpan')),
              );
            },
            child: const Text('Simpan'),
          )
        ],
      ),
    );
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await apiService.fetchProducts();
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching products: $e');
      setState(() {
        _error = 'Gagal memuat produk. Pastikan koneksi internet aktif.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCartCount() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cart = prefs.getStringList('cart') ?? [];
    setState(() {
      cartItemCount = cart.length;
    });
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      _filteredProducts = _products.where((product) => product.name.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  void _sortProducts() {
    setState(() {
      _sortAscending = !_sortAscending;
      _filteredProducts.sort((a, b) => _sortAscending ? a.price.compareTo(b.price) : b.price.compareTo(a.price));
    });
  }

  void addToCart(BuildContext context, Product product) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cartData = prefs.getStringList('cart') ?? [];
    List<Map<String, dynamic>> cartItems = cartData
        .map((item) => json.decode(item) as Map<String, dynamic>)
        .toList();

    // Tambahkan produk ke cart dengan selectedVariant = null
    cartItems.add({
      ...product.toJson(),
      'quantity': 1,
      'selectedVariant': null, // Tidak auto-pilih varian
    });

    List<String> updatedCart =
    cartItems.map((item) => json.encode(item)).toList();
    await prefs.setStringList('cart', updatedCart);

    setState(() => cartItemCount = cartItems.length);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} ditambahkan ke keranjang')),
    );
  }

  void toggleWishlist(Product product) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> wishlist = prefs.getStringList('wishlist') ?? [];

    setState(() {
      if (wishlist.contains(product.id)) {
        wishlist.remove(product.id);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.name} dihapus dari wishlist')));
      } else {
        wishlist.add(product.id);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.name} ditambahkan ke wishlist')));
      }
      _wishlist = wishlist;
    });

    await prefs.setStringList('wishlist', wishlist);
  }

  bool isInWishlist(Product product) => _wishlist.contains(product.id);

  void logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          onThemeToggle: widget.onThemeToggle,
          isDarkMode: widget.isDarkMode,
        ),
      ),
          (route) => false,
    );
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Widget buildProductGrid() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    if (_filteredProducts.isEmpty) return const Center(child: Text('Tidak ada produk yang ditemukan.'));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(hintText: 'Cari produk...', prefixIcon: Icon(Icons.search)),
                  onChanged: _filterProducts,
                ),
              ),
              IconButton(icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward), onPressed: _sortProducts),
              IconButton(
                icon: const Icon(Icons.favorite),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Wishlist'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView(
                        shrinkWrap: true,
                        children: _products
                            .where((product) => _wishlist.contains(product.id))
                            .map((product) => ListTile(
                          title: Text(product.name),
                          subtitle: Text(currencyFormatter.format(product.price)),
                        ))
                            .toList(),
                      ),
                    ),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) {
              final product = _filteredProducts[index];
              final inWishlist = isInWishlist(product);
              return ProductCard(
                product: product,
                isInWishlist: inWishlist,
                onToggleWishlist: () => toggleWishlist(product),
                onAdd: () => addToCart(context, product),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Etalase"),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => widget.onThemeToggle(!widget.isDarkMode),
          ),
        ],
      ),
      body: buildProductGrid(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          if (index == 1) {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
            setState(() => _currentIndex = 0);
            _loadCartCount();
            _loadUserData();
          } else if (index == 2) {
            setState(() => _currentIndex = 2);
            showModalBottomSheet(
              context: context,
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Akun'),
                    subtitle: Text('$_username'),
                    onTap: () {
                      Navigator.pop(context);
                      _showAccountDialog();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Pesanan'),
                    subtitle: Text(_orderHistory.isEmpty ? 'Belum ada pesanan' : '${_orderHistory.length} pesanan'),
                    onTap: () {
                      if (_orderHistory.isNotEmpty) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Riwayat Pesanan'),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _orderHistory.length,
                                itemBuilder: (context, index) {
                                  try {
                                    final order = json.decode(_orderHistory[index]);
                                    return ListTile(
                                      title: Text(order['summary']),
                                      subtitle: Text(
                                          'Waktu: ${order['timestamp']}\nTotal: ${currencyFormatter.format(order['total'])}\nMetode: ${order['paymentMethod'] ?? '-'}\nStatus: ${order['status'] ?? 'Tidak Diketahui'}'),
                                    );
                                  } catch (_) {
                                    return ListTile(title: const Text('Data rusak'), subtitle: Text(_orderHistory[index]));
                                  }
                                },
                              ),
                            ),
                            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Log Out'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Log Out'),
                          content: const Text('Apakah yakin ingin log out?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                logout(context);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Log out'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          } else {
            setState(() => _currentIndex = 0);
          }
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (cartItemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text('$cartItemCount', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                    ),
                  ),
              ],
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}