import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../settings/app_theme.dart';
import '../settings/app_strings.dart';

class OfflineInvoicePage extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;

  const OfflineInvoicePage({
    super.key,
    required this.orderId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isArabic = s.isArabic;

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final scheduled = (data['scheduledDate'] as Timestamp?)?.toDate();

    final quantity = (data['quantity'] ?? 1) as int;
    final unitPrice = (data['unitPrice'] as num?)?.toDouble();
    final totalPrice = (data['totalPrice'] as num?)?.toDouble();
    final totalCost = (data['totalCost'] as num?)?.toDouble();
    final costPerUnit = (data['unitCost'] as num?)?.toDouble();

    double? profit;
    if (totalPrice != null && totalCost != null) {
      profit = totalPrice - totalCost;
    }

    String formatMoney(num? value) {
      if (value == null) return '-';
      return '${value.toStringAsFixed(2)}${s.currencySuffix}';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isArabic ? 'الفاتورة' : 'Invoice'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ----------------------------------------------------------------
                  // HEADER
                  // ----------------------------------------------------------------
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 60,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'لمعة الإتقان',
                            style: TextStyle(
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
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isArabic ? 'رقم الفاتورة' : 'Invoice #',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            orderId.substring(
                              0,
                              orderId.length > 8 ? 8 : orderId.length,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (createdAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              dateFormat.format(createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // ----------------------------------------------------------------
                  // CUSTOMER INFO
                  // ----------------------------------------------------------------
                  Text(
                    isArabic ? 'بيانات العميل' : 'Bill to',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (data['userName'] ?? 'Unknown') as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if ((data['userPhone'] ?? '').toString().isNotEmpty)
                    Text(
                      (isArabic ? 'الهاتف: ' : 'Phone: ') +
                          data['userPhone'].toString(),
                    ),
                  if ((data['userLocation'] ?? '').toString().isNotEmpty)
                    Text(
                      (isArabic ? 'العنوان: ' : 'Address: ') +
                          data['userLocation'].toString(),
                    ),
                  if (scheduled != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      (isArabic ? 'موعد الخدمة: ' : 'Service date: ') +
                          dateFormat.format(scheduled),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ----------------------------------------------------------------
                  // ITEMS TABLE
                  // ----------------------------------------------------------------
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.background,
                    ),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(3),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                        3: FlexColumnWidth(1),
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey,
                                width: 0.4,
                              ),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                isArabic ? 'الخدمة' : 'Service',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                isArabic ? 'الكمية' : 'Qty',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                isArabic ? 'سعر الوحدة' : 'Unit',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                isArabic ? 'الإجمالي' : 'Total',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                (data['serviceName'] ?? 'Service') as String,
                              ),
                            ),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                '$quantity',
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                formatMoney(unitPrice ?? costPerUnit),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                formatMoney(totalPrice),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ----------------------------------------------------------------
                  // TOTALS
                  // ----------------------------------------------------------------
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (totalPrice != null)
                          Text(
                            (isArabic ? 'الإجمالي: ' : 'Total: ') +
                                formatMoney(totalPrice),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (totalCost != null)
                          Text(
                            (isArabic ? 'التكلفة: ' : 'Cost: ') +
                                formatMoney(totalCost),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        if (profit != null)
                          Text(
                            (isArabic ? 'الربح: ' : 'Profit: ') +
                                formatMoney(profit),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: profit >= 0
                                  ? AppColors.green
                                  : Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ----------------------------------------------------------------
                  // NOTES + THANK YOU
                  // ----------------------------------------------------------------
                  Text(
                    (isArabic ? 'ملاحظات: ' : 'Notes: ') +
                        ((data['note'] ?? '') as String),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isArabic
                        ? 'شكراً لاختيارك لمعة الإتقان ✨'
                        : 'Thank you for choosing Lamaa Itqan ✨',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
