import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MenuListPage extends StatefulWidget {
  final String token;
  final int restaurantId;
  final String restaurantName;

  const MenuListPage({
    super.key,
    required this.token,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<MenuListPage> createState() => _MenuListPageState();
}

class _MenuListPageState extends State<MenuListPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.restaurantName)),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: menus.length,
              itemBuilder: (context, index) {
                var menu = menus[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(menu["menu_name"]),
                    trailing: Text("${menu["price"]} บาท"),
                  ),
                );
              },
            ),
    );
  }
}
