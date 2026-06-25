import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobVacanciesManagementPage extends StatefulWidget {
  const JobVacanciesManagementPage({super.key});

  @override
  State<JobVacanciesManagementPage> createState() =>
      _JobVacanciesManagementPageState();
}

class _JobVacanciesManagementPageState
    extends State<JobVacanciesManagementPage> {
  final titleCtrl = TextEditingController();
  final companyCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final salaryCtrl = TextEditingController();
  final contactCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    titleCtrl.dispose();
    companyCtrl.dispose();
    locationCtrl.dispose();
    salaryCtrl.dispose();
    contactCtrl.dispose();
    descCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearForm() {
    titleCtrl.clear();
    companyCtrl.clear();
    locationCtrl.clear();
    salaryCtrl.clear();
    contactCtrl.clear();
    descCtrl.clear();
  }

  // ── Add vacancy ──────────────────────────────────────────────────────
  Future<void> addVacancy() async {
    if (titleCtrl.text.trim().isEmpty || companyCtrl.text.trim().isEmpty) {
      _showSnack('Job title and company are required', isError: true);
      return;
    }
    setState(() => _isSaving = true);

    await FirebaseFirestore.instance.collection('job_vacancies').add({
      'title': titleCtrl.text.trim(),
      'company': companyCtrl.text.trim(),
      'location': locationCtrl.text.trim(),
      'salary': salaryCtrl.text.trim(),
      'contact': contactCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'isActive': true,
      'createdAt': Timestamp.now(),
    });

    setState(() => _isSaving = false);
    _clearForm();
    if (mounted) Navigator.pop(context);
    _showSnack('Vacancy added successfully');
  }

  // ── Delete with confirm ──────────────────────────────────────────────
  Future<void> _confirmDelete(
    BuildContext ctx,
    String docId,
    String title,
  ) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Vacancy',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Remove "$title" permanently?',
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
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('job_vacancies')
          .doc(docId)
          .delete();
      _showSnack('Vacancy deleted');
    }
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

  // ── Bottom sheet form ────────────────────────────────────────────────
  void _showAddSheet() {
    _clearForm();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F6FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  const Text(
                    'Add Job Vacancy',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C1008),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Job details card
                  const _SheetLabel(label: 'JOB DETAILS'),
                  const SizedBox(height: 8),
                  _SheetCard(
                    children: [
                      _SheetField(
                        icon: Icons.work_rounded,
                        hint: 'Job title *',
                        controller: titleCtrl,
                      ),
                      const _SheetDivider(),
                      _SheetField(
                        icon: Icons.business_rounded,
                        hint: 'Company *',
                        controller: companyCtrl,
                      ),
                      const _SheetDivider(),
                      _SheetField(
                        icon: Icons.location_on_rounded,
                        hint: 'Location',
                        controller: locationCtrl,
                      ),
                      const _SheetDivider(),
                      _SheetField(
                        icon: Icons.currency_rupee_rounded,
                        hint: 'Salary (e.g. ₹15,000/month)',
                        controller: salaryCtrl,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  const _SheetLabel(label: 'CONTACT & DESCRIPTION'),
                  const SizedBox(height: 8),
                  _SheetCard(
                    children: [
                      _SheetField(
                        icon: Icons.phone_rounded,
                        hint: 'Contact number',
                        controller: contactCtrl,
                        keyboardType: TextInputType.phone,
                      ),
                      const _SheetDivider(),
                      _SheetField(
                        icon: Icons.description_rounded,
                        hint: 'Description',
                        controller: descCtrl,
                        maxLines: 3,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : addVacancy,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8651A),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(
                          0xFFE8651A,
                        ).withOpacity(0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Save Vacancy',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
          'Job Vacancies',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE8651A),
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: _showAddSheet,
        child: const Icon(Icons.add_rounded),
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
                  hintText: 'Search by title or company…',
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

          // ── List ───────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('job_vacancies')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE8651A)),
                  );
                }

                var docs = snapshot.data!.docs;

                // Client-side search
                if (_search.isNotEmpty) {
                  final q = _search.toLowerCase();
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return (data['title'] ?? '')
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
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _search.isNotEmpty
                              ? Icons.search_off_rounded
                              : Icons.work_off_rounded,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _search.isNotEmpty
                              ? 'No results found'
                              : 'No vacancies yet',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8A94A6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _search.isNotEmpty
                              ? 'Try a different search term'
                              : 'Tap + to add the first vacancy',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFB0B7C3),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final docId = docs[i].id;
                    final title = (data['title'] ?? '').toString();
                    final company = (data['company'] ?? '').toString();
                    final location = (data['location'] ?? '').toString();
                    final salary = (data['salary'] ?? '').toString();
                    final contact = (data['contact'] ?? '').toString();
                    final description = (data['description'] ?? '').toString();

                    return _VacancyCard(
                      title: title,
                      company: company,
                      location: location,
                      salary: salary,
                      contact: contact,
                      description: description,
                      onDelete: () => _confirmDelete(ctx, docId, title),
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

// ── Vacancy card ───────────────────────────────────────────────────────────
class _VacancyCard extends StatefulWidget {
  final String title;
  final String company;
  final String location;
  final String salary;
  final String contact;
  final String description;
  final VoidCallback onDelete;

  const _VacancyCard({
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.contact,
    required this.description,
    required this.onDelete,
  });

  @override
  State<_VacancyCard> createState() => _VacancyCardState();
}

class _VacancyCardState extends State<_VacancyCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: _expanded
            ? Border.all(color: const Color(0xFFE8651A).withOpacity(0.30))
            : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8651A).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.work_rounded,
                        color: Color(0xFFE8651A),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1C1008),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.company,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFE8651A),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.location.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 11,
                                  color: Color(0xFF8A94A6),
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    widget.location,
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
                    const SizedBox(width: 8),
                    // Delete + chevron
                    Column(
                      children: [
                        GestureDetector(
                          onTap: widget.onDelete,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935).withOpacity(0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.delete_rounded,
                              color: Color(0xFFE53935),
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFFD0D5DD),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Expanded details ────────────────────────────────
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (widget.salary.isNotEmpty)
                      _DetailRow(
                        icon: Icons.currency_rupee_rounded,
                        label: 'Salary',
                        value: widget.salary,
                      ),
                    if (widget.salary.isNotEmpty && widget.contact.isNotEmpty)
                      const SizedBox(height: 8),
                    if (widget.contact.isNotEmpty)
                      _DetailRow(
                        icon: Icons.phone_rounded,
                        label: 'Contact',
                        value: widget.contact,
                      ),
                    if (widget.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _DetailRow(
                        icon: Icons.description_rounded,
                        label: 'Description',
                        value: widget.description,
                        maxLines: 4,
                      ),
                    ],
                  ],
                ),
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int maxLines;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 14, color: const Color(0xFFE8651A)),
      const SizedBox(width: 6),
      Text(
        '$label: ',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8A94A6),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(fontSize: 12, color: Color(0xFF1C1008)),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

// ── Bottom sheet helpers ───────────────────────────────────────────────────
class _SheetLabel extends StatelessWidget {
  final String label;
  const _SheetLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Color(0xFF8A94A6),
      letterSpacing: 1.2,
    ),
  );
}

class _SheetCard extends StatelessWidget {
  final List<Widget> children;
  const _SheetCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
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
    child: Column(children: children),
  );
}

class _SheetField extends StatelessWidget {
  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;

  const _SheetField({
    required this.icon,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE8651A).withOpacity(0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: const Color(0xFFE8651A), size: 17),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1C1008),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF8A94A6),
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SheetDivider extends StatelessWidget {
  const _SheetDivider();

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    indent: 60,
    endIndent: 0,
    color: Color(0xFFF0F1F5),
  );
}
