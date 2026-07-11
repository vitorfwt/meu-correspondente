import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MacroeconomicIndicator {
  final String id;
  final String name;
  final double value;
  final DateTime updatedAt;

  const MacroeconomicIndicator({
    required this.id,
    required this.name,
    required this.value,
    required this.updatedAt,
  });

  factory MacroeconomicIndicator.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return MacroeconomicIndicator(
      id: json['id'] as String,
      name: json['name'] as String,
      value: toDouble(json['value']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}

class IndicatorRepository {
  final http.Client? client;
  final String? _baseUrl;

  const IndicatorRepository({
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

  Future<List<MacroeconomicIndicator>> getIndicators({required String token}) async {
    final httpClient = client ?? http.Client();
    final url = Uri.parse('$baseUrl/api/indicators');

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
          return data.map((json) => MacroeconomicIndicator.fromJson(json as Map<String, dynamic>)).toList();
        } else {
          throw Exception('Dados de indicadores macroeconômicos inválidos');
        }
      } else {
        throw Exception('Erro ao buscar indicadores (Código ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erro de conexão ao buscar indicadores macroeconômicos');
    }
  }
}
