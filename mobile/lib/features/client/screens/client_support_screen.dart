import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/responsive_container.dart';

const _supportEmail = 'suporte@universidade.edu';
const _supportPhone = '+55 21 99999-9999';
const _officeHours = 'Segunda a Sexta, das 08h às 21h';
const _whatsappUrl = 'https://wa.me/5521999999999';

class ClientSupportScreen extends StatelessWidget {
  const ClientSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Suporte')),
      body: SingleChildScrollView(
        child: ResponsiveContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),
              // Header
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.12),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.support_agent,
                  size: 40,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Suporte',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Como podemos ajudar você hoje?',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Contact options
              _ContactOption(
                icon: Icons.chat,
                iconColor: const Color(0xFF25D366),
                bgColor: const Color(0xFFE8F5E9),
                title: 'Conversar no WhatsApp',
                subtitle: 'Assistente virtual rápido',
                onTap: () => launchUrl(
                  Uri.parse(_whatsappUrl),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ContactOption(
                icon: Icons.phone,
                iconColor: colors.primary,
                bgColor: colors.surfaceContainer,
                title: 'Ligar para a Faculdade',
                subtitle: 'Atendimento telefônico',
                onTap: () => launchUrl(
                  Uri.parse(
                    'tel:${_supportPhone.replaceAll(RegExp(r'[^0-9+]'), '')}',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ContactOption(
                icon: Icons.email_outlined,
                iconColor: colors.secondary,
                bgColor: colors.secondaryContainer.withValues(alpha: 0.3),
                title: 'Enviar E-mail',
                subtitle: 'Suporte acadêmico',
                onTap: () => launchUrl(Uri.parse('mailto:$_supportEmail')),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Office hours
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: colors.outline,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'HORÁRIO DE ATENDIMENTO',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _officeHours,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
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

class _ContactOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactOption({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.outlineVariant),
        ],
      ),
    );
  }
}
