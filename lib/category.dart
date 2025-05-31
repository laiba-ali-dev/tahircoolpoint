import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart';
import 'package:tahircoolpoint/home.dart';
import 'package:tahircoolpoint/profile.dart';
import 'package:tahircoolpoint/order.dart' as MyOrder;


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

class LocationSearchResult {
  final String placeId;
  final String displayName;
  final String? street;
  final String? city;
  final String? state;
  final String? country;
  final double lat;
  final double lon;

  LocationSearchResult({
    required this.placeId,
    required this.displayName,
    this.street,
    this.city,
    this.state,
    this.country,
    this.lat = 0.0,
    this.lon = 0.0,
  });

  String get formattedAddress {
    return displayName;
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
        .where(
          (product) =>
              product.title.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
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

  Future<void> _createOrder(
    Product product,
    String locationName,
    LatLng location,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Fluttertoast.showToast(
        msg: "Please login to place an order",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    try {
      final addressDetails = await _getAddressFromCoordinates(location);

      await FirebaseFirestore.instance.collection('orders').add({
        'productId': product.id,
        'userId': user.uid,
        'technicianId': null,
        'price': null,
        'status': 'requested',
        'address': locationName,
        'addressDetails': {
          'street': addressDetails.street,
          'city': addressDetails.city,
          'state': addressDetails.state,
          'country': addressDetails.country,
        },
        'longitude': location.longitude,
        'latitude': location.latitude,
        'timestamp': FieldValue.serverTimestamp(),
        'productTitle': product.title,
        'productPrice': product.price,
      });

      Fluttertoast.showToast(
        msg: "Order placed successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to place order. Please try again.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      print('Error creating order: $e');
    }
  }

  Future<List<LocationSearchResult>> _searchPlaces(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=$query&countrycodes=pk&limit=5&addressdetails=1',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          final address = item['address'] as Map<String, dynamic>? ?? {};
          return LocationSearchResult(
            placeId: item['osm_id']?.toString() ?? '',
            displayName: item['display_name'] ?? '',
            street: address['road']?.toString() ?? 
                   address['footway']?.toString() ?? 
                   address['street']?.toString(),
            city: address['city']?.toString() ?? 
                  address['town']?.toString() ?? 
                  address['village']?.toString(),
            state: address['state']?.toString(),
            country: address['country']?.toString(),
            lat: double.tryParse(item['lat']?.toString() ?? '0.0') ?? 0.0,
            lon: double.tryParse(item['lon']?.toString() ?? '0.0') ?? 0.0,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Places search error: $e');
      return [];
    }
  }

  Future<LocationSearchResult> _getAddressFromCoordinates(LatLng point) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>? ?? {};
        return LocationSearchResult(
          placeId: data['osm_id']?.toString() ?? '',
          displayName: data['display_name'] ?? 'Unknown location',
          street: address['road']?.toString() ?? 
                 address['footway']?.toString() ?? 
                 address['street']?.toString(),
          city: address['city']?.toString() ?? 
                address['town']?.toString() ?? 
                address['village']?.toString(),
          state: address['state']?.toString(),
          country: address['country']?.toString(),
          lat: point.latitude,
          lon: point.longitude,
        );
      }
      return LocationSearchResult(
        placeId: '',
        displayName: '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
        lat: point.latitude,
        lon: point.longitude,
      );
    } catch (e) {
      return LocationSearchResult(
        placeId: '',
        displayName: '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
        lat: point.latitude,
        lon: point.longitude,
      );
    }
  }

  Future<LatLng> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LatLng(33.6844, 73.0479);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LatLng(33.6844, 73.0479);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LatLng(33.6844, 73.0479);
      }

      Position position = await Geolocator.getCurrentPosition();
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      return const LatLng(33.6844, 73.0479);
    }
  }

  void _showLocationBottomSheet(BuildContext context, Product product) {
    final TextEditingController _addressController = TextEditingController();
    LocationSearchResult? _selectedLocation;
    final MapController _mapController = MapController();
    bool _isLoadingLocation = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final location = await _getCurrentLocation();
      final address = await _getAddressFromCoordinates(location);
      if (mounted) {
        setState(() {
          _addressController.text = address.formattedAddress;
          _selectedLocation = address;
          _isLoadingLocation = false;
        });
        _mapController.move(location, 15);
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
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
                  TypeAheadField<LocationSearchResult>(
                    controller: _addressController,
                    builder: (context, controller, focusNode) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Delivery Address',
                          hintText: 'Search for an address...',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.my_location),
                            onPressed: () async {
                              setState(() => _isLoadingLocation = true);
                              final location = await _getCurrentLocation();
                              final address = await _getAddressFromCoordinates(
                                location,
                              );
                              if (mounted) {
                                setState(() {
                                  _selectedLocation = address;
                                  _addressController.text = address.formattedAddress;
                                  _isLoadingLocation = false;
                                });
                              }
                              _mapController.move(location, 15);
                            },
                          ),
                        ),
                      );
                    },
                    suggestionsCallback: (pattern) async {
                      return await _searchPlaces(pattern);
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        title: Text(suggestion.formattedAddress),
                        subtitle: suggestion.street != null 
                            ? Text(suggestion.street!) 
                            : null,
                      );
                    },
                    onSelected: (suggestion) async {
                      setState(() => _isLoadingLocation = true);
                      if (mounted) {
                        setState(() {
                          _selectedLocation = suggestion;
                          _addressController.text = suggestion.formattedAddress;
                          _isLoadingLocation = false;
                        });
                      }
                      _mapController.move(
                        LatLng(suggestion.lat, suggestion.lon), 
                        15,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter:
                                  _selectedLocation != null 
                                      ? LatLng(_selectedLocation!.lat, _selectedLocation!.lon)
                                      : const LatLng(33.6844, 73.0479),
                              initialZoom: 15.0,
                              onTap: (tapPosition, point) async {
                                final address =
                                    await _getAddressFromCoordinates(point);
                                if (mounted) {
                                  setState(() {
                                    _selectedLocation = address;
                                    _addressController.text = address.formattedAddress;
                                  });
                                }
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.app',
                              ),
                              MarkerLayer(
                                markers: [
                                  if (_selectedLocation != null)
                                    Marker(
                                      point: LatLng(_selectedLocation!.lat, _selectedLocation!.lon),
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
                          if (_isLoadingLocation)
                            const Center(child: CircularProgressIndicator()),
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: FloatingActionButton(
                              backgroundColor: const Color(0xFF00A7DD),
                              onPressed: () async {
                                setState(() => _isLoadingLocation = true);
                                final location = await _getCurrentLocation();
                                final address =
                                    await _getAddressFromCoordinates(location);
                                if (mounted) {
                                  setState(() {
                                    _selectedLocation = address;
                                    _addressController.text = address.formattedAddress;
                                    _isLoadingLocation = false;
                                  });
                                }
                                _mapController.move(location, 15);
                              },
                              child: const Icon(
                                Icons.my_location,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_selectedLocation != null) {
                          _createOrder(
                            product,
                            _selectedLocation!.formattedAddress,
                            LatLng(_selectedLocation!.lat, _selectedLocation!.lon),
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${product.title} will be delivered to: ${_selectedLocation!.formattedAddress}',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error.isNotEmpty)
              Center(child: Text(_error))
            else if (_filteredProducts.isEmpty)
              const Center(child: Text('No products found'))
            else
              Column(
                children:
                    _filteredProducts
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
 onPressed: () => Navigator.pushReplacement(
                context,
                    MaterialPageRoute(builder: (context) => MyOrder.Order()),
              ),              ),
              IconButton(
                icon: const Icon(Icons.home, color: Color(0xFF00A7DD)),
                onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) =>  Home()),
              ),
              ),
              IconButton(
                icon: const Icon(Icons.person, color: Color(0xFF00A7DD)),
 onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) =>  ProfilePage()),
              ),              ),
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
                errorBuilder:
                    (context, error, stackTrace) =>
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