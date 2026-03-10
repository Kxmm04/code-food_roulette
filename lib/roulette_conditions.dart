import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'roulette_summary.dart';

class RouletteConditionsScreen extends StatefulWidget {
  const RouletteConditionsScreen({super.key});

  @override
  State<RouletteConditionsScreen> createState() =>
      _RouletteConditionsScreenState();
}

class _RouletteConditionsScreenState extends State<RouletteConditionsScreen> {
  final TextEditingController budgetMinController =
      TextEditingController(text: '50');
  final TextEditingController budgetMaxController =
      TextEditingController(text: '100');
  final TextEditingController maxDistanceController =
      TextEditingController(text: '20');

  double? userLat;
  double? userLng;

  bool isLoadingGps = false;
  String message = '';

  @override
  void dispose() {
    budgetMinController.dispose();
    budgetMaxController.dispose();
    maxDistanceController.dispose();
    super.dispose();
  }

  Future<void> getCurrentLocation() async {
    setState(() {
      isLoadingGps = true;
      message = '';
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเปิด GPS ก่อน')),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่ได้รับสิทธิ์ตำแหน่ง')),
        );
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('สิทธิ์ตำแหน่งถูกปฏิเสธถาวร กรุณาเปิดใน Settings'),
          ),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        userLat = pos.latitude;
        userLng = pos.longitude;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ดึงพิกัด GPS สำเร็จแล้ว'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ดึง GPS ไม่สำเร็จ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoadingGps = false);
      }
    }
  }

  void goNext() {
    final budgetMin = int.tryParse(budgetMinController.text.trim());
    final budgetMax = int.tryParse(budgetMaxController.text.trim());
    final maxDistance = double.tryParse(maxDistanceController.text.trim());

    if (budgetMin == null || budgetMax == null || maxDistance == null) {
      setState(() => message = 'กรุณากรอกงบและระยะทางให้ถูกต้อง');
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
      setState(() => message = 'กรุณากดดึง GPS ก่อน');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouletteSummaryScreen(
          budgetMin: budgetMin,
          budgetMax: budgetMax,
          maxDistanceKm: maxDistance,
          userLat: userLat!,
          userLng: userLng!,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffixText,
      prefixIcon: Icon(icon, color: const Color(0xFFFF6B35)),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 1.6),
      ),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      hintStyle: TextStyle(color: Colors.grey.shade500),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = userLat != null && userLng != null;
    final budgetText =
        '${budgetMinController.text.isEmpty ? "-" : budgetMinController.text} - ${budgetMaxController.text.isEmpty ? "-" : budgetMaxController.text} บาท';
    final distanceText =
        '${maxDistanceController.text.isEmpty ? "-" : maxDistanceController.text} กม.';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(context: context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF914D), Color(0xFFFF5E3A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ตั้งเงื่อนไขการสุ่ม',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'กำหนดงบ ระยะทาง และตำแหน่ง\nเพื่อหาร้านและเมนูที่เหมาะกับคุณ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _HeroInfoChip(
                                icon: Icons.payments_rounded,
                                text: budgetText,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _HeroInfoChip(
                                icon: Icons.route_rounded,
                                text: distanceText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      'กำหนดข้อมูลที่ต้องการ',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),

                  _ModernCard(
                    icon: Icons.payments_outlined,
                    iconBg: const Color(0xFFFFF0E8),
                    iconColor: const Color(0xFFFF6B35),
                    title: 'งบประมาณ',
                    subtitle: 'เลือกราคาที่อยากจ่ายต่อมื้อ',
                    child: Column(
                      children: [
                        TextField(
                          controller: budgetMinController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            label: 'งบต่ำสุด',
                            hint: 'เช่น 50',
                            icon: Icons.keyboard_double_arrow_down_rounded,
                            suffixText: 'บาท',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: budgetMaxController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            label: 'งบสูงสุด',
                            hint: 'เช่น 100',
                            icon: Icons.keyboard_double_arrow_up_rounded,
                            suffixText: 'บาท',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  _ModernCard(
                    icon: Icons.near_me_outlined,
                    iconBg: const Color(0xFFEAF2FF),
                    iconColor: const Color(0xFF3B82F6),
                    title: 'ระยะทาง',
                    subtitle: 'กำหนดระยะทางสูงสุดที่คุณสะดวกไป',
                    child: TextField(
                      controller: maxDistanceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(
                        label: 'ระยะทางสูงสุด',
                        hint: 'เช่น 5 หรือ 10',
                        icon: Icons.route_rounded,
                        suffixText: 'กม.',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.20),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.my_location_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ตำแหน่งของคุณ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'ใช้ GPS เพื่อคำนวณระยะทางจริงจากร้านอาหาร',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF2563EB),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: isLoadingGps ? null : getCurrentLocation,
                            icon: Icon(
                              isLoadingGps
                                  ? Icons.sync_rounded
                                  : Icons.gps_fixed_rounded,
                            ),
                            label: Text(
                              isLoadingGps
                                  ? 'กำลังค้นหาตำแหน่ง...'
                                  : 'ดึง GPS ปัจจุบัน',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.10),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                hasLocation
                                    ? Icons.check_circle_rounded
                                    : Icons.location_off_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  hasLocation
                                      ? 'พิกัดปัจจุบัน\n${userLat!.toStringAsFixed(6)}, ${userLng!.toStringAsFixed(6)}'
                                      : 'ยังไม่ได้ดึงพิกัด GPS',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFFF6B35),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              message,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withOpacity(0.28),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: goNext,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text(
                          'ไปหน้าสรุปร้านและเมนู',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: Text(
                      'พร้อมแล้วค่อยกดไปหน้าถัดไป',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
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

class _TopBar extends StatelessWidget {
  final BuildContext context;

  const _TopBar({required this.context});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            elevation: 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pop(this.context),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'ตั้งเงื่อนไขการสุ่ม',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 42),
        ],
      ),
    );
  }
}

class _ModernCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;

  const _ModernCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _HeroInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroInfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}