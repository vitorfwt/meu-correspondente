import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SimulationInput {
  final double valorImovel;
  final double valorEntrada;
  final double rendaMensal;
  final String tipoImovel;
  final String estadoCivil;
  final int prazoMeses;
  final DateTime dataNascimento;

  const SimulationInput({
    required this.valorImovel,
    required this.valorEntrada,
    required this.rendaMensal,
    required this.tipoImovel,
    required this.estadoCivil,
    required this.prazoMeses,
    required this.dataNascimento,
  });

  int get idade {
    final hoje = DateTime.now();
    int idade = hoje.year - dataNascimento.year;
    if (hoje.month < dataNascimento.month ||
        (hoje.month == dataNascimento.month && hoje.day < dataNascimento.day)) {
      idade--;
    }
    return idade;
  }
}

class SimulationResult {
  final double valorImovel;
  final double valorEntrada;
  final double valorFinanciado;
  final int prazoMeses;
  final double taxaJurosAnual;
  final double taxaJurosMensal;
  final double parcelaPrice;
  final double primeiraParcelaSac;
  final double ultimaParcelaSac;
  final double totalPagoPrice;
  final double totalPagoSac;
  final double totalJurosPrice;
  final double totalJurosSac;

  const SimulationResult({
    required this.valorImovel,
    required this.valorEntrada,
    required this.valorFinanciado,
    required this.prazoMeses,
    required this.taxaJurosAnual,
    required this.taxaJurosMensal,
    required this.parcelaPrice,
    required this.primeiraParcelaSac,
    required this.ultimaParcelaSac,
    required this.totalPagoPrice,
    required this.totalPagoSac,
    required this.totalJurosPrice,
    required this.totalJurosSac,
  });
}

class BankSimulation {
  final String nomeInstituicao;
  final String? logoUrl;
  final double valorFinanciado;
  final int prazoMeses;
  final double taxaJurosAnual;
  final double taxaJurosMensal;
  final double parcelaPrice;
  final double primeiraParcelaSac;
  final double ultimaParcelaSac;
  final double totalPagoPrice;
  final double totalPagoSac;
  final double totalJurosPrice;
  final double totalJurosSac;
  final List<String> restricoes;

  const BankSimulation({
    required this.nomeInstituicao,
    this.logoUrl,
    required this.valorFinanciado,
    required this.prazoMeses,
    required this.taxaJurosAnual,
    required this.taxaJurosMensal,
    required this.parcelaPrice,
    required this.primeiraParcelaSac,
    required this.ultimaParcelaSac,
    required this.totalPagoPrice,
    required this.totalPagoSac,
    required this.totalJurosPrice,
    required this.totalJurosSac,
    required this.restricoes,
  });

  factory BankSimulation.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    final sacJson = json['sac'];
    final priceJson = json['price'];

    final nomeInstituicaoVal = (json['institutionName'] ?? json['nomeInstituicao'] ?? json['name'] ?? 'Banco') as String;
    final logoUrlVal = (json['logoUrl'] ?? json['logo_url']) as String?;
    final valorFinanciadoVal = toDouble(json['financedAmount'] ?? json['valorFinanciado'] ?? json['financedValue']);
    final prazoMesesVal = (json['term'] ?? json['prazoMeses'] ?? json['termMonths'] ?? json['prazo'] ?? 0) as int;

    double taxaJurosAnualVal = 0.0;
    double taxaJurosMensalVal = 0.0;

    if (sacJson is Map<String, dynamic>) {
      taxaJurosAnualVal = toDouble(sacJson['rateValue']) * 100;
      taxaJurosMensalVal = toDouble(sacJson['monthlyRate']) * 100;
    } else if (priceJson is Map<String, dynamic>) {
      taxaJurosAnualVal = toDouble(priceJson['rateValue']) * 100;
      taxaJurosMensalVal = toDouble(priceJson['monthlyRate']) * 100;
    } else {
      taxaJurosAnualVal = toDouble(json['taxaJurosAnual'] ?? json['annualInterestRate'] ?? json['interestRate'] ?? json['taxaJuros']);
      taxaJurosMensalVal = toDouble(json['taxaJurosMensal'] ?? json['monthlyInterestRate']);
    }

    final parcelaPriceVal = toDouble(priceJson is Map<String, dynamic>
        ? priceJson['firstPayment']
        : (json['parcelaPrice'] ?? json['priceInstallment'] ?? json['prestacionPrice'] ?? json['parcela_price']));

    final primeiraParcelaSacVal = toDouble(sacJson is Map<String, dynamic>
        ? sacJson['firstPayment']
        : (json['primeiraParcelaSac'] ?? json['sacFirstInstallment'] ?? json['primeiraParcela'] ?? json['primeira_parcela_sac']));

    final ultimaParcelaSacVal = toDouble(sacJson is Map<String, dynamic>
        ? sacJson['lastPayment']
        : (json['ultimaParcelaSac'] ?? json['sacLastInstallment'] ?? json['ultimaParcela'] ?? json['ultima_parcela_sac']));

    final totalPagoPriceVal = toDouble(priceJson is Map<String, dynamic>
        ? priceJson['totalCost']
        : (json['totalPagoPrice'] ?? json['priceTotalPaid'] ?? json['totalPaidPrice'] ?? json['total_pago_price']));

    final totalPagoSacVal = toDouble(sacJson is Map<String, dynamic>
        ? sacJson['totalCost']
        : (json['totalPagoSac'] ?? json['sacTotalPaid'] ?? json['totalPaidSac'] ?? json['total_pago_sac']));

    final totalJurosPriceVal = totalPagoPriceVal > 0
        ? (totalPagoPriceVal - valorFinanciadoVal)
        : toDouble(json['totalJurosPrice'] ?? json['priceTotalInterest'] ?? json['totalJurosPrice'] ?? json['total_juros_price']);

    final totalJurosSacVal = totalPagoSacVal > 0
        ? (totalPagoSacVal - valorFinanciadoVal)
        : toDouble(json['totalJurosSac'] ?? json['sacTotalInterest'] ?? json['totalJurosSac'] ?? json['total_juros_sac']);

    // Merge warnings/restricoes
    final Set<String> allRestrictions = {};

    // Root warnings
    final rawRestrictions = json['restricoes'] ?? json['restrictions'] ?? json['alerts'] ?? json['warnings'];
    if (rawRestrictions is List) {
      for (var e in rawRestrictions) {
        if (e != null) allRestrictions.add(e.toString());
      }
    }

    // SAC warnings
    if (sacJson is Map<String, dynamic>) {
      final sacWarnings = sacJson['warnings'];
      if (sacWarnings is List) {
        for (var e in sacWarnings) {
          if (e != null) allRestrictions.add(e.toString());
        }
      }
    }

    // PRICE warnings
    if (priceJson is Map<String, dynamic>) {
      final priceWarnings = priceJson['warnings'];
      if (priceWarnings is List) {
        for (var e in priceWarnings) {
          if (e != null) allRestrictions.add(e.toString());
        }
      }
    }

    return BankSimulation(
      nomeInstituicao: nomeInstituicaoVal,
      logoUrl: logoUrlVal,
      valorFinanciado: valorFinanciadoVal,
      prazoMeses: prazoMesesVal,
      taxaJurosAnual: taxaJurosAnualVal,
      taxaJurosMensal: taxaJurosMensalVal,
      parcelaPrice: parcelaPriceVal,
      primeiraParcelaSac: primeiraParcelaSacVal,
      ultimaParcelaSac: ultimaParcelaSacVal,
      totalPagoPrice: totalPagoPriceVal,
      totalPagoSac: totalPagoSacVal,
      totalJurosPrice: totalJurosPriceVal,
      totalJurosSac: totalJurosSacVal,
      restricoes: allRestrictions.toList(),
    );
  }
}

class SimulationRepository {
  final http.Client? client;
  final String? _baseUrl;

  const SimulationRepository({
    this.client,
    String? baseUrl,
  }) : _baseUrl = baseUrl;

  String get baseUrl {
    if (_baseUrl != null && _baseUrl!.isNotEmpty) {
      return _baseUrl!;
    }
    if (kDebugMode) {
      if (!kIsWeb && Platform.isAndroid) {
        return 'http://10.0.2.2:3000';
      }
      return 'http://localhost:3000';
    }
    return 'https://meu-correspondente.onrender.com';
  }

  Future<List<BankSimulation>> calculateSimulation(SimulationInput input, {String? token}) async {
    final httpClient = client ?? http.Client();
    final url = Uri.parse('$baseUrl/api/simulate');

    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final body = jsonEncode({
      'propertyValue': input.valorImovel,
      'downPayment': input.valorEntrada,
      'monthlyIncome': input.rendaMensal,
      'age': input.idade,
      'term': input.prazoMeses,
    });

    try {
      final response = await httpClient.post(url, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => BankSimulation.fromJson(json as Map<String, dynamic>)).toList();
        } else {
          throw Exception('Dados de retorno da simulação inválidos');
        }
      } else {
        throw Exception('Erro na simulação do servidor (Código ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erro de conexão com o servidor de simulação');
    }
  }
}
