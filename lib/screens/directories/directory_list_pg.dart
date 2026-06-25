import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_directory_page.dart';
import 'directory_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DirectoryListPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final bool isSuperAdmin;
  final bool isCustomer;

  const DirectoryListPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.isSuperAdmin = false,
    this.isCustomer = false,
  });

  @override
  State<DirectoryListPage> createState() => _DirectoryListPageState();
}

class _DirectoryListPageState extends State<DirectoryListPage> {
  String search = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      // ── AppBar ────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1008),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),

      // ── FAB ───────────────────────────────────────────────────────────
      floatingActionButton: widget.isCustomer
          ? null
          : FloatingActionButton(
              backgroundColor: const Color(0xFFE8651A),
              foregroundColor: Colors.white,
              elevation: 4,
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddDirectoryPage(
                      preselectedCategoryId: widget.categoryId,
                      isSuperAdmin: widget.isSuperAdmin,
                    ),
                  ),
                );

                if (result == true) setState(() {});
              },
              child: const Icon(Icons.add_rounded),
            ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: FirebaseAuth.instance.currentUser!.email)
            .limit(1)
            .get(),

        builder: (context, userSnap) {
          if (!userSnap.hasData || userSnap.data!.docs.isEmpty) {
            return const Center(child: Text('Admin not found'));
          }

          final userData =
              userSnap.data!.docs.first.data() as Map<String, dynamic>;

          final List assignedPanchayats = widget.isCustomer
              ? [
                  (userData['local_body'] ?? '')
                      .toString()
                      .replaceAll(' Panchayat', '')
                      .trim(),
                ]
              : userData['assignedPanchayats'] ?? [];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('directories')
                .where('categoryId', isEqualTo: widget.categoryId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00B4A6)),
                );
              }

              final allDocs = snapshot.data!.docs;

              List<QueryDocumentSnapshot> docs;

              if (widget.isSuperAdmin) {
                docs = List<QueryDocumentSnapshot>.from(allDocs);
              } else {
                docs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  print('Checking: ${data['name']} | ${data['panchayat']}');

                  final panchayat = (data['panchayat'] ?? '')
                      .toString()
                      .trim()
                      .toLowerCase();

                  final belongsToAdmin = assignedPanchayats.any(
                    (p) => p.toString().trim().toLowerCase() == panchayat,
                  );

                  if (search.isEmpty) {
                    return belongsToAdmin;
                  }

                  return panchayat.contains(search.toLowerCase());
                }).toList();
              }

              return Column(
                children: [
                  Container(
                    color: const Color(0xFF1C1008),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => search = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'Search directories…',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: search.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => search = '');
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

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${docs.length} ${docs.length == 1 ? 'entry' : 'entries'}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8A94A6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: docs.isEmpty
                        ? _EmptyState(isSearching: search.isNotEmpty)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: docs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final data =
                                  docs[index].data() as Map<String, dynamic>;

                              final canManage =
                                  widget.isSuperAdmin ||
                                  assignedPanchayats.any(
                                    (p) =>
                                        p.toString().trim().toLowerCase() ==
                                        (data['panchayat'] ?? '')
                                            .toString()
                                            .trim()
                                            .toLowerCase(),
                                  );

                              return _DirectoryCard(
                                data: data,
                                docId: docs[index].id,
                                categoryId: widget.categoryId,
                                isSuperAdmin: widget.isSuperAdmin,
                                isCustomer: widget.isCustomer,
                                canManage: canManage,
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ── Directory card ─────────────────────────────────────────────────────────
class _DirectoryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String categoryId;
  final bool isSuperAdmin;
  final bool isCustomer;
  final bool canManage;

  const _DirectoryCard({
    required this.data,
    required this.docId,
    required this.categoryId,
    required this.isSuperAdmin,
    required this.isCustomer,
    required this.canManage,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Entry',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Remove "${data['name'] ?? 'this entry'}" from the directory?',
          style: const TextStyle(color: Color(0xFF4A5568)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8A94A6)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('directories')
          .doc(docId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final phones = data['phones'] != null ? (data['phones'] as List) : [];
    final phone = phones.isNotEmpty ? phones.first.toString() : '';

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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DirectoryDetailsPage(
                data: data,
                directoryId: docId,
                canReview: false,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar / icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8651A).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.store_rounded,
                  color: Color(0xFF00B4A6),
                  size: 24,
                ),
              ),

              const SizedBox(width: 14),

              // Name, category, phone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1F36),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 3),

                    Text(
                      data['panchayat'] ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if ((data['category'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        data['category'].toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF00837A),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_rounded,
                            size: 12,
                            color: Color(0xFF8A94A6),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              phone,
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

              // Edit + Delete actions
              if (!isCustomer && canManage)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _IconBtn(
                      icon: Icons.edit_rounded,
                      color: const Color(0xFF1877F2),
                      bgColor: const Color(0xFF1877F2).withOpacity(0.10),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddDirectoryPage(
                            preselectedCategoryId: categoryId,
                            isSuperAdmin: isSuperAdmin,
                            directoryId: docId,
                            existingData: data,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _IconBtn(
                      icon: Icons.delete_rounded,
                      color: const Color(0xFFE53935),
                      bgColor: const Color(0xFFE53935).withOpacity(0.10),
                      onTap: () => _confirmDelete(context),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small icon button ──────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
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
            isSearching ? Icons.search_off_rounded : Icons.store_rounded,
            size: 64,
            color: const Color(0xFFD0D5DD),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No results found' : 'No entries yet',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8A94A6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearching
                ? 'Try a different search term'
                : 'Tap + to add the first entry',
            style: const TextStyle(fontSize: 13, color: Color(0xFFB0B7C3)),
          ),
        ],
      ),
    );
  }
}
