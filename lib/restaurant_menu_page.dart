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

    try {
      var response = await http.get(
        url,
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      var result = json.decode(response.body);

      if (!mounted) return;
      setState(() {
        menus = result["menus"] ?? [];
        loading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> deleteMenu(int menuId) async {
    var url = Uri.parse(
      "http://172.24.150.118/food_roulette_api/menu_delete.php",
    );

    try {
      var response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"menu_id": menuId}),
      );

      var result = json.decode(response.body);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "ลบเมนูสำเร็จ")),
      );

      fetchMenus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ลบเมนูไม่สำเร็จ: $e")),
      );
    }
  }

  Future<void> confirmDeleteMenu(int menuId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("ยืนยันการลบ"),
          content: const Text("ต้องการลบเมนูนี้ใช่หรือไม่"),
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
      await deleteMenu(menuId);
    }
  }

  void openEditMenuDialog(dynamic menu) {
    TextEditingController nameController =
        TextEditingController(text: menu["menu_name"]);
    TextEditingController priceController =
        TextEditingController(text: menu["price"].toString());

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("แก้ไขเมนู"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "ชื่อเมนู"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "ราคา"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("ยกเลิก"),
            ),
            ElevatedButton(
              onPressed: () async {
                var url = Uri.parse(
                  "http://172.24.150.118/food_roulette_api/menu_update.php",
                );

                var response = await http.post(
                  url,
                  headers: {
                    "Authorization": "Bearer ${widget.token}",
                    "Content-Type": "application/json",
                  },
                  body: jsonEncode({
                    "menu_id": menu["menu_id"],
                    "menu_name": nameController.text,
                    "price": int.parse(priceController.text),
                    "is_available": 1,
                  }),
                );

                var result = json.decode(response.body);

                if (!mounted) return;
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result["message"] ?? "แก้ไขเมนูสำเร็จ"),
                  ),
                );

                fetchMenus();
              },
              child: const Text("บันทึก"),
            ),
          ],
        );
      },
    );
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
          Expanded(
            child: Text(
              menu["menu_name"] ?? "ไม่มีชื่อเมนู",
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          Column(
            children: [
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
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      openEditMenuDialog(menu);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      confirmDeleteMenu(menu["menu_id"]);
                    },
                  ),
                ],
              ),
            ],
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