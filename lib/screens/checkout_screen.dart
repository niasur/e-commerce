import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> selectedItems;
  final double total;
  final VoidCallback onPaymentSuccess;

  const CheckoutPage({
    super.key,
    required this.selectedItems,
    required this.total,
    required this.onPaymentSuccess,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late List<Map<String, dynamic>> _checkoutItems;
  String? _username, _fullName, _address;
  String _shippingMethod = 'Reguler';
  String _paymentMethod = 'Cash';

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final List<Map<String, dynamic>> paymentMethods = [
    {'label': 'Cash (COD)', 'value': 'Cash', 'icon': Icons.money},
    {'label': 'Transfer Bank', 'value': 'Transfer', 'icon': Icons.account_balance},
    {'label': 'E-Wallet', 'value': 'Ewallet', 'icon': Icons.account_balance_wallet},
    {'label': 'Kartu Kredit', 'value': 'Credit', 'icon': Icons.credit_card},
  ];

  @override
  void initState() {
    super.initState();
    _checkoutItems = widget.selectedItems;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'User';
      _fullName = prefs.getString('fullName') ?? '-';
      _address = prefs.getString('address') ?? '-';
    });
  }

  double get _totalPrice {
    return _checkoutItems.fold(0.0, (total, item) {
      final price = (item['price'] as num).toDouble();
      final qty = item['quantity'] ?? 1;
      return total + (price * qty);
    });
  }

  Future<void> _payNow() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final time =
        '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}';

    final summary = _checkoutItems
        .map((item) =>
    '${item['name']}'
        ' x${item['quantity'] ?? 1}'
        '${item['selectedVariant'] != null ? ' | Varian: ${item['selectedVariant']}' : ''}')
        .join(', ');

    final order = json.encode({
      'timestamp': time,
      'username': _username,
      'summary': summary,
      'total': _totalPrice,
      'paymentMethod': _paymentMethod,
      'shippingMethod': _shippingMethod,
      'status': 'Sukses',
    });

    final history = prefs.getStringList('orderHistory') ?? [];
    history.add(order);
    await prefs.setStringList('orderHistory', history);

    widget.onPaymentSuccess();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/success.json',
              width: 150,
              repeat: false, // ⬅️ penting! agar tidak ngulang terus
            ),
            const SizedBox(height: 16),
            const Text(
              'Pembayaran Berhasil!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Metode: $_paymentMethod',
                style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );

// Tambahkan ini setelah showDialog agar tidak men-trigger 2x
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return; // ⬅️ Pastikan context masih aman digunakan

    await Future.delayed(const Duration(seconds: 3));
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _selectPaymentMethod() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: paymentMethods.map((method) {
            return ListTile(
              leading: Icon(method['icon']),
              title: Text(method['label']),
              onTap: () => Navigator.pop(context, method['value']),
            );
          }).toList(),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _paymentMethod = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedMethod = paymentMethods.firstWhere(
          (method) => method['value'] == _paymentMethod,
      orElse: () => paymentMethods.first,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('👤 Username: $_username'),
            Text('🧾 Nama Lengkap: $_fullName'),
            const SizedBox(height: 8),
            Text('📦 Alamat:\n$_address'),
            const SizedBox(height: 20),

            // PILIHAN METODE PENGIRIMAN
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Metode Pengiriman',
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _shippingMethod,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                        value: 'Reguler', child: Text('Reguler (2-4 hari)')),
                    DropdownMenuItem(
                        value: 'Express', child: Text('Express (1-2 hari)')),
                    DropdownMenuItem(
                        value: 'Same Day', child: Text('Same Day (hari ini)')),
                  ],
                  onChanged: (val) =>
                      setState(() => _shippingMethod = val!),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // PILIHAN METODE PEMBAYARAN
            GestureDetector(
              onTap: _selectPaymentMethod,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Metode Pembayaran',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  children: [
                    Icon(selectedMethod['icon']),
                    const SizedBox(width: 8),
                    Text(selectedMethod['label']),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const Text(
              '🛒 Rincian Pesanan:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ..._checkoutItems.map(
                  (item) => ListTile(
                title: Text(
                  '${item['name']}${item['selectedVariant'] != null ? ' | Varian: ${item['selectedVariant']}' : ''}',
                ),
                subtitle: Text(
                  '${_currencyFormat.format(item['price'])}, × ${item['quantity']}',
                ),
              ),
            ),
            const Divider(),
            Text(
              'Total: ${_currencyFormat.format(_totalPrice)}',
              style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _payNow,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Bayar Sekarang'),
            ),
          ],
        ),
      ),
    );
  }
}