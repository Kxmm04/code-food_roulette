import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';
import 'home.dart';

class RouletteScreen extends StatefulWidget {
  const RouletteScreen({super.key});

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen> {
  final String apiBase = 'http://172.24.148.250/food_roulette_api';

  final TextEditingController budgetMinController =
      TextEditingController(text: '50');
  final TextEditingController budgetMaxController =
      TextEditingController(text: '100');
  final TextEditingController maxDistanceController =
      TextEditingController(text: '20');

  final TextEditingController radiusKmController =
      TextEditingController(text: '1.5');
  final TextEditingController avgPriceController =
      TextEditingController(text: '60');

  double? userLat;
  double? userLng;

  bool isLoadingGps = false;
  bool isLoadingRoulette = false;
  bool isLoadingMap = false;
  bool isSavingHistory = false;
  int savingMapIndex = -1;

  String message = '';
  Map<String, dynamic>? rouletteResult;
  List<dynamic> mapPlaces = [];

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_full_name');
    await prefs.remove('user_email');

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  void dispose() {
    budgetMinController.dispose();
    budgetMaxController.dispose();
    maxDistanceController.dispose();
    radiusKmController.dispose();
    avgPriceController.dispose();
    super.dispose();
  }

  Future<void> getCurrentLocation() async {
    setState(() {
      isLoadingGps = true;
      message = '';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => message = 'กรุณาเปิด GPS (Location Service) ก่อน');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        setState(() => message = 'ไม่ได้รับสิทธิ์เข้าถึงตำแหน่ง');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => message = 'สิทธิ์ตำแหน่งถูกปฏิเสธถาวร กรุณาเปิดใน Settings');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        userLat = pos.latitude;
        userLng = pos.longitude;
        message = 'ได้พิกัด GPS แล้ว';
      });
    } catch (e) {
      setState(() => message = 'ดึง GPS ไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => isLoadingGps = false);
    }
  }

  Future<void> fetchMapNearby() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      setState(() => message = 'ไม่พบ token กรุณาเข้าสู่ระบบใหม่');
      return;
    }

    if (userLat == null || userLng == null) {
      setState(() => message = 'กรุณากด "ใช้ GPS ปัจจุบัน" ก่อน');
      return;
    }

    final radius = double.tryParse(radiusKmController.text.trim()) ?? 1.5;

    setState(() {
      isLoadingMap = true;
      message = '';
      mapPlaces = [];
    });

    try {
      final uri = Uri.parse(
        '$apiBase/map_nearby.php?lat=$userLat&lng=$userLng&radius_km=$radius&limit=30',
      );

      final res = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['ok'] == true) {
        setState(() {
          mapPlaces = data['places'] ?? [];
          message = 'พบ ${mapPlaces.length} ร้านจากแมพ';
        });
      } else {
        setState(() => message = data['message'] ?? 'ดึงร้านจากแมพไม่สำเร็จ');
      }
    } catch (e) {
      setState(() => message = 'เชื่อมต่อ API ไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => isLoadingMap = false);
    }
  }

  Future<void> saveMapPlace(dynamic p, int index) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      setState(() => message = 'ไม่พบ token กรุณาเข้าสู่ระบบใหม่');
      return;
    }

    final avgPrice = int.tryParse(avgPriceController.text.trim()) ?? 0;
    if (avgPrice <= 0) {
      setState(() => message = 'กรุณากรอกราคาเฉลี่ยเริ่มต้นให้ถูกต้อง');
      return;
    }

    setState(() {
      savingMapIndex = index;
      message = '';
    });

    try {
      final res = await http.post(
        Uri.parse('$apiBase/add_restaurant.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'restaurant_name': p['name'],
          'address': p['address'],
          'lat': p['lat'],
          'lng': p['lng'],
          'avg_price': avgPrice,
        }),
      );

      final data = jsonDecode(res.body);
      

      if (!mounted) return;

      if ((res.statusCode == 200 || res.statusCode == 201) &&
          data['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'บันทึกสำเร็จ')),
        );
      } else {
        setState(() => message = data['message'] ?? 'บันทึกไม่สำเร็จ');
      }
    } catch (e) {
      setState(() => message = 'เชื่อมต่อ API ไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => savingMapIndex = -1);
    }
  }

  Future<void> rouletteFood() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      setState(() => message = 'ไม่พบ token กรุณาเข้าสู่ระบบใหม่');
      return;
    }

    final budgetMin = int.tryParse(budgetMinController.text.trim());
    final budgetMax = int.tryParse(budgetMaxController.text.trim());
    final maxDistance = double.tryParse(maxDistanceController.text.trim());

    if (budgetMin == null || budgetMax == null || maxDistance == null) {
      setState(() => message = 'กรุณากรอกงบ/ระยะทางให้ถูกต้อง');
      return;
    }
    if (budgetMin < 0 || budgetMax < budgetMin) {
      setState(() => message = 'งบประมาณไม่ถูกต้อง');
      return;
    }
    if (maxDistance <= 0) {
      setState(() => message = 'ระยะทางต้องมากกว่า 0');
      return;
    }
    if (userLat == null || userLng == null) {
      setState(() => message = 'กรุณากด "ใช้ GPS ปัจจุบัน" ก่อน');
      return;
    }

    setState(() {
      isLoadingRoulette = true;
      message = '';
      rouletteResult = null;
    });

    try {
      final res = await http.post(
        Uri.parse('$apiBase/roulette.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'budget_min': budgetMin,
          'budget_max': budgetMax,
          'max_distance_km': maxDistance,
          'user_lat': userLat,
          'user_lng': userLng,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['ok'] == true) {
        setState(() {
          rouletteResult = data;
          message = 'สุ่มสำเร็จ';
        });
      } else {
        setState(() => message = data['message'] ?? 'สุ่มไม่สำเร็จ');
      }
    } catch (e) {
      setState(() => message = 'เชื่อมต่อ API ไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => isLoadingRoulette = false);
    }
  }

  Future<void> saveHistoryFromResult() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      setState(() => message = 'ไม่พบ token กรุณาเข้าสู่ระบบใหม่');
      return;
    }

    final restaurant = rouletteResult?['restaurant'];
    final menu = rouletteResult?['menu'];
    final distanceKm = rouletteResult?['distance_km'];

    if (restaurant == null || menu == null) {
      setState(() => message = 'ยังไม่มีผลการสุ่มให้บันทึก');
      return;
    }

    setState(() {
      isSavingHistory = true;
    });

    try {
      final res = await http.post(
        Uri.parse('$apiBase/history_add.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'restaurant_id': restaurant['restaurant_id'],
          'menu_id': menu['menu_id'],
          'price': menu['price'],
          'distance_km': distanceKm ?? 0,
        }),
      );

      final data = jsonDecode(res.body);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'บันทึกประวัติสำเร็จ')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกประวัติไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSavingHistory = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = rouletteResult?['restaurant'];
    final menu = rouletteResult?['menu'];
    final distanceKm = rouletteResult?['distance_km'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Process 4-5: สุ่มอาหาร'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
            icon: const Icon(Icons.home),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'กำหนดเงื่อนไขการสุ่ม',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: budgetMinController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'งบต่ำสุด (บาท)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: budgetMaxController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'งบสูงสุด (บาท)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: maxDistanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'ระยะทางสูงสุด (กม.)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoadingGps ? null : getCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: Text(isLoadingGps ? 'กำลังดึง GPS...' : 'ใช้ GPS ปัจจุบัน'),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              (userLat != null && userLng != null)
                  ? 'พิกัด: ${userLat!.toStringAsFixed(6)}, ${userLng!.toStringAsFixed(6)}'
                  : 'ยังไม่ได้ดึงพิกัด',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoadingRoulette ? null : rouletteFood,
                child: Text(isLoadingRoulette ? 'กำลังสุ่ม...' : 'สุ่มเมนูอาหาร'),
              ),
            ),
            const SizedBox(height: 12),
            if (message.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(message),
              ),
            const SizedBox(height: 16),
            if (restaurant != null && menu != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ผลการสุ่ม',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      Text('ร้าน: ${restaurant['restaurant_name']}'),
                      Text('เมนู: ${menu['menu_name']}'),
                      Text('ราคา: ${menu['price']} บาท'),
                      Text('ระยะทาง: $distanceKm กม.'),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isSavingHistory ? null : saveHistoryFromResult,
                          icon: const Icon(Icons.save),
                          label: Text(
                            isSavingHistory
                                ? 'กำลังบันทึก...'
                                : 'บันทึกว่ากินเมนูนี้',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'ดึงร้านจากแมพ (ใกล้ฉัน)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: radiusKmController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'รัศมี (กม.)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: avgPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ราคาเฉลี่ย',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoadingMap ? null : fetchMapNearby,
                icon: const Icon(Icons.map),
                label: Text(isLoadingMap ? 'กำลังดึงจากแมพ...' : 'ดึงร้านจากแมพ'),
              ),
            ),
            const SizedBox(height: 10),
            if (mapPlaces.isEmpty)
              const Text('ยังไม่มีร้านจากแมพ')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: mapPlaces.length,
                itemBuilder: (context, index) {
                  final p = mapPlaces[index];
                  return Card(
                    child: ListTile(
                      title: Text(p['name'] ?? '-'),
                      subtitle: Text(
                        (p['address'] ?? '').toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: ElevatedButton(
                        onPressed: savingMapIndex == index
                            ? null
                            : () => saveMapPlace(p, index),
                        child: Text(savingMapIndex == index ? '...' : 'บันทึก'),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}