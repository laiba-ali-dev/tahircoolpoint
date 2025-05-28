import 'package:flutter/material.dart';
import 'package:tahircoolpoint/profile.dart';
import 'category.dart';
import 'order.dart';

class CategoryModel {
  final String id;
  final String name;
  final String imageUrl;

  CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
  });
}

class SliderModel {
  final String id;
  final String imageUrl;

  SliderModel({
    required this.id,
    required this.imageUrl,
  });
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final String _userName = "John Doe";
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  // Dummy data
  final List<SliderModel> _sliders = [
    SliderModel(
      id: '1',
      imageUrl: 'https://via.placeholder.com/800x400?text=Slider+1',
    ),
    SliderModel(
      id: '2',
      imageUrl: 'https://via.placeholder.com/800x400?text=Slider+2',
    ),
    SliderModel(
      id: '3',
      imageUrl: 'https://via.placeholder.com/800x400?text=Slider+3',
    ),
  ];

  final List<CategoryModel> _categories = [
    CategoryModel(
      id: '1',
      name: 'Electronics',
      imageUrl: 'https://via.placeholder.com/150?text=Electronics',
    ),
    CategoryModel(
      id: '2',
      name: 'Clothing',
      imageUrl: 'https://via.placeholder.com/150?text=Clothing',
    ),
    CategoryModel(
      id: '3',
      name: 'Home & Garden',
      imageUrl: 'https://via.placeholder.com/150?text=Home+Garden',
    ),
    CategoryModel(
      id: '4',
      name: 'Sports',
      imageUrl: 'https://via.placeholder.com/150?text=Sports',
    ),
    CategoryModel(
      id: '5',
      name: 'Books',
      imageUrl: 'https://via.placeholder.com/150?text=Books',
    ),
    CategoryModel(
      id: '6',
      name: 'Beauty',
      imageUrl: 'https://via.placeholder.com/150?text=Beauty',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 5)).then((_) {
      if (_pageController.hasClients && _sliders.isNotEmpty) {
        final nextPage = (_currentPage + 1) % _sliders.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final carouselHeight = MediaQuery.of(context).size.width * 0.5;

    return Scaffold(
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        title: Row(
          children: [
            Image.asset('images/icon.png', height: 60),
            const Spacer(),
            Text(
              'Hi, $_userName',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Slider Carousel Section
            _buildSliderCarousel(carouselHeight),
            const SizedBox(height: 20),

            // Categories Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Categories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            _buildCategoriesGrid(),
          ],
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomAppBar(
          color: Colors.white,
          elevation: 4,
          child: Container(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildGradientIconButton(
                  icon: Icons.shopping_cart,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Order()),
                  ),
                ),
                _buildGradientIconButton(
                  icon: Icons.home,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Home()),
                  ),
                ),
                _buildGradientIconButton(
                  icon: Icons.person,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            colors: [Color(0xFFfe0000), Color(0xFF000000)],
            stops: [0.0, 0.8],
          ).createShader(bounds);
        },
        child: Icon(icon, size: 28, color: Colors.white),
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildSliderCarousel(double height) {
    return Column(
      children: [
        Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _sliders.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return Image.network(
                  _sliders[index].imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    );
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_sliders.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_sliders.length, (index) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Colors.blue
                      : Colors.grey.withOpacity(0.4),
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildCategoriesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        return _buildCategoryCard(_categories[index]);
      },
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Category(
              categoryId: category.id,
              categoryName: category.name,
            ),
          ),
        );
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              height: 100,
              padding: const EdgeInsets.all(5),
              child: Center(
                child: Container(
                  width: 80,
                  height: 50,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      category.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.error),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}