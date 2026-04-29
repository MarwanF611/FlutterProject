import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/device.dart';
import '../providers/auth_provider.dart';
import '../providers/reservation_provider.dart';

const _heartSvg =
    '''<svg width="18" height="16" viewBox="0 0 18 16" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M16.5266 8.61383L9.27142 15.8877C9.12207 16.0374 8.87889 16.0374 8.72858 15.8877L1.47343 8.61383C0.523696 7.66069 0 6.39366 0 5.04505C0 3.69644 0.523696 2.42942 1.47343 1.47627C2.45572 0.492411 3.74438 0 5.03399 0C6.3236 0 7.61225 0.492411 8.59454 1.47627C8.81857 1.70088 9.18143 1.70088 9.40641 1.47627C11.3691 -0.491451 14.5629 -0.491451 16.5266 1.47627C17.4763 2.42846 18 3.69548 18 5.04505C18 6.39366 17.4763 7.66165 16.5266 8.61383Z" fill="#DBDEE4"/>
</svg>
''';

class DeviceDetailScreen extends StatefulWidget {
  final Device device;
  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isFav = false;
  bool _showFullDesc = false;
  final _fmt = DateFormat('dd/MM/yyyy');

  int get _days {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  double get _total => _days * widget.device.pricePerDay;

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? now : (_startDate ?? now),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _reserve() async {
    final auth = context.read<AuthProvider>();
    if (auth.appUser == null) return;
    final ok = await context.read<ReservationProvider>().reserve(
          device: widget.device,
          start: _startDate!,
          end: _endDate!,
          tenant: auth.appUser!,
        );
    if (!mounted) return;
    if (ok) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Aanvraag verzonden'),
          content: const Text(
              'Je reserveringsaanvraag is verstuurd naar de verhuurder.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<ReservationProvider>().error ??
              'Reservering mislukt.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final loading = context.watch<ReservationProvider>().loading;
    final canReserve =
        device.isAvailable && _startDate != null && _endDate != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: const Color(0xFFF5F6F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
              elevation: 0,
              backgroundColor: Colors.white,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 18,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text(
                    device.isAvailable ? 'Beschikbaar' : 'Niet beschikbaar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: device.isAvailable
                          ? AppColors.success
                          : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    device.isAvailable
                        ? Icons.check_circle
                        : Icons.cancel_outlined,
                    size: 14,
                    color: device.isAvailable
                        ? AppColors.success
                        : AppColors.textLight,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Hero image
          _DeviceImage(device: device),

          // White rounded layer — title, description
          _TopRoundedContainer(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row + heart
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Text(
                    device.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              '€${device.pricePerDay.toStringAsFixed(2)} / dag',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFF7643),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                const Icon(Icons.person_outline,
                                    size: 14, color: AppColors.textLight),
                                const SizedBox(width: 4),
                                Text(
                                  '${device.ownerName} · ${device.ownerCity}',
                                  style: AppTypography.body3,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  kCategoryIcons[device.category] ??
                                      Icons.devices_other,
                                  size: 14,
                                  color: AppColors.textLight,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  kCategoryLabels[device.category] ??
                                      device.category,
                                  style: AppTypography.body3,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Heart button (visual favourite toggle)
                    GestureDetector(
                      onTap: () => setState(() => _isFav = !_isFav),
                      child: Container(
                        margin: const EdgeInsets.only(top: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        width: 56,
                        decoration: BoxDecoration(
                          color: _isFav
                              ? const Color(0xFFFFE6E6)
                              : const Color(0xFFF5F6F9),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                        ),
                        child: SvgPicture.string(
                          _heartSvg,
                          colorFilter: ColorFilter.mode(
                            _isFav
                                ? const Color(0xFFFF4848)
                                : const Color(0xFFDBDEE4),
                            BlendMode.srcIn,
                          ),
                          height: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl),
                  child: Text(
                    device.description,
                    maxLines: _showFullDesc ? null : 3,
                    overflow: _showFullDesc ? null : TextOverflow.ellipsis,
                    style: const TextStyle(
                      height: 1.6,
                      color: AppColors.textMedium,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _showFullDesc = !_showFullDesc),
                    child: Row(
                      children: [
                        Text(
                          _showFullDesc ? 'Minder tonen' : 'Meer bekijken',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF7643),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showFullDesc
                              ? Icons.keyboard_arrow_up
                              : Icons.arrow_forward_ios,
                          size: 12,
                          color: const Color(0xFFFF7643),
                        ),
                      ],
                    ),
                  ),
                ),

                // Grey rounded layer — reservation
                _TopRoundedContainer(
                  color: const Color(0xFFF6F7F9),
                  child: device.isAvailable
                      ? _ReservationSection(
                          startDate: _startDate,
                          endDate: _endDate,
                          days: _days,
                          total: _total,
                          fmt: _fmt,
                          onPickStart: () => _pickDate(true),
                          onPickEnd: _startDate != null
                              ? () => _pickDate(false)
                              : null,
                        )
                      : const Padding(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: Text(
                            'Dit toestel is momenteel niet beschikbaar voor reservering.',
                            style: AppTypography.body2,
                            textAlign: TextAlign.center,
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Extra space so content clears the sticky bottom bar
          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: _TopRoundedContainer(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.md),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: canReserve
                    ? const Color(0xFFFF7643)
                    : Colors.grey[300],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              onPressed: canReserve && !loading ? _reserve : null,
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      device.isAvailable
                          ? (canReserve ? 'Reserveer' : 'Kies datums')
                          : 'Niet beschikbaar',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: canReserve ? Colors.white : Colors.grey[500],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared layout widgets ─────────────────────────────────────────────────────

class _TopRoundedContainer extends StatelessWidget {
  final Color color;
  final Widget child;

  const _TopRoundedContainer({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.only(top: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: child,
    );
  }
}

class _DeviceImage extends StatefulWidget {
  final Device device;
  const _DeviceImage({required this.device});

  @override
  State<_DeviceImage> createState() => _DeviceImageState();
}

class _DeviceImageState extends State<_DeviceImage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.device.imageUrls;
    final topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight + 16;

    if (images.isEmpty) {
      return SizedBox(
        height: 300 + topPadding,
        width: double.infinity,
        child: _placeholder(),
      );
    }

    return SizedBox(
      height: 300 + topPadding,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, i) {
              try {
                final bytes = base64Decode(images[i]);
                return Image.memory(bytes, fit: BoxFit.cover);
              } catch (_) {
                return _placeholder();
              }
            },
          ),
          // Dot indicator
          if (images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          // Image counter badge
          Positioned(
            top: topPadding - 8,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentPage + 1}/${images.length}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF0F0F0),
      child: const Icon(Icons.devices, size: 80, color: AppColors.textLight),
    );
  }
}

// ── Reservation section ───────────────────────────────────────────────────────

class _ReservationSection extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final int days;
  final double total;
  final DateFormat fmt;
  final VoidCallback onPickStart;
  final VoidCallback? onPickEnd;

  const _ReservationSection({
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.total,
    required this.fmt,
    required this.onPickStart,
    required this.onPickEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reserveringsperiode',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _DateBox(
                  label: 'Van',
                  value: startDate != null ? fmt.format(startDate!) : null,
                  onTap: onPickStart,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DateBox(
                  label: 'Tot',
                  value: endDate != null ? fmt.format(endDate!) : null,
                  onTap: onPickEnd,
                ),
              ),
            ],
          ),
          if (days > 0) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$days dag${days != 1 ? 'en' : ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMedium,
                  ),
                ),
                Text(
                  '€${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF7643),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback? onTap;

  const _DateBox({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: value != null
                ? const Color(0xFFFF7643)
                : AppColors.borderGrey,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textLight),
            ),
            const SizedBox(height: 2),
            Text(
              value ?? 'Kies datum',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: value != null
                    ? AppColors.textDark
                    : active
                        ? AppColors.textMedium
                        : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
