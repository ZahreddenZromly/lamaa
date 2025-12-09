import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../settings/app_theme.dart';
import '../settings/app_strings.dart';
import '../invoice_page.dart';
import 'offline_invoice_page.dart';

/// ---------------------------------------------------------------------------
/// Shared helpers
/// ---------------------------------------------------------------------------

Color _statusColor(String status) {
  switch (status) {
    case 'confirmed':
      return AppColors.green;
    case 'done':
      return Colors.blue;
    case 'rejected':
      return Colors.red;
    default:
      return Colors.orange; // pending
  }
}
String _formatTs(Timestamp? ts) {
  if (ts == null) return '-';
  final dt = ts.toDate();
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}


bool _isArabic(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ar';

/// Localized status label for admin based on existing S strings
String _statusLabel(BuildContext context, String status) {
  final loc = S.of(context);
  switch (status) {
    case 'confirmed':
      return loc.statusConfirmed;
    case 'done':
      return loc.statusCompleted;
    case 'rejected':
      return loc.statusRejected;
    default:
      return loc.statusPending;
  }
}

/// ---------------------------------------------------------------------------
/// ADMIN DASHBOARD – 5 tabs: Orders / News / Services / Users / Offline orders
/// ---------------------------------------------------------------------------
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = _isArabic(context);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isArabic ? 'لوحة التحكم' : 'Admin dashboard',
          ),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: isArabic ? 'الطلبات' : 'Orders'),
              Tab(text: isArabic ? 'الأخبار' : 'News'),
              Tab(text: isArabic ? 'الخدمات' : 'Services'),
              Tab(text: isArabic ? 'المستخدمون' : 'Users'),
              Tab(text: isArabic ? 'الطلبات اليدوية' : 'Offline orders'),
            ],
          ),
        ),
        body: TabBarView(
          children: const [
            AdminOrdersTab(),
            AdminNewsTab(),
            AdminServicesTab(),
            AdminUsersTab(),
            AdminOfflineOrdersTab(),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// 1) ONLINE ORDERS TAB  (orders coming from the app, shows rating + review)
/// ---------------------------------------------------------------------------
class AdminOrdersTab extends StatelessWidget {
  const AdminOrdersTab({super.key});

  Stream<QuerySnapshot> get _ordersStream => FirebaseFirestore.instance
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    final isArabic = _isArabic(context);

    return StreamBuilder<QuerySnapshot>(
      stream: _ordersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              isArabic
                  ? 'حدث خطأ أثناء تحميل الطلبات:\n${snapshot.error}'
                  : 'Error loading orders:\n${snapshot.error}',
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
              isArabic ? 'لا توجد طلبات بعد.' : 'No orders yet.',
            ),
          );
        }

        final docs = snapshot.data!.docs;

        // show only ONLINE orders here (offline ones are in the Offline tab)
        final onlineDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final source = (data['source'] ?? 'online') as String;
          return source != 'offline';
        }).toList();

        if (onlineDocs.isEmpty) {
          return Center(
            child: Text(
              isArabic ? 'لا توجد طلبات من التطبيق بعد.' : 'No online orders yet.',
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: onlineDocs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final doc = onlineDocs[index];
            final data = doc.data() as Map<String, dynamic>;

            final customerName =
            (data['userName'] ?? 'Unknown') as String;
            final customerPhone =
            (data['userPhone'] ?? '') as String;
            final customerLocation =
            (data['userLocation'] ?? '') as String;

            final serviceName =
            (data['serviceName'] ?? 'Service') as String;
            final optionName = (data['optionName'] ?? '') as String;

            final status = (data['status'] ?? 'pending') as String;

            final totalPrice = (data['totalPrice'] ?? 0) as num;
            final qty = (data['quantity'] ?? 1) as num;

            final scheduledDate = data['scheduledDate'] is Timestamp
                ? (data['scheduledDate'] as Timestamp)
                : null;
            final createdAt = data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp)
                : null;

            // rating + review from customer (for admin eyes)
            final rating = (data['rating'] ?? 0) as num;
            final review = (data['review'] ?? '') as String;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // top row: icon + title + status chip
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.cleaning_services,
                              color: AppColors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$serviceName'
                                      '${optionName.isNotEmpty ? ' - $optionName' : ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person_outline,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      customerName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _statusLabel(context, status),
                              style: TextStyle(
                                color: _statusColor(status),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // contact + location
                      if (customerPhone.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              customerPhone,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      if (customerLocation.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                customerLocation,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 6),

                      // schedule / created
                      Row(
                        children: [
                          const Icon(
                            Icons.event,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              (isArabic ? 'موعد الزيارة: ' : 'Scheduled: ') +
                                  _formatTs(scheduledDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (isArabic ? 'تاريخ الإنشاء: ' : 'Created: ') +
                                  _formatTs(createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 8),

                      // quantity + price + ACTION BUTTONS (status + delete)
                      Row(
                        children: [
                          Text(
                            (isArabic ? 'الكمية: ' : 'Qty: ') + '$qty',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${isArabic ? 'الإجمالي: ' : 'Total: '}${totalPrice.toStringAsFixed(2)}${S.of(context).currencySuffix}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.orange,
                            ),
                          ),
                          const Spacer(),

                          // ----- status-based actions -----
                          if (status == 'pending') ...[
                            TextButton(
                              onPressed: () =>
                                  doc.reference.update({'status': 'confirmed'}),
                              child: Text(
                                isArabic ? 'تأكيد' : 'Confirm',
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  doc.reference.update({'status': 'rejected'}),
                              child: Text(
                                isArabic ? 'رفض' : 'Reject',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ] else if (status == 'confirmed') ...[
                            TextButton(
                              onPressed: () =>
                                  doc.reference.update({'status': 'done'}),
                              child: Text(
                                isArabic ? 'مكتمل' : 'Done',
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  doc.reference.update({'status': 'pending'}),
                              child: Text(
                                isArabic ? 'إلغاء' : 'Cancel',
                              ),
                            ),
                          ] else if (status == 'rejected') ...[
                            TextButton(
                              onPressed: () =>
                                  doc.reference.update({'status': 'pending'}),
                              child: Text(
                                isArabic ? 'إلغاء' : 'Cancel',
                              ),
                            ),
                          ],

                          const SizedBox(width: 4),

                          // ----- delete order -----
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            tooltip:
                            isArabic ? 'حذف الطلب' : 'Delete order',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(
                                    isArabic
                                        ? 'حذف الطلب'
                                        : 'Delete order',
                                  ),
                                  content: Text(
                                    isArabic
                                        ? 'هل أنت متأكد من حذف هذا الطلب؟ لا يمكن التراجع عن هذه العملية.'
                                        : 'Are you sure you want to delete this order? This action cannot be undone.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: Text(
                                        isArabic ? 'إلغاء' : 'Cancel',
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: Text(
                                        isArabic ? 'حذف' : 'Delete',
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await doc.reference.delete();
                              }
                            },
                          ),
                        ],
                      ),

                      // ---------- RATING + REVIEW FROM CUSTOMER ----------
                      if (rating > 0 || review.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            for (int i = 1; i <= 5; i++)
                              Icon(
                                i <= rating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              ),
                            if (rating > 0)
                              Text(
                                '  ${rating.toStringAsFixed(1)} / 5',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                          ],
                        ),
                        if (review.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              review,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}


/// ===================================================================
///  NEWS TAB
/// ===================================================================

class AdminNewsTab extends StatelessWidget {
  const AdminNewsTab({super.key});

  Future<void> _showNewsDialog(
      BuildContext context, {
        DocumentSnapshot? existingDoc,
      }) async {
    final isEditing = existingDoc != null;
    final data =
    isEditing ? existingDoc!.data() as Map<String, dynamic> : {};
    final titleController =
    TextEditingController(text: (data['title'] ?? '') as String);
    final bodyController =
    TextEditingController(text: (data['body'] ?? '') as String);
    bool active = (data['active'] ?? true) as bool;

    Uint8List? selectedImageBytes;
    final isArabic = _isArabic(context);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                isEditing
                    ? (isArabic ? 'تعديل خبر' : 'Edit news')
                    : (isArabic ? 'إضافة خبر' : 'Add news'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: isArabic ? 'العنوان' : 'Title',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: bodyController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: isArabic ? 'النص' : 'Text',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          final result =
                          await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            withData: true,
                          );
                          if (result != null &&
                              result.files.isNotEmpty) {
                            setStateDialog(() {
                              selectedImageBytes =
                                  result.files.first.bytes;
                            });
                          }
                        },
                        icon: const Icon(Icons.image),
                        label: Text(
                          isArabic
                              ? 'اختر صورة من الجهاز (اختياري)'
                              : 'Choose image from device (optional)',
                        ),
                      ),
                    ),
                    if (selectedImageBytes != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            selectedImageBytes!,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: active,
                          onChanged: (v) {
                            setStateDialog(() {
                              active = v ?? true;
                            });
                          },
                        ),
                        Text(
                          isArabic
                              ? 'نشط (يظهر في الصفحة الرئيسية)'
                              : 'Active (show on home page)',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final body = bodyController.text.trim();

                    if (title.isEmpty || body.isEmpty) return;

                    final collection =
                    FirebaseFirestore.instance.collection('news');

                    DocumentReference docRef;

                    String? imageBase64;

                    if (selectedImageBytes != null) {
                      imageBase64 = base64Encode(selectedImageBytes!);
                    } else if (isEditing) {
                      imageBase64 =
                      (data['imageBase64'] ?? '') as String;
                    }

                    if (isEditing) {
                      docRef = existingDoc!.reference;
                      await docRef.update({
                        'title': title,
                        'body': body,
                        'imageBase64': imageBase64 ?? '',
                        'active': active,
                      });
                    } else {
                      docRef = await collection.add({
                        'title': title,
                        'body': body,
                        'imageBase64': imageBase64 ?? '',
                        'active': active,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    isEditing
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

  @override
  Widget build(BuildContext context) {
    final isArabic = _isArabic(context);
    final newsStream = FirebaseFirestore.instance
        .collection('news')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewsDialog(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: newsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                isArabic
                    ? 'حدث خطأ أثناء تحميل الأخبار:\n${snapshot.error}'
                    : 'Error loading news:\n${snapshot.error}',
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
                isArabic ? 'لا توجد أخبار بعد.' : 'No news yet.',
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = (data['title'] ?? '') as String;
              final body = (data['body'] ?? '') as String;
              final active = (data['active'] ?? true) as bool;
              final imageBase64 =
              (data['imageBase64'] ?? '') as String;

              Uint8List? bytes;
              if (imageBase64.isNotEmpty) {
                try {
                  bytes =
                      Uint8List.fromList(base64Decode(imageBase64));
                } catch (_) {
                  bytes = null;
                }
              }

              return ListTile(
                leading: bytes != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    bytes,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                )
                    : const Icon(Icons.campaign_outlined),
                title: Text(title),
                subtitle: Text(
                  body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      active
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: active ? AppColors.green : Colors.grey,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          _showNewsDialog(context, existingDoc: doc),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => doc.reference.delete(),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// ===================================================================
///  SERVICES TAB
/// ===================================================================

class AdminServicesTab extends StatelessWidget {
  const AdminServicesTab({super.key});

  Future<void> _showServiceDialog(
      BuildContext context, {
        DocumentSnapshot? existingDoc,
      }) async {
    final isEditing = existingDoc != null;
    final data =
    isEditing ? existingDoc!.data() as Map<String, dynamic> : {};
    final titleController =
    TextEditingController(text: (data['title'] ?? '') as String);
    final subtitleController =
    TextEditingController(text: (data['subtitle'] ?? '') as String);
    final priceHintController = TextEditingController(
        text: (data['priceHint'] ?? '') as String);
    String colorName = (data['color'] ?? 'orange') as String;
    String iconType = (data['icon'] ?? 'sofa') as String;
    bool active = (data['active'] ?? true) as bool;
    bool isTop = (data['top'] ?? true) as bool;

    Uint8List? imageBytes;
    final isArabic = _isArabic(context);

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: Text(
                isEditing
                    ? (isArabic ? 'تعديل خدمة' : 'Edit service')
                    : (isArabic ? 'إضافة خدمة' : 'Add service'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText:
                        isArabic ? 'اسم الخدمة' : 'Service title',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: subtitleController,
                      decoration: InputDecoration(
                        labelText: isArabic
                            ? 'وصف / تفاصيل'
                            : 'Subtitle / description',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceHintController,
                      decoration: InputDecoration(
                        labelText: isArabic
                            ? 'وصف السعر (مثال: "ابتداءً من 50 \$")'
                            : 'Price hint (e.g. "From 50 \$ / sofa")',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: colorName,
                      decoration: InputDecoration(
                        labelText: isArabic ? 'اللون' : 'Color',
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'orange',
                          child: Text(isArabic ? 'برتقالي' : 'Orange'),
                        ),
                        DropdownMenuItem(
                          value: 'green',
                          child: Text(isArabic ? 'أخضر' : 'Green'),
                        ),
                        DropdownMenuItem(
                          value: 'blue',
                          child: Text(isArabic ? 'أزرق' : 'Blue'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setStateDialog(() => colorName = v);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: iconType,
                      decoration: InputDecoration(
                        labelText: isArabic ? 'نوع الأيقونة' : 'Icon type',
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'sofa',
                          child: Text(isArabic ? 'كنب' : 'Sofa'),
                        ),
                        DropdownMenuItem(
                          value: 'carpet',
                          child:
                          Text(isArabic ? 'سجاد' : 'Carpet'),
                        ),
                        DropdownMenuItem(
                          value: 'car',
                          child: Text(
                              isArabic ? 'مقاعد السيارة' : 'Car seats'),
                        ),
                        DropdownMenuItem(
                          value: 'curtains',
                          child: Text(isArabic ? 'ستائر' : 'Curtains'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setStateDialog(() => iconType = v);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: active,
                          onChanged: (v) {
                            setStateDialog(() => active = v ?? true);
                          },
                        ),
                        Text(isArabic ? 'نشط' : 'Active'),
                        const SizedBox(width: 16),
                        Checkbox(
                          value: isTop,
                          onChanged: (v) {
                            setStateDialog(() => isTop = v ?? true);
                          },
                        ),
                        Text(isArabic ? 'خدمة مميزة' : 'Top service'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          final result =
                          await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            withData: true,
                          );
                          if (result != null &&
                              result.files.isNotEmpty) {
                            setStateDialog(() {
                              imageBytes = result.files.first.bytes;
                            });
                          }
                        },
                        icon: const Icon(Icons.image),
                        label: Text(
                          isArabic
                              ? 'اختر صورة من الجهاز (اختياري)'
                              : 'Choose image from device (optional)',
                        ),
                      ),
                    ),
                    if (imageBytes != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            imageBytes!,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    String? base64;
                    if (imageBytes != null) {
                      base64 = base64Encode(imageBytes!);
                    } else if (isEditing) {
                      base64 =
                      (data['imageBase64'] ?? '') as String;
                    }

                    final payload = {
                      'title': title,
                      'subtitle': subtitleController.text.trim(),
                      'priceHint': priceHintController.text.trim(),
                      'color': colorName,
                      'icon': iconType,
                      'active': active,
                      'top': isTop,
                      'imageBase64': base64 ?? '',
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    if (isEditing) {
                      await existingDoc!.reference.update(payload);
                    } else {
                      await FirebaseFirestore.instance
                          .collection('services')
                          .add({
                        ...payload,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    }

                    if (context.mounted) {
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(
                    isEditing
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

  Future<void> _showOptionDialog(
      BuildContext context, {
        required String serviceId,
        DocumentSnapshot? existingDoc,
      }) async {
    final isEditing = existingDoc != null;
    final data =
    isEditing ? existingDoc!.data() as Map<String, dynamic> : {};
    final nameController =
    TextEditingController(text: (data['name'] ?? '') as String);
    final descriptionController = TextEditingController(
        text: (data['description'] ?? '') as String);
    final priceController =
    TextEditingController(text: (data['price'] ?? '').toString());
    final sortOrderController = TextEditingController(
        text: (data['sortOrder'] ?? 0).toString());

    final isArabic = _isArabic(context);

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            isEditing
                ? (isArabic ? 'تعديل خيار' : 'Edit option')
                : (isArabic ? 'إضافة خيار' : 'Add option'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText:
                    isArabic ? 'اسم الخيار' : 'Option name',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText:
                    isArabic ? 'الوصف' : 'Description',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceController,
                  keyboardType:
                  const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: InputDecoration(
                    labelText: isArabic ? 'السعر' : 'Price',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: sortOrderController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText:
                    isArabic ? 'ترتيب العرض' : 'Sort order',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final price =
                    double.tryParse(priceController.text) ?? 0;
                final sortOrder =
                    int.tryParse(sortOrderController.text) ?? 0;

                final dataPayload = {
                  'name': name,
                  'description': descriptionController.text.trim(),
                  'price': price,
                  'sortOrder': sortOrder,
                };

                final colRef = FirebaseFirestore.instance
                    .collection('services')
                    .doc(serviceId)
                    .collection('options');

                if (isEditing) {
                  await existingDoc!.reference.update(dataPayload);
                } else {
                  await colRef.add(dataPayload);
                }

                if (context.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: Text(
                isEditing
                    ? (isArabic ? 'حفظ' : 'Save')
                    : (isArabic ? 'إضافة' : 'Add'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final servicesStream = FirebaseFirestore.instance
        .collection('services')
        .orderBy('createdAt', descending: true)
        .snapshots();
    final isArabic = _isArabic(context);

    return StreamBuilder<QuerySnapshot>(
      stream: servicesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              isArabic
                  ? 'حدث خطأ أثناء تحميل الخدمات:\n${snapshot.error}'
                  : 'Error loading services:\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isArabic ? 'لا توجد خدمات بعد.' : 'No services yet.'),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _showServiceDialog(context),
                  icon: const Icon(Icons.add),
                  label: Text(
                    isArabic ? 'إضافة أول خدمة' : 'Add first service',
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showServiceDialog(context),
            child: const Icon(Icons.add),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = (data['title'] ?? '') as String;
              final subtitle =
              (data['subtitle'] ?? '') as String;
              final active = (data['active'] ?? true) as bool;
              final imageBase64 =
              (data['imageBase64'] ?? '') as String;

              Uint8List? bytes;
              if (imageBase64.isNotEmpty) {
                try {
                  bytes =
                      Uint8List.fromList(base64Decode(imageBase64));
                } catch (_) {
                  bytes = null;
                }
              }

              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ExpansionTile(
                  leading: bytes != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      bytes,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  )
                      : const Icon(Icons.cleaning_services),
                  title: Text(title),
                  subtitle: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color:
                        active ? AppColors.green : Colors.grey,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            _showServiceDialog(context,
                                existingDoc: doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.red),
                        onPressed: () => doc.reference.delete(),
                      ),
                    ],
                  ),
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: doc.reference
                          .collection('options')
                          .orderBy('sortOrder')
                          .snapshots(),
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              isArabic
                                  ? 'حدث خطأ أثناء تحميل الخيارات: ${snap.error}'
                                  : 'Error loading options: ${snap.error}',
                              style:
                              const TextStyle(color: Colors.red),
                            ),
                          );
                        }
                        final opts = snap.data?.docs ?? [];
                        return Column(
                          children: [
                            ...opts.map((optDoc) {
                              final optData =
                              optDoc.data() as Map<String, dynamic>;
                              final name =
                              (optData['name'] ?? '') as String;
                              final price =
                              (optData['price'] ?? 0) as num;
                              final desc =
                              (optData['description'] ?? '')
                              as String;

                              return ListTile(
                                dense: true,
                                title: Text(name),
                                subtitle: Text(
                                  desc,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${price.toStringAsFixed(2)}${S.of(context).currencySuffix}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.orange,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          size: 18),
                                      onPressed: () =>
                                          _showOptionDialog(
                                            context,
                                            serviceId: doc.id,
                                            existingDoc: optDoc,
                                          ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red, size: 18),
                                      onPressed: () =>
                                          optDoc.reference.delete(),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            TextButton.icon(
                              onPressed: () => _showOptionDialog(
                                context,
                                serviceId: doc.id,
                              ),
                              icon: const Icon(Icons.add),
                              label: Text(
                                isArabic
                                    ? 'إضافة خيار للخدمة'
                                    : 'Add option for service',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// ===================================================================
///  USERS TAB
/// ===================================================================

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final isArabic = _isArabic(context);
    final usersStream = FirebaseFirestore.instance
        .collection('users')
        .orderBy('name')
        .snapshots();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: isArabic
                  ? 'ابحث بالاسم أو البريد أو الهاتف...'
                  : 'Search by name, email, phone...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (value) {
              setState(() {
                _search = value.trim().toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: usersStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    isArabic
                        ? 'حدث خطأ أثناء تحميل المستخدمين:\n${snapshot.error}'
                        : 'Error loading users:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              var docs = snapshot.data?.docs ?? [];

              if (_search.isNotEmpty) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '') as String;
                  final email = (data['email'] ?? '') as String;
                  final phone = (data['phone'] ?? '') as String;
                  final all = '$name $email $phone'.toLowerCase();
                  return all.contains(_search);
                }).toList();
              }

              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    isArabic ? 'لا يوجد مستخدمون.' : 'No users.',
                  ),
                );
              }

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '') as String;
                  final email = (data['email'] ?? '') as String;
                  final phone = (data['phone'] ?? '') as String;
                  final role = (data['role'] ?? 'user') as String;
                  final active = (data['active'] ?? true) as bool;

                  return Card(
                    margin:
                    const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar
                          CircleAvatar(
                            child: Text(
                              name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Name + email + phone
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  name.isNotEmpty ? name : email,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (email.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                                if (phone.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '${isArabic ? '📞 ' : '📞 '}$phone',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Role + Active status column
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment:
                            CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    role,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: role == 'admin'
                                          ? AppColors.orange
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Switch(
                                    value: role == 'admin',
                                    onChanged: (v) {
                                      doc.reference.update({
                                        'role': v ? 'admin' : 'user',
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    active
                                        ? Icons.check_circle
                                        : Icons.remove_circle,
                                    size: 16,
                                    color: active
                                        ? AppColors.green
                                        : Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    active
                                        ? (isArabic ? 'نشط' : 'Active')
                                        : (isArabic
                                        ? 'محظور'
                                        : 'Blocked'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: active
                                          ? AppColors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
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
        ),
      ],
    );
  }
}

/// ===================================================================
///  OFFLINE ORDERS TAB
/// ===================================================================

class AdminOfflineOrdersTab extends StatelessWidget {
  const AdminOfflineOrdersTab({super.key});

  Stream<QuerySnapshot> get _offlineStream => FirebaseFirestore.instance
      .collection('orders')
      .where('source', isEqualTo: 'offline')
      .orderBy('createdAt', descending: true)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isArabic = s.isArabic;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOfflineDialog(context),
        icon: const Icon(Icons.add),
        label: Text(isArabic ? 'إضافة طلب يدوي' : 'Add offline order'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _offlineStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                isArabic
                    ? 'حدث خطأ أثناء تحميل الطلبات اليدوية:\n${snapshot.error}'
                    : 'Error loading offline orders:\n${snapshot.error}',
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
                    ? 'لا توجد طلبات يدوية حتى الآن.'
                    : 'No offline orders yet.',
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (context, index) =>
            const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final customerName =
              (data['customerName'] ??
                  data['userName'] ??
                  'Unknown') as String;
              final customerPhone =
              (data['customerPhone'] ??
                  data['userPhone'] ??
                  '') as String;
              final customerLocation =
              (data['customerLocation'] ??
                  data['userLocation'] ??
                  '') as String;
              final serviceName =
              (data['serviceName'] ?? 'Service') as String;

              final num qty = (data['quantity'] ?? 1) as num;
              final num unitPrice = (data['unitPrice'] ?? 0) as num;
              final num unitCost =
              (data['unitCost'] ?? data['costPrice'] ?? 0) as num;
              final num totalPrice =
              (data['totalPrice'] ?? (unitPrice * qty)) as num;
              final num totalCost =
              (data['totalCost'] ?? (unitCost * qty)) as num;
              final num profit =
              (data['profit'] ?? (totalPrice - totalCost)) as num;

              final sourceChannel =
              (data['sourceChannel'] ?? 'offline') as String;
              final note = (data['note'] ?? '') as String;

              final Timestamp? createdAt =
              data['createdAt'] is Timestamp
                  ? data['createdAt']
                  : null;
              final Timestamp? scheduledDate =
              data['scheduledDate'] is Timestamp
                  ? data['scheduledDate']
                  : null;

              String money(num value) =>
                  '${value.toStringAsFixed(2)}${s.currencySuffix}';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // title row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                AppColors.blue.withOpacity(0.1),
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.storefront_outlined,
                                color: AppColors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$serviceName ${isArabic ? '(يدوي)' : '(offline)'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              '${profit >= 0 ? '+' : ''}'
                                  '${profit.toStringAsFixed(2)}'
                                  '${s.currencySuffix} '
                                  '${isArabic ? 'ربح' : 'profit'}',
                              style: TextStyle(
                                color: profit >= 0
                                    ? AppColors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              customerName,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        if (customerPhone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_outlined,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                customerPhone,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (customerLocation.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  customerLocation,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.event,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                (isArabic
                                    ? 'موعد الزيارة: '
                                    : 'Scheduled: ') +
                                    _formatTs(scheduledDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (createdAt != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (isArabic
                                    ? 'تاريخ الإنشاء: '
                                    : 'Created: ') +
                                    _formatTs(createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              (isArabic ? 'الكمية: ' : 'Qty: ') +
                                  '$qty',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              (isArabic
                                  ? 'سعر الوحدة: '
                                  : 'Unit: ') +
                                  money(unitPrice),
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              (isArabic
                                  ? 'تكلفة الوحدة: '
                                  : 'Cost: ') +
                                  money(unitCost),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              (isArabic
                                  ? 'الإجمالي: '
                                  : 'Total: ') +
                                  money(totalPrice),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.orange,
                              ),
                            ),
                            const Spacer(),
                            Chip(
                              label: Text(
                                sourceChannel,
                                style:
                                const TextStyle(fontSize: 12),
                              ),
                              avatar: const Icon(
                                Icons.chat_bubble_outline,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                        if (note.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            note,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),

                        // Invoice + delete buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OfflineInvoicePage(
                                      orderId: doc.id,
                                      data: data,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.receipt_long_outlined,
                              ),
                              label: Text(
                                isArabic
                                    ? 'عرض الفاتورة'
                                    : 'Invoice',
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              tooltip: isArabic
                                  ? 'حذف الطلب'
                                  : 'Delete order',
                              onPressed: () async {
                                final confirm =
                                await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(
                                      isArabic
                                          ? 'حذف الطلب'
                                          : 'Delete order',
                                    ),
                                    content: Text(
                                      isArabic
                                          ? 'هل أنت متأكد من حذف هذا الطلب اليدوي؟ لا يمكن التراجع عن هذه العملية.'
                                          : 'Are you sure you want to delete this offline order? This action cannot be undone.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(
                                                ctx, false),
                                        child: Text(
                                          isArabic
                                              ? 'إلغاء'
                                              : 'Cancel',
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton
                                            .styleFrom(
                                          backgroundColor:
                                          Colors.red,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(
                                                ctx, true),
                                        child: Text(
                                          isArabic
                                              ? 'حذف'
                                              : 'Delete',
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await doc.reference.delete();
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  Future<void> _showAddOfflineDialog(BuildContext context) async {
    final s = S.of(context);
    final isArabic = s.isArabic;

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final locationController = TextEditingController();
    final serviceController = TextEditingController();
    final unitPriceController = TextEditingController();
    final costPriceController = TextEditingController();
    final noteController = TextEditingController();

    String sourceChannel = 'WhatsApp';
    int quantity = 1;
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            Future<void> pickDate() async {
              final now = DateTime.now();
              final date = await showDatePicker(
                context: dialogContext,
                initialDate: now,
                firstDate: now.subtract(const Duration(days: 365)),
                lastDate: now.add(const Duration(days: 365)),
              );
              if (date == null) return;
              final time = await showTimePicker(
                context: dialogContext,
                initialTime: TimeOfDay.now(),
              );
              if (time == null) return;
              setStateDialog(() {
                selectedDate = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                isArabic ? 'إضافة طلب يدوي' : 'Add offline order',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText:
                        isArabic ? 'اسم العميل' : 'Customer name',
                        prefixIcon:
                        const Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: isArabic ? 'الهاتف' : 'Phone',
                        prefixIcon:
                        const Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: isArabic
                            ? 'الموقع / العنوان'
                            : 'Location / address',
                        prefixIcon:
                        const Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: serviceController,
                      decoration: InputDecoration(
                        labelText:
                        isArabic ? 'الخدمة' : 'Service',
                        prefixIcon:
                        const Icon(Icons.cleaning_services),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(isArabic ? 'الكمية' : 'Quantity'),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                          ),
                          onPressed: quantity > 1
                              ? () {
                            setStateDialog(() {
                              quantity--;
                            });
                          }
                              : null,
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                          ),
                          onPressed: () {
                            setStateDialog(() {
                              quantity++;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: unitPriceController,
                            keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: isArabic
                                  ? 'سعر الوحدة (دينار)'
                                  : 'Unit price (LYD)',
                              prefixIcon:
                              const Icon(Icons.price_change),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: costPriceController,
                            keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: isArabic
                                  ? 'تكلفة الوحدة (دينار)'
                                  : 'Cost price (LYD)',
                              prefixIcon:
                              const Icon(Icons.attach_money),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        selectedDate == null
                            ? (isArabic
                            ? 'اختر التاريخ والوقت'
                            : 'Choose date & time')
                            : _formatTs(
                          Timestamp.fromDate(selectedDate!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: sourceChannel,
                      items: const [
                        DropdownMenuItem(
                          value: 'WhatsApp',
                          child: Text('WhatsApp'),
                        ),
                        DropdownMenuItem(
                          value: 'Phone',
                          child: Text('Phone'),
                        ),
                        DropdownMenuItem(
                          value: 'Walk-in',
                          child: Text('Walk-in'),
                        ),
                        DropdownMenuItem(
                          value: 'Other',
                          child: Text('Other'),
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText:
                        isArabic ? 'مصدر الطلب' : 'Source',
                        prefixIcon:
                        const Icon(Icons.chat_bubble_outline),
                      ),
                      onChanged: (value) {
                        if (value == null) return;
                        setStateDialog(() {
                          sourceChannel = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: isArabic
                            ? 'ملاحظات (اختياري)'
                            : 'Notes (optional)',
                        prefixIcon:
                        const Icon(Icons.note_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext),
                  child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final service =
                    serviceController.text.trim();
                    final double unit =
                        double.tryParse(
                            unitPriceController.text) ??
                            0;
                    final double cost =
                        double.tryParse(
                            costPriceController.text) ??
                            0;

                    if (name.isEmpty ||
                        service.isEmpty ||
                        unit <= 0) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            isArabic
                                ? 'يرجى إدخال اسم العميل، الخدمة وسعر الوحدة.'
                                : 'Please fill customer, service and unit price.',
                          ),
                        ),
                      );
                      return;
                    }

                    final authUser =
                        FirebaseAuth.instance.currentUser;

                    final double total = unit * quantity;
                    final double totalCost =
                        cost * quantity;
                    final double profit =
                        total - totalCost;

                    await FirebaseFirestore.instance
                        .collection('orders')
                        .add({
                      'source': 'offline',
                      'customerName': name,
                      'userName': name,
                      'customerPhone':
                      phoneController.text.trim(),
                      'userPhone':
                      phoneController.text.trim(),
                      'customerLocation':
                      locationController.text.trim(),
                      'userLocation':
                      locationController.text.trim(),
                      'serviceName': service,
                      'quantity': quantity,
                      'unitPrice': unit,
                      'unitCost': cost,
                      'totalPrice': total,
                      'totalCost': totalCost,
                      'profit': profit,
                      'sourceChannel': sourceChannel,
                      'note': noteController.text.trim(),
                      'scheduledDate': selectedDate,
                      'createdAt':
                      FieldValue.serverTimestamp(),
                      'createdByAdminId': authUser?.uid,
                    });

                    if (context.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: Text(isArabic ? 'حفظ' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

