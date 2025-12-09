import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'settings/app_theme.dart';
import 'settings/app_strings.dart';

class OrderInvoicePage extends StatelessWidget {
  final String orderId;

  const OrderInvoicePage({
    super.key,
    required this.orderId,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.green;
      case 'done':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return AppColors.orange; // pending
    }
  }

  String _statusLabel(BuildContext context, String status) {
    final s = S.of(context);
    switch (status) {
      case 'confirmed':
        return s.statusConfirmed;
      case 'done':
        return s.statusCompleted;
      case 'rejected':
        return s.statusRejected;
      default:
        return s.statusPending;
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    final d = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isArabic = s.isArabic;

    String money(num? value) {
      if (value == null) return '-';
      return '${value.toStringAsFixed(2)}${s.currencySuffix}';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isArabic ? 'فاتورة الطلب' : 'Order invoice'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .doc(orderId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    s.errorLoadingOrders(snapshot.error.toString()),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(
                  child: Text(
                    isArabic ? 'لم يتم العثور على الطلب.' : 'Order not found.',
                  ),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;

              // ------------ READ DATA ------------
              final customerName =
              (data['userName'] ?? 'Unknown') as String;
              final customerPhone =
              (data['userPhone'] ?? '') as String;
              final customerLocation =
              (data['userLocation'] ?? '') as String;

              final serviceName =
              (data['serviceName'] ?? 'Service') as String;
              final optionName =
              (data['optionName'] ?? '') as String;

              final status = (data['status'] ?? 'pending') as String;

              final num quantityNum = (data['quantity'] ?? 1) as num;
              final int quantity = quantityNum.toInt();

              final num? totalPriceNum = data['totalPrice'] as num?;
              final num? unitPriceNum = data['unitPrice'] as num?;

              double? totalPrice =
              totalPriceNum != null ? totalPriceNum.toDouble() : null;
              double? unitPrice =
              unitPriceNum != null ? unitPriceNum.toDouble() : null;

              if (unitPrice == null &&
                  totalPrice != null &&
                  quantity > 0) {
                unitPrice = totalPrice / quantity;
              }

              final rating = (data['rating'] ?? 0) as num?;
              final review = (data['review'] ?? '') as String;
              final hasRating = rating != null && rating > 0;

              final createdAt =
              (data['createdAt'] as Timestamp?)?.toDate();
              final scheduledAt =
              (data['scheduledDate'] as Timestamp?)?.toDate();

              final orderIdShort =
              orderId.length > 10 ? orderId.substring(0, 10) : orderId;

              // ------------ UI ------------
              return SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER ROW (logo + app name + status)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                'assets/images/logo.png',
                                height: 56,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.appName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isArabic
                                        ? 'فاتورة خدمات التنظيف'
                                        : 'Cleaning services invoice',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    (isArabic ? 'معرف الطلب: ' : 'Order ID: ') +
                                        orderIdShort,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _statusLabel(context, status),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _statusColor(status),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(),

                        // CUSTOMER DETAILS
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              color: AppColors.orange,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isArabic
                                  ? 'بيانات العميل'
                                  : 'Customer details',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _twoColumnRow(
                          label: isArabic ? 'الاسم' : 'Name',
                          value: customerName,
                        ),
                        if (customerPhone.isNotEmpty)
                          _twoColumnRow(
                            label: isArabic ? 'الهاتف' : 'Phone',
                            value: customerPhone,
                          ),
                        if (customerLocation.isNotEmpty)
                          _twoColumnRow(
                            label: isArabic ? 'الموقع' : 'Location',
                            value: customerLocation,
                          ),

                        const SizedBox(height: 16),
                        const Divider(),

                        // SERVICE DETAILS
                        Row(
                          children: [
                            const Icon(
                              Icons.cleaning_services_rounded,
                              color: AppColors.green,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isArabic
                                  ? 'تفاصيل الخدمة'
                                  : 'Service details',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _twoColumnRow(
                          label: isArabic ? 'الخدمة' : 'Service',
                          value: serviceName,
                        ),
                        if (optionName.isNotEmpty)
                          _twoColumnRow(
                            label: isArabic ? 'الخيار' : 'Option',
                            value: optionName,
                          ),
                        if (scheduledAt != null)
                          _twoColumnRow(
                            label: isArabic ? 'الموعد' : 'Scheduled',
                            value: _formatDateTime(scheduledAt),
                          ),
                        if (createdAt != null)
                          _twoColumnRow(
                            label: isArabic ? 'تاريخ الإنشاء' : 'Created',
                            value: _formatDateTime(createdAt),
                          ),

                        const SizedBox(height: 16),
                        const Divider(),

                        // PAYMENT
                        Row(
                          children: [
                            const Icon(
                              Icons.payment_outlined,
                              color: AppColors.blue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isArabic ? 'الدفع' : 'Payment',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _twoColumnRow(
                          label: isArabic
                              ? 'المبلغ الإجمالي'
                              : 'Total amount',
                          value: money(totalPrice),
                          valueStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.orange,
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Divider(),

                        // FEEDBACK
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rate_rounded,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isArabic
                                  ? 'تقييمك للخدمة'
                                  : 'Your feedback',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (!hasRating && review.isEmpty)
                          Text(
                            isArabic
                                ? 'لم تقم بتقييم هذه الخدمة بعد.'
                                : 'You have not rated this service yet.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          )
                        else ...[
                          if (hasRating)
                            Row(
                              children: [
                                Row(
                                  children: List.generate(5, (index) {
                                    final starIndex = index + 1;
                                    return Icon(
                                      starIndex <= (rating ?? 0)
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: Colors.amber,
                                      size: 20,
                                    );
                                  }),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  rating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          if (review.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '"$review"',
                              style: const TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],

                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            isArabic
                                ? 'شكرًا لاختيارك ${s.appName} ✨'
                                : 'Thank you for choosing ${s.appName} ✨',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Small helper row used in sections
  Widget _twoColumnRow({
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: valueStyle ??
                    const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
