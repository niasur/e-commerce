import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:lottie/lottie.dart';

import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../models/user.dart' as local;

import 'home_screen.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final Function(bool) onThemeToggle;
  final bool isDarkMode;

  const LoginScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController userCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  // Ganti mode di sini: 'firebase' atau 'api'
  final AuthService _auth = AuthService(mode: 'firebase');
  bool _obscurePassword = true;

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void login() async {
    final username = userCtrl.text.trim();
    final password = passCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackbar('Username dan Password tidak boleh kosong');
      return;
    }

    final user = await _auth.login(username, password);

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('loggedIn', true);

      if (user is fb.User) {
        // Jika login via Firebase
        prefs.setString('username', user.email ?? '');
      } else if (user is local.User) {
        // Jika login via API lokal
        prefs.setString('username', user.username);
      }

      prefs.setStringList('orderHistory', []);

      final productService = ProductService();
      try {
        final products = await productService.fetchProducts();
        final productJson = json.encode(products.map((e) => e.toJson()).toList());
        prefs.setString('products', productJson);
      } catch (e) {
        debugPrint("Gagal menyimpan produk ke cache: $e");
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            onThemeToggle: widget.onThemeToggle,
            isDarkMode: widget.isDarkMode,
          ),
        ),
      );
    } else {
      _showSnackbar('Login gagal. Cek username/email dan password.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final greyStyle = TextStyle(color: Colors.grey[600]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log In'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: () => widget.onThemeToggle(!widget.isDarkMode),
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 200,
                  child: Lottie.asset('assets/logo.json'),
                ),
                const SizedBox(height: 35),

                TextField(
                  controller: userCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline),
                    hintText: _auth.mode == 'firebase' ? 'Email' : 'Username',
                    hintStyle: greyStyle,
                    border: const UnderlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
                ),
                const SizedBox(height: 30),
                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    TextField(
                      controller: passCtrl,
                      focusNode: _passwordFocus,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        hintText: 'Password',
                        hintStyle: greyStyle,
                        border: const UnderlineInputBorder(),
                      ),
                      onSubmitted: (_) => login(),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Text(
                              'Lupa?',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Login'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RegisterScreen(
                            isDarkMode: widget.isDarkMode,
                            onThemeToggle: widget.onThemeToggle,
                          ),
                        ),
                      );
                    },
                    child: const Text("Don't have an account? Sign Up"),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}