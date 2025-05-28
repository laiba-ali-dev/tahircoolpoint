import 'package:flutter/material.dart';
import 'package:tahircoolpoint/order.dart';

class PaymentPage extends StatefulWidget {
  final String orderId;
  final double amount;

  const PaymentPage({
    Key? key,
    required this.orderId,
    required this.amount,
  }) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final TextEditingController _paymentIdController = TextEditingController();
  bool _isSubmitting = false;

  void _submitPayment(String method, [String? paymentId]) {
    setState(() {
      _isSubmitting = true;
    });

    // Simulate payment processing
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isSubmitting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment successful via $method!')),
      );
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Order()),
      );
    });
  }

  void _showPaymentDialog(String method) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter ${method.toUpperCase()} Payment ID'),
          content: TextField(
            controller: _paymentIdController,
            decoration: InputDecoration(
              hintText: 'Enter your ${method.toUpperCase()} transaction ID',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_paymentIdController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter payment ID')),
                  );
                  return;
                }
                Navigator.pop(context);
                _submitPayment(method, _paymentIdController.text);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentOption({
    required String imageAsset,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Image.asset(
                imageAsset,
                width: 50,
                height: 50,
                errorBuilder: (_, __, ___) => const Icon(Icons.payment, size: 50),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF2D2D2D) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black : Colors.grey[100],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Amount:',
              style: TextStyle(
                fontSize: 16,
                color: textColor.withOpacity(0.7),
              ),
            ),
            Text(
              'PKR ${widget.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Payment Method:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildPaymentOption(
                    imageAsset: 'images/easypaisa.png',
                    title: 'Easypaisa',
                    onTap: () => _showPaymentDialog('easypaisa'),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    imageAsset: 'images/jazzcash.png',
                    title: 'JazzCash',
                    onTap: () => _showPaymentDialog('jazzcash'),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    imageAsset: 'images/bankalhabib.png',
                    title: 'Bank Al-Habib',
                    onTap: () => _showPaymentDialog('bankalhabib'),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    imageAsset: 'images/cash.png',
                    title: 'Cash',
                    onTap: () => _submitPayment('cash'),
                  ),
                ],
              ),
            ),
            if (_isSubmitting)
              const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _paymentIdController.dispose();
    super.dispose();
  }
}