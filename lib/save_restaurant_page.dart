import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class SaveRestaurantPage extends StatefulWidget {
  final String token;

  const SaveRestaurantPage({super.key, required this.token});

  @override
  State<SaveRestaurantPage> createState() => _SaveRestaurantPageState();
}

class _SaveRestaurantPageState extends State<SaveRestaurantPage> {
  List restaurants = [];
  List savedRestaurants = [];
  bool isLoading = false;

  double userLat = 0;
  double userLng = 0;

  double calculateDistance(double lat, double lng) {
    return Geolocator.distanceBetween(userLat, userLng, lat, lng) / 1000;
  }

  bool isAlreadySaved(String name, String address) {
    return savedRestaurants.any((item) {
      final savedName = (item["restaurant_name"] ?? "").toString().trim();
      final savedAddress = (item["address"] ?? "").toString().trim();
      return savedName == name.trim() && savedAddress == address.trim();
    });
  }

  Future<void> fetchSavedRestaurants() async {
    try {
      final url = Uri.parse(
        "http://172.24.150.118/food_roulette_api/my_saved_restaurants.php",
      );

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      final result = json.decode(utf8.decode(response.bodyBytes));

      if (!mounted) return;
      setState(() {
        savedRestaurants = result["saved_restaurants"] ?? [];
      });
    } catch (e) {
      debugPrint("fetchSavedRestaurants error: $e");
    }
  }

  Future<void> fetchRestaurantsFromMap() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("กรุณาเปิด Location Permission")),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      userLat = position.latitude;
      userLng = position.longitude;

      await fetchSavedRestaurants();

      final url = Uri.parse(
        "https://overpass-api.de/api/interpreter?data=[out:json];node(around:2000,$userLat,$userLng)[amenity=restaurant];out;",
      );

      final response = await http.get(url);

      final body = utf8.decode(response.bodyBytes);
      final data = json.decode(body);

      if (!mounted) return;
      setState(() {
        restaurants = data["elements"] ?? [];
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

  Future<void> saveRestaurant(
    String name,
    String address,
    double lat,
    double lng,
  ) async {
    final url = Uri.parse(
      "http://172.24.150.118/food_roulette_api/save_restaurant.php",
    );

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "restaurant_name": name,
          "address": address,
          "avg_price": 50,
          "lat": lat,
          "lng": lng,
        }),
      );

      final result = json.decode(utf8.decode(response.bodyBytes));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "บันทึกสำเร็จ")),
      );

      await fetchSavedRestaurants();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาด $e")),
      );
    }
  }

  Widget restaurantCard(dynamic item) {
    final tags = item["tags"] ?? {};

    final String name = tags["name"] ?? "ไม่ทราบชื่อร้าน";
    final String address =
        tags["addr:full"] ??
        tags["addr:street"] ??
        tags["addr:subdistrict"] ??
        tags["addr:district"] ??
        tags["addr:province"] ??
        "ไม่พบที่อยู่";

    final double lat = (item["lat"] as num).toDouble();
    final double lon = (item["lon"] as num).toDouble();
    final double distance = calculateDistance(lat, lon);

    final alreadySaved = isAlreadySaved(name, address);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant, color: Colors.orange, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (alreadySaved)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "บันทึกแล้ว",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text("📍 $address"),
            const SizedBox(height: 4),
            Text("ระยะห่าง ${distance.toStringAsFixed(2)} km"),
            const SizedBox(height: 10),
            if (!alreadySaved)
              ElevatedButton.icon(
                icon: const Icon(Icons.favorite),
                label: const Text("บันทึกร้าน"),
                onPressed: () async {
                  await saveRestaurant(name, address, lat, lon);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchSavedRestaurants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("เลือกร้านอาหารใกล้ฉัน"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.deepOrange.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepOrange.withOpacity(0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : fetchRestaurantsFromMap,
                icon: Icon(
                  isLoading
                      ? Icons.sync_rounded
                      : Icons.location_searching_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  isLoading ? "กำลังค้นหาร้าน..." : "ค้นหาร้านใกล้ฉัน",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : restaurants.isEmpty
                ? const Center(child: Text("กดปุ่มเพื่อค้นหาร้าน"))
                : ListView.builder(
                    itemCount: restaurants.length,
                    itemBuilder: (context, index) {
                      return restaurantCard(restaurants[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}