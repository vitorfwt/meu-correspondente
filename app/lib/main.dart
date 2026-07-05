import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/simulator_form_screen.dart';
import 'design_system/colors.dart';
import 'design_system/theme.dart';
import 'widgets/custom_button.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return AuthProviderScope(
      notifier: AuthProvider(prefs: prefs),
      child: MaterialApp(
        title: 'Meu Correspondente - Design System',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeData,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthProviderScope.of(context);
    if (auth.isAuthenticated) {
      return const SimulatorFormScreen();
    } else {
      return const LoginScreen();
    }
  }
}

class StyleguideScreen extends StatefulWidget {
  const StyleguideScreen({super.key});

  @override
  State<StyleguideScreen> createState() => _StyleguideScreenState();
}

class _StyleguideScreenState extends State<StyleguideScreen> {
  int _buttonTapCount = 0;
  bool _isLoadingButton = false;

  void _onButtonPressed() {
    setState(() {
      _buttonTapCount++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Botão clicado! Cliques: $_buttonTapCount'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String colorName, String hexCode) {
    Clipboard.setData(ClipboardData(text: hexCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cor $colorName ($hexCode) copiada para a área de transferência!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthProviderScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, ${auth.user?.name ?? "Usuário"}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const Text(
              'Styleguide & Design System',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            key: const Key('logout_button'),
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Sair',
            onPressed: () {
              auth.logout();
            },
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Identidade Visual do App no Flutter aplicada com sucesso!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
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
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Identidade Visual',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Este catálogo interativo apresenta as cores oficiais, tipografia (Poppins) e variações de botões que compõem a base visual do aplicativo Meu Correspondente.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Typography Section
            _buildSectionHeader('Tipografia (Poppins)', Icons.text_fields),
            const SizedBox(height: 16),
            _buildTypographyCard(),

            const SizedBox(height: 32),

            // Colors Section
            _buildSectionHeader('Paleta de Cores', Icons.color_lens),
            const SizedBox(height: 8),
            const Text(
              'Clique em qualquer card de cor para copiar o valor hexadecimal.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildColorPaletteGrid(context),

            const SizedBox(height: 32),

            // Buttons Section
            _buildSectionHeader('Botões Reutilizáveis', Icons.smart_button),
            const SizedBox(height: 16),
            _buildButtonsShowcase(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.secondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTypographyCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lightGrey),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Headline Large (Poppins Bold)',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Divider(height: 24),
            Text(
              'Headline Medium (Poppins SemiBold)',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            Divider(height: 24),
            Text(
              'Title Large (Poppins Medium)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            Divider(height: 24),
            Text(
              'Body Large (Poppins Regular)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
            ),
            SizedBox(height: 8),
            Text(
              'A tipografia Poppins proporciona um visual moderno, clean e de alta legibilidade para todas as interfaces do nosso aplicativo.',
              style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPaletteGrid(BuildContext context) {
    final colors = [
      _ColorItem('Primary (Dark Navy)', AppColors.primary, '#0D1B2A', Colors.white),
      _ColorItem('Secondary (Dark Blue)', AppColors.secondary, '#1B4965', Colors.white),
      _ColorItem('Accent (Teal)', AppColors.accent, '#2EC4B6', AppColors.primary),
      _ColorItem('Light Grey (Ice Blue)', AppColors.lightGrey, '#E0E7EF', AppColors.primary),
      _ColorItem('Background', AppColors.background, '#F7F9FC', AppColors.primary),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = colors[index];
        return InkWell(
          onTap: () => _copyToClipboard(context, color.name, color.hex),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.value,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGrey, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  color.name,
                  style: TextStyle(
                    color: color.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  color.hex,
                  style: TextStyle(
                    color: color.textColor.withOpacity(0.8),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildButtonsShowcase() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lightGrey),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // State display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cliques no botão: $_buttonTapCount',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
                ),
                Row(
                  children: [
                    const Text('Loading:', style: TextStyle(fontSize: 12)),
                    Switch(
                      value: _isLoadingButton,
                      onChanged: (value) {
                        setState(() {
                          _isLoadingButton = value;
                        });
                      },
                      activeColor: AppColors.accent,
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Primary Button
            const Text('Primary Button (#0D1B2A)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            CustomButton(
              text: 'Acessar Conta',
              type: CustomButtonType.primary,
              isLoading: _isLoadingButton,
              onPressed: _onButtonPressed,
            ),
            const SizedBox(height: 20),

            // Secondary Button
            const Text('Secondary Button (#1B4965)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            CustomButton(
              text: 'Fazer Cadastro',
              type: CustomButtonType.secondary,
              isLoading: _isLoadingButton,
              icon: Icons.person_add_outlined,
              onPressed: _onButtonPressed,
            ),
            const SizedBox(height: 20),

            // Accent Button
            const Text('Accent Button (#2EC4B6)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            CustomButton(
              text: 'Simular Empréstimo',
              type: CustomButtonType.accent,
              isLoading: _isLoadingButton,
              icon: Icons.monetization_on_outlined,
              onPressed: _onButtonPressed,
            ),
            const SizedBox(height: 20),

            // Disabled state showcase
            const Text('Disabled State (onPressed: null)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const CustomButton(
              text: 'Indisponível',
              type: CustomButtonType.primary,
              onPressed: null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorItem {
  final String name;
  final Color value;
  final String hex;
  final Color textColor;

  _ColorItem(this.name, this.value, this.hex, this.textColor);
}
