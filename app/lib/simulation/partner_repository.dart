import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Partner {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String company;
  final String? photoUrl;
  final bool isActive;

  const Partner({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.company,
    this.photoUrl,
    required this.isActive,
  });

  factory Partner.fromJson(Map<String, dynamic> json) {
    return Partner(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      company: json['company'] as String,
      photoUrl: json['photoUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class ShareResult {
  final String shareUrl;
  final Map<String, dynamic> summary;

  const ShareResult({
    required this.shareUrl,
    required this.summary,
  });

  factory ShareResult.fromJson(Map<String, dynamic> json) {
    return ShareResult(
      shareUrl: json['shareUrl'] as String,
      summary: json['summary'] as Map<String, dynamic>? ?? {},
    );
  }
}

class PartnerRepository {
  final http.Client? client;
  final String? _baseUrl;

  const PartnerRepository({
    this.client,
    String? baseUrl,
  }) : _baseUrl = baseUrl;

  String get baseUrl {
    if (_baseUrl != null && _baseUrl!.isNotEmpty) {
      return _baseUrl!;
    }
    if (kDebugMode) {
      // IP xumbado para teste no Mi 9 Lite via Wi-Fi
      return 'http://192.168.0.70:3000';
    }
    return 'https://meu-correspondente.onrender.com';
  }

  Future<List<Partner>> getPartners({required String token}) async {
    final httpClient = client ?? http.Client();
    final url = Uri.parse('$baseUrl/api/partners');

    try {
      final response = await httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => Partner.fromJson(json as Map<String, dynamic>)).toList();
        } else {
          throw Exception('Dados de parceiros inválidos');
        }
      } else {
        throw Exception('Erro ao buscar parceiros (Código ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erro de conexão ao buscar parceiros');
    }
  }

  Future<ShareResult> shareSimulation({required String token, required String simulationId}) async {
    final httpClient = client ?? http.Client();
    final url = Uri.parse('$baseUrl/api/simulations/$simulationId/share');

    try {
      final response = await httpClient.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ShareResult.fromJson(data);
      } else {
        throw Exception('Erro ao compartilhar simulação (Código ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erro de conexão ao compartilhar simulação');
    }
  }
}
