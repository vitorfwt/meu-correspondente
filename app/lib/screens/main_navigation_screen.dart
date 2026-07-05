import 'package:flutter/material.dart';
import '../auth/auth_provider.dart';
import '../design_system/colors.dart';
import '../components/cards/app_card.dart';
import '../components/buttons/secondary_button.dart';
import '../components/buttons/tertiary_button.dart';
import 'simulator_form_screen.dart';
import 'home_screen.dart';
import 'partners_screen.dart';
import '../simulation/indicator_repository.dart';
import '../simulation/partner_repository.dart';
import '../main.dart'; // For StyleguideScreen

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  final IndicatorRepository indicatorRepository;
  final PartnerRepository partnerRepository;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 1,
    this.indicatorRepository = const IndicatorRepository(),
    this.partnerRepository = const PartnerRepository(),
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        onNavigateToSimulations: () {
          setState(() {
            _currentIndex = 1;
          });
        },
        repository: widget.indicatorRepository,
      ),
      const SimulatorFormScreen(),
      PartnersScreen(
        repository: widget.partnerRepository,
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        key: const Key('bottom_navigation_bar'),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: const Color(0xFF9EABB8), // light grey with high contrast against white
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate_outlined),
            activeIcon: Icon(Icons.calculate),
            label: 'Simulações',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business_outlined),
            activeIcon: Icon(Icons.business),
            label: 'Parceiros',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// The placeholder screens have been replaced by HomeScreen and PartnersScreen.

// Profile Screen with details, Styleguide and Logout
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthProviderScope.of(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Meu Perfil',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // User Info Card
              AppCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.accent,
                      child: Text(
                        user?.name.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.name ?? 'Usuário',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'email@exemplo.com',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Actions Card
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Styleguide Button
                    SecondaryButton(
                      key: const Key('profile_styleguide_button'),
                      text: 'Design System / Styleguide',
                      icon: Icons.palette_outlined,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const StyleguideScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Logout Button
                    TertiaryButton(
                      key: const Key('profile_logout_button'),
                      text: 'Sair da Conta',
                      icon: Icons.logout,
                      onPressed: () {
                        auth.logout();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
