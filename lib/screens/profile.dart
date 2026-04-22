import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final appUser = auth.appUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profiel'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (appUser != null) ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFFE3F2FD),
                        child: Text(
                          appUser.displayName.isNotEmpty
                              ? appUser.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appUser.displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              appUser.email,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13),
                            ),
                            Text(
                              appUser.city,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Instellingen',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _ProfileMenuItem(
                  icon: Icons.person_outline,
                  title: 'Profielinformatie',
                  subtitle: 'Wijzig je accountgegevens',
                  onTap: () {},
                ),
                _ProfileMenuItem(
                  icon: Icons.lock_outline,
                  title: 'Wachtwoord wijzigen',
                  subtitle: 'Verander je wachtwoord',
                  onTap: () {},
                ),
                _ProfileMenuItem(
                  icon: Icons.location_on_outlined,
                  title: 'Locatie',
                  subtitle: 'Beheer je stad/gemeente',
                  onTap: () {},
                ),
                _ProfileMenuItem(
                  icon: Icons.info_outline,
                  title: 'Over ToestelDelen',
                  subtitle: 'Versie 1.0.0',
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                _ProfileMenuItem(
                  icon: Icons.logout,
                  title: 'Uitloggen',
                  subtitle: 'Tot ziens!',
                  iconColor: Colors.red,
                  onTap: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 24, color: iconColor ?? Colors.grey[700]),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: iconColor ?? Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
