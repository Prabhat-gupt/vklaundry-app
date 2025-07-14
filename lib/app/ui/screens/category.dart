import 'package:flutter/material.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/ui/screens/product_list.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final List<Map<String, dynamic>> categories = [
    {
      'title': 'Men',
      'icon': Icons.person,
      'colors': [
        Color.fromRGBO(93, 162, 181, 1),
        Color.fromRGBO(90, 150, 167, 1)
      ],
      'image': 'assets/icons/men2.png',
    },
    {
      'title': 'Women',
      'icon': Icons.person_outline,
      'colors': [Color(0xFFFF7F77), Color(0xFFCE6660), Color(0xFF994C47)],
      'image': 'assets/icons/women.png',
    },
    {
      'title': 'Children',
      'icon': Icons.child_care,
      'colors': [
        Color.fromRGBO(248, 187, 23, 1),
        Color.fromRGBO(178, 133, 16, 1)
      ],
      'image': 'assets/icons/children.png',
    },
    {
      'title': 'Other',
      'icon': Icons.bed,
      'colors': [
        Color.fromRGBO(128, 112, 237, 1),
        Color.fromRGBO(96, 85, 179, 1)
      ],
      'image': 'assets/icons/others_category.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        shadowColor: Colors.grey,
        backgroundColor: Colors.white,
        title: Text(
          'All Categories',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
              fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: AppTheme.primaryColor,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductListScreen()),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: (category['colors'] as List<Color>).length == 1
                      ? List<Color>.filled(2, category['colors'][0])
                      : List<Color>.from(category['colors']),
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(category['icon'], color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    category['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    child: Image.asset(
                      category['image'],
                      width: 170,
                      height: double.infinity,
                      fit: BoxFit.fill,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
