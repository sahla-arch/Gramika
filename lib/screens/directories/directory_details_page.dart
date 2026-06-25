import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DirectoryDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String directoryId;
  final bool canReview;

  const DirectoryDetailsPage({
    super.key,
    required this.data,
    required this.directoryId,
    this.canReview = true,
  });

  Future<void> launchLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showReviewDialog(BuildContext context, String directoryId) {
    final reviewController = TextEditingController();

    double rating = 5;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Write Review"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<double>(
                    value: rating,
                    items: [1, 2, 3, 4, 5]
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.toDouble(),
                            child: Text("$e Stars"),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        rating = v!;
                      });
                    },
                  ),

                  TextField(
                    controller: reviewController,
                    decoration: const InputDecoration(
                      hintText: "Write your review",
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;

                String userName = "Anonymous";

                if (user != null) {
                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get();

                  if (userDoc.exists) {
                    userName = userDoc.data()?['name'] ?? "Anonymous";
                  }
                }

                await FirebaseFirestore.instance
                    .collection('directory_reviews')
                    .add({
                      'directoryId': directoryId,
                      'name': userName,
                      'userId': user?.uid ?? '',
                      'rating': rating,
                      'review': reviewController.text,
                      'createdAt': Timestamp.now(),
                    });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Review submitted")),
                );
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage =
        data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty;
    final List phones = data['phones'] != null ? (data['phones'] as List) : [];
    final List tags = data['tags'] != null ? (data['tags'] as List) : [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          // ── Hero SliverAppBar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF1C1008),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image or placeholder
                  if (hasImage)
                    Builder(
                      builder: (context) {
                        try {
                          final imageData = data['imageUrl'].toString();
                          if (imageData.startsWith('http')) {
                            return Image.network(
                              imageData,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imagePlaceholder(),
                            );
                          }
                          return Image.memory(
                            base64Decode(imageData),
                            fit: BoxFit.cover,
                          );
                        } catch (_) {
                          return _imagePlaceholder();
                        }
                      },
                    )
                  else
                    _imagePlaceholder(),

                  // Gradient overlay
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC1A1F36)],
                        stops: [0.45, 1.0],
                      ),
                    ),
                  ),

                  // Name + category over image
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((data['category'] ?? '').toString().isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8651A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              data['category'].toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        Text(
                          data['name'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body content ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Phone + WhatsApp ───────────────────────────────────
                  if (phones.isNotEmpty ||
                      (data['whatsapp'] ?? '').toString().isNotEmpty)
                    _SectionCard(
                      children: [
                        if (phones.isNotEmpty)
                          _ActionTile(
                            icon: Icons.phone_rounded,
                            iconColor: const Color(0xFFE8651A),
                            label: 'Phone',
                            value: phones.join(', '),
                            onTap: () => launchLink('tel:${phones.first}'),
                          ),
                        if (phones.isNotEmpty &&
                            (data['whatsapp'] ?? '').toString().isNotEmpty)
                          const _RowDivider(),
                        if ((data['whatsapp'] ?? '').toString().isNotEmpty)
                          _ActionTile(
                            icon: Icons.chat_rounded,
                            iconColor: const Color(0xFF25D366),
                            label: 'WhatsApp',
                            value: data['whatsapp'].toString(),
                            onTap: () =>
                                launchLink('https://wa.me/${data['whatsapp']}'),
                          ),
                      ],
                    ),

                  const SizedBox(height: 14),
                  // ── Location────────────────────────────────────
                  if ((data['location'] ?? '').toString().isNotEmpty)
                    Column(
                      children: [
                        _SectionCard(
                          children: [
                            _ActionTile(
                              icon: Icons.location_on_rounded,
                              iconColor: const Color(0xFFE8651A),
                              label: 'Location',
                              value:
                                  '${data['location'].latitude.toStringAsFixed(5)}, '
                                  '${data['location'].longitude.toStringAsFixed(5)}',
                              onTap: () {
                                final lat = data['location'].latitude;
                                final lng = data['location'].longitude;

                                launchLink(
                                  'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=18/$lat/$lng',
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  // ── Email + Website ────────────────────────────────────
                  if ((data['email'] ?? '').toString().isNotEmpty ||
                      (data['website'] ?? '').toString().isNotEmpty)
                    _SectionCard(
                      children: [
                        if ((data['email'] ?? '').toString().isNotEmpty)
                          _ActionTile(
                            icon: Icons.email_rounded,
                            iconColor: const Color(0xFFE53935),
                            label: 'Email',
                            value: data['email'].toString(),
                            onTap: () =>
                                launchUrl(Uri.parse('mailto:${data['email']}')),
                          ),
                        if ((data['email'] ?? '').toString().isNotEmpty &&
                            (data['website'] ?? '').toString().isNotEmpty)
                          const _RowDivider(),
                        if ((data['website'] ?? '').toString().isNotEmpty)
                          _ActionTile(
                            icon: Icons.language_rounded,
                            iconColor: const Color(0xFF1C1008),
                            label: 'Website',
                            value: data['website'].toString(),
                            onTap: () {
                              String url = data['website'].toString();
                              if (!url.startsWith('http')) {
                                url = 'https://$url';
                              }
                              launchLink(url);
                            },
                          ),
                      ],
                    ),

                  const SizedBox(height: 14),

                  // ── Social ─────────────────────────────────────────────
                  if ((data['facebook'] ?? '').toString().isNotEmpty ||
                      (data['instagram'] ?? '').toString().isNotEmpty ||
                      (data['youtube'] ?? '').toString().isNotEmpty)
                    _SectionCard(
                      children: [
                        if ((data['facebook'] ?? '').toString().isNotEmpty)
                          _ActionTile(
                            icon: Icons.facebook_rounded,
                            iconColor: const Color(0xFF1877F2),
                            label: 'Facebook',
                            value: data['facebook'].toString(),
                            onTap: () =>
                                launchLink(data['facebook'].toString()),
                          ),
                        if ((data['facebook'] ?? '').toString().isNotEmpty &&
                            (data['instagram'] ?? '').toString().isNotEmpty)
                          const _RowDivider(),
                        if ((data['instagram'] ?? '').toString().isNotEmpty)
                          _ActionTile(
                            icon: Icons.camera_alt_rounded,
                            iconColor: const Color(0xFFE1306C),
                            label: 'Instagram',
                            value: data['instagram'].toString(),
                            onTap: () {
                              String username = data['instagram']
                                  .toString()
                                  .replaceAll('@', '');
                              launchLink('https://instagram.com/$username');
                            },
                          ),
                        if ((data['instagram'] ?? '').toString().isNotEmpty &&
                            (data['youtube'] ?? '').toString().isNotEmpty)
                          const _RowDivider(),
                        if ((data['youtube'] ?? '').toString().isNotEmpty)
                          _ActionTile(
                            icon: Icons.play_circle_fill_rounded,
                            iconColor: const Color(0xFFFF0000),
                            label: 'YouTube',
                            value: data['youtube'].toString(),
                            onTap: () {
                              final url = data['youtube'].toString();
                              if (url.isNotEmpty) launchLink(url);
                            },
                          ),
                      ],
                    ),

                  // ── Tags ───────────────────────────────────────────────
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    const Text(
                      'TAGS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8A94A6),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8651A).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE8651A).withOpacity(0.30),
                            ),
                          ),
                          child: Text(
                            tag.toString(),
                            style: const TextStyle(
                              color: Color(0xFF00837A),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 25),

                  if (canReview) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.star),
                        label: const Text("Write Review"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          _showReviewDialog(context, data['name'].toString());
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 20),

                  const Text(
                    "Reviews",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  ReviewSection(directoryId: data['name'].toString()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFF1C1008),
      child: const Center(
        child: Icon(Icons.store_rounded, size: 80, color: Color(0xFF3A4060)),
      ),
    );
  }
}

// ── Reusable card wrapper ──────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

// ── Single tappable row ────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8A94A6),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1F36),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFD0D5DD),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Thin separator ─────────────────────────────────────────────────────────
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 70,
      endIndent: 0,
      color: Color(0xFFF0F1F5),
    );
  }
}

class ReviewSection extends StatelessWidget {
  final String directoryId;

  const ReviewSection({super.key, required this.directoryId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('directory_reviews')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            "Error: ${snapshot.error}",
            style: const TextStyle(color: Colors.red),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['directoryId'] == directoryId;
        }).toList();

        if (reviews.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text("No reviews yet"),
          );
        }

        return Column(
          children: reviews.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child: const Icon(Icons.person, color: Colors.orange),
                ),
                title: Text(data['name'] ?? 'Anonymous'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("⭐ ${data['rating']}"),
                    Text(data['review'] ?? ''),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
