import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../auth/auth_provider.dart';
import '../design_system/colors.dart';
import '../components/buttons/primary_button.dart';
import '../components/buttons/secondary_button.dart';
import '../components/buttons/tertiary_button.dart';
import '../components/cards/app_card.dart';
import '../simulation/simulation_repository.dart';
import '../widgets/step_indicator.dart';
import 'simulation_result_screen.dart';

class SimulatorFormScreen extends StatefulWidget {
  final SimulationRepository repository;

  const SimulatorFormScreen({
    super.key,
    this.repository = const SimulationRepository(),
  });

  @override
  State<SimulatorFormScreen> createState() => _SimulatorFormScreenState();
}

class _SimulatorFormScreenState extends State<SimulatorFormScreen> {
  // Page controller for step navigation
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 3;

  // Form keys per step
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();

  // State values
  double _valorImovel = 500000;
  double _valorEntrada = 100000;
  double _rendaMensal = 10000;
  int _prazoMeses = 420;
  String _tipoImovel = 'Residencial';
  String _estadoCivil = 'Solteiro(a)';

  // Controllers
  late final TextEditingController _valorImovelController;
  late final TextEditingController _entradaController;
  late final TextEditingController _rendaController;
  late final TextEditingController _prazoController;
  final TextEditingController _dataNascimentoController =
      TextEditingController();

  bool _isLoading = false;
  late final SimulationRepository _repository;

  static const List<String> _stepTitles = [
    'Dados do Imóvel',
    'Dados do Comprador',
    'Detalhes do Financiamento',
  ];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository;
    _valorImovelController =
        TextEditingController(text: _valorImovel.round().toString());
    _entradaController =
        TextEditingController(text: _valorEntrada.round().toString());
    _rendaController =
        TextEditingController(text: _rendaMensal.round().toString());
    _prazoController = TextEditingController(text: _prazoMeses.toString());

    _valorImovelController.addListener(_onValorImovelTextChanged);
    _entradaController.addListener(_onEntradaTextChanged);
    _rendaController.addListener(_onRendaTextChanged);
    _prazoController.addListener(_onPrazoTextChanged);
  }

  @override
  void dispose() {
    _valorImovelController.removeListener(_onValorImovelTextChanged);
    _entradaController.removeListener(_onEntradaTextChanged);
    _rendaController.removeListener(_onRendaTextChanged);
    _prazoController.removeListener(_onPrazoTextChanged);

    _valorImovelController.dispose();
    _entradaController.dispose();
    _rendaController.dispose();
    _prazoController.dispose();
    _dataNascimentoController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onValorImovelTextChanged() {
    final val = double.tryParse(_valorImovelController.text);
    if (val != null &&
        val >= 100000 &&
        val <= 5000000 &&
        val != _valorImovel) {
      setState(() => _valorImovel = val);
    }
  }

  void _onEntradaTextChanged() {
    final val = double.tryParse(_entradaController.text);
    if (val != null && val >= 0 && val != _valorEntrada) {
      setState(() => _valorEntrada = val);
    }
  }

  void _onRendaTextChanged() {
    final val = double.tryParse(_rendaController.text);
    if (val != null && val >= 0 && val != _rendaMensal) {
      setState(() => _rendaMensal = val);
    }
  }

  void _onPrazoTextChanged() {
    final val = int.tryParse(_prazoController.text);
    if (val != null && val >= 12 && val <= 420 && val != _prazoMeses) {
      setState(() => _prazoMeses = val);
    }
  }

  String _formatCurrencyCompact(double value) {
    final integerPart = value.round().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(integerPart[i]);
      count++;
    }
    return 'R\$ ${buffer.toString().split('').reversed.join('')}';
  }

  DateTime? _parseDate(String value) {
    final regExp = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');
    if (!regExp.hasMatch(value)) return null;
    final match = regExp.firstMatch(value);
    if (match == null) return null;
    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) return null;
    try {
      final date = DateTime(year, month, day);
      if (date.year != year || date.month != month || date.day != day) {
        return null;
      }
      return date;
    } catch (_) {
      return null;
    }
  }

  GlobalKey<FormState> get _currentFormKey {
    switch (_currentStep) {
      case 0:
        return _step1FormKey;
      case 1:
        return _step2FormKey;
      default:
        return _step3FormKey;
    }
  }

  void _nextStep() {
    if (!_currentFormKey.currentState!.validate()) return;
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitForm();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_step3FormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final dataNasc = _parseDate(_dataNascimentoController.text)!;
    final input = SimulationInput(
      valorImovel: _valorImovel,
      valorEntrada: _valorEntrada,
      rendaMensal: _rendaMensal,
      tipoImovel: _tipoImovel,
      estadoCivil: _estadoCivil,
      prazoMeses: _prazoMeses,
      dataNascimento: dataNasc,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SimulationResultScreen(
            input: input,
            repository: _repository,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Faça uma Simulação',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Descubra as parcelas e taxas para o seu financiamento.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.secondary.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 20),
                  StepTitle(
                    key: const Key('step_indicator'),
                    currentStep: _currentStep,
                    totalSteps: _totalSteps,
                    titles: _stepTitles,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Step Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      child: TertiaryButton(
                        key: const Key('back_button'),
                        text: 'Voltar',
                        icon: Icons.arrow_back,
                        onPressed: _prevStep,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      key: const Key('simulate_button'),
                      text: _currentStep < _totalSteps - 1
                          ? 'Avançar'
                          : 'Simular Financiamento',
                      isLoading: _isLoading,
                      icon: _currentStep < _totalSteps - 1
                          ? Icons.arrow_forward
                          : Icons.monetization_on_outlined,
                      onPressed: _nextStep,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── STEP 1: Dados do Imóvel ────────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _step1FormKey,
        child: Column(
          children: [
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.home_outlined, color: AppColors.accent),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Valores do Imóvel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Valor do Imóvel
                  const Text(
                    'Valor do Imóvel (R\$)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('valor_imovel_field'),
                    controller: _valorImovelController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Ex: 500000',
                      helperText:
                          'Valor selecionado: ${_formatCurrencyCompact(_valorImovel)}',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe o valor do imóvel';
                      }
                      final val = double.tryParse(value);
                      if (val == null || val < 100000 || val > 5000000) {
                        return 'O valor deve ser entre R\$ 100.000 e R\$ 5.000.000';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.accent,
                      inactiveTrackColor: AppColors.lightGrey,
                      thumbColor: AppColors.accent,
                      overlayColor: AppColors.accent.withOpacity(0.2),
                    ),
                    child: Slider(
                      key: const Key('valor_imovel_slider'),
                      value: _valorImovel,
                      min: 100000,
                      max: 5000000,
                      divisions: 98,
                      onChanged: (val) {
                        setState(() {
                          _valorImovel = val;
                          _valorImovelController.text = val.round().toString();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Valor de Entrada
                  const Text(
                    'Valor de Entrada (R\$)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('valor_entrada_field'),
                    controller: _entradaController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Ex: 100000',
                      helperText:
                          'Mínimo sugerido (20%): ${_formatCurrencyCompact(_valorImovel * 0.2)}',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe o valor de entrada';
                      }
                      final val = double.tryParse(value);
                      if (val == null) return 'Valor inválido';
                      final minEntrada = _valorImovel * 0.2;
                      if (val < minEntrada) {
                        return 'Entrada mínima de 20% (${_formatCurrencyCompact(minEntrada)})';
                      }
                      if (val > _valorImovel) {
                        return 'A entrada não pode ser maior que o valor do imóvel';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickPercentButton('20%', 0.2),
                      _buildQuickPercentButton('30%', 0.3),
                      _buildQuickPercentButton('40%', 0.4),
                      _buildQuickPercentButton('50%', 0.5),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── STEP 2: Dados do Comprador ─────────────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _step2FormKey,
        child: Column(
          children: [
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person_outline, color: AppColors.accent),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Perfil do Comprador',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Renda Mensal
                  const Text(
                    'Renda Familiar Mensal (R\$)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('renda_mensal_field'),
                    controller: _rendaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Ex: 10000'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe a renda mensal';
                      }
                      final val = double.tryParse(value);
                      if (val == null || val <= 0) {
                        return 'A renda deve ser maior que zero';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Data de Nascimento
                  const Text(
                    'Data de Nascimento',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('data_nascimento_field'),
                    controller: _dataNascimentoController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [DateInputFormatter()],
                    decoration: InputDecoration(
                      hintText: 'DD/MM/AAAA',
                      suffixIcon: IconButton(
                        key: const Key('calendar_button'),
                        icon: const Icon(Icons.calendar_today_outlined,
                            color: AppColors.secondary),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now()
                                .subtract(const Duration(days: 365 * 30)),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            final formatted =
                                '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                            _dataNascimentoController.text = formatted;
                          }
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe a data de nascimento';
                      }
                      final date = _parseDate(value);
                      if (date == null) return 'Formato inválido (DD/MM/AAAA)';
                      final hoje = DateTime.now();
                      int idade = hoje.year - date.year;
                      if (hoje.month < date.month ||
                          (hoje.month == date.month && hoje.day < date.day)) {
                        idade--;
                      }
                      if (idade < 18 || idade > 80) {
                        return 'O proponente deve ter entre 18 e 80 anos';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Estado Civil
                  const Text(
                    'Estado Civil',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: const Key('estado_civil_dropdown'),
                    value: _estadoCivil,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: <String>[
                      'Solteiro(a)',
                      'Casado(a)',
                      'Divorciado(a)',
                      'Viúvo(a)'
                    ]
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _estadoCivil = v);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── STEP 3: Detalhes do Financiamento ──────────────────────────────────────
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _step3FormKey,
        child: Column(
          children: [
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.assignment_outlined, color: AppColors.accent),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Detalhes do Financiamento',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Tipo de Imóvel
                  const Text(
                    'Tipo do Imóvel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: const Key('tipo_imovel_dropdown'),
                    value: _tipoImovel,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: <String>['Residencial', 'Comercial']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _tipoImovel = v);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Prazo
                  const Text(
                    'Prazo do Financiamento (Meses)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('prazo_field'),
                    controller: _prazoController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Ex: 360',
                      helperText:
                          'Prazo: $_prazoMeses meses (${(_prazoMeses / 12).toStringAsFixed(1)} anos)',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe o prazo';
                      }
                      final val = int.tryParse(value);
                      if (val == null || val < 12 || val > 420) {
                        return 'O prazo deve ser entre 12 e 420 meses';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.accent,
                      inactiveTrackColor: AppColors.lightGrey,
                      thumbColor: AppColors.accent,
                      overlayColor: AppColors.accent.withOpacity(0.2),
                    ),
                    child: Slider(
                      key: const Key('prazo_slider'),
                      value: _prazoMeses.toDouble(),
                      min: 12,
                      max: 420,
                      divisions: 34,
                      onChanged: (val) {
                        setState(() {
                          _prazoMeses = val.round();
                          _prazoController.text = val.round().toString();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPercentButton(String label, double pct) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.0),
        child: SecondaryButton(
          key: Key('quick_pct_${label.replaceAll('%', '')}'),
          text: label,
          isCompact: true,
          onPressed: () {
            setState(() {
              _valorEntrada = _valorImovel * pct;
              _entradaController.text = _valorEntrada.round().toString();
            });
          },
        ),
      ),
    );
  }
}

/// Formata automaticamente datas no formato DD/MM/AAAA ao digitar.
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    if (newValue.text.length < oldValue.text.length) {
      // Deletando — deixa o Flutter lidar normalmente
      return newValue;
    }
    final buffer = StringBuffer();
    for (int i = 0; i < text.length && i < 8; i++) {
      buffer.write(text[i]);
      if (i == 1 || i == 3) buffer.write('/');
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
