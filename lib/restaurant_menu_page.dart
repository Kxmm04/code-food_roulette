import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'add_menu_page.dart';

class RestaurantMenuPage extends StatefulWidget {
  final String token;
  final int restaurantId;
  final String restaurantName;

  const RestaurantMenuPage({
    super.key,
    required this.token,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<RestaurantMenuPage> createState() => _RestaurantMenuPageState();
}

class _RestaurantMenuPageState extends State<RestaurantMenuPage> {
  List menus = [];
  bool loading = true;

  Future<void> fetchMenus() async {
    var url = Uri.parse(
      "http://172.24.150.118/food_roulette_api/menus_list.php?restaurant_id=${widget.restaurantId}",
    );

    var response = await http.get(
      url,
      headers: {"Authorization": "Bearer ${widget.token}"},
    );

    var result = json.decode(response.body);

    setState(() {
      menus = result["menus"] ?? [];
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchMenus();
  }

  Widget menuCard(menu) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          /// ไอคอนอาหาร
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fastfood, color: Colors.orange, size: 30),
          ),

          const SizedBox(width: 14),

          /// ชื่อเมนู
          Expanded(
            child: Text(
              menu["menu_name"] ?? "ไม่มีชื่อเมนู",
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),

          /// ราคา
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${menu["price"]} บาท",
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f7fb),

      appBar: AppBar(
        title: Text(widget.restaurantName),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),

      body: Column(
        children: [
          /// Header ร้าน
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.restaurantName,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "รายการเมนูอาหารของร้าน",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// รายการเมนู
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : menus.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fastfood, size: 80, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          "ยังไม่มีเมนูอาหาร",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: menus.length,
                    itemBuilder: (context, index) {
                      return menuCard(menus[index]);
                    },
                  ),
          ),
        ],
      ),

      /// ปุ่มเพิ่มเมนู
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add),
        label: const Text("เพิ่มเมนู"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddMenuPage(
  token: widget.token,
  restaurantId: widget.restaurantId,
  restaurantName: widget.restaurantName,
),
            ),
          ).then((_) {
            fetchMenus();
          });
        },
      ),
    );
  }
}
