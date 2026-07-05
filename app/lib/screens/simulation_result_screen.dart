import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      String? token;
      try {
        final auth = AuthProviderScope.of(context);
        token = auth.token;
      } catch (_) {}

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
      if (count > 0 && count % 3 == 0) buffer.write('.');
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
        systemOverlayStyle: SystemUiOverlayStyle.dark,
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
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Buscando as melhores propostas...',
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 56,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Falha na conexão',
                style: TextStyle(
                  fontSize: 20,
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
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                key: const Key('retry_button'),
                text: 'Tentar novamente',
                icon: Icons.refresh_rounded,
                onPressed: _fetchSimulations,
              ),
            ],
          ),
        ),
      );
    }

    // Sort simulations
    BankSimulation? bestSimulation;
    final validSims =
        _simulations.where((s) => s.restricoes.isEmpty).toList();
    final invalidSims =
        _simulations.where((s) => s.restricoes.isNotEmpty).toList();

    validSims.sort((a, b) => a.totalPagoSac.compareTo(b.totalPagoSac));
    if (validSims.isNotEmpty) bestSimulation = validSims.first;

    final sortedSimulations = [...validSims, ...invalidSims];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary Card ────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RESUMO DO FINANCIAMENTO',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Valor Financiado',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatCurrency(valorFinanciado),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildSummaryChip(
                      icon: Icons.home_outlined,
                      label: 'Imóvel',
                      value: _formatCurrency(widget.input.valorImovel),
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryChip(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Entrada',
                      value: _formatCurrency(widget.input.valorEntrada),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildSummaryChip(
                      icon: Icons.calendar_month_outlined,
                      label: 'Prazo',
                      value: '${widget.input.prazoMeses} meses',
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryChip(
                      icon: Icons.person_outline,
                      label: 'Idade',
                      value: '${widget.input.idade} anos',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Section Title ───────────────────────────────────────────────────
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
            'Comparativo entre amortização SAC e PRICE.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.secondary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),

          // ── Bank Cards ──────────────────────────────────────────────────────
          if (sortedSimulations.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 48, color: AppColors.secondary.withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhum banco disponível para as condições informadas.',
                      style: TextStyle(
                          color: AppColors.secondary.withOpacity(0.7),
                          fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...sortedSimulations.map((simulation) {
              final isBest = bestSimulation != null &&
                  simulation.nomeInstituicao ==
                      bestSimulation.nomeInstituicao &&
                  simulation.restricoes.isEmpty;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: BankSimulationCard(
                  simulation: simulation,
                  isBestOption: isBest,
                  formatCurrency: _formatCurrency,
                  valorEntrada: widget.input.valorEntrada,
                ),
              );
            }),

          const SizedBox(height: 8),

          // ── CTA Button ──────────────────────────────────────────────────────
          PrimaryButton(
            key: const Key('result_back_button'),
            text: 'Nova Simulação',
            icon: Icons.replay_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── BankSimulationCard ───────────────────────────────────────────────────────

class BankSimulationCard extends StatelessWidget {
  final BankSimulation simulation;
  final bool isBestOption;
  final String Function(double) formatCurrency;
  final double valorEntrada;

  const BankSimulationCard({
    super.key,
    required this.simulation,
    required this.isBestOption,
    required this.formatCurrency,
    required this.valorEntrada,
  });

  double get _cetAnual => simulation.taxaJurosAnual + 0.3;
  double get _cetMensal => (simulation.taxaJurosMensal + 0.025);

  Widget _buildBestOptionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Color(0xFF22C55E), size: 13),
          SizedBox(width: 4),
          Text(
            'Melhor Opção',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF22C55E),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasRestrictions = simulation.restricoes.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 460;

        Widget card = Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isBestOption
                    ? const Color(0xFF22C55E).withOpacity(0.12)
                    : Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: isBestOption
                ? Border.all(
                    color: const Color(0xFF22C55E).withOpacity(0.4), width: 1.5)
                : null,
          ),
          child: Column(
            children: [
              // ── Card Header ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo placeholder
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
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
                              if (isBestOption && !isMobile)
                                _buildBestOptionBadge(),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Taxa: ${simulation.taxaJurosAnual.toStringAsFixed(2)}% a.a. · '
                            '${simulation.taxaJurosMensal.toStringAsFixed(2)}% a.m.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondary.withOpacity(0.7),
                            ),
                          ),
                          if (isBestOption && isMobile) ...[
                            const SizedBox(height: 6),
                            _buildBestOptionBadge(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── CET + Entrada ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: isMobile
                    ? Column(
                        children: [
                          _buildInfoChip(
                            label: 'CET Estimado',
                            value:
                                '${_cetAnual.toStringAsFixed(2)}% a.a. · ${_cetMensal.toStringAsFixed(2)}% a.m.',
                            icon: Icons.percent_rounded,
                            color: const Color(0xFF6366F1),
                            isMobile: true,
                          ),
                          const SizedBox(height: 10),
                          _buildInfoChip(
                            label: 'Valor de Entrada',
                            value: formatCurrency(valorEntrada),
                            icon: Icons.account_balance_wallet_outlined,
                            color: AppColors.accent,
                            isMobile: true,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          _buildInfoChip(
                            label: 'CET Estimado',
                            value:
                                '${_cetAnual.toStringAsFixed(2)}% a.a. · ${_cetMensal.toStringAsFixed(2)}% a.m.',
                            icon: Icons.percent_rounded,
                            color: const Color(0xFF6366F1),
                            isMobile: false,
                          ),
                          const SizedBox(width: 10),
                          _buildInfoChip(
                            label: 'Valor de Entrada',
                            value: formatCurrency(valorEntrada),
                            icon: Icons.account_balance_wallet_outlined,
                            color: AppColors.accent,
                            isMobile: false,
                          ),
                        ],
                      ),
              ),

              // ── SAC / PRICE Comparison ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: isMobile
                    ? Column(
                        children: [
                          _buildAmortizationColumn(
                            label: 'SAC',
                            tag: 'Parcelas Decrescentes',
                            tagColor: AppColors.accent,
                            rows: [
                              ('1ª Parcela', formatCurrency(simulation.primeiraParcelaSac)),
                              ('Última Parcela', formatCurrency(simulation.ultimaParcelaSac)),
                              ('Total Pago', formatCurrency(simulation.totalPagoSac)),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: AppColors.lightGrey, height: 1),
                          ),
                          _buildAmortizationColumn(
                            label: 'PRICE',
                            tag: 'Parcela Fixa',
                            tagColor: const Color(0xFF8B5CF6),
                            rows: [
                              ('Parcela', formatCurrency(simulation.parcelaPrice)),
                              ('Última Parcela', formatCurrency(simulation.parcelaPrice)),
                              ('Total Pago', formatCurrency(simulation.totalPagoPrice)),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildAmortizationColumn(
                              label: 'SAC',
                              tag: 'Parcelas Decrescentes',
                              tagColor: AppColors.accent,
                              rows: [
                                ('1ª Parcela', formatCurrency(simulation.primeiraParcelaSac)),
                                ('Última Parcela', formatCurrency(simulation.ultimaParcelaSac)),
                                ('Total Pago', formatCurrency(simulation.totalPagoSac)),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 110,
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            color: AppColors.lightGrey,
                          ),
                          Expanded(
                            child: _buildAmortizationColumn(
                              label: 'PRICE',
                              tag: 'Parcela Fixa',
                              tagColor: const Color(0xFF8B5CF6),
                              rows: [
                                ('Parcela', formatCurrency(simulation.parcelaPrice)),
                                ('Última Parcela', formatCurrency(simulation.parcelaPrice)),
                                ('Total Pago', formatCurrency(simulation.totalPagoPrice)),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),

              // ── Restrictions ─────────────────────────────────────────────────────
              if (hasRestrictions) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Column(
                    children: simulation.restricoes.map((r) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFEF4444),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  r,
                                  style: const TextStyle(
                                    color: Color(0xFFEF4444),
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
                ),
              ],

              // ── "Ver Detalhes" Footer Button ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: SecondaryButton(
                  key: Key('ver_detalhes_${simulation.nomeInstituicao.replaceAll(' ', '_')}'),
                  text: 'Ver Detalhes',
                  icon: Icons.open_in_new_rounded,
                  onPressed: () => _showDetailsSheet(context),
                ),
              ),
            ],
          ),
        );

        if (hasRestrictions) {
          card = Opacity(opacity: 0.5, child: card);
        }

        return card;
      },
    );
  }

  Widget _buildAmortizationColumn({
    required String label,
    required String tag,
    required Color tagColor,
    required List<(String, String)> rows,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: tagColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: tagColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...rows.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      r.$1,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary.withOpacity(0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      r.$2,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildInfoChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isMobile,
  }) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.9),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (isMobile) {
      return SizedBox(
        width: double.infinity,
        child: child,
      );
    }
    return Expanded(child: child);
  }

  void _showDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BankDetailsSheet(
        simulation: simulation,
        valorEntrada: valorEntrada,
        formatCurrency: formatCurrency,
        cetAnual: _cetAnual,
        cetMensal: _cetMensal,
      ),
    );
  }
}

// ─── Bottom Sheet: Detalhes do Banco ─────────────────────────────────────────

class _BankDetailsSheet extends StatelessWidget {
  final BankSimulation simulation;
  final double valorEntrada;
  final String Function(double) formatCurrency;
  final double cetAnual;
  final double cetMensal;

  const _BankDetailsSheet({
    required this.simulation,
    required this.valorEntrada,
    required this.formatCurrency,
    required this.cetAnual,
    required this.cetMensal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.account_balance_rounded,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        simulation.nomeInstituicao,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Detalhes da Proposta',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.secondary.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Details table
            _buildSection('Taxas e Custos', [
              ('Taxa de Juros Anual',
                  '${simulation.taxaJurosAnual.toStringAsFixed(2)}% a.a.'),
              ('Taxa de Juros Mensal',
                  '${simulation.taxaJurosMensal.toStringAsFixed(2)}% a.m.'),
              ('CET Estimado Anual', '${cetAnual.toStringAsFixed(2)}% a.a.'),
              ('CET Estimado Mensal',
                  '${cetMensal.toStringAsFixed(2)}% a.m.'),
            ]),
            const SizedBox(height: 16),

            _buildSection('Valores', [
              ('Valor de Entrada', formatCurrency(valorEntrada)),
              ('1ª Parcela SAC',
                  formatCurrency(simulation.primeiraParcelaSac)),
              ('Última Parcela SAC',
                  formatCurrency(simulation.ultimaParcelaSac)),
              ('Total Pago (SAC)', formatCurrency(simulation.totalPagoSac)),
              ('Parcela PRICE', formatCurrency(simulation.parcelaPrice)),
              ('Total Pago (PRICE)',
                  formatCurrency(simulation.totalPagoPrice)),
            ]),

            const SizedBox(height: 24),

            // Share button
            SecondaryButton(
              text: 'Compartilhar Proposta',
              icon: Icons.share_rounded,
              onPressed: () => _shareProposta(context),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(
                'Fechar',
                style: TextStyle(
                  color: AppColors.secondary.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<(String, String)> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: rows.asMap().entries.map((entry) {
              final isLast = entry.key == rows.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.value.$1,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.secondary.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          entry.value.$2,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _shareProposta(BuildContext context) {
    final text = '''📊 Proposta de Financiamento – ${simulation.nomeInstituicao}

💰 Taxa: ${simulation.taxaJurosAnual.toStringAsFixed(2)}% a.a. (${simulation.taxaJurosMensal.toStringAsFixed(2)}% a.m.)
🧾 CET Estimado: ${cetAnual.toStringAsFixed(2)}% a.a.
📅 SAC 1ª Parcela: ${formatCurrency(simulation.primeiraParcelaSac)}
📅 Total SAC: ${formatCurrency(simulation.totalPagoSac)}
📅 PRICE (parcela fixa): ${formatCurrency(simulation.parcelaPrice)}

Simulado via Meu Correspondente''';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Proposta copiada para a área de transferência!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }
}
