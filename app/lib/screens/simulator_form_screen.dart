import 'package:flutter/material.dart';
import '../auth/auth_provider.dart';
import '../design_system/colors.dart';
import '../widgets/custom_button.dart';
import '../simulation/simulation_repository.dart';
import 'simulation_result_screen.dart';
import '../main.dart'; // For StyleguideScreen navigation

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
  final _formKey = GlobalKey<FormState>();

  // State values
  double _valorImovel = 500000;
  double _valorEntrada = 100000;
  double _rendaMensal = 10000;
  int _prazoMeses = 360;
  String _tipoImovel = 'Residencial';
  String _estadoCivil = 'Solteiro(a)';

  // Controllers
  late final TextEditingController _valorImovelController;
  late final TextEditingController _entradaController;
  late final TextEditingController _rendaController;
  late final TextEditingController _prazoController;
  final TextEditingController _dataNascimentoController = TextEditingController();

  bool _isLoading = false;
  late final SimulationRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository;
    _valorImovelController = TextEditingController(text: _valorImovel.round().toString());
    _entradaController = TextEditingController(text: _valorEntrada.round().toString());
    _rendaController = TextEditingController(text: _rendaMensal.round().toString());
    _prazoController = TextEditingController(text: _prazoMeses.toString());

    // Sync controllers to sliders/states
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
    super.dispose();
  }

  void _onValorImovelTextChanged() {
    final val = double.tryParse(_valorImovelController.text);
    if (val != null && val >= 100000 && val <= 5000000 && val != _valorImovel) {
      setState(() {
        _valorImovel = val;
      });
    }
  }

  void _onEntradaTextChanged() {
    final val = double.tryParse(_entradaController.text);
    if (val != null && val >= 0 && val != _valorEntrada) {
      setState(() {
        _valorEntrada = val;
      });
    }
  }

  void _onRendaTextChanged() {
    final val = double.tryParse(_rendaController.text);
    if (val != null && val >= 0 && val != _rendaMensal) {
      setState(() {
        _rendaMensal = val;
      });
    }
  }

  void _onPrazoTextChanged() {
    final val = int.tryParse(_prazoController.text);
    if (val != null && val >= 12 && val <= 420 && val != _prazoMeses) {
      setState(() {
        _prazoMeses = val;
      });
    }
  }

  String _formatCurrencyCompact(double value) {
    final integerPart = value.round().toString();
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
    return 'R\$ $reversedInteger';
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
      if (date.year != year || date.month != month || date.day != day) return null;
      return date;
    } catch (_) {
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
    final auth = AuthProviderScope.of(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Simulador de Financiamento',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppColors.accent,
                child: Text(
                  user?.name.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              accountName: Text(
                user?.name ?? 'Usuário',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(user?.email ?? 'email@exemplo.com'),
            ),
            ListTile(
              leading: const Icon(Icons.calculate, color: AppColors.secondary),
              title: const Text('Simulador'),
              selected: true,
              selectedTileColor: AppColors.accent.withOpacity(0.1),
              selectedColor: AppColors.secondary,
              onTap: () {
                Navigator.pop(context); // Close drawer
              },
            ),
            ListTile(
              key: const Key('drawer_styleguide_tile'),
              leading: const Icon(Icons.palette_outlined, color: AppColors.secondary),
              title: const Text('Design System / Styleguide'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const StyleguideScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              key: const Key('drawer_logout_tile'),
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Sair', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context); // Close drawer
                auth.logout();
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
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
                const SizedBox(height: 8),
                Text(
                  'Descubra as parcelas e taxas para o seu financiamento imobiliário.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondary.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),

                // CARD 1: Valores
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.lightGrey),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.home, color: AppColors.accent),
                            SizedBox(width: 8),
                            Text(
                              'Valores do Imóvel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
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
                            helperText: 'Valor selecionado: ${_formatCurrencyCompact(_valorImovel)}',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe o valor do imóvel';
                            }
                            final val = double.tryParse(value);
                            if (val == null || val < 100000 || val > 5000000) {
                              return 'O valor do imóvel deve ser entre R\$ 100.000 e R\$ 5.000.000';
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
                            divisions: 98, // De 50k em 50k
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
                            helperText: 'Entrada mínima sugerida (20%): ${_formatCurrencyCompact(_valorImovel * 0.2)}',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe o valor de entrada';
                            }
                            final val = double.tryParse(value);
                            if (val == null) {
                              return 'Valor inválido';
                            }
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // CARD 2: Perfil do Comprador
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.lightGrey),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person, color: AppColors.accent),
                            SizedBox(width: 8),
                            Text(
                              'Perfil do Comprador',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Renda Familiar Mensal
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
                          decoration: const InputDecoration(
                            hintText: 'Ex: 10000',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe a renda mensal';
                            }
                            final val = double.tryParse(value);
                            if (val == null || val <= 0) {
                              return 'A renda familiar mensal deve ser maior que zero';
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
                          keyboardType: TextInputType.datetime,
                          decoration: InputDecoration(
                            hintText: 'DD/MM/AAAA',
                            suffixIcon: IconButton(
                              key: const Key('calendar_button'),
                              icon: const Icon(Icons.calendar_today, color: AppColors.secondary),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().subtract(const Duration(days: 365 * 30)),
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
                            if (date == null) {
                              return 'Formato inválido (DD/MM/AAAA)';
                            }
                            // Calculate age
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
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: <String>['Solteiro(a)', 'Casado(a)', 'Divorciado(a)', 'Viúvo(a)']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _estadoCivil = newValue;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // CARD 3: Detalhes do Financiamento
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.lightGrey),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.assignment, color: AppColors.accent),
                            SizedBox(width: 8),
                            Text(
                              'Detalhes do Financiamento',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
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
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: <String>['Residencial', 'Comercial']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _tipoImovel = newValue;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Prazo em Meses
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
                            helperText: 'Prazo selecionado: $_prazoMeses meses (${(_prazoMeses / 12).toStringAsFixed(1)} anos)',
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
                            divisions: 34, // Saltos de 12 meses (1 ano)
                            onChanged: (val) {
                              setState(() {
                                _prazoMeses = val.round();
                                _prazoController.text = val.round().toString();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botão de Simulação
                CustomButton(
                  key: const Key('simulate_button'),
                  text: 'Simular Financiamento',
                  type: CustomButtonType.accent,
                  isLoading: _isLoading,
                  icon: Icons.monetization_on_outlined,
                  onPressed: _submitForm,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPercentButton(String label, double pct) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: OutlinedButton(
          key: Key('quick_pct_${label.replaceAll('%', '')}'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: AppColors.lightGrey),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            setState(() {
              _valorEntrada = _valorImovel * pct;
              _entradaController.text = _valorEntrada.round().toString();
            });
          },
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
