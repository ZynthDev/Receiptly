import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../providers/receipt_provider.dart';
import '../models/receipt.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/receipt_card.dart';
import '../widgets/loading_shimmer.dart';
import 'receipt_detail_screen.dart';
import 'camera_screen.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Receipts'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'All',
                child: Text('All Categories'),
              ),
              ...['Food & Dining', 'Shopping', 'Transportation', 'Healthcare', 
                  'Entertainment', 'Bills & Utilities', 'Education', 'Travel', 
                  'Groceries', 'Other']
                  .map((category) => PopupMenuItem(
                        value: category,
                        child: Text(category),
                      )),
            ],
          ),
        ],
      ),
      body: Consumer<ReceiptProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.receipts.isEmpty) {
            return const LoadingShimmer();
          }

          if (provider.error != null) {
            return _buildErrorState(provider.error!);
          }

          final receipts = _getFilteredReceipts(provider.receipts);

          if (receipts.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadReceipts(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(receipts),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverMasonryGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childCount: receipts.length,
                    itemBuilder: (context, index) {
                      final receipt = receipts[index];
                      return ReceiptCard(
                        receipt: receipt,
                        onTap: () => _navigateToDetail(receipt),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(List<Receipt> receipts) {
    final totalAmount = receipts.fold<double>(
      0.0, 
      (sum, receipt) => sum + receipt.totalAmount,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.gradientDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Expenses',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Helpers.formatCurrency(totalAmount),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${receipts.length} receipts${_selectedCategory != 'All' ? ' in $_selectedCategory' : ''}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No receipts found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'Start by scanning your first receipt',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to camera screen directly
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CameraScreen(),
                ),
              );
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Scan Receipt'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<ReceiptProvider>().loadReceipts();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  List<Receipt> _getFilteredReceipts(List<Receipt> receipts) {
    var filtered = receipts;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = context.read<ReceiptProvider>().searchReceipts(_searchQuery);
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((receipt) => receipt.category == _selectedCategory).toList();
    }

    return filtered;
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Receipts'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search by merchant, category, or items...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (query) {
            setState(() {
              _searchQuery = query;
            });
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(Receipt receipt) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReceiptDetailScreen(receipt: receipt),
      ),
    );
  }
}
