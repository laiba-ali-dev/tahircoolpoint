import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tahircoolpoint/profile.dart';
import 'package:tahircoolpoint/home.dart';
import 'package:tahircoolpoint/payment.dart';

class Order extends StatefulWidget {
  const Order({Key? key}) : super(key: key);

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order> {
  final List<Map<String, dynamic>> orders = [
    {
      '_id': '1',
      'productId': '101',
      'price': 499.99,
      'status': 'completed',
      'locationName': 'Islamabad, Pakistan',
      'createdAt': '2023-06-15T10:30:00Z',
      'productDetails': {
        'title': 'Premium Smartphone',
        'productImage': 'https://via.placeholder.com/150?text=Smartphone',
        'price': 499.99,
        'categoryId': {'name': 'Electronics'},
      },
    },
    {
      '_id': '2',
      'productId': '102',
      'price': 129.99,
      'status': 'paid',
      'locationName': 'Lahore, Pakistan',
      'createdAt': '2023-06-10T14:45:00Z',
      'paymentMethod': 'Credit Card',
      'productDetails': {
        'title': 'Wireless Headphones',
        'productImage': 'https://via.placeholder.com/150?text=Headphones',
        'price': 129.99,
        'categoryId': {'name': 'Audio'},
      },
    },
    {
      '_id': '3',
      'productId': '103',
      'price': 199.99,
      'status': 'in progress',
      'locationName': 'Karachi, Pakistan',
      'createdAt': '2023-06-05T09:15:00Z',
      'productDetails': {
        'title': 'Smart Watch',
        'productImage': 'https://via.placeholder.com/150?text=Smartwatch',
        'price': 199.99,
        'categoryId': {'name': 'Wearables'},
      },
    },
  ];

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildGradientIcon(IconData icon) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          colors: [Color(0xFFfe0000), Color(0xFF000000)],
          stops: [0.0, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds);
      },
      child: Icon(icon, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        leading: IconButton(
          icon: _buildGradientIcon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Orders',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFfe0000), Color(0xFF000000)],
              stops: [0.0, 0.8],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            color: Colors.black.withOpacity(0.3),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final product = order['productDetails'];
                
                return _buildOrderCard(
                  context: context,
                  order: order,
                  product: product,
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildOrderCard({
    required BuildContext context,
    required Map<String, dynamic> order,
    required Map<String, dynamic> product,
  }) {
    Color statusColor;
    String statusText = order['status']?.toLowerCase() ?? 'unknown';
    
    switch (statusText) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'in progress':
        statusColor = Colors.orange;
        break;
      case 'requested':
        statusColor = Colors.blue;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      case 'paid':
        statusColor = Colors.purple;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      color: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product['productImage'] != null
                      ? Image.network(
                          product['productImage'],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => 
                              _buildGradientIcon(Icons.image),
                        )
                      : _buildGradientIcon(Icons.shopping_bag),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['title'] ?? 'Unknown Service',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Price: ${order['price']?.toStringAsFixed(2) ?? 'N/A'} PKR',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (product['categoryId'] != null)
                        Text(
                          'Category: ${product['categoryId']['name']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(
                          statusText.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: statusColor,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1, color: Colors.grey),
            Row(
              children: [
                _buildGradientIcon(Icons.location_on),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order['locationName'] ?? 'Unknown location',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildGradientIcon(Icons.calendar_today),
                const SizedBox(width: 8),
                Text(
                  'Ordered on: ${_formatDate(order['createdAt'])}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            if (statusText == 'completed' && order['price'] != null && order['status'] != 'paid') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentPage(
                          orderId: order['_id'],
                          amount: order['price'] is int 
                              ? order['price'].toDouble()
                              : order['price'],
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'PAY NOW',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
            if (statusText == 'paid') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildGradientIcon(Icons.payment),
                  const SizedBox(width: 8),
                  Text(
                    'Paid via ${order['paymentMethod'] ?? 'unknown method'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      color: Colors.black.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: _buildGradientIcon(Icons.shopping_cart),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Order()),
              ),
            ),
            IconButton(
              icon: _buildGradientIcon(Icons.home),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Home()),
              ),
            ),
            IconButton(
              icon: _buildGradientIcon(Icons.person),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}