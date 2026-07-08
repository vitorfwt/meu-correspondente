import 'package:flutter/material.dart';
import '../auth/auth_provider.dart';
import '../design_system/colors.dart';
import '../components/buttons/primary_button.dart';
import '../components/buttons/secondary_button.dart';
import '../components/cards/app_card.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProviderScope.of(context);

    // Show error message if it exists
    if (authProvider.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 64.0).clamp(0.0, double.infinity), // account for padding
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand / Logo Section
                    const SizedBox(height: 40),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_outlined,
                          size: 64,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Meu Correspondente',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.background,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sua conexão direta com as melhores oportunidades financeiras.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.lightGrey,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 60),

                    // Authentication Card
                    AppCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Entrar na sua conta',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Escolha uma das opções abaixo para acessar',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.secondary.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 24),

                           // Google Login Button
                          SecondaryButton(
                            key: const Key('google_login_button'),
                            text: 'Entrar com Google',
                            isLoading: authProvider.isLoading,
                            icon: Icons.g_mobiledata,
                            onPressed: authProvider.isLoading
                                ? null
                                : () => authProvider.loginWithGoogle(),
                          ),
                          const SizedBox(height: 16),

                          // Apple Login Button
                          PrimaryButton(
                            key: const Key('apple_login_button'),
                            text: 'Entrar com Apple',
                            isLoading: authProvider.isLoading,
                            icon: Icons.apple,
                            onPressed: authProvider.isLoading
                                ? null
                                : () => authProvider.loginWithApple(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Footer terms and privacy
                    Text(
                      'Ao entrar, você concorda com nossos Termos de Serviço e Política de Privacidade.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.lightGrey.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
