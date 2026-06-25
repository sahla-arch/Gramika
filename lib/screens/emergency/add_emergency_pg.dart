import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEmergencyPage extends StatefulWidget {
  const AddEmergencyPage({super.key});

  @override
  State<AddEmergencyPage> createState() => _AddEmergencyPageState();
}

class _AddEmergencyPageState extends State<AddEmergencyPage> {
  // ── Theme ──────────────────────────────────────────────────────
  static const _accent = Color(0xFFE8651A);
  static const _dark = Color(0xFF1C1008);
  static const _bg = Color(0xFFF5F6FA);
  static const _hint = Color(0xFF8A94A6);

  // ── Controllers ────────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();

  // ── State ──────────────────────────────────────────────────────
  bool _isSaving = false;
  String? _nameError;
  String? _numberError;

  // Preset icon + colour pairs the admin can pick
  final List<_Preset> _presets = const [
    _Preset('Police', Icons.local_police_rounded, '#1565C0', 'local_police'),

    _Preset(
      'Fire',
      Icons.local_fire_department_rounded,
      '#B71C1C',
      'local_fire_department',
    ),

    _Preset(
      'Ambulance',
      Icons.medical_services_rounded,
      '#2E7D32',
      'emergency',
    ),

    _Preset('Women', Icons.woman_rounded, '#6A1B9A', 'woman'),

    _Preset('Child', Icons.child_care_rounded, '#E65100', 'child_care'),

    _Preset(
      'Electric',
      Icons.electric_bolt_rounded,
      '#F57F17',
      'electrical_services',
    ),

    _Preset('General', Icons.phone_rounded, '#FF9800', 'phone'),

    _Preset('Water', Icons.water_drop_rounded, '#0277BD', 'water_drop'),
  ];

  int _selectedPreset = 6; // default → General / phone

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────
  bool _validate() {
    final nErr = _nameController.text.trim().isEmpty
        ? 'Contact name cannot be empty'
        : null;
    final num = _numberController.text.trim();
    String? numErr;
    if (num.isEmpty) {
      numErr = 'Phone number cannot be empty';
    } else if (!RegExp(r'^\d{1,15}$').hasMatch(num)) {
      numErr = 'Enter a valid phone number (digits only)';
    }
    setState(() {
      _nameError = nErr;
      _numberError = numErr;
    });
    return nErr == null && numErr == null;
  }

  // ── Save (original logic preserved) ───────────────────────────
  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _isSaving = true);

    try {
      final p = _presets[_selectedPreset];
      await FirebaseFirestore.instance.collection('emergency_contacts').add({
        'name': _nameController.text.trim(),
        'number': _numberController.text.trim(),
        'icon': p.iconKey,
        'color': p.color,
        'createdAt': Timestamp.now(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _snack('Failed to save: $e', isError: true);
      setState(() => _isSaving = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
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
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFE53935)
            : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _dark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Add Emergency Contact',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // accent strip
          Container(height: 4, color: _accent),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Live preview card ──────────────────────
                  _buildPreviewCard(),
                  const SizedBox(height: 24),

                  // ── Contact info ───────────────────────────
                  _sectionLabel('CONTACT DETAILS'),
                  const SizedBox(height: 8),
                  _WhiteCard(
                    child: Column(
                      children: [
                        _buildNameField(),
                        _FieldDivider(),
                        _buildNumberField(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Icon / colour preset ───────────────────
                  _sectionLabel('CONTACT TYPE'),
                  const SizedBox(height: 8),
                  _buildPresetGrid(),

                  const SizedBox(height: 32),

                  // ── Save button ────────────────────────────
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Preview card ───────────────────────────────────────────────
  Widget _buildPreviewCard() {
    final p = _presets[_selectedPreset];
    final color = _hexColor(p.color);
    final name = _nameController.text.trim().isEmpty
        ? 'Contact Name'
        : _nameController.text.trim();
    final number = _numberController.text.trim().isEmpty
        ? 'Phone Number'
        : _numberController.text.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_dark, color.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(p.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.phone_rounded,
                      color: Colors.white54,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      number,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Preview',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Name field ─────────────────────────────────────────────────
  Widget _buildNameField() {
    final hasErr = _nameError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.badge_rounded,
                  color: hasErr ? Colors.red.shade400 : _accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  onChanged: (_) {
                    if (_nameError != null) {
                      setState(
                        () => _nameError = _nameController.text.trim().isEmpty
                            ? 'Contact name cannot be empty'
                            : null,
                      );
                    }
                    setState(() {}); // refresh preview
                  },
                  style: const TextStyle(
                    fontSize: 14,
                    color: _dark,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Police, Fire Station',
                    hintStyle: const TextStyle(color: _hint, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    errorText: null,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasErr) _inlineError(_nameError!),
      ],
    );
  }

  // ── Number field ───────────────────────────────────────────────
  Widget _buildNumberField() {
    final hasErr = _numberError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.phone_rounded,
                  color: hasErr ? Colors.red.shade400 : _accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _numberController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) {
                    if (_numberError != null)
                      setState(() => _numberError = null);
                    setState(() {}); // refresh preview
                  },
                  style: const TextStyle(
                    fontSize: 14,
                    color: _dark,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 100, 101, 1091',
                    hintStyle: TextStyle(color: _hint, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasErr) _inlineError(_numberError!),
      ],
    );
  }

  // ── Preset grid ────────────────────────────────────────────────
  Widget _buildPresetGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _presets.length,
      itemBuilder: (_, i) {
        final p = _presets[i];
        final color = _hexColor(p.color);
        final selected = i == _selectedPreset;
        return GestureDetector(
          onTap: () => setState(() => _selectedPreset = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: selected ? color.withOpacity(0.12) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? color : const Color(0xFFE4E7EC),
                width: selected ? 2 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? color.withOpacity(0.2)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: selected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(p.icon, color: color, size: 22),
                    ),
                    if (selected)
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 9,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  p.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? color : const Color(0xFF4A4A4A),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Save button ────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _accent.withOpacity(0.5),
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
                'Save Contact',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────
  Widget _sectionLabel(String label) => Text(
    label,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: _hint,
      letterSpacing: 1.2,
    ),
  );

  Widget _inlineError(String msg) => Padding(
    padding: const EdgeInsets.fromLTRB(64, 0, 16, 8),
    child: Row(
      children: [
        Icon(Icons.error_outline_rounded, size: 13, color: Colors.red.shade500),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            msg,
            style: TextStyle(fontSize: 12, color: Colors.red.shade600),
          ),
        ),
      ],
    ),
  );

  Color _hexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return _accent;
    }
  }
}

// ── Data model ────────────────────────────────────────────────────────────
class _Preset {
  final String label;
  final IconData icon;
  final String color; // hex string stored in Firestore
  final String iconKey; // string stored in Firestore

  const _Preset(this.label, this.icon, this.color, this.iconKey);

  // Override iconKey per preset
}

// ── Shared widgets ────────────────────────────────────────────────────────
class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

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
    child: child,
  );
}

class _FieldDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    indent: 64,
    endIndent: 0,
    color: Color(0xFFF0F1F5),
  );
}
