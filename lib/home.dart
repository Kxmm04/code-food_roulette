import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'login.dart';
import 'roulette_conditions.dart';
import 'save_restaurant_page.dart';
import 'my_saved_restaurants_page.dart';
import 'history_list_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String fullName = '';
  String email = '';
  String token = '';
  bool isLoading = true;

  int savedRestaurantCount = 0;
  bool isCheckingSaved = true;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    fullName = prefs.getString('user_full_name') ?? '';
    email = prefs.getString('user_email') ?? '';
    token = prefs.getString('token') ?? '';

    await fetchSavedRestaurantCount();

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchSavedRestaurantCount() async {
    if (token.isEmpty) {
      savedRestaurantCount = 0;
      isCheckingSaved = false;
      return;
    }

    try {
      final url = Uri.parse(
        "http://172.24.150.118/food_roulette_api/my_saved_restaurants.php",
      );

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      final result = json.decode(response.body);

      if (!mounted) return;

      savedRestaurantCount = (result["saved_restaurants"] ?? []).length;
      isCheckingSaved = false;
    } catch (e) {
      if (!mounted) return;
      savedRestaurantCount = 0;
      isCheckingSaved = false;
    }
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

  Future<void> openPage(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );

    await fetchSavedRestaurantCount();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final displayName = fullName.isNotEmpty ? fullName : 'ผู้ใช้งาน';
    final canRoulette = savedRestaurantCount >= 2;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFFFF8F3),
        foregroundColor: Colors.black87,
        title: const Text(
          'หน้าแรก',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8A3D), Color(0xFFFF5A2A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.restaurant_menu,
                            color: Color(0xFFFF6B35),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'สวัสดี, $displayName 👋',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email.isNotEmpty ? email : '-',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'เลือกเมนูที่ต้องการใช้งานได้เลย',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: canRoulette
                          ? const LinearGradient(
                              colors: [Color(0xFFFF6B35), Color(0xFFFF7A45)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFFBDBDBD), Color(0xFF9E9E9E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: (canRoulette
                                  ? const Color(0xFFFF6B35)
                                  : Colors.grey)
                              .withOpacity(0.20),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.casino_rounded,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'สุ่มอาหาร • กินอะไรดี',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    canRoulette
                                        ? 'ตั้งงบประมาณ ระยะทาง และให้ระบบช่วยเลือกเมนูที่เหมาะกับคุณ'
                                        : 'ต้องมีร้านที่บันทึกไว้อย่างน้อย 2 ร้านก่อน จึงจะเริ่มสุ่มอาหารได้',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

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
                            isCheckingSaved
                                ? 'กำลังตรวจสอบร้านที่บันทึกไว้...'
                                : 'ร้านที่บันทึกไว้ $savedRestaurantCount ร้าน',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canRoulette
                                  ? Colors.white
                                  : Colors.grey.shade300,
                              foregroundColor: canRoulette
                                  ? const Color(0xFFFF6B35)
                                  : Colors.grey.shade600,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: Icon(
                              canRoulette
                                  ? Icons.arrow_forward_rounded
                                  : Icons.lock_outline_rounded,
                            ),
                            label: Text(
                              canRoulette
                                  ? 'เริ่มสุ่มอาหารตอนนี้'
                                  : 'ยังสุ่มไม่ได้',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            onPressed: (!canRoulette || isCheckingSaved)
                                ? null
                                : () {
                                    openPage(const RouletteConditionsScreen());
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _MenuButtonCard(
                          title: 'บันทึกร้าน',
                          icon: Icons.add_business_rounded,
                          color: const Color(0xFF2563EB),
                          onTap: () {
                            openPage(SaveRestaurantPage(token: token));
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MenuButtonCard(
                          title: 'ร้านที่บันทึกไว้',
                          icon: Icons.bookmark_rounded,
                          color: const Color(0xFF16A34A),
                          onTap: () {
                            openPage(MySavedRestaurantsPage(token: token));
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _MenuButtonCard(
                          title: 'ประวัติการกิน',
                          icon: Icons.history_rounded,
                          color: const Color(0xFF8B5CF6),
                          onTap: () {
                            openPage(HistoryListPage(token: token));
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.lightbulb_rounded,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'แนะนำการใช้งาน',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                canRoulette
                                    ? '1) บันทึกร้านอาหาร\n'
                                      '2) เพิ่มเมนูให้ร้าน\n'
                                      '3) ไปที่สุ่มอาหาร\n'
                                      '4) บันทึกประวัติการกินได้ภายหลัง'
                                    : '1) บันทึกร้านอาหารอย่างน้อย 2 ร้าน\n'
                                      '2) เพิ่มเมนูให้แต่ละร้าน\n'
                                      '3) แล้วค่อยไปที่สุ่มอาหาร',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _MenuButtonCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuButtonCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 130,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}