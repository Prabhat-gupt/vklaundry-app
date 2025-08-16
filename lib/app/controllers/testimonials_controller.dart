import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestimonialsController extends GetxController {
  var testimonials = <Map<String, dynamic>>[].obs; // Holds all testimonials
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();
    fetchTestimonials(); // Load testimonials when controller is initialized
  }

  void fetchTestimonials() async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      final response = await supabase
            .from('testimonials')
            .select('*');

      print("Response from the testimonials $response");
      // Replace this with your API/database call
      var fetchedData = [
        {
          "customer_name": "John Doe",
          "customer_feedback":
              "Great service! Highly recommended. My clothes have never been cleaner."
        },
        {
          "customer_name": "Jane Smith",
          "customer_feedback":
              "Fast and professional. I love how fresh my clothes smell!"
        },
        {
          "customer_name": "Michael Johnson",
          "customer_feedback":
              "Affordable prices and top-notch quality. Definitely coming back!"
        }
      ];

      testimonials.assignAll(response);
    } catch (e) {
      print("Error fetching testimonials: $e");
    }
  }
}



// [{id: 1, created_at: 2025-08-11T17:19:08.727814+00:00, customer_name: Priya M, customer_feedback: Quick and efficient. VK Laundry makes my life so much easier!}, {id: 2, created_at: 2025-08-11T17:19:52.996461+00:00, customer_name: Rahul D, customer_feedback: Reliable service and the steam iron option is a game changer!}, {id: 3, created_at: 2025-08-11T17:20:18.90253+00:00, customer_name: Sneha K, customer_feedback: Affordable and professional. Great team and always on time.}]