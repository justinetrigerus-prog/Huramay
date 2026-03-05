import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SignUpScreen(),
  ));
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Input controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _selectedDept;

  List<String> depts = [
    'BS in Information Technology',
    'BS in Computer Science',
    'BS in Information Systems',
    'BS in Business Administration',
    'Bachelor of Education'
  ];

  // Logic to send data to Python
  Future<void> doSignup() async {
    if (_nameCtrl.text.isEmpty || _selectedDept == null || _passCtrl.text.isEmpty) {
      _msg("Please fill all fields");
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      _msg("Passwords do not match");
      return;
    }

    try {
      var url = Uri.parse('http://127.0.0.1:5000/signup');
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': _nameCtrl.text,
          'email': _emailCtrl.text,
          'department': _selectedDept,
          'password': _passCtrl.text,
        }),
      );

      var res = jsonDecode(response.body);
      _msg(res['message']);

      if (response.statusCode == 201) {
        _nameCtrl.clear(); _emailCtrl.clear();
        _passCtrl.clear(); _confirmCtrl.clear();
      }
    } catch (e) {
      _msg("Connection Error: Is app.py running?");
    }
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A0088), Color(0xFFFDEB00)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                const Text("Huramay", style: TextStyle(fontSize: 45, color: Colors.white, fontWeight: FontWeight.bold)),
                const Text("Signup", style: TextStyle(color: Colors.white70, fontSize: 18)),
                const SizedBox(height: 30),

                _field("Full Name", _nameCtrl, Icons.person),
                _field("Email", _emailCtrl, Icons.email),

                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.school, color: Color(0xFF1A0088)), border: InputBorder.none),
                      hint: const Text("Department"),
                      value: _selectedDept,
                      items: depts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (v) => setState(() => _selectedDept = v),
                    ),
                  ),
                ),

                _field("Password", _passCtrl, Icons.lock, isPass: true),
                _field("Confirm Password", _confirmCtrl, Icons.lock_outline, isPass: true),

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: doSignup,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF1A0088), shape: const StadiumBorder()),
                    child: const Text("SIGN UP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String hint, TextEditingController controller, IconData icon, {bool isPass = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: TextField(
        controller: controller,
        obscureText: isPass,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF1A0088)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}