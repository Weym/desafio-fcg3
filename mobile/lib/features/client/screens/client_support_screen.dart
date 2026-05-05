import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/widgets/responsive_container.dart';

const _supportEmail = 'suporte@universidade.edu';
const _supportPhone = '+55 21 99999-9999';
const _officeHours = 'Segunda a Sexta, 8h as 17h';
const _whatsappUrl = 'https://wa.me/5521999999999';

class ClientSupportScreen extends StatelessWidget {
  const ClientSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suporte'),
      ),
      body: SingleChildScrollView(
        child: ResponsiveContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
            const SizedBox(height: 16),
            Icon(
              Icons.support_agent,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Central de Atendimento',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Precisa de ajuda? Entre em contato conosco.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.email_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text(_supportEmail),
                subtitle: const Text('Enviar email'),
                trailing: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onTap: () => launchUrl(Uri.parse('mailto:$_supportEmail')),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.phone_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text(_supportPhone),
                subtitle: const Text('Ligar'),
                trailing: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onTap: () => launchUrl(
                  Uri.parse(
                    'tel:${_supportPhone.replaceAll(RegExp(r'[^0-9+]'), '')}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.chat_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('WhatsApp'),
                subtitle: const Text('Abrir conversa'),
                trailing: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onTap: () => launchUrl(
                  Uri.parse(_whatsappUrl),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  _officeHours,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }
}
