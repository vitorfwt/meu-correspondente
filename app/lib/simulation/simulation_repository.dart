import 'dart:math';

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

class SimulationRepository {
  const SimulationRepository();

  Future<SimulationResult> calculateSimulation(SimulationInput input) async {
    // Simular atraso de rede
    await Future.delayed(const Duration(milliseconds: 600));

    final valorFinanciado = input.valorImovel - input.valorEntrada;
    
    // Taxa de juros anual mockada (ex: 10.5%)
    const taxaJurosAnual = 10.5;
    // Conversão para taxa mensal: (1 + taxaAnual)^(1/12) - 1
    final taxaJurosMensal = pow(1 + (taxaJurosAnual / 100), 1 / 12) - 1;

    final n = input.prazoMeses;
    final i = taxaJurosMensal;

    // --- Cálculo PRICE ---
    // PMT = PV * (i * (1 + i)^n) / ((1 + i)^n - 1)
    double parcelaPrice = 0.0;
    if (i > 0) {
      parcelaPrice = valorFinanciado * (i * pow(1 + i, n)) / (pow(1 + i, n) - 1);
    } else {
      parcelaPrice = valorFinanciado / n;
    }

    final totalPagoPrice = parcelaPrice * n;
    final totalJurosPrice = totalPagoPrice - valorFinanciado;

    // --- Cálculo SAC ---
    // Amortização constante A = PV / n
    final amortizacaoSac = valorFinanciado / n;
    
    // Primeira Parcela = A + PV * i
    final primeiraParcelaSac = amortizacaoSac + (valorFinanciado * i);
    
    // Última Parcela = A + (PV - (n-1)*A) * i = A + A * i
    final ultimaParcelaSac = amortizacaoSac + (amortizacaoSac * i);

    // Total pago SAC: Somatório das parcelas
    // P_k = A + (PV - (k-1)*A) * i
    // Total = n * A + i * [ PV * n - A * n * (n-1) / 2 ]
    // Como A = PV/n, Total = PV + i * PV * (n + 1) / 2
    final totalJurosSac = i * valorFinanciado * (n + 1) / 2;
    final totalPagoSac = valorFinanciado + totalJurosSac;

    return SimulationResult(
      valorImovel: input.valorImovel,
      valorEntrada: input.valorEntrada,
      valorFinanciado: valorFinanciado,
      prazoMeses: n,
      taxaJurosAnual: taxaJurosAnual,
      taxaJurosMensal: i * 100, // em percentual
      parcelaPrice: parcelaPrice,
      primeiraParcelaSac: primeiraParcelaSac,
      ultimaParcelaSac: ultimaParcelaSac,
      totalPagoPrice: totalPagoPrice,
      totalPagoSac: totalPagoSac,
      totalJurosPrice: totalJurosPrice,
      totalJurosSac: totalJurosSac,
    );
  }
}
