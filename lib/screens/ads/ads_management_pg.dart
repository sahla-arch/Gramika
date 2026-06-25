import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_ads_pg.dart';
import 'edit_ads_pg.dart';

class AdsManagementPage extends StatelessWidget {
  const AdsManagementPage({super.key});

  static const _orange = Color(0xFFFF6B00);
  static const _orangeLight = Color(0xFFFFF3EB);
  static const _bg = Color(0xFFF5F4F0);

  // ── Delete dialog ─────────────────────────────────────────────
  Future<void> _confirmDelete(
    BuildContext context,
    String docId,
    String title,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.red.shade500,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete Ad',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete "$title"? This cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade500,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('ads').doc(docId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildList(context)),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _orangeLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: _orange,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_orange, Color(0xFFFF4500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ads Management',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.3,
                  ),
                ),
                const Text(
                  'Admin Panel',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey),
                ),
              ],
            ),
          ),
          // Live count
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('ads').snapshots(),
            builder: (_, snap) {
              final count = snap.data?.docs.length ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _orangeLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count ads',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _orange,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── List ──────────────────────────────────────────────────────
  Widget _buildList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ads')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _orange, strokeWidth: 2.5),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  color: Colors.grey.shade400,
                  size: 44,
                ),
                const SizedBox(height: 10),
                Text(
                  'Could not load ads',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.campaign_rounded,
                  color: Colors.grey.shade300,
                  size: 56,
                ),
                const SizedBox(height: 14),
                const Text(
                  'No Ads Yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap + to create your first ad',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _AdCard(
              docId: doc.id,
              data: data,
              onDelete: () =>
                  _confirmDelete(context, doc.id, data['title'] ?? 'Ad'),
              onEdit: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditAdsPage(adsId: doc.id, ads: data),
                ),
              ),
              onToggle: (val) => FirebaseFirestore.instance
                  .collection('ads')
                  .doc(doc.id)
                  .update({'isActive': val}),
            );
          },
        );
      },
    );
  }

  // ── FAB ───────────────────────────────────────────────────────
  Widget _buildFAB(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddAdsPage()),
      ),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_orange, Color(0xFFFF4500)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _orange.withOpacity(0.45),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

// ── Ad Card ───────────────────────────────────────────────────────
class _AdCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final void Function(bool) onToggle;

  const _AdCard({
    required this.docId,
    required this.data,
    required this.onDelete,
    required this.onEdit,
    required this.onToggle,
  });

  static const _orange = Color(0xFFFF6B00);
  static const _orangeLight = Color(0xFFFFF3EB);

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? '';
    final businessName = data['bussinessName'] as String? ?? '';
    final imgUrl = data['imgUrl'] as String? ?? '';
    final isActive = data['isActive'] as bool? ?? true;
    final phone = data['phone'] as String? ?? '';
    final websiteUrl = data['websiteUrl'] as String? ?? '';
    final validFrom = data['validFrom'] as Timestamp?;
    final validTo = data['validTo'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Image banner ──
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: _buildImage(imgUrl),
          ),

          // ── Content ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + active badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          if (businessName.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.store_rounded,
                                  size: 12,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  businessName,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? Colors.green.shade600
                              : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Validity dates
                if (validFrom != null || validTo != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _orangeLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.date_range_rounded,
                          size: 13,
                          color: Colors.orange.shade600,
                        ),
                        const SizedBox(width: 6),
                        if (validFrom != null)
                          Text(
                            _formatDate(validFrom.toDate()),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        if (validFrom != null && validTo != null)
                          Text(
                            '  →  ',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        if (validTo != null)
                          Text(
                            _formatDate(validTo.toDate()),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),

                // Phone / website chips
                if (phone.isNotEmpty || websiteUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (phone.isNotEmpty)
                        _infoPill(
                          Icons.phone_rounded,
                          phone,
                          Colors.blue.shade50,
                          Colors.blue.shade700,
                        ),
                      if (websiteUrl.isNotEmpty)
                        _infoPill(
                          Icons.language_rounded,
                          websiteUrl.length > 28
                              ? '${websiteUrl.substring(0, 28)}…'
                              : websiteUrl,
                          Colors.purple.shade50,
                          Colors.purple.shade700,
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),

                // Divider
                Divider(height: 1, color: Colors.grey.shade100),

                // Action row
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      // Active toggle
                      Row(
                        children: [
                          Switch(
                            value: isActive,
                            onChanged: onToggle,
                            activeColor: Colors.green.shade600,
                            activeTrackColor: Colors.green.shade100,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          Text(
                            isActive ? 'Live' : 'Off',
                            style: TextStyle(
                              fontSize: 12,
                              color: isActive
                                  ? Colors.green.shade600
                                  : Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Edit button
                      _actionBtn(
                        icon: Icons.edit_rounded,
                        label: 'Edit',
                        color: const Color(0xFF1565C0),
                        bg: const Color(0xFFE3F2FD),
                        onTap: onEdit,
                      ),
                      const SizedBox(width: 8),
                      // Delete button
                      _actionBtn(
                        icon: Icons.delete_rounded,
                        label: 'Delete',
                        color: Colors.red.shade600,
                        bg: Colors.red.shade50,
                        onTap: onDelete,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imgUrl) {
    // imgUrl from Firestore is a Cloudinary URL (https://)
    if (imgUrl.isNotEmpty && imgUrl.startsWith('http')) {
      return Image.network(
        imgUrl,
        width: double.infinity,
        height: 160,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 160,
            color: Colors.orange.shade50,
            child: const Center(
              child: CircularProgressIndicator(color: _orange, strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _imageFallback(),
      );
    }

    // Legacy base64 stored image (coverImage field)
    final base64Str = data['coverImage'] as String? ?? '';
    if (base64Str.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(base64Str),
          width: double.infinity,
          height: 160,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imageFallback(),
        );
      } catch (_) {
        return _imageFallback();
      }
    }

    return _imageFallback();
  }

  Widget _imageFallback() => Container(
    height: 160,
    color: _orangeLight,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_rounded, color: Colors.orange.shade300, size: 40),
          const SizedBox(height: 6),
          Text(
            'No Image',
            style: TextStyle(
              color: Colors.orange.shade400,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _infoPill(IconData icon, String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  static const _months = [
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
}
