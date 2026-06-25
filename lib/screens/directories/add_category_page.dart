import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddCategoryPage extends StatefulWidget {
  const AddCategoryPage({super.key});

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final nameController = TextEditingController();

  final Map<String, IconData> iconOptions = {
    "school_rounded": Icons.school_rounded,
    "local_hospital_rounded": Icons.local_hospital_rounded,
    "directions_bus_rounded": Icons.directions_bus_rounded,
    "account_balance_rounded": Icons.account_balance_rounded,
    "store_rounded": Icons.store_rounded,
    "travel_explore_rounded": Icons.travel_explore_rounded,
    "restaurant_rounded": Icons.restaurant_rounded,
    "home_rounded": Icons.home_rounded,
    "directions_car_rounded": Icons.directions_car_rounded,
  };

  final List<Color> colorPalette = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.brown,
  ];

  String selectedIcon = "school_rounded";
  String selectedColor = "0xFF3B82F6";
  bool _isSaving = false;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> saveCategory() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a category name'),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final doc = await FirebaseFirestore.instance
        .collection('directory_categories')
        .add({
          'name': nameController.text.trim(),
          'icon': selectedIcon,
          'colors': selectedColor,
          'isActive': true,
        });

    Navigator.pop(context, {
      'categoryId': doc.id,
      'categoryName': nameController.text.trim(),
    });
  }

  Color get _selectedColorValue {
    final match = colorPalette.firstWhere(
      (c) => "0x${c.value.toRadixString(16).toUpperCase()}" == selectedColor,
      orElse: () => Colors.blue,
    );
    return match;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      // ── AppBar ───────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1008),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Add Category',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),

      body: Column(
        children: [
          // ── Teal accent strip (matches details page hero) ────────────
          Container(height: 4, color: const Color(0xFFE8651A)),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Live preview card ──────────────────────────────
                  Center(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: _selectedColorValue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: _selectedColorValue.withOpacity(0.35),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        iconOptions[selectedIcon]!,
                        size: 52,
                        color: _selectedColorValue,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Center(
                    child: Text(
                      nameController.text.trim().isEmpty
                          ? 'Category Preview'
                          : nameController.text.trim(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1F36),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Category name ──────────────────────────────────
                  _SectionLabel(label: 'CATEGORY NAME'),
                  const SizedBox(height: 8),
                  _Card(
                    child: TextField(
                      controller: nameController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1F36),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter category name',
                        hintStyle: TextStyle(
                          color: Color(0xFF8A94A6),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.label_rounded,
                          color: Color(0xFF00B4A6),
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Icon picker ────────────────────────────────────
                  _SectionLabel(label: 'SELECT ICON'),
                  const SizedBox(height: 8),
                  _Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: iconOptions.entries.map((e) {
                          final isSelected = selectedIcon == e.key;
                          return GestureDetector(
                            onTap: () => setState(() => selectedIcon = e.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _selectedColorValue.withOpacity(0.15)
                                    : const Color(0xFFF5F6FA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? _selectedColorValue
                                      : const Color(0xFFE4E7EC),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Icon(
                                e.value,
                                size: 26,
                                color: isSelected
                                    ? _selectedColorValue
                                    : const Color(0xFF8A94A6),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Color picker ───────────────────────────────────
                  _SectionLabel(label: 'SELECT COLOR'),
                  const SizedBox(height: 8),
                  _Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: colorPalette.map((color) {
                          final colorHex =
                              "0x${color.value.toRadixString(16).toUpperCase()}";
                          final isSelected = selectedColor == colorHex;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => selectedColor = colorHex),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: const Color(0xFF1C1008),
                                        width: 3,
                                      )
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withOpacity(0.5),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Save button ────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : saveCategory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8651A),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(
                          0xFF00B4A6,
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
                              'Save Category',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
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
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF8A94A6),
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── White card wrapper ─────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: child,
    );
  }
}
