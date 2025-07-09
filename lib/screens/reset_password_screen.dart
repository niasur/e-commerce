import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final FocusNode passwordFocus = FocusNode();
  bool isLoading = false;

  Future<void> resetPassword() async {
    final username = usernameCtrl.text.trim();
    final newPassword = passwordCtrl.text.trim();

    if (username.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username and new password are required")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 🔄 Ganti endpoint ke /users
      final url = Uri.parse('http://localhost:3000/users');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List users = json.decode(response.body);
        final user = users.firstWhere(
              (u) => u['username'] == username,
          orElse: () => null,
        );

        if (user != null) {
          final int userId = user['id'];
          final updateUrl = Uri.parse('http://localhost:3000/users/$userId');

          final updatedUser = {
            'id': userId,
            'username': user['username'],
            'fullName': user['fullName'],
            'password': newPassword,
          };

          final updateResponse = await http.put(
            updateUrl,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(updatedUser),
          );

          if (updateResponse.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Password updated successfully")),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to update password: ${updateResponse.statusCode}")),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Username not found")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unexpected error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                TextField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(labelText: "Username"),
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(passwordFocus),
                ),
                TextField(
                  controller: passwordCtrl,
                  focusNode: passwordFocus,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "New Password"),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => resetPassword(),
                ),
                const SizedBox(height: 20),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: resetPassword,
                  child: const Text("Reset Password"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}