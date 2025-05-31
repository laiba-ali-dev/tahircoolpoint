import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tahircoolpoint/login.dart';
import 'package:tahircoolpoint/profile.dart';
import 'package:tahircoolpoint/home.dart';
import 'package:tahircoolpoint/payment.dart';

class Order extends StatefulWidget {
  const Order({Key? key}) : super(key: key);

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
    final String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;



 @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

 void _checkLoginStatus() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      // If not logged in, redirect to login page
      Future.microtask(() {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to view your orders')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Login()), // 👈 or your Login screen
        );
      });
    }
  }

  String _formatDate(dynamic dateValue) {
    // dateValue can be String or Timestamp or null
    try {
      DateTime date;
      if (dateValue == null) return 'Unknown Date';

      if (dateValue is Timestamp) {
        date = dateValue.toDate();
      } else if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return 'Unknown Date';
      }
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown Date';
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
            child: StreamBuilder<QuerySnapshot>(
stream: currentUserUid == null
    ? null
    : _firestore
        .collection('orders')
        .where('userId', isEqualTo: currentUserUid)
        .snapshots(),
        
              builder: (context, snapshot) {
                if (currentUserUid == null) {
  return const Center(child: Text('Please login to view your orders.', style: TextStyle(color: Colors.white)));
}
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No orders found',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    // Remove 'address' field before passing to UI
                  

                    return _buildOrderCard(
                      context: context,
                      order: data,
                      product: (data['productDetails'] is Map<String, dynamic>)
                          ? data['productDetails'] as Map<String, dynamic>
                          : {},
                    );
                  },
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
    String statusText =
        (order['status'] is String) ? order['status'].toString() : 'unknown';

    switch (statusText) {
      case 'Completed':
        statusColor = Colors.green;
        break;
         case 'Assigned':
        statusColor = Colors.orange;
        break;
      case 'In-Progress':
        statusColor = Colors.orange;
        break;
      case 'requested':
        statusColor = Colors.blue;
        break;
     
     
      default:
        statusColor = Colors.grey;
    }

    // Price handling safely:
    String priceText = 'N/A';
    final price = order['price'];
    if (price != null) {
      if (price is num) {
        priceText = price.toStringAsFixed(2);
      } else {
        priceText = price.toString();
      }
    }

    // Category name safely
    String? categoryName;
    final category = product['categoryId'];
    if (category is Map<String, dynamic> && category['name'] is String) {
      categoryName = category['name'];
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
                  child: (product['productImage'] is String && (product['productImage'] as String).isNotEmpty)
                      ? Image.network(
                          product['productImage'],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildGradientIcon(Icons.image),
                        )
                      : _buildGradientIcon(Icons.shopping_bag),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['productTitle'] is String ? order['productTitle'] : 'Unknown Service',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                     if (statusText == 'Completed')
  Text(
    'Price: $priceText PKR',
    style: const TextStyle(color: Colors.white70),
  ),

                      if (categoryName != null)
                        Text(
                          'Category: $categoryName',
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
                        const SizedBox(height: 8),

           if (order['address'] != null && order['address'].toString().isNotEmpty) ...[
  const SizedBox(height: 8),
  Row(
    children: [
      _buildGradientIcon(Icons.location_on),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          'Address: ${order['address']}',
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    ],
  ),
],

            const SizedBox(height: 8),
            Row(
              children: [
                _buildGradientIcon(Icons.calendar_today),
                const SizedBox(width: 8),
                Text(
                  'Ordered on: ${_formatDate(order['timestamp'])}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
   // if (statusText == 'Completed' && price != null ) ...[
//   const SizedBox(height: 16),
//   SizedBox(
//     width: double.infinity,
//     child: ElevatedButton(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.green,
//         padding: const EdgeInsets.symmetric(vertical: 12),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//       onPressed: () {
//         final orderId = order['_id'];
//         if (orderId != null) {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => PaymentPage(
//                 orderId: orderId,
//                 amount: (price is int) ? price.toDouble() : price,
//               ),
//             ),
//           );
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Invalid order ID')),
//           );
//         }
//       },
//       child: const Text(
//         'PAY NOW',
//         style: TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     ),
//   ),
// ],

            if (statusText == 'Completed') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildGradientIcon(Icons.payment),
                  const SizedBox(width: 8),
                  Text(
                    'Paid via ${order['paymentMethod'] is String ? order['paymentMethod'] : 'unknown method'}',
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
              onPressed: () => Navigator.pushReplacement(
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
