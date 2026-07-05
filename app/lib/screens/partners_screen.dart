import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth/auth_provider.dart';
import '../design_system/colors.dart';
import '../design_system/radius.dart';
import '../design_system/typography.dart';
import '../components/cards/app_card.dart';
import '../simulation/partner_repository.dart';

class PartnersScreen extends StatefulWidget {
  final PartnerRepository repository;

  const PartnersScreen({
    super.key,
    this.repository = const PartnerRepository(),
  });

  @override
  State<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State<PartnersScreen> {
  late Future<List<Partner>> _partnersFuture;
  String? _lastToken;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthProviderScope.of(context);
    final token = auth.token ?? '';
    if (_lastToken != token) {
      _lastToken = token;
      _loadPartners(token);
    }
  }

  void _loadPartners(String token) {
    _partnersFuture = widget.repository.getPartners(token: token);
  }

  Future<void> _refresh() async {
    final auth = AuthProviderScope.of(context);
    final token = auth.token ?? '';
    setState(() {
      _loadPartners(token);
    });
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'P';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  Future<void> _launchContact(String scheme, String value) async {
    Uri uri;
    if (scheme == 'whatsapp') {
      final cleanPhone = value.replaceAll(RegExp(r'\D'), '');
      uri = Uri.parse('https://wa.me/$cleanPhone');
    } else {
      uri = Uri(scheme: scheme, path: value);
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Não foi possível abrir o aplicativo para $scheme.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao tentar abrir o contato.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Text(
                  'Parceiros',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.primary,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nossos correspondentes bancários e parceiros de confiança.',
                  style: AppTypography.legend.copyWith(
                    color: AppColors.secondary.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),

                FutureBuilder<List<Partner>>(
                  future: _partnersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingPartners();
                    } else if (snapshot.hasError) {
                      return _buildErrorPartners();
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyPartners();
                    }

                    final partners = snapshot.data!;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: partners.length,
                      itemBuilder: (context, index) {
                        final partner = partners[index];
                        final initials = _getInitials(partner.name);

                        return Container(
                          key: Key('partner_card_${partner.id}'),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: AppCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: AppColors.lightGrey,
                                  backgroundImage: partner.photoUrl != null && partner.photoUrl!.isNotEmpty
                                      ? NetworkImage(partner.photoUrl!)
                                      : null,
                                  child: partner.photoUrl == null || partner.photoUrl!.isEmpty
                                      ? Text(
                                          initials,
                                          style: AppTypography.sectionTitle.copyWith(
                                            color: AppColors.secondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        partner.name,
                                        style: AppTypography.legend.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        partner.company,
                                        style: AppTypography.helperText.copyWith(
                                          color: AppColors.secondary.withOpacity(0.8),
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (partner.phone != null && partner.phone!.isNotEmpty) ...[
                                      _buildContactIconButton(
                                        key: Key('whatsapp_${partner.id}'),
                                        icon: Icons.chat_bubble_outline_rounded,
                                        color: const Color(0xFF25D366),
                                        tooltip: 'WhatsApp',
                                        onTap: () => _launchContact('whatsapp', partner.phone!),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildContactIconButton(
                                        key: Key('phone_${partner.id}'),
                                        icon: Icons.phone_outlined,
                                        color: AppColors.info,
                                        tooltip: 'Ligar',
                                        onTap: () => _launchContact('tel', partner.phone!),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    _buildContactIconButton(
                                      key: Key('email_${partner.id}'),
                                      icon: Icons.mail_outline_rounded,
                                      color: AppColors.warning,
                                      tooltip: 'E-mail',
                                      onTap: () => _launchContact('mailto', partner.email),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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

  Widget _buildContactIconButton({
    required Key key,
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      shape: const CircleBorder(),
      child: IconButton(
        key: key,
        icon: Icon(icon, color: color, size: 20),
        onPressed: onTap,
        tooltip: tooltip,
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildLoadingPartners() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 92,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.radiusCards),
            border: Border.all(color: AppColors.lightGrey),
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
        );
      },
    );
  }

  Widget _buildErrorPartners() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.radiusCards),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 36),
          const SizedBox(height: 8),
          const Text(
            'Erro ao carregar parceiros',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            key: const Key('retry_partners_button'),
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

  Widget _buildEmptyPartners() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.radiusCards),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: const Center(
        child: Text(
          'Nenhum parceiro ativo encontrado.',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
