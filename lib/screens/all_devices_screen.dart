import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/device.dart';
import '../providers/device_provider.dart';
import 'device_detail.dart';

const _heartSvg =
    '''<svg width="18" height="16" viewBox="0 0 18 16" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M16.5266 8.61383L9.27142 15.8877C9.12207 16.0374 8.87889 16.0374 8.72858 15.8877L1.47343 8.61383C0.523696 7.66069 0 6.39366 0 5.04505C0 3.69644 0.523696 2.42942 1.47343 1.47627C2.45572 0.492411 3.74438 0 5.03399 0C6.3236 0 7.61225 0.492411 8.59454 1.47627C8.81857 1.70088 9.18143 1.70088 9.40641 1.47627C11.3691 -0.491451 14.5629 -0.491451 16.5266 1.47627C17.4763 2.42846 18 3.69548 18 5.04505C18 6.39366 17.4763 7.66165 16.5266 8.61383Z" fill="#DBDEE4"/>
</svg>
''';

class AllDevicesScreen extends StatefulWidget {
  final String title;
  final bool recentOnly;

  const AllDevicesScreen({
    super.key,
    required this.title,
    this.recentOnly = false,
  });

  @override
  State<AllDevicesScreen> createState() => _AllDevicesScreenState();
}

class _AllDevicesScreenState extends State<AllDevicesScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _sort = 'newest';
  double? _radiusKm;
  bool _showMap = false;
  Position? _userPosition;
  final MapController _mapController = MapController();

  static const _radii = [5.0, 10.0, 25.0, 50.0];
  static const _belgiumCenter = LatLng(50.5039, 4.4699);

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
      () => setState(() => _search = _searchCtrl.text.toLowerCase().trim()),
    );
    _loadLocation();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 8));
      if (mounted) setState(() => _userPosition = pos);
    } catch (_) {}
  }

  List<Device> _filter(List<Device> all) {
    var list = all.toList();

    if (widget.recentOnly) {
      list = list
          .where((d) => DateTime.now().difference(d.createdAt).inDays <= 7)
          .toList();
    }

    if (_search.isNotEmpty) {
      list = list
          .where(
            (d) =>
                d.title.toLowerCase().contains(_search) ||
                d.description.toLowerCase().contains(_search) ||
                d.ownerCity.toLowerCase().contains(_search),
          )
          .toList();
    }

    if (_radiusKm != null && _userPosition != null) {
      list = list.where((d) {
        if (d.lat == null || d.lng == null) return false;
        final dist = Geolocator.distanceBetween(
          _userPosition!.latitude,
          _userPosition!.longitude,
          d.lat!,
          d.lng!,
        );
        return dist <= _radiusKm! * 1000;
      }).toList();
    }

    switch (_sort) {
      case 'priceAsc':
        list.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
        break;
      case 'priceDesc':
        list.sort((a, b) => b.pricePerDay.compareTo(a.pricePerDay));
        break;
      default:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return list;
  }

  void _openDevice(BuildContext ctx, Device device) {
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => DeviceDetailScreen(device: device)),
    );
  }

  void _showDeviceSheet(Device device) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.title, style: AppTypography.title2),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  kCategoryIcons[device.category] ?? Icons.devices_other,
                  size: 16,
                  color: AppColors.textMedium,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  kCategoryLabels[device.category] ?? device.category,
                  style: AppTypography.body2,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '€${device.pricePerDay.toStringAsFixed(2)} / dag',
              style: AppTypography.price,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _openDevice(context, device);
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
                child: const Text('Bekijk'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.grid_view : Icons.map_outlined),
            tooltip: _showMap ? 'Rasterweergave' : 'Kaartweergave',
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: StreamBuilder<List<Device>>(
              stream: context.watch<DeviceProvider>().devicesStream,
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final devices = _filter(snapshot.data ?? []);
                if (devices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 64,
                            color: Colors.grey.withValues(alpha: 0.4)),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Geen toestellen gevonden',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }
                return _showMap
                    ? _buildMap(devices)
                    : _buildGrid(ctx, devices);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Zoeken...',
              hintStyle: const TextStyle(color: AppColors.textLight),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textLight),
              filled: true,
              fillColor: AppColors.primaryDark.withValues(alpha: 0.08),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _Chip(
                    label: 'Nieuwste',
                    selected: _sort == 'newest',
                    onTap: () => setState(() => _sort = 'newest')),
                const SizedBox(width: AppSpacing.sm),
                _Chip(
                    label: 'Prijs ↑',
                    selected: _sort == 'priceAsc',
                    onTap: () => setState(() => _sort = 'priceAsc')),
                const SizedBox(width: AppSpacing.sm),
                _Chip(
                    label: 'Prijs ↓',
                    selected: _sort == 'priceDesc',
                    onTap: () => setState(() => _sort = 'priceDesc')),
                const SizedBox(width: AppSpacing.lg),
                _Chip(
                    label: 'Alles',
                    selected: _radiusKm == null,
                    onTap: () => setState(() => _radiusKm = null)),
                const SizedBox(width: AppSpacing.sm),
                for (final r in _radii) ...[
                  _Chip(
                    label: '${r.toInt()} km',
                    selected: _radiusKm == r,
                    onTap: _userPosition != null
                        ? () => setState(() => _radiusKm = r)
                        : null,
                    disabled: _userPosition == null,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext ctx, List<Device> devices) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: devices.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.68,
        mainAxisSpacing: 20,
        crossAxisSpacing: 16,
      ),
      itemBuilder: (context, i) => _DeviceProductCard(
        device: devices[i],
        onPress: () => _openDevice(ctx, devices[i]),
      ),
    );
  }

  Widget _buildMap(List<Device> devices) {
    final center = _userPosition != null
        ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
        : _belgiumCenter;

    final markers = devices
        .where((d) => d.lat != null && d.lng != null)
        .map(
          (d) => Marker(
            point: LatLng(d.lat!, d.lng!),
            width: 44,
            height: 44,
            child: GestureDetector(
              onTap: () => _showDeviceSheet(d),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  kCategoryIcons[d.category] ?? Icons.devices_other,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        )
        .toList();

    // Add user location marker
    if (_userPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
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
            initialCenter: center,
            initialZoom: markers.isEmpty ? 10 : 11,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.flutter_project',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        if (markers.isEmpty)
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Text(
                'Geen toestellen met locatiedata beschikbaar op de kaart.',
                textAlign: TextAlign.center,
                style: AppTypography.body2,
              ),
            ),
          ),
        if (_userPosition != null)
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () => _mapController.move(
                LatLng(_userPosition!.latitude, _userPosition!.longitude),
                14,
              ),
              child: const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  const _Chip({
    required this.label,
    required this.selected,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : disabled
                  ? Colors.grey.withValues(alpha: 0.08)
                  : const Color(0xFF979797).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.circle),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected
                ? Colors.white
                : disabled
                    ? Colors.grey.withValues(alpha: 0.4)
                    : AppColors.textMedium,
          ),
        ),
      ),
    );
  }
}

class _DeviceProductCard extends StatefulWidget {
  final Device device;
  final VoidCallback onPress;

  const _DeviceProductCard({required this.device, required this.onPress});

  @override
  State<_DeviceProductCard> createState() => _DeviceProductCardState();
}

class _DeviceProductCardState extends State<_DeviceProductCard> {
  bool _isFav = false;

  Widget _buildImage(String url) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stack) =>
            const Icon(Icons.devices, color: AppColors.textLight, size: 40),
      );
    }
    try {
      return Image.memory(
        base64Decode(url),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } catch (_) {
      return const Icon(Icons.devices, color: AppColors.textLight, size: 40);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.02,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: const Color(0xFF979797).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: widget.device.imageUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: _buildImage(widget.device.imageUrls.first),
                    )
                  : const Icon(Icons.devices, color: AppColors.textLight, size: 40),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.device.title,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '€${widget.device.pricePerDay.toStringAsFixed(2)}/dag',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF7643),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.circle),
                onTap: () => setState(() => _isFav = !_isFav),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(
                    color: _isFav
                        ? const Color(0xFFFF7643).withValues(alpha: 0.15)
                        : const Color(0xFF979797).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.string(
                    _heartSvg,
                    colorFilter: ColorFilter.mode(
                      _isFav
                          ? const Color(0xFFFF4848)
                          : const Color(0xFFDBDEE4),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
