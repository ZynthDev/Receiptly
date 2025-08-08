class Receipt {
  final int? id;
  final String imagePath;
  final String merchantName;
  final double totalAmount;
  final DateTime date;
  final String category;
  final List<ReceiptItem> items;
  final String? notes;
  final DateTime createdAt;

  Receipt({
    this.id,
    required this.imagePath,
    required this.merchantName,
    required this.totalAmount,
    required this.date,
    required this.category,
    required this.items,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'merchantName': merchantName,
      'totalAmount': totalAmount,
      'date': date.millisecondsSinceEpoch,
      'category': category,
      'items': items.map((item) => item.toJson()).toList(),
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'],
      imagePath: json['imagePath'] ?? '',
      merchantName: json['merchantName'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] ?? DateTime.now().millisecondsSinceEpoch),
      category: json['category'] ?? 'Other',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => ReceiptItem.fromJson(item))
          .toList() ?? [],
      notes: json['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'merchantName': merchantName,
      'totalAmount': totalAmount,
      'date': date.millisecondsSinceEpoch,
      'category': category,
      'items': items.map((item) => item.toJson()).toString(),
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toMapForDb() {
    return {
      'imagePath': imagePath,
      'merchantName': merchantName,
      'totalAmount': totalAmount,
      'date': date.millisecondsSinceEpoch,
      'category': category,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      id: map['id'],
      imagePath: map['imagePath'],
      merchantName: map['merchantName'],
      totalAmount: map['totalAmount'].toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      category: map['category'],
      items: [], // Will be populated separately
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  Receipt copyWith({
    int? id,
    String? imagePath,
    String? merchantName,
    double? totalAmount,
    DateTime? date,
    String? category,
    List<ReceiptItem>? items,
    String? notes,
    DateTime? createdAt,
  }) {
    return Receipt(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      merchantName: merchantName ?? this.merchantName,
      totalAmount: totalAmount ?? this.totalAmount,
      date: date ?? this.date,
      category: category ?? this.category,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static Receipt fromApiResponse(Map<String, dynamic> json, String imagePath) {
    final List<ReceiptItem> parsedItems = (json['items'] as List<dynamic>)
        .map((item) => ReceiptItem(
      name: item['description'] ?? 'Unknown',
      price: (item['total_price'] ?? 0.0).toDouble(),
      quantity: item['quantity'] ?? 1,
      category: null, // You may assign a category if needed
    ))
        .toList();

    return Receipt(
      id: null,
      imagePath: imagePath,
      merchantName: json['business_name'] ?? 'Unknown',
      totalAmount: (json['total'] ?? 0.0).toDouble(),
      date: _parseDate(json['date'], json['time']),
      category: json['category'] ?? 'Other',
      items: parsedItems,
      notes: json['receipt_number'],
      createdAt: DateTime.now(),
    );
  }

  static DateTime _parseDate(String? dateStr, String? timeStr) {
    try {
      final dateTimeString = '${dateStr ?? ''} ${timeStr ?? ''}'.trim();
      return DateTime.parse(dateTimeString);
    } catch (_) {
      return DateTime.now();
    }
  }
}

class ReceiptItem {
  final int? id;
  final int? receiptId;
  final String name;
  final double price;
  final int quantity;
  final String? category;

  ReceiptItem({
    this.id,
    this.receiptId,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receiptId': receiptId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'category': category,
    };
  }

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      id: json['id'],
      receiptId: json['receiptId'],
      name: json['name'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      quantity: json['quantity'] ?? 1,
      category: json['category'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receiptId': receiptId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'category': category,
    };
  }

  factory ReceiptItem.fromMap(Map<String, dynamic> map) {
    return ReceiptItem(
      id: map['id'],
      receiptId: map['receiptId'],
      name: map['name'],
      price: map['price'].toDouble(),
      quantity: map['quantity'],
      category: map['category'],
    );
  }
}
