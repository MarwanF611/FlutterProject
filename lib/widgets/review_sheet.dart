import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/reservation.dart';
import '../models/review.dart';
import '../services/firestore_service.dart';

/// Opens a bottom sheet where the current user can rate the other party.
/// [revieweeId] is the person being rated.
void showReviewSheet(
  BuildContext context, {
  required Reservation reservation,
  required String reviewerId,
  required String reviewerName,
  required String revieweeId,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ReviewSheet(
      reservation: reservation,
      reviewerId: reviewerId,
      reviewerName: reviewerName,
      revieweeId: revieweeId,
    ),
  );
}

class ReviewSheet extends StatefulWidget {
  final Reservation reservation;
  final String reviewerId;
  final String reviewerName;
  final String revieweeId;

  const ReviewSheet({
    super.key,
    required this.reservation,
    required this.reviewerId,
    required this.reviewerName,
    required this.revieweeId,
  });

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Geef eerst een beoordeling (1–5 sterren).')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final review = Review(
        id: '',
        reviewerId: widget.reviewerId,
        reviewerName: widget.reviewerName,
        revieweeId: widget.revieweeId,
        reservationId: widget.reservation.id,
        deviceTitle: widget.reservation.deviceTitle,
        rating: _rating,
        comment: _commentCtrl.text.trim(),
        createdAt: DateTime.now(),
      );
      await FirestoreService().addReview(review);
      if (mounted) setState(() => _submitted = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Indienen mislukt. Probeer opnieuw.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: _submitted
          ? _SuccessView(onClose: () => Navigator.pop(context))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Beoordeel "${widget.reservation.deviceTitle}"',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Hoe was je ervaring?',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    return GestureDetector(
                      onTap: () => setState(() => _rating = star),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          star <= _rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 40,
                          color: star <= _rating
                              ? Colors.amber
                              : Colors.grey[400],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _commentCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Optionele opmerking…',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Indienen',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final VoidCallback onClose;
  const _SuccessView({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 56),
        const SizedBox(height: 12),
        const Text(
          'Bedankt voor je beoordeling!',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onClose,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Sluiten'),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
