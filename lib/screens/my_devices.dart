import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/device.dart';
import '../providers/auth_provider.dart';
import '../providers/device_provider.dart';

class MyDevicesScreen extends StatelessWidget {
  const MyDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.user?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Niet ingelogd.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mijn toestellen'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add-device'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Toestel toevoegen'),
      ),
      body: StreamBuilder<List<Device>>(
        stream: context.read<DeviceProvider>().ownerDevicesStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final devices = snapshot.data ?? [];
          if (devices.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_box_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Je hebt nog geen toestellen toegevoegd.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return _DeviceOwnerTile(device: device);
            },
          );
        },
      ),
    );
  }
}

class _DeviceOwnerTile extends StatelessWidget {
  final Device device;
  const _DeviceOwnerTile({required this.device});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DeviceProvider>();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(
            Icons.devices,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          device.title,
          style: AppTypography.title3,
        ),
        subtitle: Text(
          '€${device.pricePerDay.toStringAsFixed(2)} / dag',
          style: AppTypography.body3,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: device.isAvailable,
              onChanged: (v) =>
                  provider.toggleAvailability(device.id, device.isAvailable),
              activeThumbColor: AppColors.success,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _confirmDelete(context, provider),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, DeviceProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Toestel verwijderen?'),
        content: Text('Weet je zeker dat je "${device.title}" wilt verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.removeDevice(device.id, device.imageUrl);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );
  }
}
