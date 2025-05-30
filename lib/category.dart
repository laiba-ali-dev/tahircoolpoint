import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';

class Product {
  final String id;
  final String title;
  final double price;
  final String productImage;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.productImage,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      title: data['product'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      productImage: data['image'] ?? '',
    );
  }
}

class Category extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const Category({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  _CategoryState createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  List<Product> _allProducts = [];
  String _searchQuery = '';
  bool _isLoading = true;
  String _error = '';

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return _allProducts;
    return _allProducts
        .where((product) =>
            product.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchProductsFromFirestore();
  }

  Future<void> _fetchProductsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('product')
          .where('categoryId', isEqualTo: widget.categoryId)
          .get();

      setState(() {
        _allProducts =
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load products.';
        _isLoading = false;
      });
    }
  }

 void _showLocationBottomSheet(BuildContext context, Product product) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please login to place an order')),
    );
    return;
  }

  LatLng currentLocation = const LatLng(33.6844, 73.0479);
  final MapController _mapController = MapController();
  final TextEditingController _addressController = TextEditingController();

  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    currentLocation = LatLng(position.latitude, position.longitude);

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;

      _addressController.text =
          '${place.subThoroughfare} ${place.thoroughfare}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
    } else {
      _addressController.text = 'Address not found';
    }
  } catch (e) {
    _addressController.text = 'Failed to get current location';
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Delivery Location',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Delivery Address',
                hintText: 'House no, Area, City...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.home),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: () async {
                    try {
                      final position = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high,
                      );
                      setState(() {
                        currentLocation =
                            LatLng(position.latitude, position.longitude);
                      });
                      _mapController.move(currentLocation, 15.0);

                      List<Placemark> placemarks =
                          await placemarkFromCoordinates(
                        position.latitude,
                        position.longitude,
                      );

                      if (placemarks.isNotEmpty) {
                        Placemark place = placemarks.first;
                        _addressController.text =
                            '${place.subThoroughfare} ${place.thoroughfare}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
                      } else {
                        _addressController.text = 'Address not found';
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Location error: $e')),
                      );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: currentLocation,
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: currentLocation,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await FirebaseFirestore.instance.collection('orders').add({
                    'userId': user.uid,
                    'productId': product.id,
                    'productTitle': product.title,
                    'price': product.price,
                    'address': _addressController.text,
                    'location': {
                      'lat': currentLocation.latitude,
                      'lng': currentLocation.longitude,
                    },
                    'timestamp': Timestamp.now(),
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${product.title} order placed to: ${_addressController.text}',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A7DD),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'CONFIRM LOCATION',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: _filteredProducts
                            .map(
                              (product) => _buildProductCard(
                                product: product,
                                isDarkMode: isDarkMode,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomAppBar(
          color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Color(0xFF00A7DD)),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.home, color: Color(0xFF00A7DD)),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
              IconButton(
                icon: const Icon(Icons.person, color: Color(0xFF00A7DD)),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard({
    required Product product,
    required bool isDarkMode,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                product.productImage,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error, size: 80),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.categoryName,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Starting From PKR. ${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Icon(Icons.star_half, color: Colors.amber, size: 16),
                      SizedBox(width: 5),
                      Text('4.5', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _showLocationBottomSheet(context, product),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A7DD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(12),
              ),
              child: const Icon(Icons.add, size: 24, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
