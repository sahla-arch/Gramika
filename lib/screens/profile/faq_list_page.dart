import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FAQListPage extends StatelessWidget {
  const FAQListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1008),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Frequently Asked Questions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),

      body: Column(
        children: [
          Container(height: 4, color: const Color(0xFFE8651A)),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('faqs')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE8651A)),
                  );
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.quiz_rounded,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No questions yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8A94A6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Check back soon for answers',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFB0B7C3),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final question = (data['question'] ?? '').toString();
                    final status = (data['status'] ?? 'Pending').toString();
                    final answer = (data['answer'] ?? '').toString().trim();
                    final hasAnswer = answer.isNotEmpty;
                    final isAnswered = status.toLowerCase() == 'answered';

                    return _FaqCard(
                      question: question,
                      status: status,
                      answer: answer,
                      hasAnswer: hasAnswer,
                      isAnswered: isAnswered,
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

// ── FAQ expandable card ────────────────────────────────────────────────────
class _FaqCard extends StatefulWidget {
  final String question;
  final String status;
  final String answer;
  final bool hasAnswer;
  final bool isAnswered;

  const _FaqCard({
    required this.question,
    required this.status,
    required this.answer,
    required this.hasAnswer,
    required this.isAnswered,
  });

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.isAnswered
        ? const Color(0xFF2E7D32)
        : const Color(0xFFE8651A);
    final statusBg = widget.isAnswered
        ? const Color(0xFF2E7D32)
        : const Color(0xFFE8651A);

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
            // ── Header row ───────────────────────────────────────
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Q bubble
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8651A).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'Q',
                          style: TextStyle(
                            fontSize: 15,
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
                            widget.question,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1C1008),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Status chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.isAnswered
                                      ? Icons.check_circle_rounded
                                      : Icons.hourglass_top_rounded,
                                  size: 11,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Chevron
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFFD0D5DD),
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Answer panel ─────────────────────────────────────
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.hasAnswer
                      ? const Color(0xFF2E7D32).withOpacity(0.06)
                      : const Color(0xFFE8651A).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.hasAnswer
                        ? const Color(0xFF2E7D32).withOpacity(0.18)
                        : const Color(0xFFE8651A).withOpacity(0.18),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: widget.hasAnswer
                            ? const Color(0xFF2E7D32).withOpacity(0.12)
                            : const Color(0xFFE8651A).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'A',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: widget.hasAnswer
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFE8651A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Response',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: widget.hasAnswer
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFE8651A),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.hasAnswer
                                ? widget.answer
                                : 'Awaiting admin response…',
                            style: TextStyle(
                              fontSize: 13,
                              color: widget.hasAnswer
                                  ? const Color(0xFF1C1008)
                                  : const Color(0xFF8A94A6),
                              height: 1.5,
                              fontStyle: widget.hasAnswer
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
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
