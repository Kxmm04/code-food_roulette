import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'restaurant_menu_page.dart';

class MySavedRestaurantsPage extends StatefulWidget {
  final String token;

  const MySavedRestaurantsPage({super.key, required this.token});

  @override
  State<MySavedRestaurantsPage> createState() => _MySavedRestaurantsPageState();
}

class _MySavedRestaurantsPageState extends State<MySavedRestaurantsPage> {
  List restaurants = [];
  bool isLoading = true;

  Future<void> fetchRestaurants() async {
    var url = Uri.parse(
      "http://172.24.150.118/food_roulette_api/my_saved_restaurants.php",
    );

    var response = await http.get(
      url,
      headers: {"Authorization": "Bearer ${widget.token}"},
    );

    var result = json.decode(response.body);

    setState(() {
      restaurants = result["saved_restaurants"] ?? [];
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchRestaurants();
  }

  Widget restaurantCard(item) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RestaurantMenuPage(
              token: widget.token,
              restaurantId: item["restaurant_id"],
              restaurantName: item["restaurant_name"],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            /// รูปร้าน
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xffFFF3E0),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: const Icon(
                Icons.restaurant,
                size: 40,
                color: Colors.orange,
              ),
            ),

            /// รายละเอียดร้าน
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item["restaurant_name"] ?? "ไม่มีชื่อร้าน",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item["address"] ?? "ไม่พบที่อยู่",
                            style: const TextStyle(color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(
                          Icons.attach_money,
                          size: 16,
                          color: Colors.green,
                        ),
                        Text(
                          "ราคาเฉลี่ย ${item["avg_price"] ?? "-"} บาท",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f7fb),

      appBar: AppBar(
        title: const Text("ร้านที่บันทึกไว้"),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : restaurants.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    "ยังไม่มีร้านที่บันทึกไว้",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: restaurants.length,
              itemBuilder: (context, index) {
                return restaurantCard(restaurants[index]);
              },
            ),
    );
  }
}
