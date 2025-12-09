import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'settings/app_theme.dart';
import 'settings/app_strings.dart';
import 'order_invoice_page.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

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

  String _formatDateTime(BuildContext context, DateTime? dt) {
    final loc = S.of(context);
    if (dt == null) return loc.notSet;
    final d = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _showRatingDialog(
      BuildContext context, {
        required DocumentSnapshot doc,
        num? existingRating,
        String existingReview = '',
      }) async {
    final loc = S.of(context);

    double rating = (existingRating ?? 0).toDouble();
    final TextEditingController reviewController =
    TextEditingController(text: existingReview);

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: Text(loc.rateServiceTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        return IconButton(
                          onPressed: () {
                            setStateDialog(() {
                              rating = starIndex.toDouble();
                            });
                          },
                          icon: Icon(
                            starIndex <= rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 30,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reviewController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: loc.adminCommentLabel,
                        hintText: loc.adminCommentHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(loc.cancelButton),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (rating <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.pleaseSelectStarRating),
                        ),
                      );
                      return;
                    }

                    await doc.reference.update({
                      'rating': rating,
                      'review': reviewController.text.trim(),
                    });

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(loc.submitButton),
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
    final loc = S.of(context);
    final user = FirebaseAuth.instance.currentUser!;
    final ordersStream = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.myOrdersTitle),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ordersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                loc.errorLoadingOrders(snapshot.error.toString()),
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
                loc.noOrdersYet,
                style: const TextStyle(color: AppColors.darkText),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final serviceName =
              (data['serviceName'] ?? 'Service') as String;
              final optionName = (data['optionName'] ?? '') as String;
              final status = (data['status'] ?? 'pending') as String;
              final totalPrice = data['totalPrice'];
              final scheduledDate =
              (data['scheduledDate'] as Timestamp?)?.toDate();
              final createdAt =
              (data['createdAt'] as Timestamp?)?.toDate();
              final rating = (data['rating'] ?? 0) as num?;
              final review = (data['review'] ?? '') as String;
              final hasRating = rating != null && rating > 0;

              final subtitleParts = <String>[];
              if (optionName.isNotEmpty) {
                subtitleParts.add(optionName);
              }
              if (scheduledDate != null) {
                subtitleParts.add(
                  '${loc.visitPrefix}${_formatDateTime(context, scheduledDate)}',
                );
              }

              final canRate =
                  status == 'done' && !hasRating; // only once, after done

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderInvoicePage(orderId: doc.id),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Icon column
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.cleaning_services_rounded,
                            color: AppColors.orange,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Text column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row: service + status
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      serviceName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.darkText,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _statusLabel(context, status),
                                      style: TextStyle(
                                        color: _statusColor(status),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              if (subtitleParts.isNotEmpty)
                                Text(
                                  subtitleParts.join(' • '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),

                              const SizedBox(height: 4),

                              if (createdAt != null)
                                Text(
                                  '${loc.createdPrefix}${_formatDateTime(context, createdAt)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),

                              const SizedBox(height: 4),

                              Row(
                                children: [
                                  if (totalPrice != null)
                                    Text(
                                      '$totalPrice${loc.currencySuffix}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.orange,
                                      ),
                                    ),
                                  const Spacer(),
                                  if (hasRating)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 16,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          rating!.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (canRate) ...[
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () => _showRatingDialog(
                                        context,
                                        doc: doc,
                                        existingRating: rating,
                                        existingReview: review,
                                      ),
                                      child: Text(
                                        loc.rateButtonLabel,
                                        style:
                                        const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ],
                          ),
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
}
