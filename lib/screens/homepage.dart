import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/device.dart';
import '../providers/device_provider.dart';
import '../widgets/category_chip.dart';
import '../widgets/device_card.dart';
import 'all_devices_screen.dart';
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
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gradient Header
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hallo! 👋',
                      style: AppTypography.headline2.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Wat wil je vandaag huren?',
                      style: AppTypography.body2.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SearchField(),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: _buildSectionTitle(context, '🏷️ Categorieën', onPressed: () {}),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Geen extra Padding hier – CategoryChipRow heeft eigen interne padding
                    CategoryChipRow(
                      selectedCategory: deviceProvider.selectedCategory,
                      onSelected: deviceProvider.selectCategory,
                    ),
                  ],
                ),
              ),

              // Beschikbare Toestellen
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: _buildSectionTitle(
                        context,
                        '✨ Populair nu',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AllDevicesScreen(title: 'Alle Toestellen'),
                            ),
                          );
                        },
                      ),
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
                            children: List.generate(devices.length, (index) {
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
                            }),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Recent Toegevoegd
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: _buildSectionTitle(
                        context,
                        '🆕 Nieuw toegevoegd',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AllDevicesScreen(
                                title: 'Nieuw toegevoegd',
                                recentOnly: true,
                              ),
                            ),
                          );
                        },
                      ),
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
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Text(
                                  '📭 Geen nieuwe toestellen',
                                  style: AppTypography.body2,
                                ),
                              ),
                            ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, {required VoidCallback onPressed}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.title3.copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.circle),
          ),
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
            child: const Text('Meer'),
          ),
        ),
      ],
    );
  }
}

// Zoekbalk — tikt opent AllDevicesScreen met volledige zoek-/filteropties
class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AllDevicesScreen(title: 'Alle Toestellen'),
        ),
      ),
      child: AbsorbPointer(
        child: TextField(
          decoration: InputDecoration(
            filled: true,
            hintText: 'Zoeken naar apparaten...',
            hintStyle: const TextStyle(color: Colors.white60),
            fillColor: Colors.white.withValues(alpha: 0.15),
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            suffixIcon: const Icon(Icons.tune, color: Colors.white70),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

