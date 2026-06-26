import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Result type metadata ────────────────────────────────────────────────────
class _TypeMeta {
  final String label;
  final IconData icon;
  final Color color;
  const _TypeMeta(this.label, this.icon, this.color);
}

const Map<String, _TypeMeta> _typeMeta = {
  'directory': _TypeMeta(
    'Directory',
    Icons.business_rounded,
    Color(0xFF1E88E5),
  ),
  'emergency': _TypeMeta(
    'Emergency',
    Icons.emergency_rounded,
    Color(0xFFE53935),
  ),
  'job': _TypeMeta('Job', Icons.work_rounded, Color(0xFFFF6D00)),
  'news': _TypeMeta('News', Icons.newspaper_rounded, Color(0xFF8E24AA)),
  'service': _TypeMeta(
    'Service',
    Icons.miscellaneous_services_rounded,
    Color(0xFF43A047),
  ),
  'other': _TypeMeta('Result', Icons.search_rounded, Color(0xFF78909C)),
};

_TypeMeta _meta(String type) =>
    _typeMeta[type.toLowerCase()] ?? _typeMeta['other']!;

// ── Result model ─────────────────────────────────────────────────────────────
class _Result {
  final String type;
  final String title;
  final String subtitle;
  final Map<String, dynamic> data;
  const _Result({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.data,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
//  GlobalSearchPage
// ═══════════════════════════════════════════════════════════════════════════
class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  List<_Result> _results = [];
  bool _loading = false;
  bool _searched = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ── Search ─────────────────────────────────────────────────────────────
  Future<void> _search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _searched = true;
    });

    final List<_Result> found = [];
    final List<_Result> categoryResults = [];

    try {
      // Directories
      final dirs = await FirebaseFirestore.instance
          .collection('directories')
          .get();

      for (final doc in dirs.docs) {
        final d = doc.data();

        final nameMatch = (d['name'] ?? '').toString().toLowerCase().contains(
          q,
        );

        final tagMatch = (d['tags'] ?? '').toString().toLowerCase().contains(q);

        final locationMatch =
            (d['district'] ?? '').toString().toLowerCase().contains(q) ||
            (d['panchayat'] ?? '').toString().toLowerCase().contains(q);

        final categoryMatch = (d['category'] ?? '')
            .toString()
            .toLowerCase()
            .contains(q);

        if (nameMatch || tagMatch || locationMatch) {
          found.add(
            _Result(
              type: 'directory',
              title: d['name'] ?? d['title'] ?? 'Directory',
              subtitle: [
                d['category'],
                d['district'],
              ].whereType<String>().join(' • '),
              data: d,
            ),
          );
        } else if (categoryMatch) {
          categoryResults.add(
            _Result(
              type: 'directory',
              title: d['name'] ?? d['title'] ?? 'Directory',
              subtitle: [
                d['category'],
                d['district'],
              ].whereType<String>().join(' • '),
              data: d,
            ),
          );
        }
      }
      // Emergency contacts
      final emg = await FirebaseFirestore.instance
          .collection('emergency_contacts')
          .get();
      for (final doc in emg.docs) {
        final d = doc.data();
        final match = [
          d['name'],
          d['number'],
        ].any((v) => v?.toString().toLowerCase().contains(q) == true);
        if (match) {
          found.add(
            _Result(
              type: 'emergency',
              title: d['name'] ?? 'Emergency Contact',
              subtitle: d['number']?.toString() ?? '',
              data: d,
            ),
          );
        }
      }

      // Jobs
      final jobs = await FirebaseFirestore.instance.collection('jobs').get();
      for (final doc in jobs.docs) {
        final d = doc.data();
        final match = [
          d['profession'],
          d['Company'],
          d['location'],
          d['name'],
        ].any((v) => v?.toString().toLowerCase().contains(q) == true);
        if (match) {
          found.add(
            _Result(
              type: 'job',
              title: d['profession'] ?? d['name'] ?? 'Job',
              subtitle: [
                d['Company'],
                d['location'],
              ].whereType<String>().join(' • '),
              data: d,
            ),
          );
        }
      }
    } catch (_) {
      found.addAll(categoryResults); // Silently handle errors; show empty state
    }

    found.sort((a, b) {
      final pa = (a.data['priority'] ?? 99) as int;
      final pb = (b.data['priority'] ?? 99) as int;
      return pa.compareTo(pb);
    });

    if (mounted) {
      setState(() {
        _results = found;
        _loading = false;
      });
    }
  }

  void _clear() {
    _ctrl.clear();
    setState(() {
      _results = [];
      _searched = false;
      _loading = false;
    });
    _focus.requestFocus();
  }

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Container(
          height: 42,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _search,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Search directories, jobs, emergency…',
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.orange,
                size: 20,
              ),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.black38,
                        size: 18,
                      ),
                      onPressed: _clear,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
            ),
          ),
        ),
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Loading
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 14),
            Text("Searching…", style: TextStyle(color: Colors.black38)),
          ],
        ),
      );
    }

    // Initial / empty query
    if (!_searched) {
      return _EmptyPrompt(
        icon: Icons.travel_explore_rounded,
        title: "Search Gramika",
        subtitle: "Find directories, emergency contacts,\njobs and more",
        chips: const ['Mechanic', 'Hospital', 'Plumber', 'Police'],
        onChipTap: (v) {
          _ctrl.text = v;
          _search(v);
        },
      );
    }

    // No results
    if (_results.isEmpty) {
      return _EmptyPrompt(
        icon: Icons.search_off_rounded,
        title: "No results found",
        subtitle: 'Try a different keyword\nor check the spelling',
      );
    }

    // Results
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Result count + filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Text(
            "${_results.length} result${_results.length == 1 ? '' : 's'} found",
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: _results.length,
            itemBuilder: (context, i) => _ResultCard(result: _results[i]),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Result card
// ═══════════════════════════════════════════════════════════════════════════
class _ResultCard extends StatelessWidget {
  final _Result result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final m = _meta(result.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: m.color.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: m.color.withOpacity(0.08),
          onTap: () {}, // hook up detail navigation here
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: m.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(m.icon, color: m.color, size: 22),
                ),

                const SizedBox(width: 14),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1A1A2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (result.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          result.subtitle,
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: m.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    m.label.toUpperCase(),
                    style: TextStyle(
                      color: m.color,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Empty / prompt state
// ═══════════════════════════════════════════════════════════════════════════
class _EmptyPrompt extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> chips;
  final void Function(String)? onChipTap;

  const _EmptyPrompt({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.chips = const [],
    this.onChipTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: Colors.orange),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black38,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (chips.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                "TRY SEARCHING",
                style: TextStyle(
                  color: Colors.black38,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: chips
                    .map(
                      (c) => ActionChip(
                        label: Text(
                          c,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: Colors.orange.withOpacity(0.08),
                        side: BorderSide(color: Colors.orange.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onPressed: () => onChipTap?.call(c),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
