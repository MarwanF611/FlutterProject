import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/review.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';

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
        backgroundColor: AppColors.primary,
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
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          appUser.displayName.isNotEmpty
                              ? appUser.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
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
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                            Text(
                              appUser.city,
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _ReviewsSection(uid: appUser.uid),
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
                  subtitle: 'Wijzig je naam',
                  onTap: () => _showEditNameDialog(context, auth),
                ),
                _ProfileMenuItem(
                  icon: Icons.lock_outline,
                  title: 'Wachtwoord wijzigen',
                  subtitle: 'Verander je wachtwoord',
                  onTap: () => _showChangePasswordDialog(context, auth),
                ),
                _ProfileMenuItem(
                  icon: Icons.location_on_outlined,
                  title: 'Locatie',
                  subtitle: 'Wijzig je stad/gemeente',
                  onTap: () => _showEditCityDialog(context, auth),
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

  void _showEditNameDialog(BuildContext context, AuthProvider auth) {
    final ctrl = TextEditingController(text: auth.appUser?.displayName ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Naam wijzigen'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Volledige naam'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              final ok = await auth.updateProfile(displayName: name);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Naam bijgewerkt!' : 'Bijwerken mislukt.'),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );
  }

  void _showEditCityDialog(BuildContext context, AuthProvider auth) {
    final ctrl = TextEditingController(text: auth.appUser?.city ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stad wijzigen'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Stad / gemeente'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () async {
              final city = ctrl.text.trim();
              if (city.isEmpty) return;
              Navigator.pop(ctx);
              final ok = await auth.updateProfile(city: city);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Stad bijgewerkt!' : 'Bijwerken mislukt.'),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AuthProvider auth) {
    final ctrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wachtwoord wijzigen'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: ctrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nieuw wachtwoord'),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Minimaal 6 tekens' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Bevestig wachtwoord'),
                validator: (v) =>
                    v != ctrl.text ? 'Wachtwoorden komen niet overeen' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              final ok = await auth.changePassword(ctrl.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? 'Wachtwoord gewijzigd!'
                        : auth.error ?? 'Wijzigen mislukt.'),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  final String uid;
  const _ReviewsSection({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Review>>(
      stream: FirestoreService().getReviewsForUser(uid),
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? [];
        final avg = reviews.isEmpty
            ? 0.0
            : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                reviews.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Beoordelingen',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 10),
                if (reviews.isNotEmpty) ...[
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 3),
                  Text(
                    '${avg.toStringAsFixed(1)} (${reviews.length})',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            if (reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Nog geen beoordelingen ontvangen.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              )
            else
              ...reviews.take(3).map((r) => _ReviewCard(review: r)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  review.reviewerName.isNotEmpty
                      ? review.reviewerName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.reviewerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(
                      review.deviceTitle,
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.comment,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            DateFormat('dd/MM/yyyy').format(review.createdAt),
            style: TextStyle(color: Colors.grey[400], fontSize: 11),
          ),
        ],
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
