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

      if (!mounted) return;

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
      debugPrint(e.toString());
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteHistory(int historyId) async {
    var url = Uri.parse(
      "http://172.24.150.118/food_roulette_api/history_delete.php",
    );

    try {
      var response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"history_id": historyId}),
      );

      var result = json.decode(response.body);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "ลบประวัติสำเร็จ")),
      );

      fetchHistory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("ลบประวัติไม่สำเร็จ: $e")));
    }
  }

  Future<void> confirmDeleteHistory(int historyId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("ยืนยันการลบ"),
          content: const Text("ต้องการลบประวัติการกินนี้ใช่หรือไม่"),
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
      await deleteHistory(historyId);
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
        color: Colors.orange.shade50, // พื้นหลังกล่องสีส้มอ่อน
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
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
            Row(
              children: [
                const Icon(Icons.soup_kitchen, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item["restaurant_name"] ?? "",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    confirmDeleteHistory(item["history_id"]);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              "เมนู: ${item["menu_name"]}",
              style: const TextStyle(fontSize: 15, color: Colors.black),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.attach_money, color: Colors.green),
                    Text(
                      "${item["price"]} บาท",
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red),
                    Text(
                      "${item["distance_km"]} km",
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.blue),
                    Text(
                      item["eaten_at"].toString().substring(0, 10),
                      style: const TextStyle(color: Colors.black),
                    ),
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
      appBar: AppBar(
        title: const Text("ประวัติการกิน"),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : history.isEmpty
          ? const Center(
              child: Text(
                "ยังไม่มีประวัติการกิน",
                style: TextStyle(color: Colors.black),
              ),
            )
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                return historyCard(history[index]);
              },
            ),
    );
  }
}