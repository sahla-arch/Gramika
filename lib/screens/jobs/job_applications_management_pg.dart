import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobApplicationsManagementPage extends StatefulWidget {
  const JobApplicationsManagementPage({super.key});

  @override
  State<JobApplicationsManagementPage> createState() =>
      _JobApplicationsManagementPageState();
}

class _JobApplicationsManagementPageState
    extends State<JobApplicationsManagementPage> {
  String _search = '';
  String _filter = 'All'; // All | Approved | Rejected | Pending
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance
        .collection('job_applications')
        .doc(docId)
        .update({'status': status});

    _showSnack(
      status == 'Approved' ? 'Application approved' : 'Application rejected',
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? const Color(0xFFE53935)
            : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1008),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Job Applications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),

      body: Column(
        children: [
          Container(height: 4, color: const Color(0xFFE8651A)),

          // ── Search bar ─────────────────────────────────────────────
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
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v.trim()),
                style: const TextStyle(fontSize: 14, color: Color(0xFF1C1008)),
                decoration: InputDecoration(
                  hintText: 'Search by name, job or company…',
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
                            _searchCtrl.clear();
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

          // ── Filter chips ───────────────────────────────────────────
          Container(
            color: const Color(0xFFF5F6FA),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Pending', 'Approved', 'Rejected'].map((f) {
                  final sel = _filter == f;
                  Color chipColor;
                  if (f == 'Approved')
                    chipColor = const Color(0xFF2E7D32);
                  else if (f == 'Rejected')
                    chipColor = const Color(0xFFE53935);
                  else
                    chipColor = const Color(0xFFE8651A);

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
                          color: sel ? chipColor : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel ? chipColor : const Color(0xFFE4E7EC),
                          ),
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                    color: chipColor.withOpacity(0.25),
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
                            color: sel ? Colors.white : const Color(0xFF8A94A6),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── List ───────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('job_applications')
                  .orderBy('appliedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE8651A)),
                  );
                }

                var docs = snapshot.data!.docs;

                // Filter by status
                if (_filter != 'All') {
                  docs = docs.where((d) {
                    final status = ((d.data() as Map)['status'] ?? '')
                        .toString()
                        .toLowerCase();
                    return status == _filter.toLowerCase();
                  }).toList();
                }

                // Search filter
                if (_search.isNotEmpty) {
                  final q = _search.toLowerCase();
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return (data['applicantName'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(q) ||
                        (data['jobTitle'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(q) ||
                        (data['company'] ?? '')
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final docId = docs[i].id;
                    final status = (data['status'] ?? 'Pending').toString();

                    return _ApplicationCard(
                      data: data,
                      status: status,
                      onApprove: () => _updateStatus(docId, 'Approved'),
                      onReject: () => _updateStatus(docId, 'Rejected'),
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

// ── Application card ───────────────────────────────────────────────────────
class _ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String status;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApplicationCard({
    required this.data,
    required this.status,
    required this.onApprove,
    required this.onReject,
  });

  Color get _statusColor {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF2E7D32);
      case 'rejected':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFFE8651A);
    }
  }

  IconData get _statusIcon {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (data['applicantName'] ?? '').toString();
    final job = (data['jobTitle'] ?? '').toString();
    final company = (data['company'] ?? '').toString();
    final phone = (data['phone'] ?? '').toString();

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
            // ── Top row ──────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar initials
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8651A).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE8651A),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1008),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        job,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE8651A),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (company.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.business_rounded,
                              size: 11,
                              color: Color(0xFF8A94A6),
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                company,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF8A94A6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_rounded,
                              size: 11,
                              color: Color(0xFF8A94A6),
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                phone,
                                style: const TextStyle(
                                  fontSize: 11,
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

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon, size: 12, color: _statusColor),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Action buttons ────────────────────────────────────
            if (status.toLowerCase() == 'pending' ||
                status.toLowerCase() == 'rejected' ||
                status.toLowerCase() == 'approved') ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF0F1F5)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ActionBtn(
                      label: 'Approve',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF2E7D32),
                      active: status.toLowerCase() == 'approved',
                      onTap: onApprove,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionBtn(
                      label: 'Reject',
                      icon: Icons.cancel_rounded,
                      color: const Color(0xFFE53935),
                      active: status.toLowerCase() == 'rejected',
                      onTap: onReject,
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

// ── Action button ──────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: active ? color : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? color : color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: active ? Colors.white : color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : color,
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Empty state ────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isSearching;
  const _EmptyState({required this.isSearching});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isSearching ? Icons.search_off_rounded : Icons.inbox_rounded,
          size: 64,
          color: Colors.grey.shade300,
        ),
        const SizedBox(height: 16),
        Text(
          isSearching ? 'No results found' : 'No applications yet',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8A94A6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isSearching
              ? 'Try a different name, job or company'
              : 'Applications will appear here',
          style: const TextStyle(fontSize: 13, color: Color(0xFFB0B7C3)),
        ),
      ],
    ),
  );
}
