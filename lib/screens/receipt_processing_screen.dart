import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/receipt.dart';
import '../providers/receipt_provider.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';
import '../models/expense_category.dart';

class ReceiptProcessingScreen extends StatefulWidget {
  final File imageFile;

  const ReceiptProcessingScreen({
    super.key,
    required this.imageFile,
  });

  @override
  State<ReceiptProcessingScreen> createState() => _ReceiptProcessingScreenState();
}

class _ReceiptProcessingScreenState extends State<ReceiptProcessingScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _successController;
  Receipt? _processedReceipt;
  bool _isProcessing = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _successController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _animationController.repeat();
    _processReceiptImage();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _processReceiptImage() async {
    try {
      final receiptProvider = context.read<ReceiptProvider>();
      final receipt = await receiptProvider.processReceiptImage(widget.imageFile);
      
      if (receipt != null) {
        setState(() {
          _processedReceipt = receipt;
          _isProcessing = false;
        });
        _animationController.stop();
        _successController.forward();
      } else {
        _handleError('Failed to process receipt');
      }
    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _handleError(String error) {
    setState(() {
      _hasError = true;
      _errorMessage = error;
      _isProcessing = false;
    });
    _animationController.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Processing Receipt'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !_isProcessing,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Image preview
              _buildImagePreview(),
              
              const SizedBox(height: 32),
              
              // Processing status
              Expanded(
                child: _buildProcessingContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          widget.imageFile,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildProcessingContent() {
    if (_hasError) {
      return _buildErrorContent();
    } else if (_isProcessing) {
      return _buildProcessingIndicator();
    } else {
      return _buildResultContent();
    }
  }

  Widget _buildProcessingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _animationController.value * 2 * 3.14159,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'Analyzing Receipt...',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Please wait while we extract the information',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 24),
        
        LinearProgressIndicator(
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      ],
    );
  }

  Widget _buildErrorContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 80,
          color: AppTheme.errorColor,
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'Processing Failed',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.errorColor,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          _errorMessage ?? 'An unexpected error occurred',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _retryProcessing,
                child: const Text('Try Again'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultContent() {
    if (_processedReceipt == null) return const SizedBox();
    
    return Column(
      children: [
        // Success animation
        ScaleTransition(
          scale: Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
          ),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.successColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'Receipt Processed!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.successColor,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Receipt summary card
        Expanded(
          child: _buildReceiptSummary(),
        ),
        
        const SizedBox(height: 24),
        
        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Discard'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveReceipt,
                child: const Text('Save Receipt'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReceiptSummary() {
    if (_processedReceipt == null) return const SizedBox();
    
    final category = ExpenseCategory.getCategoryByName(_processedReceipt!.category);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Merchant and amount
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _processedReceipt!.merchantName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Helpers.formatDateTime(_processedReceipt!.date),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  Helpers.formatCurrency(_processedReceipt!.totalAmount),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Category chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: 16,
                    color: category.color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _processedReceipt!.category,
                    style: TextStyle(
                      color: category.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            if (_processedReceipt!.items.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              
              Text(
                'Items (${_processedReceipt!.items.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 12),
              
              ...List.generate(
                _processedReceipt!.items.length.clamp(0, 3), // Show max 3 items
                (index) {
                  final item = _processedReceipt!.items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          Helpers.formatCurrency(item.price * item.quantity),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              if (_processedReceipt!.items.length > 3) ...[
                Text(
                  '... and ${_processedReceipt!.items.length - 3} more items',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveReceipt() async {
    if (_processedReceipt == null) return;
    
    try {
      await context.read<ReceiptProvider>().addReceipt(_processedReceipt!);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Receipt saved successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      
      // Navigate back to home
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving receipt: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _retryProcessing() {
    setState(() {
      _hasError = false;
      _isProcessing = true;
      _errorMessage = null;
    });
    _animationController.repeat();
    _processReceiptImage();
  }
}
