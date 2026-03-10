import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';

class RouletteSummaryScreen extends StatefulWidget {
  final int budgetMin;
  final int budgetMax;
  final double maxDistanceKm;
  final double userLat;
  final double userLng;

  const RouletteSummaryScreen({
    super.key,
    required this.budgetMin,
    required this.budgetMax,
    required this.maxDistanceKm,
    required this.userLat,
    required this.userLng,
  });

  @override
  State<RouletteSummaryScreen> createState() => _RouletteSummaryScreenState();
}

class _RouletteSummaryScreenState extends State<RouletteSummaryScreen> {
  final String baseUrl = 'http://172.24.150.118/food_roulette_api';

  bool isLoading = true;
  bool isRandoming = false;
  bool isSavingHistory = false;
  bool historySaved = false;
  String message = '';
  List<Map<String, dynamic>> matched = [];

  int randomCount = 0;
  final int maxRandomCount = 3;

  final List<int> usedMenuIds = [];

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  void initState() {
    super.initState();
    fetchAndFilter();
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const earth = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180.0;
    final dLon = (lon2 - lon1) * pi / 180.0;

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) *
            cos(lat2 * pi / 180.0) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earth * c;
  }

  String _distanceText(double km) {
    if (km < 1) return '${(km * 1000).round()} ม.';
    return '${km.toStringAsFixed(2)} กม.';
  }

  Future<void> fetchAndFilter() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      setState(() {
        isLoading = false;
        message = 'ไม่พบ token กรุณาเข้าสู่ระบบใหม่';
      });
      return;
    }

    setState(() {
      isLoading = true;
      message = '';
      matched = [];
      randomCount = 0;
      usedMenuIds.clear();
    });

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/restaurants_with_menus.php'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(res.body);

      if (res.statusCode != 200 || data['ok'] != true) {
        setState(() {
          message = data['message'] ?? 'ดึงข้อมูลร้าน+เมนูไม่สำเร็จ';
        });
        return;
      }

      final restaurants = (data['restaurants'] ?? []) as List<dynamic>;
      final List<Map<String, dynamic>> out = [];

      for (final r in restaurants) {
        final rLat = r['lat'];
        final rLng = r['lng'];
        if (rLat == null || rLng == null) continue;

        final dist = _haversineKm(
          widget.userLat,
          widget.userLng,
          (rLat as num).toDouble(),
          (rLng as num).toDouble(),
        );

        if (dist > widget.maxDistanceKm) continue;

        final menus = (r['menus'] ?? []) as List<dynamic>;

        final filteredMenus = menus.where((m) {
          final price = (m['price'] ?? 0) as num;
          final available = (m['is_available'] ?? 1) as num;
          return available == 1 &&
              price >= widget.budgetMin &&
              price <= widget.budgetMax;
        }).toList();

        if (filteredMenus.isEmpty) continue;

        out.add({
          'restaurant_id': r['restaurant_id'],
          'restaurant_name': (r['restaurant_name'] ?? '-').toString(),
          'address': (r['address'] ?? '').toString(),
          'distance_km': dist,
          'menus': filteredMenus,
        });
      }

      out.sort(
        (a, b) =>
            (a['distance_km'] as double).compareTo(b['distance_km'] as double),
      );

      setState(() {
        matched = out;
        message = matched.isEmpty
            ? 'ไม่พบร้าน/เมนูที่เข้าเงื่อนไข (งบ/ระยะทาง)'
            : '';
      });
    } catch (e) {
      setState(() {
        message = 'เชื่อมต่อ API ไม่สำเร็จ: $e';
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> saveHistory({
    required int restaurantId,
    required int menuId,
    required int price,
    required double distanceKm,
  }) async {
    if (historySaved) return;

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบ token กรุณาเข้าสู่ระบบใหม่')),
      );
      return;
    }

    setState(() => isSavingHistory = true);

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/history_add.php'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'restaurant_id': restaurantId,
          'menu_id': menuId,
          'price': price,
          'distance_km': distanceKm,
        }),
      );

      final data = jsonDecode(res.body);

      if (!mounted) return;

      if (res.statusCode == 200 && data['ok'] == true) {
        setState(() {
          historySaved = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'บันทึกประวัติสำเร็จ')),
        );

        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'บันทึกประวัติไม่สำเร็จ')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกประวัติไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isSavingHistory = false);
      }
    }
  }

  Future<void> _showRandomLoadingDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _RandomLoadingDialog(),
    );
  }

  Future<void> randomPick() async {
    if (matched.isEmpty || isRandoming) return;

    if (randomCount >= maxRandomCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('คุณสุ่มครบ 3 ครั้งแล้ว')),
      );
      return;
    }

    setState(() => isRandoming = true);

    final all = <Map<String, dynamic>>[];
    for (final r in matched) {
      final menus = (r['menus'] as List).cast<dynamic>();
      for (final m in menus) {
        all.add({'r': r, 'm': m});
      }
    }

    if (all.isEmpty) {
      if (mounted) setState(() => isRandoming = false);
      return;
    }

    final available = all.where((item) {
      final m = item['m'] as Map<String, dynamic>;
      final menuId = ((m['menu_id'] ?? 0) as num).toInt();
      return !usedMenuIds.contains(menuId);
    }).toList();

    if (available.isEmpty) {
      if (mounted) {
        setState(() => isRandoming = false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เมนูที่เข้าเงื่อนไขถูกสุ่มครบแล้ว')),
      );
      return;
    }

    final pick = available[Random().nextInt(available.length)];
    final r = pick['r'] as Map<String, dynamic>;
    final m = pick['m'] as Map<String, dynamic>;

    final restaurantId = ((r['restaurant_id'] ?? 0) as num).toInt();
    final menuId = ((m['menu_id'] ?? 0) as num).toInt();
    final restaurantName = (r['restaurant_name'] ?? '-').toString();
    final menuName = (m['menu_name'] ?? '-').toString();
    final priceInt = ((m['price'] ?? 0) as num).toInt();
    final distKm = (r['distance_km'] as double);
    final distText = _distanceText(distKm);

    setState(() {
      randomCount++;
      historySaved = false;
      usedMenuIds.add(menuId);
    });

    await _showRandomLoadingDialog();
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pop();
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 24,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.14),
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8A3D), Color(0xFFFF5A2A)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'เมนูที่ได้กินวันนี้',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'ขอให้เป็นมื้อที่อร่อยนะ',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepOrange.withOpacity(0.10),
                            Colors.orange.withOpacity(0.07),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.deepOrange.withOpacity(0.12),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            menuName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.deepOrange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '$priceInt บาท',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ResultInfoRow(
                      icon: Icons.storefront_rounded,
                      label: 'ร้านอาหาร',
                      value: restaurantName,
                    ),
                    const SizedBox(height: 10),
                    _ResultInfoRow(
                      icon: Icons.location_on_rounded,
                      label: 'ระยะทาง',
                      value: distText,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'โอเค',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              historySaved ? Colors.green : Colors.deepOrange,
                          side: BorderSide(
                            color:
                                historySaved ? Colors.green : Colors.deepOrange,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: (isSavingHistory || historySaved)
                            ? null
                            : () async {
                                setDialogState(() {});
                                await saveHistory(
                                  restaurantId: restaurantId,
                                  menuId: menuId,
                                  price: priceInt,
                                  distanceKm: distKm,
                                );
                                if (mounted) {
                                  setDialogState(() {});
                                }
                              },
                        icon: Icon(
                          historySaved
                              ? Icons.check_circle
                              : Icons.save_alt_rounded,
                        ),
                        label: Text(
                          isSavingHistory
                              ? 'กำลังบันทึก...'
                              : historySaved
                                  ? 'บันทึกแล้ว'
                                  : 'บันทึกว่ากินเมนูนี้',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (mounted) {
      setState(() => isRandoming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final condText =
        'งบ ${widget.budgetMin}-${widget.budgetMax} บาท • ระยะไม่เกิน ${widget.maxDistanceKm.toStringAsFixed(1)} กม.';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFFFF8F3),
        foregroundColor: Colors.black87,
        title: const Text(
          'ร้านและเมนูที่เข้าเงื่อนไข',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: isLoading
          ? ListView(
              physics: const ClampingScrollPhysics(),
              children: const [
                SizedBox(height: 250),
                Center(child: CircularProgressIndicator()),
              ],
            )
          : ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepOrange.shade400,
                        Colors.orange.shade400,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrange.withOpacity(0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'เงื่อนไขที่เลือก',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        condText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              'พบ ${matched.length} ร้าน',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.restaurant,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    onPressed:
                        (matched.isEmpty ||
                                isRandoming ||
                                randomCount >= maxRandomCount)
                            ? null
                            : () => randomPick(),
                    icon: const Icon(Icons.casino_rounded),
                    label: Text(
                      isRandoming
                          ? 'กำลังสุ่ม...'
                          : randomCount >= maxRandomCount
                              ? 'สุ่มครบ 3 ครั้งแล้ว'
                              : 'สุ่มจากรายการนี้',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'สุ่มไปแล้ว $randomCount / $maxRandomCount ครั้ง',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'ระบบจะไม่สุ่มเมนูซ้ำในรอบนี้',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange.shade200),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(message),
                  ),
                ],
                const SizedBox(height: 12),
                if (matched.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: Text('ไม่มีรายการที่เข้าเงื่อนไข')),
                  )
                else
                  ...matched.map((r) {
                    final menus = (r['menus'] as List).cast<dynamic>();
                    final dist = (r['distance_km'] as double);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrange.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Icon(
                                    Icons.storefront,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r['restaurant_name'] ?? '-',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if ((r['address'] ?? '')
                                          .toString()
                                          .isNotEmpty)
                                        Text(
                                          r['address'],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    _distanceText(dist),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.fastfood_rounded,
                                  size: 18,
                                  color: Colors.deepOrange,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'เมนูที่เข้าเงื่อนไข',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                    color: Color(0xFF2D2D2D),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: menus.map((m) {
                                final menuName =
                                    (m['menu_name'] ?? '-').toString();
                                final price = (m['price'] ?? '-').toString();

                                return Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 120,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.deepOrange.withOpacity(0.12),
                                        Colors.orange.withOpacity(0.08),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.deepOrange.withOpacity(
                                        0.18,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.deepOrange.withOpacity(
                                          0.06,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.restaurant_menu_rounded,
                                          size: 16,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              menuName,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF2D2D2D),
                                                height: 1.25,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$price บาท',
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.deepOrange,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

class _ResultInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ResultInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.deepOrange),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black54,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }
}

class _RandomLoadingDialog extends StatefulWidget {
  const _RandomLoadingDialog();

  @override
  State<_RandomLoadingDialog> createState() => _RandomLoadingDialogState();
}

class _RandomLoadingDialogState extends State<_RandomLoadingDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.08).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8A3D), Color(0xFFFF5A2A)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(
                  Icons.ramen_dining_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'กำลังสุ่มเมนูให้อยู่นะ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'กำลังเลือกเมนูที่ใช่สำหรับคุณ...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: const LinearProgressIndicator(
                minHeight: 8,
                backgroundColor: Color(0xFFFFE0D1),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}