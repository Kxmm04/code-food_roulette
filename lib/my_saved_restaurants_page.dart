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
      "http://172.24.148.76/food_roulette_api/my_saved_restaurants.php",
    );

    try {
      var response = await http.get(
        url,
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      var result = json.decode(response.body);

      if (!mounted) return;
      setState(() {
        restaurants = result["saved_restaurants"] ?? [];
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteSaved(int savedId) async {
    var url = Uri.parse(
      "http://172.24.148.76/food_roulette_api/saved_delete.php",
    );

    try {
      var response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"saved_id": savedId}),
      );

      var result = json.decode(response.body);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "ลบร้านสำเร็จ")),
      );

      fetchRestaurants();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("ลบร้านไม่สำเร็จ: $e")));
    }
  }

  Future<void> confirmDeleteSaved(int savedId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("ยืนยันการลบ"),
          content: const Text(
            "ต้องการลบร้านนี้ออกจากรายการที่บันทึกไว้ใช่หรือไม่",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("ยกเลิก"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("ลบ"),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      await deleteSaved(savedId);
    }
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
          color: Colors.orange.shade50, // พื้นหลังส้มอ่อน
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              color: Colors.orange.withOpacity(0.2),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xffFFE0B2),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: const Icon(
                Icons.dinner_dining,
                size: 40,
                color: Colors.orange,
              ),
            ),
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
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item["address"] ?? "ไม่พบที่อยู่",
                            style: const TextStyle(color: Colors.black),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    confirmDeleteSaved(item["saved_id"]);
                  },
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ],
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
                  Icon(Icons.restaurant_menu, size: 80, color: Colors.orange),
                  SizedBox(height: 10),
                  Text(
                    "ยังไม่มีร้านที่บันทึกไว้",
                    style: TextStyle(fontSize: 18, color: Colors.black),
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