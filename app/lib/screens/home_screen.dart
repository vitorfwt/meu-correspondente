import 'package:flutter/material.dart';
import '../auth/auth_provider.dart';
import '../design_system/colors.dart';
import '../design_system/radius.dart';
import '../design_system/typography.dart';
import '../components/cards/app_card.dart';
import '../simulation/indicator_repository.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToSimulations;
  final IndicatorRepository repository;
  final int initialIndex;

  const HomeScreen({
    super.key,
    required this.onNavigateToSimulations,
    this.initialIndex = 0,
    this.repository = const IndicatorRepository(),
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<MacroeconomicIndicator>> _indicatorsFuture;
  String? _lastToken;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthProviderScope.of(context);
    final token = auth.token ?? '';
    if (_lastToken != token) {
      _lastToken = token;
      _loadIndicators(token);
    }
  }

  void _loadIndicators(String token) {
    _indicatorsFuture = widget.repository.getIndicators(token: token);
  }

  Future<void> _refresh() async {
    final auth = AuthProviderScope.of(context);
    final token = auth.token ?? '';
    setState(() {
      _loadIndicators(token);
    });
  }

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    return '$day/$month/$year';
  }

  String _formatValue(double val) {
    final percentVal = val * 100;
    if (percentVal < 0.5 && percentVal > 0) {
      return '${percentVal.toStringAsFixed(4).replaceAll('.', ',')}%';
    }
    return '${percentVal.toStringAsFixed(2).replaceAll('.', ',')}%';
  }

  IconData _getIconForIndicator(String name) {
    switch (name.toUpperCase()) {
      case 'SELIC':
        return Icons.trending_up;
      case 'IPCA':
        return Icons.percent;
      case 'TR':
        return Icons.show_chart;
      case 'POUPANCA':
      case 'POUPANÇA':
        return Icons.savings_outlined;
      default:
        return Icons.monetization_on_outlined;
    }
  }

  String _getDisplayName(String name) {
    if (name.toUpperCase() == 'POUPANCA') {
      return 'Poupança';
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthProviderScope.of(context);
    final user = auth.user;
    final userName = user?.name ?? 'Usuário';
    final isBroker = user?.role == 'broker';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Greetings and Badge)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, $userName',
                            style: AppTypography.titleLarge.copyWith(
                              color: AppColors.primary,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bem-vindo ao Meu Correspondente!',
                            style: AppTypography.legend.copyWith(
                              color: AppColors.secondary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Condition badge
                    if (isBroker)
                      Container(
                        key: const Key('broker_badge'),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Corretor • CRECI: ${user?.creci ?? ""}-${user?.uf ?? ""}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      )
                    else
                      Container(
                        key: const Key('client_badge'),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Cliente',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 28),

                // Shortcut Card "Nova Simulação"
                GestureDetector(
                  key: const Key('new_simulation_card'),
                  onTap: widget.onNavigateToSimulations,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.radiusCards),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nova Simulação',
                                style: AppTypography.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Compare taxas de financiamento imobiliário nos principais bancos.',
                                style: AppTypography.body.copyWith(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.calculate,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Indicators Section Header
                Text(
                  'Indicadores Macroeconômicos',
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Taxas de referência atualizadas do mercado financeiro.',
                  style: AppTypography.legend.copyWith(
                    color: AppColors.secondary.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),

                // Macroeconomic Indicators Row (Horizontal Grade)
                FutureBuilder<List<MacroeconomicIndicator>>(
                  future: _indicatorsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingIndicators();
                    } else if (snapshot.hasError) {
                      return _buildErrorIndicators();
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyIndicators();
                    }

                    final list = snapshot.data!;
                    
                    final copomList = list.where((ind) => ind.name.toUpperCase() == 'COPOM').toList();
                    final copomIndicator = copomList.isNotEmpty ? copomList.first : null;

                    Widget? copomCard;
                    if (copomIndicator != null) {
                      final copomDate = DateTime.fromMillisecondsSinceEpoch(copomIndicator.value.toInt());
                      final difference = copomDate.difference(DateTime.now()).inDays;
                      if (difference >= 0) {
                        copomCard = Container(
                          key: const Key('copom_card'),
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppRadius.radiusCards),
                            border: Border.all(color: AppColors.accent, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month,
                                color: AppColors.accent,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Próxima reunião do COPOM',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      difference == 0
                                          ? 'É hoje! Reunião do COPOM (${_formatDate(copomDate)})'
                                          : 'Faltam $difference dias (${_formatDate(copomDate)})',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    }

                    final gridList = list.where((ind) => ind.name.toUpperCase() != 'COPOM').toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: gridList.map((ind) {
                            return SizedBox(
                              key: Key('indicator_card_${ind.name}'),
                              width: (MediaQuery.of(context).size.width - 48 - 12) / 2,
                              child: AppCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _getDisplayName(ind.name),
                                            style: AppTypography.legend.copyWith(
                                              color: AppColors.secondary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(
                                          _getIconForIndicator(ind.name),
                                          color: AppColors.accent,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _formatValue(ind.value),
                                      style: AppTypography.sectionTitle.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Atu. ${_formatDate(ind.updatedAt)}',
                                      style: AppTypography.helperText.copyWith(
                                        color: AppColors.secondary.withOpacity(0.5),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (copomCard != null) ...[
                          const SizedBox(height: 16),
                          copomCard,
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicators() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(4, (index) {
            return SizedBox(
              width: cardWidth,
              height: 100,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.radiusCards),
                  border: Border.all(color: AppColors.lightGrey, width: 1),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildErrorIndicators() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.radiusCards),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 28),
          const SizedBox(height: 8),
          const Text(
            'Erro ao carregar indicadores',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            key: const Key('retry_indicators_button'),
            onPressed: _refresh,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Tentar Novamente'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyIndicators() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.radiusCards),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: const Center(
        child: Text(
          'Nenhum indicador disponível.',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
