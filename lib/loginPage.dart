import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';  // Import shared_preferences
import 'firstPage.dart';
import 'homePage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscureText = true;
  bool _rememberMe = false;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String errorMessage = '';

  @override
void initState() {
  super.initState();
  _loadRememberedLogin();
}

Future<void> _loadRememberedLogin() async { // ตัว remember
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool? rememberMe = prefs.getBool('rememberMe') ?? false;

  if (rememberMe) {
    String? savedEmail = prefs.getString('email');
    String? savedPassword = prefs.getString('password');

    if (savedEmail != null && savedPassword != null) {
      var result = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: savedEmail)
          .where('password', isEqualTo: savedPassword)
          .get();

      if (result.docs.isNotEmpty) {
        String userDocumentId = result.docs.first.id;
        DocumentReference userDocRef =
            FirebaseFirestore.instance.collection('users').doc(userDocumentId);

        var subCollection = await userDocRef.collection('information').get();

        if (subCollection.docs.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(companyName: "", userId: userDocumentId),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => FirstPage(userId: userDocumentId),
            ),
          );
        }
      }
    }
  }
}

  Future<void> _storeLoginCredentials() async { // ตัวกล่อง checkbox
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (_rememberMe) {
    prefs.setBool('rememberMe', _rememberMe);
    prefs.setString('email', emailController.text);
    prefs.setString('password', passwordController.text);
  } else {
    prefs.remove('rememberMe');
    prefs.remove('email');
    prefs.remove('password');
  }
}

  Future<void> _login() async {  // login ธรรมดา
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'กรุณากรอกอีเมลและรหัสผ่าน';
      });
      return;
    }

    try {
      var result = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .get();

      if (result.docs.isNotEmpty) {
        String userDocumentId = result.docs.first.id;
        DocumentReference userDocRef =
            FirebaseFirestore.instance.collection('users').doc(userDocumentId);

        var subCollection = await userDocRef.collection('information').get();

        if (subCollection.docs.isNotEmpty) {
          await _storeLoginCredentials();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(companyName: "", userId: userDocumentId),
            ),
          );
        } else {
          // Store login credentials before redirecting
          await _storeLoginCredentials();

          // Redirect to FirstPage if 'information' does not exist
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => FirstPage(userId: userDocumentId),
            ),
          );
        }
      } else {
        setState(() {
          errorMessage = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ';
      });
      print('Error logging in: $e');
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.blueAccent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
      ),
      title: Text(
        'เข้าสู่ระบบ',
        style: TextStyle(color: Colors.white),
      ),
    ),
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.lightBlueAccent, Colors.blueAccent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                Text(
                  'HIGHLIGHT',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 30),
                SizedBox(
                  width: 600,
                  height: 50,
                  child: TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'อีเมล',
                      labelStyle: TextStyle(color: Colors.black),
                      prefixIcon: Icon(Icons.perm_identity, color: Colors.blueAccent),
                      filled: true,
                      fillColor: Colors.white,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: 600,
                  height: 50,
                  child: TextField(
                    controller: passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: 'รหัสผ่าน',
                      labelStyle: TextStyle(color: Colors.black),
                      prefixIcon: Icon(Icons.lock, color: Colors.blueAccent),
                      filled: true,
                      fillColor: Colors.white,
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility_off : Icons.visibility,
                          color: Colors.blueAccent,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      errorMessage,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 0, left: 0),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (bool? value) {
                            setState(() {
                              _rememberMe = value!;
                            });
                          },
                        ),
                        Text(
                          'บันทึกรหัสผ่าน',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: 600,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      side: BorderSide.none,
                    ),
                    child: Text('เข้าสู่ระบบ'),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
