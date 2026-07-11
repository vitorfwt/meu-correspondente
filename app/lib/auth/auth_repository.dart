import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'client' or 'broker'
  final String? creci;
  final String? uf;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.creci,
    this.uf,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'creci': creci,
        'uf': uf,
      };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'client',
      creci: json['creci'] as String?,
      uf: (json['uf'] ?? json['creciState']) as String?,
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? creci,
    String? uf,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      creci: creci ?? this.creci,
      uf: uf ?? this.uf,
    );
  }
}

class AuthRepository {
  final http.Client? client;
  final String? _baseUrl;

  const AuthRepository({
    this.client,
    String? baseUrl,
  }) : _baseUrl = baseUrl;

  String get baseUrl {
    if (_baseUrl != null && _baseUrl!.isNotEmpty) {
      return _baseUrl!;
    }
    if (kDebugMode) {
      // IP xumbado para teste no Mi 9 Lite via Wi-Fi (192.168.0.70)
      return 'http://192.168.0.70:3000';
    }
    return 'https://meu-correspondente.onrender.com';
  }

  Future<(User, String)> loginWithGoogle() async {
    final url = Uri.parse('$baseUrl/api/auth/social-login');
    try {
      final response = await (client ?? http.Client()).post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': 'google',
          'idToken': 'mock-joao-silva',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user'] as Map<String, dynamic>);
        final token = data['token'] as String;
        return (user, token);
      } else {
        throw Exception('Erro ao realizar login no servidor (Código ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('loginWithGoogle error: $e');
      rethrow;
    }
  }

  Future<(User, String)> loginWithApple() async {
    final url = Uri.parse('$baseUrl/api/auth/social-login');
    try {
      final response = await (client ?? http.Client()).post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': 'apple',
          'idToken': 'mock-joao-corretor',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user'] as Map<String, dynamic>);
        final token = data['token'] as String;
        return (user, token);
      } else {
        throw Exception('Erro ao realizar login no servidor (Código ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('loginWithApple error: $e');
      rethrow;
    }
  }

  Future<User> updateProfile(String token, String creci, String uf) async {
    final url = Uri.parse('$baseUrl/api/profile');
    try {
      final response = await (client ?? http.Client()).put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'creci': creci,
          'creciState': uf,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final userJson = data['user'] as Map<String, dynamic>;
        return User.fromJson(userJson);
      } else {
        throw Exception('Erro ao atualizar perfil no servidor (Código ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('updateProfile error, falling back to mock: $e');
      return User(
        id: 'apple_123',
        name: 'João Silva',
        email: 'joao.silva@example.com',
        role: 'broker',
        creci: creci,
        uf: uf,
      );
    }
  }
}
