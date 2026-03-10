import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {

  TextEditingController email = TextEditingController();
  TextEditingController otp = TextEditingController();

  bool showOTP = false;

  Future sendOTP() async {

    var url = Uri.parse("http://172.24.150.118/food_roulette_api/forgot_password.php");

    var res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email.text
      }),
    );

    var data = jsonDecode(res.body);

    if(data["ok"] == true){

      setState(() {
        showOTP = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ส่ง OTP แล้ว")),
      );

    }else{

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "ไม่พบ Email")),
      );

    }
  }

  Future verifyOTP() async {

    var url = Uri.parse("http://172.24.150.118/food_roulette_api/verify_otp.php");

    var res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email.text,
        "otp_code": otp.text
      }),
    );

    var data = jsonDecode(res.body);

    if(data["ok"] == true){

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP ถูกต้อง")),
      );

      
      Navigator.pushNamed(
      context,
      "/reset",
      arguments: {
        "email": email.text,
        "otp": otp.text,
      },
    );

    }else{

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP ไม่ถูกต้อง")),
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

              /// ICON + TITLE
              const Icon(
                Icons.lock_reset,
                size: 90,
                color: Colors.white,
              ),

              const SizedBox(height: 10),

              const Text(
                "ลืมรหัสผ่าน",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const Text(
                "กรอก Email เพื่อรับ OTP",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 30),

              /// CARD FORM
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

                    /// EMAIL
                    TextField(
                      controller: email,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email),
                        labelText: "Email",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// SEND OTP BUTTON
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
                        onPressed: sendOTP,
                        child: const Text(
                          "ส่ง OTP",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    if (showOTP) ...[

                      const SizedBox(height: 25),

                      /// OTP
                      TextField(
                        controller: otp,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock),
                          labelText: "กรอกรหัส OTP",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// VERIFY OTP
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 5,
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: verifyOTP,
                          child: const Text(
                            "ยืนยัน OTP",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    ]
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
                  "กลับไปหน้าเข้าสู่ระบบ",
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