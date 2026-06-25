import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Colour palette per service category ────────────────────────────────────
const Map<String, Color> _categoryColor = {
  "AC Technician": Color(0xFF1E88E5),
  "Carpenter": Color(0xFF6D4C41),
  "Cleaner": Color(0xFF00ACC1),
  "Cook / Catering": Color(0xFFE53935),
  "Driver": Color(0xFF8E24AA),
  "Electrician": Color(0xFFFB8C00),
  "Event Organizer": Color(0xFFD81B60),
  "Gardener": Color(0xFF43A047),
  "Home Nurse": Color(0xFF00897B),
  "IT Services": Color(0xFF3949AB),
  "Mechanic": Color(0xFF546E7A),
  "Mobile Technician": Color(0xFF039BE5),
  "Painter": Color(0xFF7B1FA2),
  "Photographer": Color(0xFFF4511E),
  "Plumber": Color(0xFF00838F),
  "Tailor": Color(0xFFAD1457),
  "Tutor": Color(0xFF558B2F),
  "Welder": Color(0xFF37474F),
};

Color _colorFor(String title) =>
    _categoryColor[title] ?? const Color(0xFFFF6D00);

// ── Services list ───────────────────────────────────────────────────────────
const List<Map<String, dynamic>> _services = [
  {"title": "AC Technician", "icon": Icons.ac_unit},
  {"title": "Carpenter", "icon": Icons.handyman},
  {"title": "Cleaner", "icon": Icons.cleaning_services},
  {"title": "Cook / Catering", "icon": Icons.restaurant},
  {"title": "Driver", "icon": Icons.drive_eta},
  {"title": "Electrician", "icon": Icons.electrical_services},
  {"title": "Event Organizer", "icon": Icons.celebration},
  {"title": "Gardener", "icon": Icons.yard},
  {"title": "Home Nurse", "icon": Icons.local_hospital},
  {"title": "IT Services", "icon": Icons.computer},
  {"title": "Mechanic", "icon": Icons.car_repair},
  {"title": "Mobile Technician", "icon": Icons.phone_android},
  {"title": "Painter", "icon": Icons.format_paint},
  {"title": "Photographer", "icon": Icons.camera_alt},
  {"title": "Plumber", "icon": Icons.plumbing},
  {"title": "Tailor", "icon": Icons.content_cut},
  {"title": "Tutor", "icon": Icons.menu_book},
  {"title": "Welder", "icon": Icons.construction},
];

// ═══════════════════════════════════════════════════════════════════════════
//  ServicesPage
// ═══════════════════════════════════════════════════════════════════════════
class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  String _query = '';

  List<Map<String, dynamic>> get _filtered => _services
      .where(
        (s) =>
            s['title'].toString().toLowerCase().contains(_query.toLowerCase()),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      // ── App bar ──────────────────────────────────────────────────────────
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: const Text(
          "Community Services",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Search a service…",
                hintStyle: const TextStyle(color: Colors.black38),
                prefixIcon: const Icon(Icons.search, color: Colors.orange),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.black38),
                        onPressed: () => setState(() => _query = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),

      // ── Body ─────────────────────────────────────────────────────────────
      body: _filtered.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.black26),
                  SizedBox(height: 12),
                  Text(
                    "No services match your search",
                    style: TextStyle(color: Colors.black38, fontSize: 15),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: _filtered.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final svc = _filtered[index];
                return _ServiceTile(service: svc);
              },
            ),
    );
  }
}

// ── Service tile ─────────────────────────────────────────────────────────
class _ServiceTile extends StatelessWidget {
  final Map<String, dynamic> service;
  const _ServiceTile({required this.service});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(service['title']);
    final light = color.withOpacity(0.12);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: color.withOpacity(0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withOpacity(0.15),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceProvidersPage(profession: service['title']),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon bubble
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: light, shape: BoxShape.circle),
                child: Icon(service['icon'], size: 30, color: color),
              ),

              const SizedBox(height: 10),

              // Title
              Text(
                service['title'],
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: Color(0xFF1A1A2E),
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 6),

              // Live count badge
              _CountBadge(profession: service['title'], color: color),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Live count badge ─────────────────────────────────────────────────────
class _CountBadge extends StatelessWidget {
  final String profession;
  final Color color;
  const _CountBadge({required this.profession, required this.color});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('profession', isEqualTo: profession)
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.circle,
                size: 7,
                color: count > 0 ? color : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                count > 0 ? "$count Available" : "None Available",
                style: TextStyle(
                  color: count > 0 ? color : Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ServiceProvidersPage
// ═══════════════════════════════════════════════════════════════════════════
class ServiceProvidersPage extends StatelessWidget {
  final String profession;
  const ServiceProvidersPage({super.key, required this.profession});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(profession);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          profession,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('profession', isEqualTo: profession)
            .where('isApproved', isEqualTo: true)
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Loading
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: color));
          }

          final docs = snapshot.data!.docs;

          // Empty state
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: color.withOpacity(0.1),
                    child: Icon(Icons.person_search, size: 40, color: color),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No $profession found",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Check back later — providers join daily.",
                    style: TextStyle(color: Colors.black38, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _ProviderCard(data: data, color: color);
            },
          );
        },
      ),
    );
  }
}

// ── Provider card ────────────────────────────────────────────────────────
class _ProviderCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color color;
  const _ProviderCard({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? '—';
    final location = data['location'] as String? ?? '';
    final phone = data['phone'] as String? ?? '';

    // Initials avatar fallback
    final initials = name
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withOpacity(0.12),
              child: Text(
                initials,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 13,
                          color: Colors.black38,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 13,
                          color: Colors.black38,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          phone,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Call button
            GestureDetector(
              onTap: () async {
                if (phone.isNotEmpty) {
                  await launchUrl(Uri.parse('tel:$phone'));
                }
              },
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.call, color: Colors.green.shade600, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
