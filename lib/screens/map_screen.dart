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
  double _searchRadius = 10.0; // in km
  bool _popupShownOnce = false; // Track if popup was already shown

  // Belgium center fallback
  static const LatLng _belgiumCenter = LatLng(50.5039, 4.4699);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  void _checkAndShowDevicesInRadius(List<Device> devices) {
    // Only show popup once per session
    if (_popupShownOnce) return;
    
    final filteredDevices = _userPosition != null
        ? devices.where((d) {
            if (d.lat == null || d.lng == null) return false;
            final dist = Geolocator.distanceBetween(
              _userPosition!.latitude,
              _userPosition!.longitude,
              d.lat!,
              d.lng!,
            );
            return dist <= _searchRadius * 1000;
          }).toList()
        : <Device>[];

    if (filteredDevices.isNotEmpty && _userPosition != null && mounted) {
      _popupShownOnce = true;
      _showDevicesInRadius(filteredDevices);
    }
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

      // Try to get position with longer timeout for web
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 15), // Longer timeout
        ),
      );
      if (mounted) {
        setState(() {
          _userPosition = position;
          _loadingLocation = false;
        });
      }
    } catch (e) {
      // More specific error handling
      debugPrint('Location error: $e');
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

  void _showRadiusSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      backgroundColor: Colors.white,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const Text('Zoekradius instellen', style: AppTypography.title2),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '${_searchRadius.toStringAsFixed(0)} km',
                style: AppTypography.body1,
              ),
              Slider(
                value: _searchRadius,
                min: 1,
                max: 50,
                divisions: 49,
                label: '${_searchRadius.toStringAsFixed(0)} km',
                onChanged: (value) {
                  setState(() => _searchRadius = value);
                  this.setState(() {});
                },
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text('Toepassen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                    color: AppColors.primary.withValues(alpha: 0.1),
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
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.textLight,
                ),
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
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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

  void _showDevicesInRadius(List<Device> devices) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      backgroundColor: Colors.white,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                '🎯 Toestellen binnen ${_searchRadius.toStringAsFixed(0)} km',
                style: AppTypography.title2,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${devices.length} apparaat${devices.length == 1 ? '' : 'ten'} gevonden',
                style: AppTypography.body2.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: devices.isEmpty
                    ? Center(
                        child: Text(
                          'Er zijn geen apparaten binnen de geselecteerde radius.',
                          style: AppTypography.body2,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        controller: controller,
                        itemCount: devices.length,
                        separatorBuilder: (context, separatorIndex) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          final distanceMeters =
                              _userPosition != null &&
                                  device.lat != null &&
                                  device.lng != null
                              ? Geolocator.distanceBetween(
                                  _userPosition!.latitude,
                                  _userPosition!.longitude,
                                  device.lat!,
                                  device.lng!,
                                )
                              : 0.0;
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              side: BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            elevation: 2,
                            shadowColor: AppColors.primary.withValues(alpha: 0.1),
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DeviceDetailScreen(device: device),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primary.withValues(alpha: 0.15),
                                            AppColors.primary.withValues(alpha: 0.05),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.md,
                                        ),
                                      ),
                                      child: Icon(
                                        kCategoryIcons[device.category] ??
                                            Icons.devices_other,
                                        color: AppColors.primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            device.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 12,
                                                color: AppColors.textLight,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                '${device.ownerCity} • ${distanceMeters ~/ 1000} km',
                                                style: AppTypography.body3,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '€${device.pricePerDay.toStringAsFixed(2)} / dag',
                                            style: AppTypography.price.copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Marker> _buildMarkers(List<Device> devices) {
    final filteredDevices = _userPosition != null
        ? devices.where((d) {
            if (d.lat == null || d.lng == null) return false;
            final dist = Geolocator.distanceBetween(
              _userPosition!.latitude,
              _userPosition!.longitude,
              d.lat!,
              d.lng!,
            );
            return dist <= _searchRadius * 1000;
          }).toList()
        : devices.where((d) => d.lat != null && d.lng != null).toList();

    return filteredDevices.map((d) {
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
                      .withValues(alpha: 0.4),
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
    }).toList();
  }

  Widget _buildDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: 64, color: AppColors.textLight),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Locatietoegang is nodig voor de kaart',
              style: AppTypography.title2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Om apparaten in de buurt te zien, moet je locatie toegang toestaan. '
              'Vernieuw de pagina en accepteer de locatie toestemming in je browser.',
              style: AppTypography.body2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            // Only show settings button on mobile platforms
            if (Theme.of(context).platform == TargetPlatform.android ||
                Theme.of(context).platform == TargetPlatform.iOS)
              TextButton(
                onPressed: Geolocator.openAppSettings,
                child: const Text('Instellingen openen'),
              )
            else
              ElevatedButton(
                onPressed: () {
                  // For web, just retry location
                  setState(() {
                    _locationDenied = false;
                    _loadingLocation = true;
                  });
                  _initLocation();
                },
                child: const Text('Opnieuw proberen'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingLocation) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
          final allDevices = snapshot.data ?? [];

          if (!_popupShownOnce && allDevices.isNotEmpty && _userPosition != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _checkAndShowDevicesInRadius(allDevices);
            });
          }

          final filteredDevices = _userPosition != null
              ? allDevices.where((d) {
                  if (d.lat == null || d.lng == null) return false;
                  final dist = Geolocator.distanceBetween(
                    _userPosition!.latitude,
                    _userPosition!.longitude,
                    d.lat!,
                    d.lng!,
                  );
                  return dist <= _searchRadius * 1000;
                }).toList()
              : allDevices
                    .where((d) => d.lat != null && d.lng != null)
                    .toList();
          final markers = _buildMarkers(filteredDevices);

          // User location marker
          if (_userPosition != null) {
            markers.add(
              Marker(
                point: LatLng(
                  _userPosition!.latitude,
                  _userPosition!.longitude,
                ),
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.4),
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
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.circle),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.place, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${filteredDevices.length} producten ${_userPosition != null ? "binnen ${_searchRadius.toStringAsFixed(0)} km" : "in de buurt"}',
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

              if (filteredDevices.isNotEmpty)
                Positioned(
                  top: 64,
                  left: 12,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.circle),
                      ),
                    ),
                    icon: const Icon(Icons.list, size: 18),
                    label: const Text('Toon lijst'),
                    onPressed: () => _showDevicesInRadius(filteredDevices),
                  ),
                ),

              // My location button
              if (_userPosition != null)
                Positioned(
                  bottom: 24,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: _showRadiusSettings,
                        child: const Icon(
                          Icons.settings,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: _centerOnUser,
                        child: const Icon(
                          Icons.my_location,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
