class User {
  final String id;
  final String username;
  final String password;
  final String fullName;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.fullName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      username: json['username'],
      password: json['password'],
      fullName: json['fullName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'fullName': fullName,
    };
  }
}