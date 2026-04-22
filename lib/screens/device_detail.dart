import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../providers/auth_provider.dart';
import '../providers/reservation_provider.dart';
import '../widgets/loading_button.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Device device;
  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
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
          content: Text(
              context.read<ReservationProvider>().error ?? 'Reservering mislukt.'),
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
      appBar: AppBar(
        title: Text(device.title),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 240,
              width: double.infinity,
              child: device.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: device.imageUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: const Color(0xFFF0F0F0),
                      child: const Icon(Icons.devices, size: 80, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          device.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: device.isAvailable
                              ? Colors.green[50]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          device.isAvailable ? 'Beschikbaar' : 'Niet beschikbaar',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: device.isAvailable
                                ? Colors.green[700]
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '€${device.pricePerDay.toStringAsFixed(2)} / dag',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${device.ownerName} · ${device.ownerCity}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.category_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        device.category[0].toUpperCase() +
                            device.category.substring(1),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Beschrijving',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(device.description, style: const TextStyle(height: 1.5)),
                  if (device.isAvailable) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Reserveringsperiode',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _DateButton(
                            label: 'Startdatum',
                            value: _startDate != null
                                ? _fmt.format(_startDate!)
                                : null,
                            onTap: () => _pickDate(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateButton(
                            label: 'Einddatum',
                            value: _endDate != null
                                ? _fmt.format(_endDate!)
                                : null,
                            onTap: _startDate != null ? () => _pickDate(false) : null,
                          ),
                        ),
                      ],
                    ),
                    if (_days > 0) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Totaal: €${_total.toStringAsFixed(2)} ($_days dag${_days != 1 ? 'en' : ''})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    LoadingButton(
                      label: 'Reserveer',
                      isLoading: loading,
                      onPressed: canReserve ? _reserve : null,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback? onTap;

  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value ?? 'Kies datum',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: value != null ? Colors.black87 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
