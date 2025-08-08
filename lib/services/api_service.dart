import 'dart:io';
import 'package:dio/dio.dart';

import '../models/receipt.dart';

class ApiService {
  static const String baseUrl = 'https://api.receiptsprocessor.com';
  static const Duration timeout = Duration(seconds: 30);

  Future<Receipt> processReceiptImage(File imageFile) async {
    try {
      final dio = Dio();

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await dio.post(
        'https://zynthdev321-gemini-data-extractor.hf.space/extract-receipt',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          responseType: ResponseType.json,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // You should map the response JSON into your Receipt model here
        final receipt = Receipt.fromApiResponse(data, imageFile.path); // Replace with your actual mapping logic
        return receipt;
      } else {
        throw ApiException('Failed to process receipt. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error processing receipt: $e');
    }
  }

  // Mock function to generate realistic receipt data
  Receipt _generateMockReceipt(String imagePath) {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    
    final merchants = [
      'Walmart',
      'Target',
      'Starbucks',
      'McDonald\'s',
      'Whole Foods',
      'CVS Pharmacy',
      'Home Depot',
      'Best Buy',
      'Amazon Fresh',
      'Costco'
    ];

    final categories = [
      'Groceries',
      'Food & Dining',
      'Shopping',
      'Healthcare',
      'Entertainment',
      'Bills & Utilities',
      'Other'
    ];

    final itemNames = [
      'Coffee',
      'Sandwich',
      'Milk',
      'Bread',
      'Eggs',
      'Bananas',
      'Chicken Breast',
      'Rice',
      'Yogurt',
      'Cereal',
      'Notebook',
      'Pen',
      'Batteries',
      'Phone Charger',
      'Shampoo'
    ];

    final merchantName = merchants[random % merchants.length];
    final category = categories[random % categories.length];
    
    // Generate random items
    final itemCount = (random % 5) + 1; // 1-5 items
    final items = <ReceiptItem>[];
    double totalAmount = 0;

    for (int i = 0; i < itemCount; i++) {
      final itemName = itemNames[(random + i) % itemNames.length];
      final price = (5.0 + (random + i * 10) % 50).toDouble();
      final quantity = 1 + (random + i) % 3; // 1-3 quantity
      
      items.add(ReceiptItem(
        name: itemName,
        price: price,
        quantity: quantity,
      ));
      
      totalAmount += price * quantity;
    }

    return Receipt(
      imagePath: imagePath,
      merchantName: merchantName,
      totalAmount: double.parse(totalAmount.toStringAsFixed(2)),
      date: DateTime.now(),
      category: category,
      items: items,
      createdAt: DateTime.now(),
    );
  }

  // Additional API methods would go here
  Future<bool> validateApiKey(String apiKey) async {
    try {
      // Mock validation - always returns true for demo
      await Future.delayed(const Duration(seconds: 1));
      return true;
      
      // Real implementation:
      /*
      final response = await http.get(
        Uri.parse('$baseUrl/validate'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ).timeout(timeout);
      
      return response.statusCode == 200;
      */
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getApiUsage() async {
    try {
      // Mock usage data
      await Future.delayed(const Duration(seconds: 1));
      return {
        'requests_used': 45,
        'requests_limit': 100,
        'reset_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      };
      
      // Real implementation:
      /*
      final response = await http.get(
        Uri.parse('$baseUrl/usage'),
        headers: {
          'Authorization': 'Bearer YOUR_API_KEY',
          'Content-Type': 'application/json',
        },
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException('Failed to get usage data');
      }
      */
    } catch (e) {
      throw ApiException('Error getting API usage: $e');
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
