import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../auth/auth_provider.dart';
import '../design_system/colors.dart';
import '../design_system/radius.dart';
import '../design_system/typography.dart';
import '../components/buttons/primary_button.dart';
import '../components/cards/app_card.dart';

class CreciSetupScreen extends StatefulWidget {
  const CreciSetupScreen({super.key});

  @override
  State<CreciSetupScreen> createState() => _CreciSetupScreenState();
}

class _CreciSetupScreenState extends State<CreciSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _creciController = TextEditingController();
  String? _selectedUf;
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<String> _ufs = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
    'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN',
    'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
  ];

  @override
  void dispose() {
    _creciController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final auth = AuthProviderScope.of(context);
      await auth.saveProfile(
        creci: _creciController.text.trim(),
        uf: _selectedUf!,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Falha ao salvar dados do CRECI. Tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthProviderScope.of(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Configuração de Perfil'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            key: const Key('creci_logout_button'),
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: () => auth.logout(),
            tooltip: 'Sair da conta',
          )
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.lightGrey,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.badge_outlined,
                        size: 48,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Olá, ${user?.name ?? "Corretor"}!',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.primary,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Identificamos que sua conta é de Corretor. Para prosseguir, insira os dados do seu CRECI.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      color: AppColors.secondary.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Form Card
                  AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: AppTypography.legend.copyWith(color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // CRECI Input
                        Text(
                          'Número do CRECI',
                          style: AppTypography.legend.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          key: const Key('creci_field'),
                          controller: _creciController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(8),
                          ],
                          decoration: InputDecoration(
                            hintText: 'Ex: 12345',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.radiusInputs),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor, informe seu CRECI.';
                            }
                            final cleanVal = value.trim();
                            if (cleanVal.length < 4 || cleanVal.length > 8) {
                              return 'O CRECI deve ter entre 4 e 8 dígitos.';
                            }
                            if (!RegExp(r'^\d+$').hasMatch(cleanVal)) {
                              return 'O CRECI deve conter apenas números.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        // UF Input
                        Text(
                          'UF do CRECI',
                          style: AppTypography.legend.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          key: const Key('creci_uf_field'),
                          value: _selectedUf,
                          hint: const Text('Selecione a UF'),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.radiusInputs),
                            ),
                          ),
                          items: _ufs.map((uf) {
                            return DropdownMenuItem<String>(
                              value: uf,
                              child: Text(uf),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedUf = val;
                              if (val != null) {
                                _errorMessage = null;
                              }
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, selecione a UF.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        
                        // Submit Button
                        PrimaryButton(
                          key: const Key('creci_submit_button'),
                          text: 'Confirmar e Entrar',
                          isLoading: _isSubmitting,
                          onPressed: _isSubmitting ? null : _submit,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
