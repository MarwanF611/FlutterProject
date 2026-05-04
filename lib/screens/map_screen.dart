import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/device.dart';
import '../providers/device_provider.dart';
import 'device_detail.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Position? _userPosition;
  bool _locationDenied = false;
  bool _loadingLocation = true;
  Device? _selectedDevice;

  // Belgium center fallback
  static const LatLng _belgiumCenter = LatLng(50.5039, 4.4699);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationDenied = true;
            _loadingLocation = false;
          });
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 8));
      if (mounted) {
        setState(() {
          _userPosition = position;
          _loadingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationDenied = true;
          _loadingLocation = false;
        });
      }
    }
  }

  void _centerOnUser() {
    if (_userPosition != null) {
      _mapController.move(
        LatLng(_userPosition!.latitude, _userPosition!.longitude),
        14,
      );
    }
  }

  void _showDeviceBottomSheet(Device device) {
    setState(() => _selectedDevice = device);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.borderGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    kCategoryIcons[device.category] ?? Icons.devices_other,
                    size: 22,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(device.title, style: AppTypography.title2),
                      Text(
                        kCategoryLabels[device.category] ?? device.category,
                        style: AppTypography.body2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(device.ownerCity, style: AppTypography.body3),
                const Spacer(),
                Text(
                  '€${device.pricePerDay.toStringAsFixed(2)} / dag',
                  style: AppTypography.price,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DeviceDetailScreen(device: device),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: const Text('Bekijk details'),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() => setState(() => _selectedDevice = null));
  }

  List<Marker> _buildMarkers(List<Device> devices) {
    return devices
        .where((d) => d.lat != null && d.lng != null)
        .map((d) {
          final isSelected = _selectedDevice?.id == d.id;
          return Marker(
            point: LatLng(d.lat!, d.lng!),
            width: isSelected ? 56 : 44,
            height: isSelected ? 56 : 44,
            child: GestureDetector(
              onTap: () => _showDeviceBottomSheet(d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: (isSelected ? AppColors.accent : AppColors.primary)
                          .withValues(alpha:0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  kCategoryIcons[d.category] ?? Icons.devices_other,
                  color: Colors.white,
                  size: isSelected ? 26 : 20,
                ),
              ),
            ),
          );
        })
        .toList();
  }

  Widget _buildDeniedView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off, size: 64, color: AppColors.textLight),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Locatietoegang geweigerd.\nKaart is niet beschikbaar.',
            style: AppTypography.body2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: Geolocator.openAppSettings,
            child: const Text('Instellingen openen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingLocation) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_locationDenied) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kaart'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: _buildDeniedView(),
      );
    }

    final initialCenter = _userPosition != null
        ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
        : _belgiumCenter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kaart'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Device>>(
        stream: context.watch<DeviceProvider>().devicesStream,
        builder: (context, snapshot) {
          final devices = snapshot.data ?? [];
          final markers = _buildMarkers(devices);

          // User location marker
          if (_userPosition != null) {
            markers.add(
              Marker(
                point: LatLng(
                    _userPosition!.latitude, _userPosition!.longitude),
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha:0.4),
                        blurRadius: 8,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: 13,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.flutter_project',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),

              // Device count badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.circle),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha:0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.place, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${devices.where((d) => d.lat != null && d.lng != null).length} producten in de buurt',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // My location button
              if (_userPosition != null)
                Positioned(
                  bottom: 24,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: _centerOnUser,
                    child: const Icon(Icons.my_location,
                        color: AppColors.primary),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
