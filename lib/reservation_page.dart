import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'settings/app_theme.dart';
import 'settings/app_strings.dart';

class ReservationPage extends StatefulWidget {
  final String serviceId;
  final String serviceName;

  const ReservationPage({
    super.key,
    required this.serviceId,
    required this.serviceName,
  });

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  String? _selectedOptionId;
  String? _selectedOptionName;
  double? _selectedPrice;

  bool _useCustomOption = false;
  final TextEditingController _customOptionController =
  TextEditingController();

  DateTime? _selectedDateTime;
  final TextEditingController _noteController = TextEditingController();

  bool _submitting = false;

  // quantity
  int _quantity = 1;

  // service data & image
  Map<String, dynamic>? _serviceData;
  Uint8List? _serviceImageBytes;

  Future<void> _loadService() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceId)
          .get();
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      Uint8List? bytes;
      final base64 = (data['imageBase64'] ?? '') as String;
      if (base64.isNotEmpty) {
        try {
          bytes = Uint8List.fromList(base64Decode(base64));
        } catch (_) {
          bytes = null;
        }
      }
      if (mounted) {
        setState(() {
          _serviceData = data;
          _serviceImageBytes = bytes;
        });
      }
    } catch (_) {
      // ignore, page still works without image
    }
  }

  String get _serviceSubtitle =>
      (_serviceData?['subtitle'] ?? '') as String;

  String get _servicePriceHint =>
      (_serviceData?['priceHint'] ?? '') as String;

  @override
  void initState() {
    super.initState();
    _loadService();
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final s = S.of(context);
    final isArabic = s.isArabic;

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      helpText: isArabic ? 'اختر التاريخ' : 'Select date',
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: isArabic ? 'اختر الوقت' : 'Select time',
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    final s = S.of(context);
    final isArabic = s.isArabic;

    if (!_useCustomOption &&
        (_selectedOptionId == null || _selectedPrice == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'يرجى اختيار خيار من القائمة أو تفعيل الخيار المخصص.'
                : 'Please select an option or choose custom.',
          ),
        ),
      );
      return;
    }

    if (_useCustomOption && _customOptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'يرجى وصف المقاس أو الخيار المخصص.'
                : 'Please describe the custom size / option.',
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) {
        throw Exception(
          isArabic ? 'المستخدم غير مسجل الدخول.' : 'Not logged in',
        );
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .get();

      final userData =
          userDoc.data() as Map<String, dynamic>? ?? <String, dynamic>{};

      final userName =
      (userData['name'] ?? authUser.email?.split('@').first ?? '') as String;
      final userPhone = (userData['phone'] ?? '') as String;
      final userLocation = (userData['location'] ?? '') as String;
      final userLocationDesc =
      (userData['locationDescription'] ?? '') as String;

      final isCustom = _useCustomOption;
      final optionName = isCustom
          ? _customOptionController.text.trim()
          : _selectedOptionName;

      final double? unitPrice = isCustom ? null : _selectedPrice;
      final double? totalPrice = (isCustom || _selectedPrice == null)
          ? null
          : _selectedPrice! * _quantity;

      await FirebaseFirestore.instance.collection('orders').add({
        'userId': authUser.uid,
        'userName': userName,
        'userPhone': userPhone,
        'userLocation': userLocation,
        'userLocationDescription': userLocationDesc,
        'serviceId': widget.serviceId,
        'serviceName': widget.serviceName,
        'optionId': isCustom ? 'custom' : _selectedOptionId,
        'optionName': optionName,
        'isCustomOption': isCustom,
        'quantity': _quantity,
        'unitPrice': unitPrice,
        'totalPrice': totalPrice,
        'note': _noteController.text.trim(),
        'status': 'pending',
        'scheduledDate': _selectedDateTime,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تم إرسال الحجز بنجاح 🎉'
                : 'Reservation submitted successfully 🎉',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (S.of(context).isArabic
                ? 'حدث خطأ أثناء إرسال الحجز: '
                : 'Error submitting reservation: ') +
                e.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _customOptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isArabic = s.isArabic;

    final optionsStream = FirebaseFirestore.instance
        .collection('services')
        .doc(widget.serviceId)
        .collection('options')
        .orderBy('sortOrder')
        .snapshots();

    String money(num value) =>
        '${value.toStringAsFixed(2)}${s.currencySuffix}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ---------- HEADER IMAGE ----------
          SizedBox(
            height: 260,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_serviceImageBytes != null)
                  Image.memory(
                    _serviceImageBytes!,
                    fit: BoxFit.cover,
                  )
                else
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.orange,
                          AppColors.green,
                          AppColors.blue,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.75),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor:
                                Colors.white.withOpacity(0.15),
                              ),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.serviceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_serviceSubtitle.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            _serviceSubtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        if (_servicePriceHint.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _servicePriceHint,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---------- CONTENT ----------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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

                final docs = snapshot.data?.docs ?? [];

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---------- OPTIONS ----------
                      if (docs.isNotEmpty) ...[
                        Text(
                          isArabic ? 'اختر خياراً' : 'Choose an option',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 3,
                          child: Column(
                            children: docs.map((doc) {
                              final data =
                              doc.data() as Map<String, dynamic>;
                              final name =
                              (data['name'] ?? '') as String;
                              final desc =
                              (data['description'] ?? '') as String;
                              final price =
                              (data['price'] ?? 0) as num;
                              final id = doc.id;

                              return RadioListTile<String>(
                                value: id,
                                groupValue: _useCustomOption
                                    ? null
                                    : _selectedOptionId,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _useCustomOption = false;
                                    _selectedOptionId = value;
                                    _selectedOptionName = name;
                                    _selectedPrice = price.toDouble();
                                  });
                                },
                                activeColor: AppColors.orange,
                                title: Text(name),
                                subtitle: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    if (desc.isNotEmpty) Text(desc),
                                    Text(
                                      money(price),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // ---------- CUSTOM OPTION ----------
                      Text(
                        isArabic
                            ? 'أو اختر مقاس / خيار مخصص'
                            : 'Or custom size / option',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 3,
                        child: Column(
                          children: [
                            SwitchListTile(
                              value: _useCustomOption,
                              activeColor: AppColors.green,
                              title: Text(
                                isArabic
                                    ? 'استخدام خيار مخصص'
                                    : 'Use custom option',
                              ),
                              subtitle: Text(
                                isArabic
                                    ? 'مثال: "سجادة غرفة 5×7" أو "كنبة حرف L".'
                                    : 'For example: “Carpet 5×7 room” or “L-shaped sofa”.',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _useCustomOption = value;
                                  if (value) {
                                    _selectedOptionId = null;
                                    _selectedOptionName = null;
                                    _selectedPrice = null;
                                  }
                                });
                              },
                            ),
                            if (_useCustomOption)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 16),
                                child: TextField(
                                  controller: _customOptionController,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    labelText: isArabic
                                        ? 'صف طلبك'
                                        : 'Describe your request',
                                    hintText: isArabic
                                        ? 'مثال: "كنبة كبيرة على شكل زاوية، سجادة 3×4 مع بقع"'
                                        : 'Example: “Big corner sofa, 3×4 carpet with stains”',
                                    border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            if (_useCustomOption)
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 16, right: 16, bottom: 16),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        isArabic
                                            ? 'سيتم تأكيد السعر معك هاتفياً للطلبات المخصصة.'
                                            : 'Price will be confirmed with you by phone for custom requests.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ---------- QUANTITY ----------
                      Text(
                        isArabic ? 'الكمية' : 'Quantity',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: _quantity > 1
                                    ? () {
                                  setState(() {
                                    _quantity--;
                                  });
                                }
                                    : null,
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                ),
                              ),
                              Text(
                                '$_quantity',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _quantity++;
                                  });
                                },
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.format_list_numbered,
                                color: AppColors.orange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isArabic ? 'عناصر' : 'items',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.darkText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ---------- DATE / TIME ----------
                      Text(
                        isArabic
                            ? 'التاريخ والوقت المفضلان'
                            : 'Preferred date & time',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.orange.withOpacity(0.6),
                          ),
                          foregroundColor: AppColors.orange,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: _pickDateTime,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _selectedDateTime == null
                              ? (isArabic
                              ? 'اختر التاريخ والوقت'
                              : 'Choose date & time')
                              : _formatDateTime(_selectedDateTime!),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ---------- NOTES ----------
                      Text(
                        isArabic
                            ? 'ملاحظات إضافية (اختياري)'
                            : 'Additional notes (optional)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: isArabic
                              ? 'تفاصيل عن الموقع، مواقف السيارات، الحيوانات الأليفة، إلخ.'
                              : 'Details about location, parking, pets, etc.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ---------- TOTAL + BUTTON ----------
                      Row(
                        children: [
                          if (!_useCustomOption && _selectedPrice != null)
                            Text(
                              (isArabic ? 'الإجمالي: ' : 'Total: ') +
                                  money(_selectedPrice! * _quantity),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.orange,
                              ),
                            )
                          else
                            Text(
                              isArabic
                                  ? 'الإجمالي: سيتم تأكيده معك'
                                  : 'Total: to be confirmed',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: _submitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.orange,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            child: _submitting
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                                : Text(
                              isArabic
                                  ? 'تأكيد الحجز'
                                  : 'Confirm booking',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
