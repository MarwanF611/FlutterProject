import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
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
    
    // Bepaal accentkleur op basis van status
    Color accentColor;
    String icon;
    switch (reservation.status) {
      case 'approved':
        accentColor = Colors.green;
        icon = '✅';
        break;
      case 'rejected':
        accentColor = Colors.red;
        icon = '❌';
        break;
      case 'completed':
        accentColor = Colors.grey;
        icon = '✔️';
        break;
      default:
        accentColor = Colors.orange;
        icon = '⏳';
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accentColor.withValues(alpha: 0.3), width: 1.5),
      ),
      elevation: 2,
      shadowColor: accentColor.withValues(alpha: 0.1),
      child: Stack(
        children: [
          // Left accent border
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 5,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reservation.deviceTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (onApprove != null)
                            Text(
                              'Van: ${reservation.tenantName}',
                              style: AppTypography.body3,
                            ),
                        ],
                      ),
                    ),
                    _StatusChip(status: reservation.status),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month, size: 16, color: accentColor),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '${fmt.format(reservation.startDate)} → ${fmt.format(reservation.endDate)}',
                          style: AppTypography.body3,
                        ),
                      ),
                      Text(
                        '${reservation.durationDays} dag${reservation.durationDays != 1 ? 'en' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '€${reservation.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'per ${reservation.durationDays} dag',
                      style: AppTypography.body3,
                    ),
                  ],
                ),
                if (reservation.status == 'pending' &&
                    (onApprove != null || onReject != null)) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onReject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
                              borderRadius: BorderRadius.circular(10),
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
        ],
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
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
