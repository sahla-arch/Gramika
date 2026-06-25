import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FAQReplyPage extends StatefulWidget {
  final String faqId;
  final Map<String, dynamic> data;

  const FAQReplyPage({super.key, required this.faqId, required this.data});

  @override
  State<FAQReplyPage> createState() => _FAQReplyPageState();
}

class _FAQReplyPageState extends State<FAQReplyPage> {
  late TextEditingController answerController;

  bool loading = false;

  @override
  void initState() {
    super.initState();

    answerController = TextEditingController(text: widget.data['answer'] ?? '');
  }

  Future<void> saveAnswer() async {
    if (answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter an answer")));
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('faqs')
          .doc(widget.faqId)
          .update({
            'answer': answerController.text.trim(),
            'status': 'answered',
            'answeredAt': Timestamp.now(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Answer submitted successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("FAQ Reply")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.data['question'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text("Asked By: ${widget.data['askedBy'] ?? ''}"),

                    Text("Panchayat: ${widget.data['panchayat'] ?? ''}"),

                    Text("Status: ${widget.data['status'] ?? 'pending'}"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: answerController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: "Enter Answer",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),

                label: Text(loading ? "Submitting..." : "Submit Answer"),

                onPressed: loading ? null : saveAnswer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
