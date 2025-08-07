import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/receipt.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../services/camera_service.dart';

class ReceiptProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final ApiService _apiService = ApiService();
  final CameraService _cameraService = CameraService();

  List<Receipt> _receipts = [];
  bool _isLoading = false;
  String? _error;
  Receipt? _currentReceipt;

  List<Receipt> get receipts => _receipts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Receipt? get currentReceipt => _currentReceipt;

  // Load all receipts from database
  Future<void> loadReceipts() async {
    try {
      _setLoading(true);
      _receipts = await _databaseService.getAllReceipts();
      _clearError();
    } catch (e) {
      _setError('Failed to load receipts: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add new receipt
  Future<void> addReceipt(Receipt receipt) async {
    try {
      _setLoading(true);
      final id = await _databaseService.insertReceipt(receipt);
      final newReceipt = receipt.copyWith(id: id);
      _receipts.insert(0, newReceipt);
      _clearError();
    } catch (e) {
      _setError('Failed to add receipt: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Process receipt image with API
  Future<Receipt?> processReceiptImage(File imageFile) async {
    try {
      _setLoading(true);
      
      // Save image to app directory
      final savedImagePath = await _cameraService.saveImageToAppDirectory(imageFile);
      
      // Process with API
      final receipt = await _apiService.processReceiptImage(imageFile);
      
      // Update with saved image path
      final processedReceipt = receipt.copyWith(imagePath: savedImagePath);
      
      _clearError();
      return processedReceipt;
    } catch (e) {
      _setError('Failed to process receipt: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update existing receipt
  Future<void> updateReceipt(Receipt receipt) async {
    try {
      _setLoading(true);
      await _databaseService.updateReceipt(receipt);
      
      final index = _receipts.indexWhere((r) => r.id == receipt.id);
      if (index != -1) {
        _receipts[index] = receipt;
      }
      
      _clearError();
    } catch (e) {
      _setError('Failed to update receipt: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Delete receipt
  Future<void> deleteReceipt(int receiptId) async {
    try {
      _setLoading(true);
      
      // Find receipt to get image path
      final receipt = _receipts.firstWhere((r) => r.id == receiptId);
      
      // Delete from database
      await _databaseService.deleteReceipt(receiptId);
      
      // Delete image file
      await _cameraService.deleteImage(receipt.imagePath);
      
      // Remove from list
      _receipts.removeWhere((r) => r.id == receiptId);
      
      _clearError();
    } catch (e) {
      _setError('Failed to delete receipt: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get receipt by id
  Future<Receipt?> getReceiptById(int id) async {
    try {
      return await _databaseService.getReceiptById(id);
    } catch (e) {
      _setError('Failed to get receipt: $e');
      return null;
    }
  }

  // Set current receipt for viewing
  void setCurrentReceipt(Receipt receipt) {
    _currentReceipt = receipt;
    notifyListeners();
  }

  void clearCurrentReceipt() {
    _currentReceipt = null;
    notifyListeners();
  }

  // Filter receipts by category
  List<Receipt> getReceiptsByCategory(String category) {
    return _receipts.where((receipt) => receipt.category == category).toList();
  }

  // Filter receipts by date range
  List<Receipt> getReceiptsByDateRange(DateTime startDate, DateTime endDate) {
    return _receipts.where((receipt) {
      return receipt.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          receipt.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Search receipts
  List<Receipt> searchReceipts(String query) {
    if (query.isEmpty) return _receipts;
    
    final lowerQuery = query.toLowerCase();
    return _receipts.where((receipt) {
      return receipt.merchantName.toLowerCase().contains(lowerQuery) ||
          receipt.category.toLowerCase().contains(lowerQuery) ||
          receipt.items.any((item) => item.name.toLowerCase().contains(lowerQuery)) ||
          (receipt.notes?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // Get total amount by category
  Map<String, double> getTotalsByCategory() {
    final totals = <String, double>{};
    for (final receipt in _receipts) {
      totals[receipt.category] = (totals[receipt.category] ?? 0) + receipt.totalAmount;
    }
    return totals;
  }

  // Get total amount for date range
  double getTotalForDateRange(DateTime startDate, DateTime endDate) {
    final receiptsInRange = getReceiptsByDateRange(startDate, endDate);
    return receiptsInRange.fold(0.0, (sum, receipt) => sum + receipt.totalAmount);
  }

  // Get receipts count by month
  Map<int, int> getReceiptCountsByMonth(int year) {
    final counts = <int, int>{};
    for (int i = 1; i <= 12; i++) {
      counts[i] = 0;
    }
    
    for (final receipt in _receipts) {
      if (receipt.date.year == year) {
        counts[receipt.date.month] = (counts[receipt.date.month] ?? 0) + 1;
      }
    }
    
    return counts;
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _receipts.clear();
    _currentReceipt = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }
}
