class User {
  final String id;
  final String name;
  final String email;

  const User({
    required this.id,
    required this.name,
    required this.email,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
      };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}

class AuthRepository {
  const AuthRepository();

  Future<(User, String)> loginWithGoogle() async {
    await Future.delayed(const Duration(seconds: 2));
    final user = User(
      id: 'google_123',
      name: 'João Silva',
      email: 'joao.silva@example.com',
    );
    const token = 'fake_jwt_token_google_12345';
    return (user, token);
  }

  Future<(User, String)> loginWithApple() async {
    await Future.delayed(const Duration(seconds: 2));
    final user = User(
      id: 'apple_123',
      name: 'João Silva',
      email: 'joao.silva@example.com',
    );
    const token = 'fake_jwt_token_apple_12345';
    return (user, token);
  }
}
