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
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header met zoekbalk
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _SearchField(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Categorieën
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: _buildSectionTitle(context, 'Alle Categorieën', onPressed: () {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Geen extra Padding hier – CategoryChipRow heeft eigen interne padding
                  CategoryChipRow(
                    selectedCategory: deviceProvider.selectedCategory,
                    onSelected: deviceProvider.selectCategory,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Beschikbare Toestellen
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: _buildSectionTitle(
                      context,
                      'Beschikbare Toestellen',
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
              const SizedBox(height: AppSpacing.xl),

              // Recent Toegevoegd
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: _buildSectionTitle(
                      context,
                      'Recent Toegevoegd',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AllDevicesScreen(
                              title: 'Recent Toegevoegd',
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

  Widget _buildSectionTitle(BuildContext context, String title, {required VoidCallback onPressed}) {
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
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            hintText: 'Zoeken op naam, categorie of stad...',
            prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
          ),
        ),
      ),
    );
  }
}
