import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'directory_list_pg.dart';

class DirectoryPage extends StatelessWidget {
  final String? initialCategory;

  const DirectoryPage({super.key, this.initialCategory});

  // Maps Firestore "icon" key strings → IconData (matches the Quick
  // Directory preview on the home tab so icons stay consistent app-wide).
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
    'security_rounded': Icons.security_rounded,
    'light_mode_rounded': Icons.light_mode_rounded,
    'cleaning_services_rounded': Icons.cleaning_services_rounded,
    'local_shipping_rounded': Icons.local_shipping_rounded,
    'work_rounded': Icons.work_rounded,
    'shopping_cart_rounded': Icons.shopping_cart_rounded,
  };

  // Fallback palette cycled through when a category has no stored color,
  // so the grid never looks monochrome even with legacy data.
  static const List<Color> _palette = [
    Color(0xFFE8651A),
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
  ];

  IconData _resolveIcon(Map<String, dynamic> data) {
    final key = data['icon'] as String?;
    if (key != null && _iconMap.containsKey(key)) return _iconMap[key]!;
    return Icons.folder_rounded;
  }

  Color _resolveColor(Map<String, dynamic> data, int index) {
    final hex = data['colors'] as String?;
    if (hex != null && hex.isNotEmpty) {
      try {
        return Color(int.parse(hex));
      } catch (_) {
        // fall through to palette
      }
    }
    return _palette[index % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
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
                    Icons.grid_view_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  initialCategory ?? 'Directory',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: Color(0xFF1C1008),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('directory_categories')
                    .where('isActive', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE8651A),
                          strokeWidth: 2.5,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState();
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 4,
                          bottom: 14,
                          top: 8,
                        ),
                        child: Text(
                          'Browse all categories',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.15,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          final icon = _resolveIcon(data);
                          final color = _resolveColor(data, index);
                          final name = data['name'] as String? ?? '';

                          return _CategoryCard(
                            icon: icon,
                            color: color,
                            name: name,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DirectoryListPage(
                                    categoryId: docs[index].id,
                                    categoryName: name,
                                    isSuperAdmin: false,
                                    isCustomer: true,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
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
            'Could not load categories',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.folder_off_rounded, color: Colors.grey.shade300, size: 40),
          const SizedBox(height: 8),
          Text(
            'No categories yet',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String name;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.color,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: color.withOpacity(0.25), width: 1),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1008),
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
