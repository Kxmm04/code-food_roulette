import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HistoryListPage extends StatefulWidget {
  final String token;

  const HistoryListPage({super.key, required this.token});

  @override
  State<HistoryListPage> createState() => _HistoryListPageState();
}

class _HistoryListPageState extends State<HistoryListPage> {
  List history = [];
  bool isLoading = true;

  Future<void> fetchHistory() async {
    var url = Uri.parse(
      "http://172.24.150.118/food_roulette_api/history_list.php",
    );

    try {
      var response = await http.get(
        url,
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      var jsonData = json.decode(response.body);

      if (jsonData["ok"] == true) {
        setState(() {
          history = jsonData["history"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Widget historyCard(item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ชื่อร้าน
            Row(
              children: [
                const Icon(Icons.restaurant, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item["restaurant_name"] ?? "",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            /// เมนู
            Text(
              "เมนู: ${item["menu_name"]}",
              style: const TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.attach_money, color: Colors.green),
                    Text("${item["price"]} บาท"),
                  ],
                ),

                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red),
                    Text("${item["distance_km"]} km"),
                  ],
                ),

                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.blue),
                    Text(item["eaten_at"].toString().substring(0, 10)),
                  ],
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
      backgroundColor: const Color(0xfff5f5f5),

      appBar: AppBar(title: const Text("ประวัติการกิน"), centerTitle: true),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : history.isEmpty
          ? const Center(child: Text("ยังไม่มีประวัติการกิน"))
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                return historyCard(history[index]);
              },
            ),
    );
  }
}
