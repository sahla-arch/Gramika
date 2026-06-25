import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackManagementPage extends StatelessWidget {
  const FeedbackManagementPage({super.key});

  static const _orange = Colors.orange;
  static const _bg = Color(0xFFF5F6FA);
  static const _dark = Color(0xFF1A1A2E);

  Color _ratingColor(int rating) {
    if (rating >= 4) return const Color(0xFF43A047);
    if (rating == 3) return const Color(0xFFFF6D00);
    return const Color(0xFFE53935);
  }

  String _ratingLabel(int rating) {
    if (rating >= 5) return 'Excellent';
    if (rating == 4) return 'Good';
    if (rating == 3) return 'Average';
    if (rating == 2) return 'Poor';
    return 'Very Poor';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Feedback Management',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('feedbacks')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            // Loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _orange),
                    SizedBox(height: 14),
                    Text(
                      'Loading feedbacks…',
                      style: TextStyle(color: Colors.black38, fontSize: 13),
                    ),
                  ],
                ),
              );
            }

            // Error
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          size: 34,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Something went wrong',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _dark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Could not load feedbacks.\nPlease check your connection.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black38,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            // Empty state
            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.rate_review_outlined,
                          size: 38,
                          color: _orange,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'No Feedbacks Yet',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: _dark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'User feedbacks will appear here\nonce citizens submit their reviews.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black38,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Summary bar
            final ratings = docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return (data['rating'] as num?)?.toInt() ?? 0;
            }).toList();
            final avg = ratings.isEmpty
                ? 0.0
                : ratings.reduce((a, b) => a + b) / ratings.length;

            return Column(
              children: [
                // ── Summary strip ──────────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    children: [
                      // Average rating
                      Expanded(
                        child: _SummaryTile(
                          icon: Icons.star_rounded,
                          iconColor: Colors.amber,
                          value: avg.toStringAsFixed(1),
                          label: 'Avg Rating',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: const Color(0xFFEEEEEE),
                      ),
                      // Total count
                      Expanded(
                        child: _SummaryTile(
                          icon: Icons.rate_review_rounded,
                          iconColor: _orange,
                          value: '${docs.length}',
                          label: 'Total Reviews',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: const Color(0xFFEEEEEE),
                      ),
                      // 5-star count
                      Expanded(
                        child: _SummaryTile(
                          icon: Icons.thumb_up_alt_rounded,
                          iconColor: const Color(0xFF43A047),
                          value: '${ratings.where((r) => r >= 4).length}',
                          label: 'Positive',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // ── List ───────────────────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final rating = (data['rating'] as num?)?.toInt() ?? 0;
                      final feedback =
                          (data['feedback'] as String?)?.trim() ?? '';
                      final userId = (data['userId'] as String?)?.trim() ?? '';
                      final ts = data['createdAt'] as Timestamp?;
                      final date = ts != null ? _formatDate(ts.toDate()) : '';

                      return _FeedbackCard(
                        rating: rating,
                        feedback: feedback,
                        userId: userId,
                        date: date,
                        ratingColor: _ratingColor(rating),
                        ratingLabel: _ratingLabel(rating),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ── Summary tile ─────────────────────────────────────────────────────────────
class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _SummaryTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black38),
        ),
      ],
    );
  }
}

// ── Feedback card ─────────────────────────────────────────────────────────────
class _FeedbackCard extends StatelessWidget {
  final int rating;
  final String feedback;
  final String userId;
  final String date;
  final Color ratingColor;
  final String ratingLabel;

  const _FeedbackCard({
    required this.rating,
    required this.feedback,
    required this.userId,
    required this.date,
    required this.ratingColor,
    required this.ratingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ratingColor.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: stars + badge ──────────────────────────────
            Row(
              children: [
                // Stars
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 20,
                      color: i < rating ? Colors.amber : Colors.black12,
                    );
                  }),
                ),

                const SizedBox(width: 8),

                // Rating label badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: ratingColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ratingLabel.toUpperCase(),
                    style: TextStyle(
                      color: ratingColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const Spacer(),

                // Date
                if (date.isNotEmpty)
                  Text(
                    date,
                    style: const TextStyle(fontSize: 11, color: Colors.black38),
                  ),
              ],
            ),

            // ── Feedback text ───────────────────────────────────────
            if (feedback.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                feedback,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A2E),
                  height: 1.55,
                ),
              ),
            ],

            // ── User row ────────────────────────────────────────────
            if (userId.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(height: 1, color: const Color(0xFFF0F0F0)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      userId.isNotEmpty ? userId[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      userId,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
