import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'settings/app_theme.dart';
import 'settings/app_strings.dart';

/// ---------------------------------------------------------------------------
/// Service options page – manage sizes / packages for one service
/// ---------------------------------------------------------------------------
class ServiceOptionsPage extends StatelessWidget {
  final String serviceId;
  final String serviceName;

  const ServiceOptionsPage({
    super.key,
    required this.serviceId,
    required this.serviceName,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isArabic = s.isArabic;

    final optionsStream = FirebaseFirestore.instance
        .collection('services')
        .doc(serviceId)
        .collection('options')
        .orderBy('sortOrder')
        .snapshots();

    String money(num value) =>
        '${value.toStringAsFixed(2)}${s.currencySuffix}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabic
              ? 'الخيارات – $serviceName'
              : 'Options – $serviceName',
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: optionsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                (isArabic
                    ? 'حدث خطأ أثناء تحميل الخيارات:\n'
                    : 'Error loading options:\n') +
                    snapshot.error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                isArabic
                    ? 'لا توجد خيارات بعد.'
                    : 'No options yet.',
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
            itemCount: docs.length,
            separatorBuilder: (context, index) =>
            const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final name = (data['name'] ?? 'Option') as String;
              final desc = (data['description'] ?? '') as String;
              final price = (data['price'] ?? 0) as num;
              final active = (data['active'] ?? true) as bool;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (desc.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                desc,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              money(price),
                              style: const TextStyle(
                                color: AppColors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: active
                                    ? AppColors.green
                                    : Colors.grey.shade700,
                              ),
                              icon: Icon(
                                active
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                size: 18,
                              ),
                              label: Text(
                                active
                                    ? (isArabic ? 'مفعل' : 'Active')
                                    : (isArabic ? 'غير مفعل' : 'Inactive'),
                              ),
                              onPressed: () {
                                doc.reference.update({'active': !active});
                              },
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            tooltip: isArabic
                                ? 'تعديل الخيار'
                                : 'Edit option',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _showOptionDialog(
                              context: context,
                              serviceId: serviceId,
                              existingDoc: doc,
                              existingData: data,
                            ),
                          ),
                          IconButton(
                            tooltip: isArabic
                                ? 'حذف الخيار'
                                : 'Delete option',
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red.shade400,
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: Text(
                                    isArabic
                                        ? 'حذف الخيار'
                                        : 'Delete option',
                                  ),
                                  content: Text(
                                    isArabic
                                        ? 'هل تريد حذف "$name" من هذه الخدمة؟'
                                        : 'Delete "$name" from this service?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      child: Text(
                                        isArabic ? 'إلغاء' : 'Cancel',
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      child: Text(
                                        isArabic ? 'حذف' : 'Delete',
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                await doc.reference.delete();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showOptionDialog(
          context: context,
          serviceId: serviceId,
        ),
        icon: const Icon(Icons.add),
        label: Text(
          isArabic ? 'إضافة خيار' : 'Add option',
        ),
      ),
    );
  }
}

// dialog for add / edit option
Future<void> _showOptionDialog({
  required BuildContext context,
  required String serviceId,
  DocumentSnapshot? existingDoc,
  Map<String, dynamic>? existingData,
}) async {
  final s = S.of(context);
  final isArabic = s.isArabic;

  final bool editing = existingDoc != null;
  final data = existingData ?? {};

  final nameController =
  TextEditingController(text: (data['name'] ?? '') as String);
  final descController =
  TextEditingController(text: (data['description'] ?? '') as String);
  final priceController = TextEditingController(
    text: data['price'] != null ? data['price'].toString() : '',
  );
  final sortController = TextEditingController(
    text: data['sortOrder'] != null ? data['sortOrder'].toString() : '',
  );
  bool active = (data['active'] ?? true) as bool;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              editing
                  ? (isArabic ? 'تعديل الخيار' : 'Edit option')
                  : (isArabic ? 'إضافة خيار' : 'Add option'),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'الاسم' : 'Name',
                      prefixIcon: const Icon(Icons.label_outline),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText:
                      isArabic ? 'الوصف' : 'Description',
                      prefixIcon:
                      const Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceController,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: isArabic
                          ? 'السعر (${s.currencySuffix.trim()})'
                          : 'Price (${s.currencySuffix.trim()})',
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: sortController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: isArabic
                          ? 'ترتيب العرض (1، 2، 3...)'
                          : 'Sort order (1,2,3...)',
                      prefixIcon: const Icon(Icons.sort),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: active,
                    title: Text(
                      isArabic ? 'مفعل' : 'Active',
                    ),
                    onChanged: (v) {
                      setStateDialog(() => active = v);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  isArabic ? 'إلغاء' : 'Cancel',
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isArabic
                              ? 'اسم الخيار مطلوب.'
                              : 'Option name is required.',
                        ),
                      ),
                    );
                    return;
                  }
                  final double price =
                      double.tryParse(priceController.text) ?? 0;
                  final int sortOrder =
                      int.tryParse(sortController.text) ?? 0;

                  final payload = {
                    'name': name,
                    'description': descController.text.trim(),
                    'price': price,
                    'sortOrder': sortOrder,
                    'active': active,
                  };

                  final col = FirebaseFirestore.instance
                      .collection('services')
                      .doc(serviceId)
                      .collection('options');

                  if (editing) {
                    await existingDoc!.reference.update(payload);
                  } else {
                    await col.add(payload);
                  }

                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                child: Text(
                  editing
                      ? (isArabic ? 'حفظ' : 'Save')
                      : (isArabic ? 'إضافة' : 'Add'),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
