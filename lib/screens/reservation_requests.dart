import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reservation.dart';
import '../providers/auth_provider.dart';
import '../providers/reservation_provider.dart';
import '../widgets/reservation_tile.dart';

class ReservationRequestsScreen extends StatelessWidget {
  const ReservationRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().user?.uid;
    if (uid == null) {
      return const Center(child: Text('Niet ingelogd.'));
    }

    return StreamBuilder<List<Reservation>>(
      stream: context.read<ReservationProvider>().ownerReservationsStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final reservations = snapshot.data ?? [];
        if (reservations.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'Geen binnenkomende aanvragen.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: reservations.length,
          itemBuilder: (context, index) {
            final res = reservations[index];
            return ReservationTile(
              reservation: res,
              onApprove: res.status == 'pending'
                  ? () => context
                      .read<ReservationProvider>()
                      .approveReservation(res.id, res.deviceId)
                  : null,
              onReject: res.status == 'pending'
                  ? () => context
                      .read<ReservationProvider>()
                      .rejectReservation(res.id, res.deviceId)
                  : null,
            );
          },
        );
      },
    );
  }
}
