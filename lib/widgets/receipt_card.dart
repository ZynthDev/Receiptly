import 'dart:io';
import 'package:flutter/material.dart';
import '../models/receipt.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';
import '../models/expense_category.dart';

class ReceiptCard extends StatelessWidget {
  final Receipt receipt;
  final VoidCallback onTap;

  const ReceiptCard({
    super.key,
    required this.receipt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Receipt image
            _buildReceiptImage(),
            
            // Receipt details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Merchant name
                  Text(
                    receipt.merchantName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Date
                  Text(
                    Helpers.formatRelativeDate(receipt.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textLight,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Category chip
                  _buildCategoryChip(),
                  
                  const SizedBox(height: 8),
                  
                  // Amount
                  Text(
                    Helpers.formatCurrency(receipt.totalAmount),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  
                  // Items count
                  if (receipt.items.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${receipt.items.length} item${receipt.items.length != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: SizedBox(
        height: 120,
        width: double.infinity,
        child: File(receipt.imagePath).existsSync()
            ? Image.file(
                File(receipt.imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildImagePlaceholder();
                },
              )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: Icon(
        Icons.receipt_long,
        size: 40,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildCategoryChip() {
    final category = ExpenseCategory.getCategoryByName(receipt.category);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            category.icon,
            size: 12,
            color: category.color,
          ),
          const SizedBox(width: 4),
          Text(
            receipt.category,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: category.color,
            ),
          ),
        ],
      ),
    );
  }
}
