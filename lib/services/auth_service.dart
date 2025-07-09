import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user.dart';

class AuthService {
  final String mode; // 'firebase' atau 'api'
  final String baseUrl = 'http://localhost:3000';
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;

  AuthService({this.mode = 'firebase'});

  /// Login (Firebase atau API)
  Future<dynamic> login(String emailOrUsername, String password) async {
    if (mode == 'firebase') {
      return _firebaseLogin(emailOrUsername, password);
    } else {
      return _apiLogin(emailOrUsername, password);
    }
  }

  /// Firebase login
  Future<fb.User?> _firebaseLogin(String email, String password) async {
    try {
      final result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      if (user != null) {
        print('Firebase login berhasil: ${user.email}, UID: ${user.uid}');
      }
      return user;
    } catch (e) {
      print('Firebase login error: $e');
      return null;
    }
  }

  /// API login
  Future<User?> _apiLogin(String username, String password) async {
    try {
      final url = Uri.parse('$baseUrl/users?username=$username');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final userData = data[0];
          if (userData['password'] == password) {
            final user = User.fromJson(userData);
            print('API login berhasil: username=${user.username}, id=${user.id}');
            return user;
          } else {
            print('Password tidak cocok untuk user: $username');
          }
        } else {
          print('Username tidak ditemukan: $username');
        }
      } else {
        print('Gagal mengakses API: ${response.statusCode}');
      }
    } catch (e) {
      print('API login error: $e');
    }

    return null;
  }

  /// Register (hanya Firebase)
  Future<fb.User?> register(String email, String password) async {
    if (mode != 'firebase') {
      throw UnsupportedError('Register hanya didukung dalam mode Firebase');
    }

    try {
      final result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      print('Firebase register berhasil: ${user?.email}');
      return user;
    } catch (e) {
      print('Firebase register error: $e');
      return null;
    }
  }

  /// Logout (hanya Firebase)
  Future<void> logout() async {
    if (mode == 'firebase') {
      final email = _firebaseAuth.currentUser?.email;
      await _firebaseAuth.signOut();
      print('Firebase logout: $email');
    } else {
      print('Logout dipanggil dalam mode API (tidak ada proses signOut)');
    }
  }

  /// Get current Firebase user
  fb.User? get currentUser => _firebaseAuth.currentUser;
}