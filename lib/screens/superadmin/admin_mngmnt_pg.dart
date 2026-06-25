import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AdminManagementPage extends StatefulWidget {
  const AdminManagementPage({super.key});

  @override
  State<AdminManagementPage> createState() => _AdminManagementPageState();
}

class _AdminManagementPageState extends State<AdminManagementPage> {
  String searchText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          "Admin Management",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.orange.shade700,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange.shade700,
        onPressed: () => _showAddAdminDialog(context),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text("Add Admin", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.orange.shade700,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search admin by name...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.8),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
            ),
          ),

          // Admin List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'admin')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Something went wrong."));
                }

                final admins = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['name'] ?? '').toString().toLowerCase().contains(
                    searchText,
                  );
                }).toList();

                if (admins.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No admins found",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: admins.length,
                  itemBuilder: (context, index) {
                    final doc = admins[index];
                    final admin = doc.data() as Map<String, dynamic>;
                    final isActive =
                        (admin['status'] ?? 'active') != 'inactive';
                    final assignedList = List<String>.from(
                      admin['assignedPanchayats'] ?? [],
                    );

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            CircleAvatar(
                              backgroundColor: Colors.orange.shade100,
                              radius: 28,
                              child: Text(
                                (admin['name'] ?? 'A')
                                    .toString()
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name + Status badge
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          admin['name'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? Colors.green.shade50
                                              : Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: isActive
                                                ? Colors.green.shade300
                                                : Colors.red.shade300,
                                          ),
                                        ),
                                        child: Text(
                                          isActive ? "Active" : "Inactive",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isActive
                                                ? Colors.green.shade700
                                                : Colors.red.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  // Email
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.email_outlined,
                                        size: 13,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          admin['email'] ?? '',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),

                                  // Phone
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.phone_outlined,
                                        size: 13,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        admin['phone'] ?? 'N/A',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Assigned Panchayats chip row
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.map_outlined,
                                        size: 13,
                                        color: Colors.orange.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          assignedList.isEmpty
                                              ? "No panchayats assigned"
                                              : assignedList.join(', '),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: assignedList.isEmpty
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Popup menu
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              itemBuilder: (context) => [
                                _menuItem(Icons.edit, 'edit', "Edit Admin"),
                                _menuItem(
                                  Icons.assignment,
                                  'assign',
                                  "Assign Panchayats",
                                ),
                                _menuItem(
                                  Icons.visibility,
                                  'view_assigned',
                                  "View Assigned Panchayats",
                                ),
                                const PopupMenuDivider(),
                                _menuItem(
                                  Icons.delete_outline,
                                  'delete',
                                  "Delete",
                                  color: Colors.red,
                                ),
                              ],
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit':
                                    _showEditAdminDialog(
                                      context,
                                      doc.id,
                                      admin,
                                    );
                                    break;
                                  case 'assign':
                                    _showAssignDialog(context, doc.id, admin);
                                    break;
                                  case 'view_assigned':
                                    _showViewPanchayatsDialog(context, admin);
                                    break;
                                  case 'delete':
                                    _deleteAdmin(context, doc.id);
                                    break;
                                }
                              },
                            ),
                          ],
                        ),
                      ),
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

  PopupMenuItem<String> _menuItem(
    IconData icon,
    String value,
    String label, {
    Color? color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.grey.shade700),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color ?? Colors.black87)),
        ],
      ),
    );
  }

  String generatePassword() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@#\$%';
    Random rnd = Random();

    return List.generate(
      10,
      (index) => chars[rnd.nextInt(chars.length)],
    ).join();
  }
  // ─── Add Admin Dialog ───────────────────────────────────────────────────────

  void _showAddAdminDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController(text: generatePassword());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.person_add, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              const Text(
                "Add Admin",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(nameController, "Full Name", Icons.person),
                const SizedBox(height: 12),
                _buildTextField(
                  emailController,
                  "Email Address",
                  Icons.email,
                  type: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  phoneController,
                  "Phone Number",
                  Icons.phone,
                  type: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Auto Generated Password",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        passwordController.text = generatePassword();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    emailController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Name and Email are required."),
                    ),
                  );
                  return;
                }
                await FirebaseFirestore.instance.collection("users").add({
                  "name": nameController.text.trim(),
                  "email": emailController.text.trim(),
                  "phone": phoneController.text.trim(),
                  "password": passwordController.text.trim(),
                  "role": "admin",
                  "assignedPanchayats": [],
                  "status": "active",
                  "mustChangePassword": true,
                });
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Admin Credentials"),
                    content: SelectableText(
                      "Email: ${emailController.text.trim()}\n\n"
                      "Password: ${passwordController.text}",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // ─── Edit Admin Dialog ──────────────────────────────────────────────────────

  void _showEditAdminDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> admin,
  ) {
    final nameController = TextEditingController(text: admin['name'] ?? '');
    final emailController = TextEditingController(text: admin['email'] ?? '');
    final phoneController = TextEditingController(text: admin['phone'] ?? '');
    bool isActive = (admin['status'] ?? 'active') != 'inactive';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.edit, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  const Text(
                    "Edit Admin",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(nameController, "Full Name", Icons.person),
                    const SizedBox(height: 12),
                    _buildTextField(
                      emailController,
                      "Email Address",
                      Icons.email,
                      type: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      phoneController,
                      "Phone Number",
                      Icons.phone,
                      type: TextInputType.phone,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Admin Active"),
                      subtitle: Text(
                        isActive
                            ? "This admin can log in"
                            : "Access is disabled",
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive
                              ? Colors.green.shade600
                              : Colors.red.shade600,
                        ),
                      ),
                      value: isActive,
                      activeColor: Colors.orange.shade700,
                      onChanged: (value) {
                        setDialogState(() => isActive = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(docId)
                        .update({
                          "name": nameController.text.trim(),
                          "email": emailController.text.trim(),
                          "phone": phoneController.text.trim(),
                          "status": isActive ? "active" : "inactive",
                        });
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Delete Admin ───────────────────────────────────────────────────────────

  Future<void> _deleteAdmin(BuildContext context, String docId) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
              const SizedBox(width: 8),
              const Text(
                "Delete Admin",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: const Text(
            "Are you sure you want to permanently delete this admin? This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);

                // Check if admin has associated panchayat records
                final panchayats = await FirebaseFirestore.instance
                    .collection('panchayats')
                    .where('createdBy', isEqualTo: docId)
                    .get();

                if (!context.mounted) return;

                if (panchayats.docs.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        "Admin has existing records. Deactivate instead of deleting.",
                      ),
                      backgroundColor: Colors.orange.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(docId)
                    .delete();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Admin deleted successfully."),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  // ─── Assign Panchayats Dialog ───────────────────────────────────────────────

  void _showAssignDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> admin,
  ) async {
    final current = List<String>.from(admin['assignedPanchayats'] ?? []);
    final snapshot = await FirebaseFirestore.instance
        .collection('panchayats')
        .get();

    final allPanchayats =
        snapshot.docs.map((doc) => doc['name'].toString()).toList()..sort();

    final searchController = TextEditingController();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = allPanchayats
                .where(
                  (p) => p.toLowerCase().contains(
                    searchController.text.toLowerCase(),
                  ),
                )
                .toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              title: Row(
                children: [
                  Icon(Icons.assignment, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Assign Panchayats",
                      style: TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.55,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Search panchayat...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${current.length} selected",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: filtered.isEmpty
                          ? const Center(child: Text("No panchayats found"))
                          : ListView(
                              shrinkWrap: true,
                              children: filtered.map((p) {
                                return CheckboxListTile(
                                  title: Text(
                                    p,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  value: current.contains(p),
                                  activeColor: Colors.orange.shade700,
                                  dense: true,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      if (value == true) {
                                        current.add(p);
                                      } else {
                                        current.remove(p);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(docId)
                        .update({"assignedPanchayats": current});
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── View Assigned Panchayats Dialog ───────────────────────────────────────

  void _showViewPanchayatsDialog(
    BuildContext context,
    Map<String, dynamic> admin,
  ) {
    final String adminUid = admin['uid'];
    final assigned = List<String>.from(admin['assignedPanchayats'] ?? []);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
          title: Row(
            children: [
              Icon(Icons.map, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Assigned Panchayats",
                  style: TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: assigned.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text("No panchayats have been assigned yet."),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: assigned.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.orange.shade50,
                          child: Text(
                            "${index + 1}",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          assigned[index],
                          style: const TextStyle(fontSize: 14),
                        ),

                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),

                          onPressed: () async {
                            assigned.removeAt(index);

                            final adminDoc = await FirebaseFirestore.instance
                                .collection("users")
                                .doc(adminUid)
                                .get();

                            await adminDoc.reference.update({
                              "assignedPanchayats": assigned,
                            });

                            Navigator.pop(context);

                            _showViewPanchayatsDialog(context, {
                              ...admin,
                              "assignedPanchayats": assigned,
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  // ─── Helper: Build Text Field ───────────────────────────────────────────────

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange.shade700),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.orange.shade700, width: 1.5),
        ),
      ),
    );
  }
}
