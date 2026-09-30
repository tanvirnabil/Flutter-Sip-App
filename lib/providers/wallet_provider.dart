import 'package:flutter/material.dart';

class WalletTransaction {
  final String id;
  final double amount;
  final String method;
  final DateTime date;
  final String status;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.method,
    required this.date,
    this.status = 'Completed',
  });
}

class WalletProvider extends ChangeNotifier {
  double _balance = 15.00;
  bool _isProcessing = false;

  final List<WalletTransaction> _transactions = [
    WalletTransaction(
      id: 'TXN-90412',
      amount: 15.00,
      method: 'Welcome Bonus',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  double get balance => _balance;
  bool get isProcessing => _isProcessing;
  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);

  Future<bool> rechargeBalance(double amount, String paymentMethod) async {
    _isProcessing = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    _balance += amount;
    _transactions.insert(
      0,
      WalletTransaction(
        id: 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        amount: amount,
        method: paymentMethod,
        date: DateTime.now(),
      ),
    );

    _isProcessing = false;
    notifyListeners();
    return true;
  }
}
