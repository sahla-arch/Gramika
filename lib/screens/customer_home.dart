import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '/screens/directories/directory_pg.dart';
import 'services_pg.dart';
import '/screens/profile/profile_pg.dart';
import '/screens/news/news_detail_page.dart';
import '/screens/directories/directory_list_pg.dart';
import '/screens/jobs/customer_job_vacancies_pg.dart';
import '/screens/reports_feedbacks/citizen_services_page.dart';
import 'package:url_launcher/url_launcher.dart';
import '/screens/reports_feedbacks/notification_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'global_search_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Root scaffold with bottom nav
// ─────────────────────────────────────────────────────────────────────────────
class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      HomeTab(),
      DirectoryPage(),
      ServicesPage(),
      CustomerJobVacanciesPage(),
      ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: _BottomNav(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

// ── Bottom nav ─────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(Icons.home_rounded, Icons.home_outlined, 'Home'),
    _NavItem(Icons.grid_view_rounded, Icons.grid_view_outlined, 'Directory'),
    _NavItem(Icons.build_rounded, Icons.build_outlined, 'Services'),
    _NavItem(Icons.work_rounded, Icons.work_outline_rounded, 'Vacancies'),
    _NavItem(Icons.person_rounded, Icons.person_outlined, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 68,
          child: Row(
            children: List.generate(_items.length, (i) {
              final sel = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          sel ? _items[i].activeIcon : _items[i].icon,
                          key: ValueKey(sel),
                          color: sel
                              ? const Color(0xFFE8651A)
                              : Colors.grey.shade400,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _items[i].label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                          color: sel
                              ? const Color(0xFFE8651A)
                              : Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 3,
                        width: sel ? 20 : 0,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8651A),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon;
  final IconData icon;
  final String label;
  const _NavItem(this.activeIcon, this.icon, this.label);
}

// ─────────────────────────────────────────────────────────────────────────────
// Home Tab
// ─────────────────────────────────────────────────────────────────────────────
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Future<void> _changePanchayat(String uid, String currentPanchayat) async {
    final panchayatSnap = await FirebaseFirestore.instance
        .collection('panchayats')
        .get();

    final panchayats = panchayatSnap.docs
        .map((e) => e['name'].toString())
        .toList();

    String selected = currentPanchayat;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Panchayat'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return DropdownButton<String>(
                value: selected,
                isExpanded: true,
                items: panchayats.map((p) {
                  return DropdownMenuItem(value: p, child: Text(p));
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selected = value!;
                  });
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, selected);
              },
              child: const Text("Continue"),
            ),
          ],
        );
      },
    );

    if (result == null || result == currentPanchayat) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Change"),
        content: Text(
          "Change your panchayat from '$currentPanchayat' to '$result'?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'local_body': '$result Panchayat',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Panchayat updated successfully")),
        );
      }

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildGreeting(context),
                const SizedBox(height: 28),
                _SectionHeader(title: 'Offers & Announcements'),
                const SizedBox(height: 12),
                const _AdsCarousel(),
                const SizedBox(height: 28),
                _SectionHeader(title: 'Quick Directory'),
                const SizedBox(height: 12),
                const _DirectoryPreview(),
                const SizedBox(height: 28),
                _SectionHeader(title: 'Emergency Contacts'),
                const SizedBox(height: 12),
                const _EmergencyGrid(),
                const SizedBox(height: 28),
                _SectionHeader(title: 'Citizen Services'),
                const SizedBox(height: 10),
                const _CitizenServicesCard(),
                const SizedBox(height: 28),
                const _SectionHeader(title: 'Latest News'),
                const SizedBox(height: 12),
                const _LatestNewsList(),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // Removed automatic leading back-arrow (this is the post-login home, no
  // route should be able to pop back to the login screen).
  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8651A), Color(0xFFB84A0E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.location_city_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Gramika',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: Color(0xFF1C1008),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GlobalSearchPage()),
            );
          },
        ),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where(
                'userId',
                isEqualTo: FirebaseAuth.instance.currentUser?.uid,
              )
              .snapshots(),
          builder: (context, snapshot) {
            final hasNotifications =
                snapshot.hasData && snapshot.data!.docs.isNotEmpty;

            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationPage(),
                      ),
                    );
                  },
                ),
                if (hasNotifications)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      height: 10,
                      width: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildGreeting(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

        final uid = snapshot.data!.id;

        final currentPanchayat = (data['local_body'] ?? '')
            .toString()
            .replaceAll(' Panchayat', '');

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE8651A), Color(0xFFB84A0E)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back! 👋',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              GestureDetector(
                onTap: () => _changePanchayat(uid, currentPanchayat),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        currentPanchayat,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: Color(0xFF1C1008),
      letterSpacing: -0.2,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Firestore helper
// ─────────────────────────────────────────────────────────────────────────────
Future<List<Map<String, dynamic>>> _firestoreFetch({
  required String collection,
  required String orderField,
  int limit = 20,
}) async {
  try {
    final snap = await FirebaseFirestore.instance
        .collection(collection)
        .orderBy(orderField, descending: true)
        .limit(limit)
        .get()
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Firestore timeout'),
        );
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  } catch (e) {
    debugPrint('[$collection] Error: $e');
    rethrow;
  }
}

// ── Shared states ──────────────────────────────────────────────────────────
Widget _buildLoading() => Center(
  child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: CircularProgressIndicator(
      color: const Color(0xFFE8651A),
      strokeWidth: 2.5,
    ),
  ),
);

Widget _buildError(VoidCallback onRetry) => Container(
  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Colors.grey.shade200),
  ),
  child: Column(
    children: [
      Icon(Icons.cloud_off_rounded, color: Colors.grey.shade400, size: 38),
      const SizedBox(height: 8),
      Text(
        'Could not load data',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Check your internet connection',
        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      ),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: onRetry,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8651A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Retry',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ],
  ),
);

Widget _buildEmpty(String message, IconData icon) => Container(
  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Colors.grey.shade200),
  ),
  child: Column(
    children: [
      Icon(icon, color: Colors.grey.shade300, size: 40),
      const SizedBox(height: 8),
      Text(
        message,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      ),
    ],
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// Ads Carousel
// ─────────────────────────────────────────────────────────────────────────────
class _AdsCarousel extends StatefulWidget {
  const _AdsCarousel();

  @override
  State<_AdsCarousel> createState() => _AdsCarouselState();
}

class _AdsCarouselState extends State<_AdsCarousel> {
  final PageController _ctrl = PageController(viewportFraction: 0.92);
  int _page = 0;
  Timer? _timer;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _firestoreFetch(
      collection: 'ads',
      orderField: 'createdAt',
      limit: 20,
    );
  }

  void _retry() => setState(_load);

  void _startAutoPlay(int count) {
    _timer?.cancel();
    if (count <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      _ctrl.animateToPage(
        (_page + 1) % count,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SizedBox(height: 190, child: _buildLoading());
        }
        if (snap.hasError) return _buildError(_retry);
        final ads = snap.data ?? [];
        if (ads.isEmpty) {
          return _buildEmpty('No ads available', Icons.campaign_rounded);
        }
        _startAutoPlay(ads.length);
        return Column(
          children: [
            SizedBox(
              height: 190,
              child: PageView.builder(
                controller: _ctrl,
                itemCount: ads.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _AdCard(data: ads[i]),
              ),
            ),
            if (ads.length > 1) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(ads.length, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFE8651A)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _AdCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AdCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final imgUrl = (data['imgUrl'] as String? ?? '').trim();
    final title = (data['title'] as String? ?? 'Advertisement').trim();
    final biz = (data['bussinessName'] as String? ?? '').trim();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _AdImage(imgUrl: imgUrl),
            // Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                  stops: [0.0, 0.6],
                ),
              ),
            ),
            // Content
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8651A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'AD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                  if (biz.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      biz,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
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

/// Handles HTTP URL, base64 string, and broken images cleanly
class _AdImage extends StatelessWidget {
  final String imgUrl;
  const _AdImage({required this.imgUrl});

  @override
  Widget build(BuildContext context) {
    if (imgUrl.isEmpty) return _fallback();

    if (imgUrl.startsWith('http')) {
      return Image.network(
        imgUrl,
        fit: BoxFit.cover,
        // no cacheWidth/cacheHeight — avoids cache codec issues
        errorBuilder: (_, __, ___) => _fallback(),
        loadingBuilder: (_, child, prog) {
          if (prog == null) return child;
          return Container(
            color: const Color(0xFFFFF3E0),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE8651A),
                strokeWidth: 2,
              ),
            ),
          );
        },
      );
    }

    // base64
    try {
      final bytes = base64Decode(imgUrl);
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (_) {
      return _fallback();
    }
  }

  Widget _fallback() => Container(
    color: const Color(0xFFFFF3E0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.campaign_rounded,
          color: const Color(0xFFE8651A).withOpacity(0.4),
          size: 44,
        ),
        const SizedBox(height: 8),
        Text(
          'Advertisement',
          style: TextStyle(
            color: const Color(0xFFE8651A).withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Directory Preview  — live from Firestore categories
// ─────────────────────────────────────────────────────────────────────────────
class _DirectoryPreview extends StatelessWidget {
  const _DirectoryPreview();

  // Map stored icon-key strings → IconData
  static const Map<String, IconData> _iconMap = {
    'school_rounded': Icons.school_rounded,
    'local_hospital_rounded': Icons.local_hospital_rounded,
    'directions_bus_rounded': Icons.directions_bus_rounded,
    'account_balance_rounded': Icons.account_balance_rounded,
    'store_rounded': Icons.store_rounded,
    'travel_explore_rounded': Icons.travel_explore_rounded,
    'restaurant_rounded': Icons.restaurant_rounded,
    'home_rounded': Icons.home_rounded,
    'directions_car_rounded': Icons.directions_car_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Browse Categories',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DirectoryPage()),
                ),
                child: Row(
                  children: [
                    Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFFE8651A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Color(0xFFE8651A),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Live categories from Firestore
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('directory_categories')
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return SizedBox(height: 88, child: _buildLoading());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return SizedBox(
                  height: 88,
                  child: Center(
                    child: Text(
                      'No categories yet',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final iconKey = d['icon'] as String? ?? 'store_rounded';
                    final colorHex = d['colors'] as String? ?? '0xFFE8651A';
                    final icon = _iconMap[iconKey] ?? Icons.store_rounded;
                    Color color;
                    try {
                      color = Color(int.parse(colorHex));
                    } catch (_) {
                      color = const Color(0xFFE8651A);
                    }
                    final name = d['name'] as String? ?? '';
                    final catId = docs[i].id;

                    return _DirectoryChip(
                      icon: icon,
                      label: name,
                      color: color,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DirectoryListPage(
                            categoryId: catId,
                            categoryName: name,
                            isSuperAdmin: false,
                            isCustomer: true,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

IconData _getFirestoreIcon(String iconName) {
  switch (iconName) {
    case 'local_police':
      return Icons.local_police;

    case 'emergency':
      return Icons.emergency;

    case 'local_fire_department':
      return Icons.local_fire_department;

    case 'woman':
      return Icons.woman;

    case 'child_care':
      return Icons.child_care;

    case 'electrical_services':
      return Icons.electrical_services;

    case 'water_drop':
      return Icons.water_drop;

    case 'local_hospital':
      return Icons.local_hospital;

    default:
      return Icons.phone;
  }
}

class _DirectoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _DirectoryChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.25), width: 1),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 7),
          SizedBox(
            width: 60,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _hexToColor(String? hex) {
  if (hex == null || hex.isEmpty) {
    return const Color(0xFFE8651A);
  }

  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return const Color(0xFFE8651A);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Emergency Grid
// ─────────────────────────────────────────────────────────────────────────────
class _EmergencyGrid extends StatelessWidget {
  const _EmergencyGrid();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('emergency_contacts')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(height: 80, child: _buildLoading());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return _buildEmpty(
            'No emergency contacts',
            Icons.phone_missed_rounded,
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.90,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return _EmergencyCard(
              title: d['name'] ?? '',
              number: d['number'] ?? '',
              icon: _getFirestoreIcon(d['icon'] ?? ''),
              color: _hexToColor(d['color'] as String?),
            );
          },
        );
      },
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  final String title;
  final String number;
  final IconData icon;
  final Color color;

  const _EmergencyCard({
    required this.title,
    required this.number,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final Uri phone = Uri(scheme: 'tel', path: number);

        await launchUrl(phone);
      },

      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),

              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: Color(0xFF1C1008),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                number,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Citizen Services — restyled to match the rest of the home UI
// ─────────────────────────────────────────────────────────────────────────────
class _CitizenServicesCard extends StatelessWidget {
  const _CitizenServicesCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CitizenServicesPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE8651A).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFE8651A).withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.miscellaneous_services_rounded,
                color: Color(0xFFE8651A),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Citizen Services',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C1008),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Apply, track, and manage requests',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFD0D5DD),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Latest News List
// ─────────────────────────────────────────────────────────────────────────────
class _LatestNewsList extends StatefulWidget {
  const _LatestNewsList();

  @override
  State<_LatestNewsList> createState() => _LatestNewsListState();
}

class _LatestNewsListState extends State<_LatestNewsList> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _firestoreFetch(
      collection: 'news',
      orderField: 'createdAt',
      limit: 10,
    );
  }

  void _retry() => setState(_load);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SizedBox(height: 120, child: _buildLoading());
        }
        if (snap.hasError) return _buildError(_retry);
        final news = snap.data ?? [];
        if (news.isEmpty) {
          return _buildEmpty('No news yet', Icons.newspaper_rounded);
        }

        return Column(
          children: news.map((item) {
            return _NewsCard(
              item: item,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NewsDetailPage(news: item)),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _NewsCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  const _NewsCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final coverImage = (item['coverImage'] as String? ?? '').trim();
    final title = (item['title'] as String? ?? '').trim();
    final tag = (item['tag'] as String? ?? '').trim();
    final createdAt = item['createdAt'];
    String timeStr = '';
    if (createdAt is Timestamp) {
      timeStr = timeago.format(createdAt.toDate());
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 100,
                height: 90,
                child: _NewsImage(coverImage: coverImage),
              ),
            ),

            // Text content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (tag.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8651A).withOpacity(0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE8651A),
                              ),
                            ),
                          ),
                        if (tag.isNotEmpty && timeStr.isNotEmpty)
                          const SizedBox(width: 6),
                        if (timeStr.isNotEmpty)
                          Flexible(
                            child: Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1008),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFD0D5DD),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Safe news thumbnail — handles base64, HTTP, and broken
class _NewsImage extends StatelessWidget {
  final String coverImage;
  const _NewsImage({required this.coverImage});

  @override
  Widget build(BuildContext context) {
    if (coverImage.isEmpty) return _fallback();

    if (coverImage.startsWith('http')) {
      return Image.network(
        coverImage,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
        loadingBuilder: (_, child, prog) {
          if (prog == null) return child;
          return Container(color: const Color(0xFFFFF3E0));
        },
      );
    }

    try {
      return Image.memory(
        base64Decode(coverImage),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    } catch (_) {
      return _fallback();
    }
  }

  Widget _fallback() => Container(
    color: const Color(0xFFFFF3E0),
    child: Center(
      child: Icon(
        Icons.newspaper_rounded,
        color: const Color(0xFFE8651A).withOpacity(0.35),
        size: 28,
      ),
    ),
  );
}
