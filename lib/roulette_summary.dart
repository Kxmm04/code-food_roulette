import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  final String baseUrl = 'http://172.24.148.250/food_roulette_api';

  bool isLoading = true;
  bool isRandoming = false;
  bool isSavingHistory = false;
  String message = '';
  List<Map<String, dynamic>> matched = [];

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
    });

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/restaurants_with_menus.php'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(res.body);

      if (res.statusCode != 200 || data['ok'] != true) {
        setState(
          () => message = data['message'] ?? 'ดึงข้อมูลร้าน+เมนูไม่สำเร็จ',
        );
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
      setState(() => message = 'เชื่อมต่อ API ไม่สำเร็จ: $e');
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'บันทึกประวัติสำเร็จ')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('บันทึกประวัติไม่สำเร็จ: $e')));
    } finally {
      if (mounted) {
        setState(() => isSavingHistory = false);
      }
    }
  }

  Future<void> randomPick() async {
    if (matched.isEmpty || isRandoming) return;

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

    final pick = all[Random().nextInt(all.length)];
    final r = pick['r'] as Map<String, dynamic>;
    final m = pick['m'] as Map<String, dynamic>;

    final restaurantId = ((r['restaurant_id'] ?? 0) as num).toInt();
    final menuId = ((m['menu_id'] ?? 0) as num).toInt();
    final restaurantName = (r['restaurant_name'] ?? '-').toString();
    final menuName = (m['menu_name'] ?? '-').toString();
    final priceInt = ((m['price'] ?? 0) as num).toInt();
    final distKm = (r['distance_km'] as double);
    final distText = _distanceText(distKm);

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.casino,
                            color: Colors.deepOrange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'ผลการสุ่ม',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'ร้าน', value: restaurantName),
                    _InfoRow(label: 'เมนู', value: menuName),
                    _InfoRow(label: 'ราคา', value: '$priceInt บาท'),
                    _InfoRow(label: 'ระยะทาง', value: distText),
                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'โอเค',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: isSavingHistory
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
                        icon: const Icon(Icons.save),
                        label: Text(
                          isSavingHistory
                              ? 'กำลังบันทึก...'
                              : 'บันทึกว่ากินเมนูนี้',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
      body: RefreshIndicator(
        onRefresh: fetchAndFilter,
        child: isLoading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 250),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepOrange.shade400,
                          Colors.orange.shade400,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepOrange.withOpacity(0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'เงื่อนไข',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          condText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
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
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(14),
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
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: (matched.isEmpty || isRandoming)
                          ? null
                          : () => randomPick(),
                      icon: const Icon(Icons.casino),
                      label: Text(
                        isRandoming ? 'กำลังสุ่ม...' : 'สุ่มจากรายการนี้',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(message),
                    ),
                  ],
                  const SizedBox(height: 10),
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
                          borderRadius: BorderRadius.circular(18),
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
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange.withOpacity(
                                        0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
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
                                            fontWeight: FontWeight.bold,
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
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'เมนูที่เข้าเงื่อนไข',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: menus.map((m) {
                                  final menuName = (m['menu_name'] ?? '-')
                                      .toString();
                                  final price = (m['price'] ?? '-').toString();

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange.withOpacity(
                                        0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.deepOrange.withOpacity(
                                          0.12,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      '$menuName • $price บาท',
                                      style: const TextStyle(fontSize: 12),
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
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
