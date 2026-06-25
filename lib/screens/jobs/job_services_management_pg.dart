import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'job_categories_page.dart';

class JobServicesManagementPage extends StatefulWidget {
  const JobServicesManagementPage({super.key});

  @override
  State<JobServicesManagementPage> createState() =>
      _JobServicesManagementPageState();
}

class _JobServicesManagementPageState extends State<JobServicesManagementPage> {
  String _filter = 'All'; // All | Approved | Pending
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Firestore actions ────────────────────────────────────────────────
  Future<void> _update(String docId, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('jobs').doc(docId).update(data);
  }

  Future<void> _delete(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Service',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Remove "${data['name'] ?? 'this service'}" permanently?',
          style: const TextStyle(color: Color(0xFF4A5568)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8A94A6)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance.collection('jobs').doc(docId).delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Service deleted'),
          backgroundColor: const Color(0xFF1C1008),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: const Color(0xFFE8651A),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('jobs')
                  .doc(docId)
                  .set(data);
            },
          ),
        ),
      );
    }
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Service Category"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Enter category name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final category = controller.text.trim();

                if (category.isEmpty) return;

                await FirebaseFirestore.instance
                    .collection('job_categories')
                    .add({'name': category, 'createdAt': Timestamp.now()});

                if (context.mounted) {
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Category added successfully'),
                    ),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Category"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Category Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              await FirebaseFirestore.instance.collection('job_categories').add(
                {'name': controller.text.trim(), 'createdAt': Timestamp.now()},
              );

              if (mounted) Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _editCategory(String docId, String oldName) async {
    final controller = TextEditingController(text: oldName);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Category"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('job_categories')
                  .doc(docId)
                  .update({'name': controller.text.trim()});

              if (mounted) Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(String docId) async {
    await FirebaseFirestore.instance
        .collection('job_categories')
        .doc(docId)
        .delete();
  }

  Future<void> _showCategoriesDialog() async {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          child: Container(
            width: 500,
            height: 500,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Service Categories",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addCategory,
                    ),
                  ],
                ),

                const Divider(),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('job_categories')
                        .orderBy('name')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;

                      if (docs.isEmpty) {
                        return const Center(child: Text("No Categories"));
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (_, index) {
                          final doc = docs[index];

                          return ListTile(
                            leading: const Icon(Icons.work),

                            title: Text(doc['name']),

                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {
                                    _editCategory(doc.id, doc['name']);
                                  },
                                ),

                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    _deleteCategory(doc.id);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      // ── AppBar ───────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1008),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Job Services',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JobCategoriesPage()),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddCategoryDialog();
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Orange accent strip ──────────────────────────────────────
          Container(height: 4, color: const Color(0xFFE8651A)),

          // ── Search bar ───────────────────────────────────────────────
          Container(
            color: const Color(0xFF1C1008),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _search = v.trim()),
                style: const TextStyle(fontSize: 14, color: Color(0xFF1C1008)),
                decoration: InputDecoration(
                  hintText: 'Search by name or profession…',
                  hintStyle: const TextStyle(
                    color: Color(0xFF8A94A6),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF8A94A6),
                    size: 20,
                  ),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF8A94A6),
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // ── Filter chips ─────────────────────────────────────────────
          Container(
            color: const Color(0xFFF5F6FA),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: ['All', 'Approved', 'Pending'].map((f) {
                final selected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFE8651A)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFE8651A)
                              : const Color(0xFFE4E7EC),
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFE8651A,
                                  ).withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF8A94A6),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── List ─────────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE8651A)),
                  );
                }

                var docs = snapshot.data!.docs;

                // Apply filter
                if (_filter == 'Approved') {
                  docs = docs
                      .where((d) => (d.data() as Map)['isApproved'] == true)
                      .toList();
                } else if (_filter == 'Pending') {
                  docs = docs
                      .where((d) => (d.data() as Map)['isApproved'] != true)
                      .toList();
                }

                // Apply search
                if (_search.isNotEmpty) {
                  final q = _search.toLowerCase();
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return (data['name'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(q) ||
                        (data['profession'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(q);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return _EmptyState(
                    isSearching: _search.isNotEmpty || _filter != 'All',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    final isApproved = data['isApproved'] ?? false;
                    final isActive = data['isActive'] ?? true;

                    return _JobCard(
                      data: data,
                      docId: docId,
                      isApproved: isApproved,
                      isActive: isActive,
                      onApprove: () => _update(docId, {'isApproved': true}),
                      onReject: () => _update(docId, {'isApproved': false}),
                      onToggleVisibility: () async {
                        await _update(docId, {'isActive': !isActive});
                        if (context.mounted) {
                          _showSnack(
                            context,
                            isActive ? 'Service hidden' : 'Service visible',
                          );
                        }
                      },
                      onDelete: () => _delete(context, docId, data),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Job card ───────────────────────────────────────────────────────────────
class _JobCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool isApproved;
  final bool isActive;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onToggleVisibility;
  final VoidCallback onDelete;

  const _JobCard({
    required this.data,
    required this.docId,
    required this.isApproved,
    required this.isActive,
    required this.onApprove,
    required this.onReject,
    required this.onToggleVisibility,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: avatar + name + menu ──────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8651A).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.work_rounded,
                    color: Color(0xFFE8651A),
                    size: 24,
                  ),
                ),

                const SizedBox(width: 12),

                // Name + profession
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1008),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data['profession'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE8651A),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if ((data['phone'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_rounded,
                              size: 11,
                              color: Color(0xFF8A94A6),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                data['phone'].toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8A94A6),
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

                // Popup menu
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF8A94A6),
                    size: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'approve') onApprove();
                    if (value == 'reject') onReject();
                    if (value == 'toggle') onToggleVisibility();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    _menuItem(
                      'approve',
                      Icons.check_circle_rounded,
                      'Approve',
                      const Color(0xFF2E7D32),
                    ),
                    _menuItem(
                      'reject',
                      Icons.cancel_rounded,
                      'Reject',
                      const Color(0xFFE53935),
                    ),
                    _menuItem(
                      'toggle',
                      isActive
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      isActive ? 'Hide' : 'Unhide',
                      const Color(0xFF1C1008),
                    ),
                    _menuItem(
                      'delete',
                      Icons.delete_rounded,
                      'Delete',
                      const Color(0xFFE53935),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Status badges ───────────────────────────────────────
            Row(
              children: [
                _StatusBadge(
                  label: isApproved ? 'Approved' : 'Pending',
                  color: isApproved
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFE8651A),
                  bgColor: isApproved
                      ? const Color(0xFF2E7D32).withOpacity(0.10)
                      : const Color(0xFFE8651A).withOpacity(0.10),
                  icon: isApproved
                      ? Icons.check_circle_rounded
                      : Icons.hourglass_top_rounded,
                ),
                const SizedBox(width: 8),
                _StatusBadge(
                  label: isActive ? 'Visible' : 'Hidden',
                  color: isActive
                      ? const Color(0xFF1877F2)
                      : const Color(0xFF8A94A6),
                  bgColor: isActive
                      ? const Color(0xFF1877F2).withOpacity(0.10)
                      : const Color(0xFF8A94A6).withOpacity(0.10),
                  icon: isActive
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label,
    Color color,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status badge ───────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isSearching;
  const _EmptyState({required this.isSearching});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching ? Icons.search_off_rounded : Icons.work_off_rounded,
            size: 64,
            color: const Color(0xFFD0D5DD),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No results found' : 'No services yet',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8A94A6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearching
                ? 'Try a different name or profession'
                : 'Job service listings will appear here',
            style: const TextStyle(fontSize: 13, color: Color(0xFFB0B7C3)),
          ),
        ],
      ),
    );
  }
}
