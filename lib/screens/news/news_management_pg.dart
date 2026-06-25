import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_news_pg.dart';
import 'edit_news_pg.dart';

// ── Theme constants ─────────────────────────────────────────────────────────
const _kAccent = Color(0xFFE8651A);
const _kDark = Color(0xFF1C1008);
const _kBg = Color(0xFFF5F6FA);
const _kMuted = Color(0xFF8A94A6);

// ── Tag colours ─────────────────────────────────────────────────────────────
const Map<String, Color> _tagColor = {
  'General': Color(0xFF546E7A),
  'Government': Color(0xFF1E88E5),
  'Education': Color(0xFF43A047),
  'Health': Color(0xFFE53935),
};
Color _tColor(String? t) => _tagColor[t] ?? _kAccent;

// ═══════════════════════════════════════════════════════════════════════════
//  NewsManagementPage
// ═══════════════════════════════════════════════════════════════════════════
class NewsManagementPage extends StatefulWidget {
  const NewsManagementPage({super.key});

  @override
  State<NewsManagementPage> createState() => _NewsManagementPageState();
}

class _NewsManagementPageState extends State<NewsManagementPage> {
  String _filterTag = 'All';
  static const _tags = ['All', 'General', 'Government', 'Education', 'Health'];

  // ── Snack ────────────────────────────────────────────────────────────────
  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(child: Text(msg)),
            ],
          ),
          backgroundColor: isError
              ? const Color(0xFFE53935)
              : const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ── Toggle active ────────────────────────────────────────────────────────
  Future<void> _toggleActive(String docId, bool current) async {
    try {
      await FirebaseFirestore.instance.collection('news').doc(docId).update({
        'isActive': !current,
      });
    } catch (e) {
      _snack('Failed to update: $e', isError: true);
    }
  }

  // ── Delete confirm ───────────────────────────────────────────────────────
  Future<void> _confirmDelete(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.red.shade50,
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete News?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 8),
              const Text(
                'This news item will be permanently removed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black45, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.bold),
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
      try {
        await FirebaseFirestore.instance.collection('news').doc(docId).delete();
        _snack('News deleted');
      } catch (e) {
        _snack('Delete failed: $e', isError: true);
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,

      appBar: AppBar(
        backgroundColor: _kDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'News Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(height: 4, color: _kAccent),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add News',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddNewsPage()),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('news')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Loading
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _kAccent),
            );
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Something went wrong',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            );
          }

          final allDocs = snapshot.data!.docs;

          // Filter by tag
          final docs = _filterTag == 'All'
              ? allDocs
              : allDocs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return (data['tag'] ?? '') == _filterTag;
                }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stats bar ──────────────────────────────────────────
              Container(
                color: _kDark,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    _StatChip(
                      label: 'Total',
                      count: allDocs.length,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      label: 'Active',
                      count: allDocs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return data['isActive'] == true;
                      }).length,
                      color: Colors.greenAccent,
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      label: 'Hidden',
                      count: allDocs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return data['isActive'] != true;
                      }).length,
                      color: Colors.orangeAccent,
                    ),
                  ],
                ),
              ),

              // ── Filter chips ───────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _tags.map((t) {
                      final selected = _filterTag == t;
                      final tColor = t == 'All' ? _kAccent : _tColor(t);
                      return GestureDetector(
                        onTap: () => setState(() => _filterTag = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? tColor : tColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? tColor
                                  : tColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : tColor,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // ── Count label ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Text(
                  '${docs.length} ${docs.length == 1 ? 'article' : 'articles'}',
                  style: const TextStyle(
                    color: _kMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // ── List ───────────────────────────────────────────────
              Expanded(
                child: docs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: _kAccent.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.newspaper_rounded,
                                color: _kAccent,
                                size: 34,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No news found',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _kDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _filterTag == 'All'
                                  ? 'Tap + Add News to get started'
                                  : 'No articles tagged "$_filterTag"',
                              style: const TextStyle(
                                color: _kMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _NewsCard(
                            data: data,
                            docId: doc.id,
                            onToggle: () =>
                                _toggleActive(doc.id, data['isActive'] ?? true),
                            onEdit: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditNewsPage(newsId: doc.id, news: data),
                              ),
                            ),
                            onDelete: () => _confirmDelete(context, doc.id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  News card
// ═══════════════════════════════════════════════════════════════════════════
class _NewsCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NewsCard({
    required this.data,
    required this.docId,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = data['isActive'] ?? true;
    final tag = data['tag'] as String?;
    final tColor = _tColor(tag);
    final coverImage = (data['coverImage'] ?? '').toString();
    final hasImage = coverImage.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accent bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: tColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: hasImage
                        ? Image.network(
                            coverImage,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, prog) {
                              if (prog == null) return child;
                              return Container(
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: _kAccent,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade100,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: Colors.black26,
                              ),
                            ),
                          )
                        : Container(
                            color: _kAccent.withOpacity(0.08),
                            child: const Icon(
                              Icons.newspaper_rounded,
                              color: _kAccent,
                              size: 30,
                            ),
                          ),
                  ),
                ),

                const SizedBox(width: 12),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: tColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag ?? 'General',
                          style: TextStyle(
                            color: tColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(height: 5),

                      // Title
                      Text(
                        data['title'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _kDark,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Short description
                      Text(
                        data['shortDescription'] ?? '',
                        style: const TextStyle(
                          color: _kMuted,
                          fontSize: 12,
                          height: 1.4,
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

          // Divider
          const Divider(height: 1, color: Color(0xFFF0F1F5)),

          // Footer: toggle + actions
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            child: Row(
              children: [
                // Active status
                Icon(
                  isActive
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  size: 14,
                  color: isActive ? Colors.green : _kMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  isActive ? 'Published' : 'Hidden',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.green : _kMuted,
                  ),
                ),

                const Spacer(),

                // Toggle switch
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: isActive,
                    onChanged: (_) => onToggle(),
                    activeColor: _kAccent,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),

                // Edit button
                _ActionBtn(
                  icon: Icons.edit_outlined,
                  color: _kAccent,
                  onTap: onEdit,
                ),

                // Delete button
                _ActionBtn(
                  icon: Icons.delete_outline_rounded,
                  color: Colors.red,
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small action icon button ─────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }
}

// ── Stats chip ───────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
