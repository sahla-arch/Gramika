import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';
import 'issue_details_page.dart';

class AdminIssuesPage extends StatefulWidget {
  const AdminIssuesPage({super.key});

  @override
  State<AdminIssuesPage> createState() => _AdminIssuesPageState();
}

class _AdminIssuesPageState extends State<AdminIssuesPage> {
  String _search = '';
  String _filter = 'All';
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _filters = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
    'Forwarded',
    'Resolved',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Update status + notify ───────────────────────────────────────────
  Future<void> updateStatus(String docId, String status, String userId) async {
    await FirebaseFirestore.instance.collection('issues').doc(docId).update({
      'status': status,
      'forwarded': status == 'Forwarded',
    });

    await NotificationService.sendNotification(
      userId: userId,
      title: 'Issue Updated',
      message: 'Your issue status changed to $status',
    );

    _showSnack('Marked as $status');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Status colour helpers ────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF2E7D32);
      case 'rejected':
        return const Color(0xFFE53935);
      case 'forwarded':
        return const Color(0xFF1877F2);
      case 'resolved':
        return const Color(0xFF6A0DAD);
      default:
        return const Color(0xFFE8651A);
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'forwarded':
        return Icons.forward_rounded;
      case 'resolved':
        return Icons.task_alt_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
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
          'Issues & Reports',
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
                  hintText: 'Search by title or description…',
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
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final sel = _filter == f;
                final col = f == 'All'
                    ? const Color(0xFFE8651A)
                    : _statusColor(f);

                return GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? col : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? col : const Color(0xFFE4E7EC),
                      ),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                color: col.withOpacity(0.25),
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
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          // ── List ───────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('issues')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE8651A)),
                  );
                }

                var docs = snapshot.data!.docs;

                // Status filter
                if (_filter != 'All') {
                  docs = docs.where((d) {
                    final s = ((d.data() as Map)['status'] ?? '')
                        .toString()
                        .toLowerCase();
                    return s == _filter.toLowerCase();
                  }).toList();
                }

                // Search filter
                if (_search.isNotEmpty) {
                  final q = _search.toLowerCase();
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return (data['title'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(q) ||
                        (data['description'] ?? '')
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
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final status = (data['status'] ?? 'Pending').toString();
                    final userId = (data['userId'] ?? '').toString();

                    return _IssueCard(
                      data: data,
                      docId: doc.id,
                      status: status,
                      userId: userId,
                      statusColor: _statusColor(status),
                      statusIcon: _statusIcon(status),
                      onTap: () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => IssueDetailsPage(
                            issueData: data,
                            issueId: doc.id,
                          ),
                        ),
                      ),
                      onUpdateStatus: (s) => updateStatus(doc.id, s, userId),
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

// ── Issue card ─────────────────────────────────────────────────────────────
class _IssueCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String status;
  final String userId;
  final Color statusColor;
  final IconData statusIcon;
  final VoidCallback onTap;
  final Future<void> Function(String) onUpdateStatus;

  const _IssueCard({
    required this.data,
    required this.docId,
    required this.status,
    required this.userId,
    required this.statusColor,
    required this.statusIcon,
    required this.onTap,
    required this.onUpdateStatus,
  });

  @override
  State<_IssueCard> createState() => _IssueCardState();
}

class _IssueCardState extends State<_IssueCard> {
  bool _actionsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final title = (widget.data['title'] ?? '').toString();
    final desc = (widget.data['description'] ?? '').toString();

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
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row ─────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.statusColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.report_rounded,
                      color: widget.statusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1008),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A94A6),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: widget.statusColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.statusIcon,
                          size: 11,
                          color: widget.statusColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          widget.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: widget.statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF0F1F5)),
              const SizedBox(height: 8),

              // ── Actions row ─────────────────────────────────────
              Row(
                children: [
                  const Text(
                    'Update status:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8A94A6),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _actionsExpanded = !_actionsExpanded),
                    child: Row(
                      children: [
                        Text(
                          _actionsExpanded ? 'Hide' : 'Actions',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE8651A),
                          ),
                        ),
                        AnimatedRotation(
                          turns: _actionsExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: Color(0xFFE8651A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Expandable action buttons ───────────────────────
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusBtn(
                        label: 'Approve',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF2E7D32),
                        active: widget.status.toLowerCase() == 'approved',
                        onTap: () => widget.onUpdateStatus('Approved'),
                      ),
                      _StatusBtn(
                        label: 'Reject',
                        icon: Icons.cancel_rounded,
                        color: const Color(0xFFE53935),
                        active: widget.status.toLowerCase() == 'rejected',
                        onTap: () => widget.onUpdateStatus('Rejected'),
                      ),
                      _StatusBtn(
                        label: 'Forward',
                        icon: Icons.forward_rounded,
                        color: const Color(0xFF1877F2),
                        active: widget.status.toLowerCase() == 'forwarded',
                        onTap: () => widget.onUpdateStatus('Forwarded'),
                      ),
                      _StatusBtn(
                        label: 'Resolve',
                        icon: Icons.task_alt_rounded,
                        color: const Color(0xFF6A0DAD),
                        active: widget.status.toLowerCase() == 'resolved',
                        onTap: () => widget.onUpdateStatus('Resolved'),
                      ),
                    ],
                  ),
                ),
                crossFadeState: _actionsExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status action button ───────────────────────────────────────────────────
class _StatusBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _StatusBtn({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: active ? color : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? color : color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: active ? Colors.white : color),
          const SizedBox(width: 5),
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
          isSearching ? 'No results found' : 'No issues found',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8A94A6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isSearching
              ? 'Try a different title or description'
              : 'Reported issues will appear here',
          style: const TextStyle(fontSize: 13, color: Color(0xFFB0B7C3)),
        ),
      ],
    ),
  );
}
