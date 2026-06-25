import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ── Status metadata ─────────────────────────────────────────────────────────
class _StatusMeta {
  final Color color;
  final IconData icon;
  const _StatusMeta(this.color, this.icon);
}

const Map<String, _StatusMeta> _statusMeta = {
  'Pending': _StatusMeta(Color(0xFFFF6D00), Icons.hourglass_top_rounded),
  'Approved': _StatusMeta(Color(0xFF1E88E5), Icons.verified_rounded),
  'Forwarded': _StatusMeta(Color(0xFF8E24AA), Icons.forward_rounded),
  'Resolved': _StatusMeta(Color(0xFF43A047), Icons.check_circle_rounded),
  'Rejected': _StatusMeta(Color(0xFFE53935), Icons.cancel_rounded),
};

_StatusMeta _meta(String s) =>
    _statusMeta[s] ??
    const _StatusMeta(Color(0xFFFF6D00), Icons.hourglass_top_rounded);

// ── Tracking steps ──────────────────────────────────────────────────────────
const List<Map<String, String>> _trackingSteps = [
  {
    'key': 'submitted',
    'label': 'Complaint Submitted',
    'sub': 'Issue received by Gramika',
  },
  {
    'key': 'Pending',
    'label': 'Under Review',
    'sub': 'Being reviewed by authorities',
  },
  {
    'key': 'Approved',
    'label': 'Approved',
    'sub': 'Complaint accepted for action',
  },
  {
    'key': 'Forwarded',
    'label': 'Forwarded',
    'sub': 'Sent to responsible department',
  },
  {'key': 'Resolved', 'label': 'Resolved', 'sub': 'Issue has been resolved'},
];

bool _isStepDone(String currentStatus, String stepKey) {
  if (stepKey == 'submitted') return true;
  const order = ['Pending', 'Approved', 'Forwarded', 'Resolved'];
  return order.indexOf(currentStatus) >= order.indexOf(stepKey);
}

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
//  IssueDetailsPage
// ═══════════════════════════════════════════════════════════════════════════
class IssueDetailsPage extends StatefulWidget {
  final Map<String, dynamic> issueData;
  final String issueId;

  const IssueDetailsPage({
    super.key,
    required this.issueData,
    required this.issueId,
  });

  @override
  State<IssueDetailsPage> createState() => _IssueDetailsPageState();
}

class _IssueDetailsPageState extends State<IssueDetailsPage> {
  final _chatCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Send message ────────────────────────────────────────────────────────
  Future<void> _sendMessage() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _sending = true);

    try {
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(widget.issueId)
          .collection('messages')
          .add({
            'message': text,
            'senderId': user.uid,
            'senderName': user.displayName ?? 'User',
            'createdAt': Timestamp.now(),
          });
      _chatCtrl.clear();
      // scroll to bottom
      Future.delayed(const Duration(milliseconds: 150), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Flexible(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final data = widget.issueData;
    final status = (data['status'] ?? 'Pending') as String;
    final m = _meta(status);
    final imageUrl = (data['imageUrl'] ?? '').toString();
    final date = _formatDate(data['createdAt']);
    final isRejected = status == 'Rejected';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: const Text(
          'Issue Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),

      body: Column(
        children: [
          // ── Scrollable content ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Issue card ─────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: m.color.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
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
                            color: m.color,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(18),
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status + date row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: m.color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(m.icon, size: 13, color: m.color),
                                        const SizedBox(width: 5),
                                        Text(
                                          status,
                                          style: TextStyle(
                                            color: m.color,
                                            fontSize: 12,
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
                                          size: 11,
                                          color: Colors.black38,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          date,
                                          style: const TextStyle(
                                            color: Colors.black38,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // Title
                              Text(
                                data['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A2E),
                                  height: 1.3,
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Description
                              Text(
                                data['description'] ?? '',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13.5,
                                  height: 1.6,
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Meta chips row
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if ((data['category'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    _MiniChip(
                                      icon: Icons.category_outlined,
                                      label: data['category'],
                                      color: Colors.blueGrey,
                                    ),
                                  if ((data['type'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    _MiniChip(
                                      icon: Icons.label_outline,
                                      label: data['type'],
                                      color: Colors.teal,
                                    ),
                                  if ((data['priority'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    _MiniChip(
                                      icon: Icons.flag_outlined,
                                      label: data['priority'],
                                      color: Colors.orange,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Image ────────────────────────────────────────────────
                  if (imageUrl.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 210,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 210,
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
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.black26,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // ── Rejected banner ──────────────────────────────────────
                  if (isRejected) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cancel_outlined,
                            color: Colors.red,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This complaint was rejected by the authority.',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Tracking timeline ─────────────────────────────────────
                  _SectionLabel(label: 'Complaint Tracking'),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: List.generate(_trackingSteps.length, (i) {
                        final step = _trackingSteps[i];
                        final done = _isStepDone(status, step['key']!);
                        final isLast = i == _trackingSteps.length - 1;
                        // Skip Resolved step if rejected
                        if (isRejected && step['key'] == 'Resolved') {
                          return const SizedBox.shrink();
                        }
                        return _TrackingStep(
                          label: step['label']!,
                          sublabel: step['sub']!,
                          done: done,
                          isLast: isLast || isRejected,
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Conversation ──────────────────────────────────────────
                  _SectionLabel(label: 'Conversation'),
                  const SizedBox(height: 12),

                  Container(
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('issues')
                          .doc(widget.issueId)
                          .collection('messages')
                          .orderBy('createdAt')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.orange,
                            ),
                          );
                        }

                        final msgs = snapshot.data!.docs;

                        if (msgs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 36,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    color: Colors.black38,
                                    fontSize: 13,
                                  ),
                                ),
                                const Text(
                                  'Start the conversation below',
                                  style: TextStyle(
                                    color: Colors.black26,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                            itemCount: msgs.length,
                            itemBuilder: (context, index) {
                              final msg =
                                  msgs[index].data() as Map<String, dynamic>;
                              final isMe =
                                  msg['senderId'] ==
                                  FirebaseAuth.instance.currentUser?.uid;
                              return _ChatBubble(
                                message: msg['message'] ?? '',
                                isMe: isMe,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Chat input (pinned to bottom) ──────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatCtrl,
                    onSubmitted: (_) => _sendMessage(),
                    textInputAction: TextInputAction.send,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Type a message…',
                      hintStyle: const TextStyle(
                        color: Colors.black38,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F6FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sending ? null : _sendMessage,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _sending
                          ? Colors.orange.withOpacity(0.5)
                          : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Tracking step widget
// ═══════════════════════════════════════════════════════════════════════════
class _TrackingStep extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool done;
  final bool isLast;

  const _TrackingStep({
    required this.label,
    required this.sublabel,
    required this.done,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = done ? Colors.green : Colors.grey.shade300;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Circle + line
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: done ? Colors.green : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: done
                  ? const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: Colors.white,
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 44,
                margin: const EdgeInsets.symmetric(vertical: 3),
                color: color,
              ),
          ],
        ),

        const SizedBox(width: 14),

        // Labels
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                    color: done ? const Color(0xFF1A1A2E) : Colors.black38,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: done ? Colors.black45 : Colors.black26,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Done tick badge
        if (done)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Done',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Chat bubble ────────────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  const _ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.orange : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isMe ? Colors.white : const Color(0xFF1A1A2E),
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

// ── Mini chip ──────────────────────────────────────────────────────────────
class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color color;
  const _MiniChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label ?? '',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────
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
