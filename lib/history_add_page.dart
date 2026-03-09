import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HistoryAddPage extends StatefulWidget {
  final String token;

  const HistoryAddPage({super.key, required this.token});

  @override
  State<HistoryAddPage> createState() => _HistoryAddPageState();
}

class _HistoryAddPageState extends State<HistoryAddPage> {
  List restaurants = [];
  List menus = [];

  int? selectedRestaurantId;
  int? selectedMenuId;
  int selectedPrice = 0;

  bool loadingRestaurant = true;
  bool loadingMenu = false;

  @override
  void initState() {
    super.initState();
    fetchRestaurants();
  }

  /// โหลดร้าน
  Future<void> fetchRestaurants() async {
    var url = Uri.parse(
      "http://172.24.148.250/food_roulette_api/my_saved_restaurants.php",
    );

    var response = await http.get(
      url,
      headers: {"Authorization": "Bearer ${widget.token}"},
    );

    var result = json.decode(utf8.decode(response.bodyBytes));

    setState(() {
      restaurants = result["saved_restaurants"] ?? [];
      loadingRestaurant = false;
    });
  }

  /// โหลดเมนู
  Future<void> fetchMenus(int restaurantId) async {
    setState(() {
      loadingMenu = true;
      menus = [];
    });

    var url = Uri.parse(
      "http://172.24.148.250/food_roulette_api/menus_list.php?restaurant_id=$restaurantId",
    );

    var response = await http.get(
      url,
      headers: {"Authorization": "Bearer ${widget.token}"},
    );

    var result = json.decode(utf8.decode(response.bodyBytes));

    setState(() {
      menus = result["menus"] ?? [];
      loadingMenu = false;
    });
  }

  /// บันทึก
  Future<void> saveHistory() async {
    if (selectedRestaurantId == null || selectedMenuId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("กรุณาเลือกร้านและเมนู")));
      return;
    }

    var url = Uri.parse(
      "http://172.24.148.250/food_roulette_api/history_add.php",
    );

    var response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer ${widget.token}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "restaurant_id": selectedRestaurantId,
        "menu_id": selectedMenuId,
        "price": selectedPrice,
        "distance_km": 0,
      }),
    );

    var result = json.decode(response.body);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result["message"] ?? "บันทึกสำเร็จ")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f7fb),

      appBar: AppBar(
        title: const Text("บันทึกประวัติการกิน"),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),

      body: Column(
        children: [
          /// HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "วันนี้คุณกินอะไร ? 🍜",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "เลือกร้านและเมนูที่กิน",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// FORM
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.black.withOpacity(0.08),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    /// เลือกร้าน
                    loadingRestaurant
                        ? const CircularProgressIndicator()
                        : DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: "เลือกร้านอาหาร",
                              prefixIcon: Icon(Icons.restaurant),
                              border: OutlineInputBorder(),
                            ),
                            value: selectedRestaurantId,
                            items: restaurants.map<DropdownMenuItem<int>>((r) {
                              return DropdownMenuItem(
                                value: r["restaurant_id"],
                                child: Text(r["restaurant_name"]),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedRestaurantId = value;
                                selectedMenuId = null;
                              });

                              fetchMenus(value!);
                            },
                          ),

                    const SizedBox(height: 20),

                    /// เลือกเมนู
                    loadingMenu
                        ? const CircularProgressIndicator()
                        : DropdownButtonFormField<int>(
                            key: ValueKey(menus.length),
                            decoration: const InputDecoration(
                              labelText: "เลือกเมนู",
                              prefixIcon: Icon(Icons.fastfood),
                              border: OutlineInputBorder(),
                            ),
                            value: selectedMenuId,
                            items: menus.map<DropdownMenuItem<int>>((m) {
                              return DropdownMenuItem(
                                value: m["menu_id"],
                                child: Text(
                                  "${m["menu_name"]} (${m["price"]} บาท)",
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              var menu = menus.firstWhere(
                                (m) => m["menu_id"] == value,
                              );

                              setState(() {
                                selectedMenuId = value;
                                selectedPrice = menu["price"];
                              });
                            },
                          ),

                    const Spacer(),

                    /// ปุ่มบันทึก
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text(
                          "บันทึกประวัติการกิน",
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: saveHistory,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
