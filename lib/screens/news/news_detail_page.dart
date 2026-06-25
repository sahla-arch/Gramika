import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Tag colours ─────────────────────────────────────────────────────────────
const Map<String, Color> _tagColor = {
  'General': Color(0xFF546E7A),
  'Government': Color(0xFF1E88E5),
  'Education': Color(0xFF43A047),
  'Health': Color(0xFFE53935),
  'News': Color(0xFFFF6D00),
};
Color _tColor(String? t) => _tagColor[t] ?? const Color(0xFFFF6D00);

// ── Date formatter ──────────────────────────────────────────────────────────
String _formatDate(dynamic ts) {
  if (ts == null) return '';
  try {
    final dt = (ts as dynamic).toDate() as DateTime;
    const m = [
      '',
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
    return '${m[dt.month]} ${dt.day}, ${dt.year}';
  } catch (_) {
    return '';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  NewsDetailPage
// ═══════════════════════════════════════════════════════════════════════════
class NewsDetailPage extends StatelessWidget {
  final Map<String, dynamic> news;
  const NewsDetailPage({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    final title = (news['title'] as String? ?? '').trim();
    final fullDesc = (news['fullDescription'] as String? ?? '').trim();
    final shortDesc = (news['shortDescription'] as String? ?? '').trim();
    final coverImage = (news['coverImage'] as String? ?? '').trim();
    final tag = (news['tag'] as String? ?? 'News').trim();
    final source = (news['source'] as String? ?? '').trim();
    final date = _formatDate(news['createdAt']);
    final images = (news['images'] as List? ?? []).whereType<String>().toList();
    final ytLinks = (news['youtubeLinks'] as List? ?? [])
        .whereType<String>()
        .where((l) => l.isNotEmpty)
        .toList();
    final tColor = _tColor(tag);
    final bodyText = fullDesc.isNotEmpty
        ? fullDesc
        : (shortDesc.isNotEmpty ? shortDesc : 'No details available.');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      body: CustomScrollView(
        slivers: [
          // ── Hero app bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: coverImage.isNotEmpty ? 280 : 160,
            pinned: true,
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            title: const Text(
              'News Details',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: coverImage.isNotEmpty
                  ? Image.network(
                      coverImage,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, prog) {
                        if (prog == null) return child;
                        return Container(
                          color: Colors.orange.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => _coverPlaceholder(tColor),
                    )
                  : _coverPlaceholder(tColor),
            ),
          ),

          // ── Body content ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag + date row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: tColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: tColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.label_rounded, size: 11, color: tColor),
                            const SizedBox(width: 4),
                            Text(
                              '#$tag',
                              style: TextStyle(
                                color: tColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      if (date.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: Colors.black38,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              date,
                              style: const TextStyle(
                                color: Colors.black38,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                      height: 1.3,
                    ),
                  ),

                  // Source
                  if (source.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.link_rounded,
                          size: 13,
                          color: Colors.black38,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Source: $source',
                            style: const TextStyle(
                              color: Colors.black38,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 16),

                  // Body text
                  Text(
                    bodyText,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF3D3D3D),
                      height: 1.75,
                    ),
                  ),

                  // ── Related images ──────────────────────────────────
                  if (images.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _SectionLabel(label: 'Related Images'),
                    const SizedBox(height: 12),
                    ...images.map(
                      (img) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            img,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, prog) {
                              if (prog == null) return child;
                              return Container(
                                height: 180,
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.orange,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.black26,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // ── YouTube links ───────────────────────────────────
                  if (ytLinks.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _SectionLabel(label: 'Watch on YouTube'),
                    const SizedBox(height: 12),
                    ...ytLinks.map((link) => _YoutubeCard(link: link)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _coverPlaceholder(Color color) {
    return Container(
      color: color.withOpacity(0.12),
      child: Center(
        child: Icon(
          Icons.newspaper_rounded,
          size: 72,
          color: color.withOpacity(0.4),
        ),
      ),
    );
  }
}

// ── YouTube card ─────────────────────────────────────────────────────────
class _YoutubeCard extends StatelessWidget {
  final String link;
  const _YoutubeCard({required this.link});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(link);
        if (uri != null && uri.hasScheme) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.play_circle_fill_rounded,
                color: Colors.red.shade600,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Watch Video',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    link,
                    style: const TextStyle(color: Colors.black38, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.open_in_new_rounded,
              color: Colors.red.shade400,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: const TextStyle(
      color: Colors.black38,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
    ),
  );
}
