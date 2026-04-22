import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reservation.dart';

class ReservationTile extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const ReservationTile({
    super.key,
    required this.reservation,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reservation.deviceTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                _StatusChip(status: reservation.status),
              ],
            ),
            const SizedBox(height: 6),
            if (onApprove != null)
              Text(
                'Huurder: ${reservation.tenantName}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            const SizedBox(height: 4),
            Text(
              '${fmt.format(reservation.startDate)} → ${fmt.format(reservation.endDate)}  (${reservation.durationDays} dag${reservation.durationDays != 1 ? 'en' : ''})',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              'Totaal: €${reservation.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            if (reservation.status == 'pending' &&
                (onApprove != null || onReject != null)) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Weigeren'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Goedkeuren'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'approved':
        bg = Colors.green[50]!;
        fg = Colors.green[700]!;
        label = 'Goedgekeurd';
        break;
      case 'rejected':
        bg = Colors.red[50]!;
        fg = Colors.red[700]!;
        label = 'Geweigerd';
        break;
      case 'completed':
        bg = Colors.grey[200]!;
        fg = Colors.grey[700]!;
        label = 'Voltooid';
        break;
      default:
        bg = Colors.orange[50]!;
        fg = Colors.orange[700]!;
        label = 'In behandeling';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
