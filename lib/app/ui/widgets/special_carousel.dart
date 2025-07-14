import 'package:flutter/material.dart';

class SpecialCarousel extends StatefulWidget {
  const SpecialCarousel({super.key});

  @override
  State<SpecialCarousel> createState() => _SpecialCarouselState();
}

class _SpecialCarouselState extends State<SpecialCarousel> {
  final List<Map<String, String>> _items = [
    {
      'image': 'assets/icons/special.png',
      'text': 'Get Discount upto 25%\nFor every laundry service',
    },
    {
      'image': 'assets/icons/special.png',
      'text': 'Dry Cleaning\nSpecial Offer!',
    },
    {
      'image': 'assets/icons/special.png',
      'text': 'Steam Ironing\nNow at 10% Off',
    },
  ];

  int _current = 0;
  final PageController _controller = PageController(viewportFraction: 0.9);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
              controller: _controller,
              itemCount: _items.length,
              onPageChanged: (index) {
                setState(() {
                  _current = index;
                });
              },
              itemBuilder: (context, index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(
                      horizontal: 2, vertical: _current == index ? 0 : 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      // BoxShadow(
                      //   color: Colors.black26,
                      //   blurRadius: 8,
                      //   offset: Offset(0, 4),
                      // ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          _items[index]['image']!,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.2),
                                Colors.transparent,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Get Discount\n',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'upto 25%\n',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  WidgetSpan(
                                    child: SizedBox(height: 28),
                                  ),
                                  TextSpan(
                                    text: 'For every laundry service',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_items.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: _current == index ? 12 : 6,
              decoration: BoxDecoration(
                color: _current == index
                    ? const Color(0xFF59A892)
                    : Colors.grey[400],
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }
}
