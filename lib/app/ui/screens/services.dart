import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/home_page_controller.dart';
import 'package:laundry_app/app/ui/screens/product_list.dart';

class ServiceScreen extends StatelessWidget {
  const ServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomePageController());

    // List of working Unsplash images
    // final List<String> serviceImages = [
    //   'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRZGOWHxy5gcPkGjr4AxlsSgRIVVTCaQ0sJDw&s', // Washing
    //   'https://static.vecteezy.com/system/resources/thumbnails/038/949/666/small/ai-generated-stack-of-clean-clothes-on-ironing-board-at-home-closeup-photo.jpg', // Dry cleaning
    //   'https://5.imimg.com/data5/QT/OS/GLADMIN-59689206/normal-ironing-and-steam-ironing.png', // Ironing
    //   'https://media.istockphoto.com/id/542303516/photo/worker-laundry-ironed-clothes-iron-dry.jpg?s=612x612&w=0&k=20&c=lcI-9Caxcqd-ZI9vwAPmHAl76cB_T205hB8tFr2Iclg=', // Shoe cleaning
    //   'https://media.istockphoto.com/id/1279912899/photo/beautiful-woman-in-winter-thick-warm-robe-is-sitting-and-neatly-folding-bed-linens-and-bath.jpg?s=612x612&w=0&k=20&c=RBNfJQyLxVhe0weOIzjfm287LBXRClUhDuOvHMozLjY=',
    //   'https://media.istockphoto.com/id/688398000/photo/dresses-hanged-in-a-clothing-store.jpg?s=612x612&w=0&k=20&c=tfmN4c9k3yx9Us3E8N1g9Mesd96HxyNFmGhJKQ5hShs='
    // ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F5),
      appBar: AppBar(
        elevation: 0,
        shadowColor: Colors.grey,
        backgroundColor: Colors.white,
        title: Text(
          'Our Services',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        centerTitle: true,
        // actions: [
        //   IconButton(
        //     icon: Icon(
        //       Icons.search,
        //       color: AppTheme.primaryColor,
        //     ),
        //     onPressed: () {},
        //   ),
        // ],
      ),
      body: Obx(() {
        final services = controller.services;

        if (services.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            // final imageUrl = serviceImages[index % serviceImages.length];

            return InkWell(
              onTap: () {
                Get.to(
                  () => const ProductListScreen(),
                  arguments: {
                    'serviceName': service['name'],
                    'service_id': service['id'],
                  },
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(20),
                      ),
                      child: Image.network(
                        service['image_url'] ??
                            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRZGOWHxy5gcPkGjr4AxlsSgRIVVTCaQ0sJDw&s',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 50),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service['name'] ?? '-',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              service['description'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 12.0),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
