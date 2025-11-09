// Create client_discounts_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/data/repositories/marketing_repository.dart';

class ClientDiscountsScreen extends StatelessWidget {
  final String barberId;
  final String barberName;

  const ClientDiscountsScreen({
    super.key,
    required this.barberId,
    required this.barberName,
  });

  @override
  Widget build(BuildContext context) {
    final marketingRepository = MarketingRepository();

    return Scaffold(
      appBar: AppBar(
        title: Text('Special Offers - $barberName'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: marketingRepository.getActiveDiscounts(barberId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading discounts: ${snapshot.error}'),
            );
          }

          final discounts = snapshot.data ?? [];

          if (discounts.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: discounts.length,
            itemBuilder: (context, index) {
              final discount = discounts[index];
              return _buildDiscountCard(discount);
            },
          );
        },
      ),
    );
  }

  Widget _buildDiscountCard(Map<String, dynamic> discount) {
    final isExpired =
        DateTime.now().millisecondsSinceEpoch > discount['expiresAt'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isExpired ? Colors.grey[100] : AppColors.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    discount['title'] ?? 'Special Offer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isExpired ? Colors.grey : AppColors.text,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? Colors.grey
                        : AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${discount['discount']}% OFF',
                    style: TextStyle(
                      color: isExpired ? Colors.grey : AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (discount['description'] != null) ...[
              Text(
                discount['description']!,
                style: TextStyle(
                  color: isExpired ? Colors.grey : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Icon(Icons.local_offer_rounded,
                    size: 16,
                    color: isExpired ? Colors.grey : AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Code: ${discount['discountCode']}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isExpired ? Colors.grey : AppColors.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Valid until ${_formatDate(discount['expiresAt'])}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isExpired ? Colors.grey : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (isExpired) ...[
              const SizedBox(height: 8),
              Text(
                'EXPIRED',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Current Offers',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for special promotions and discounts',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(int milliseconds) {
    return DateFormat('MMM d, yyyy')
        .format(DateTime.fromMillisecondsSinceEpoch(milliseconds));
  }
}
