import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordPage({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {

  final TextEditingController password = TextEditingController();

  Future<void> resetPassword() async {

  var url = Uri.parse(
      "http://172.24.150.118/food_roulette_api/reset_password.php");

  try {

    var res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": widget.email,
        "otp_code": widget.otp,
        "new_password": password.text
      }),
    );

    var data = jsonDecode(res.body);

    if(data["ok"] == true){

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("เปลี่ยนรหัสผ่านสำเร็จ")),
      );

      Navigator.popUntil(context, (route) => route.isFirst);

    }else{

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "เปลี่ยนรหัสไม่สำเร็จ")),
      );

    }

  } catch (e) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("เชื่อมต่อ Server ไม่ได้")),
    );

  }
}
  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFF7043),
            Color(0xFFFFA726),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),

      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),

          child: Column(
            children: [

              /// ICON
              const Icon(
                Icons.lock_open,
                size: 90,
                color: Colors.white,
              ),

              const SizedBox(height: 10),

              const Text(
                "ตั้งรหัสผ่านใหม่",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const Text(
                "กรอกรหัสผ่านใหม่ของคุณ",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 30),

              /// CARD
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),

                child: Column(
                  children: [

                    /// PASSWORD
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock),
                        labelText: "รหัสผ่านใหม่",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    /// SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,

                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 5,
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),

                        onPressed: resetPassword,

                        child: const Text(
                          "บันทึกรหัสผ่าน",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),

              const SizedBox(height: 15),

              /// BACK BUTTON
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "ย้อนกลับ",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )

            ],
          ),
        ),
      ),
    ),
  );
}
}