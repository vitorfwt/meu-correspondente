import 'package:flutter/material.dart';
import '../design_system/colors.dart';
import '../components/buttons/primary_button.dart';
import '../components/buttons/secondary_button.dart';
import '../simulation/simulation_repository.dart';
import '../auth/auth_provider.dart';

class SimulationResultScreen extends StatefulWidget {
  final SimulationInput input;
  final SimulationRepository repository;

  const SimulationResultScreen({
    super.key,
    required this.input,
    this.repository = const SimulationRepository(),
  });

  @override
  State<SimulationResultScreen> createState() => _SimulationResultScreenState();
}

class _SimulationResultScreenState extends State<SimulationResultScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<BankSimulation> _simulations = [];

  @override
  void initState() {
    super.initState();
    _fetchSimulations();
  }

  Future<void> _fetchSimulations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Obter o token JWT se o usuário estiver logado
      String? token;
      try {
        final auth = AuthProviderScope.of(context);
        token = auth.token;
      } catch (_) {
        // Ignora caso não tenha AuthProviderScope (ex: testes de widget isolados)
      }

      final results = await widget.repository.calculateSimulation(
        widget.input,
        token: token,
      );

      setState(() {
        _simulations = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double value) {
    final stringValue = value.toStringAsFixed(2);
    final parts = stringValue.split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    final buffer = StringBuffer();
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(integerPart[i]);
      count++;
    }
    final reversedInteger = buffer.toString().split('').reversed.join('');
    return 'R\$ $reversedInteger,$decimalPart';
  }

  @override
  Widget build(BuildContext context) {
    final valorFinanciado = widget.input.valorImovel - widget.input.valorEntrada;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Resultado da Simulação',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: _buildBody(valorFinanciado),
      ),
    );
  }

  Widget _buildBody(double valorFinanciado) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Simulando propostas...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary.withOpacity(0.8),
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                'Falha na conexão com o servidor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Erro desconhecido ao simular propostas.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondary.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                key: const Key('retry_button'),
                text: 'Tentar novamente',
                icon: Icons.refresh,
                onPressed: _fetchSimulations,
              ),
            ],
          ),
        ),
      );
    }

    // Encontrar o melhor banco (sem restrições e com menor taxa ou menor custo total)
    BankSimulation? bestSimulation;
    final validSims = _simulations.where((s) => s.restricoes.isEmpty).toList();
    final invalidSims = _simulations.where((s) => s.restricoes.isNotEmpty).toList();

    // Ordenar válidas pelo menor custo total no SAC
    validSims.sort((a, b) => a.totalPagoSac.compareTo(b.totalPagoSac));
    if (validSims.isNotEmpty) {
      bestSimulation = validSims.first;
    }

    final sortedSimulations = [...validSims, ...invalidSims];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumo do Financiamento',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Valor Financiado:',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    Text(
                      _formatCurrency(valorFinanciado),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Valor do Imóvel:',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      _formatCurrency(widget.input.valorImovel),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Valor da Entrada:',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      _formatCurrency(widget.input.valorEntrada),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prazo',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.input.prazoMeses} meses',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Idade do Proponente',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.input.idade} anos',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            'Propostas Disponíveis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Compare as opções de financiamento em amortização constante (SAC) e francesa (PRICE).',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.secondary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),

          // List of Banks
          if (sortedSimulations.isEmpty)
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.lightGrey),
              ),
              child: const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'Nenhum banco disponível para simulação com as condições informadas.',
                    style: TextStyle(color: AppColors.secondary),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            ...sortedSimulations.map((simulation) {
              final isBest = bestSimulation != null &&
                  simulation.nomeInstituicao == bestSimulation.nomeInstituicao &&
                  simulation.restricoes.isEmpty;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: BankSimulationCard(
                  simulation: simulation,
                  isBestOption: isBest,
                  formatCurrency: _formatCurrency,
                ),
              );
            }),

          const SizedBox(height: 20),

          // Voltar Button
          SecondaryButton(
            key: const Key('result_back_button'),
            text: 'Nova Simulação',
            icon: Icons.replay,
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class BankSimulationCard extends StatelessWidget {
  final BankSimulation simulation;
  final bool isBestOption;
  final String Function(double) formatCurrency;

  const BankSimulationCard({
    super.key,
    required this.simulation,
    required this.isBestOption,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final hasRestrictions = simulation.restricoes.isNotEmpty;
    final cardColor = hasRestrictions ? Colors.white.withOpacity(0.9) : Colors.white;
    final borderColor = hasRestrictions
        ? Colors.orange.shade800
        : (isBestOption ? Colors.green.shade600 : AppColors.lightGrey);
    final borderThickness = hasRestrictions || isBestOption ? 2.0 : 1.0;

    Widget cardBody = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header of the bank card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        simulation.nomeInstituicao,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (isBestOption)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade600, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.green.shade600, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Melhor Opção',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Rates display
          Row(
            children: [
              Text(
                'Taxa de Juros: ',
                style: TextStyle(fontSize: 13, color: AppColors.secondary.withOpacity(0.8)),
              ),
              Text(
                '${simulation.taxaJurosAnual.toStringAsFixed(2)}% a.a.',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Mensal: ',
                style: TextStyle(fontSize: 13, color: AppColors.secondary.withOpacity(0.8)),
              ),
              Text(
                '${simulation.taxaJurosMensal.toStringAsFixed(2)}% a.m.',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Comparison of SAC and PRICE
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SAC Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SAC',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Decrescente',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1ª: ${formatCurrency(simulation.primeiraParcelaSac)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Última: ${formatCurrency(simulation.ultimaParcelaSac)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Pago: ${formatCurrency(simulation.totalPagoSac)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Divider column
              Container(
                height: 75,
                width: 1,
                color: AppColors.lightGrey,
              ),
              const SizedBox(width: 12),
              // PRICE Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PRICE',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Parcela Fixa',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Parcela: ${formatCurrency(simulation.parcelaPrice)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Última: Mesmo valor',
                      style: TextStyle(fontSize: 12, color: AppColors.secondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Pago: ${formatCurrency(simulation.totalPagoPrice)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Display restrictions if present
          if (hasRestrictions) ...[
            const Divider(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: simulation.restricoes.map((restriction) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade800.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            restriction,
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );

    if (hasRestrictions) {
      cardBody = Opacity(
        opacity: 0.45,
        child: cardBody,
      );
    }

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: borderColor,
          width: borderThickness,
        ),
      ),
      child: cardBody,
    );
  }
}
