import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/device.dart';
import '../providers/device_provider.dart';
import '../widgets/category_chip.dart';
import '../widgets/device_card.dart';
import 'device_detail.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Search and Icons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _buildHeader(context),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Promo Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _buildPromoBanner(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Categories Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: _buildSectionTitle('Alle Categorieën', onPressed: () {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: CategoryChipRow(
                      selectedCategory: deviceProvider.selectedCategory,
                      onSelected: deviceProvider.selectCategory,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Popular/Available Devices
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: _buildSectionTitle('Beschikbare Toestellen', onPressed: () {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  StreamBuilder<List<Device>>(
                    stream: deviceProvider.devicesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Fout bij laden: ${snapshot.error}',
                            style: const TextStyle(color: AppColors.error),
                          ),
                        );
                      }
                      final devices = snapshot.data ?? [];
                      if (devices.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.devices, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Nog geen toestellen beschikbaar.',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      }
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Row(
                          children: List.generate(
                            devices.length,
                            (index) {
                              final device = devices[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index != devices.length - 1 ? AppSpacing.md : 0,
                                ),
                                child: SizedBox(
                                  width: 160,
                                  child: DeviceCard(
                                    device: device,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DeviceDetailScreen(device: device),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Recently Added Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: _buildSectionTitle('Recent Toegevoegd', onPressed: () {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  StreamBuilder<List<Device>>(
                    stream: deviceProvider.devicesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final devices = (snapshot.data ?? [])
                          .where((d) => DateTime.now().difference(d.createdAt).inDays <= 7)
                          .toList();

                      if (devices.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: Text('Geen recent toegevoegde toestellen'),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: devices.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.xl,
                            childAspectRatio: 0.7,
                          ),
                          itemBuilder: (context, index) {
                            return DeviceCard(
                              device: devices[index],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DeviceDetailScreen(device: devices[index]),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _SearchField(),
        ),
        const SizedBox(width: AppSpacing.md),
        _IconButton(
          icon: Icons.shopping_cart_outlined,
          onPressed: () {},
          badge: null,
        ),
        const SizedBox(width: AppSpacing.sm),
        _IconButton(
          icon: Icons.notifications_outlined,
          onPressed: () {},
          badge: 3,
        ),
      ],
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: const Text.rich(
        TextSpan(
          style: TextStyle(color: Colors.white),
          children: [
            TextSpan(
              text: 'Exclusieve Aanbieding\n',
              style: AppTypography.body2,
            ),
            TextSpan(
              text: 'Tot 30% Korting',
              style: AppTypography.headline3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {required VoidCallback onPressed}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.title3),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(foregroundColor: AppColors.textMedium),
          child: const Text('Meer'),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (value) {},
      decoration: InputDecoration(
        filled: true,
        hintStyle: const TextStyle(color: AppColors.textLight),
        fillColor: AppColors.primaryDark.withValues(alpha: 0.08),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        hintText: 'Zoeken',
        prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final int? badge;

  const _IconButton({
    required this.icon,
    required this.onPressed,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.circle),
      onTap: onPressed,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textMedium),
          ),
          if (badge != null)
            Positioned(
              top: -3,
              right: 0,
              child: Container(
                height: 20,
                width: 20,
                decoration: BoxDecoration(
                  color: AppColors.accentRed,
                  shape: BoxShape.circle,
                  border: Border.all(width: 1.5, color: Colors.white),
                ),
                child: Center(
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
