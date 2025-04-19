import 'package:flutter/material.dart';
import 'loginPage.dart'; // Import the LoginPage.
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isEmailValid = false; // Flag to check if email is valid
  bool doPasswordsMatch = false; // Flag to check if passwords match

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  String errorMessage = '';
  
  // Function to validate the email format
  void validateEmail(String value) {
    setState(() {
      isEmailValid = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value);
      if (isEmailValid) {
        errorMessage = ''; // Clear error message if email is valid
      } else {
        errorMessage = 'กรุณากรอกอีเมลที่ถูกต้อง'; // Invalid email message
      }
    });
  }

  // Function to check if the passwords match
  void validatePasswords() {
    setState(() {
      doPasswordsMatch = passwordController.text == confirmPasswordController.text;
    });
  }

  // Function to check if email exists in Firestore
Future<bool> emailExists(String email) async {
  try {
    // Query the 'users' collection for a document with the same email
    var result = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    // Debugging output to check the result of the query
    print("Number of documents found: ${result.docs.length}");

    return result.docs.isNotEmpty; // If documents exist, email is already taken
  } catch (e) {
    // Handle any errors that occur during the query
    print('Error checking email: $e');
    return false;
  }
}

  @override
Widget build(BuildContext context) {
  return Stack(
    children: [
      // Background gradient (under everything)
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.blueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),

      Scaffold(
        backgroundColor: Colors.transparent, // Transparent to let background show
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
            'สมัครใช้งาน',
            style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60.0, left: 30.0, right: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Text(
                      'HIGHLIGHT',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 30),
                    _buildInputField(Icons.email, 'อีเมล', emailController, validateEmail),
                    SizedBox(height: 20),
                    _buildPasswordInputField(
                      icon: Icons.lock,
                      hint: 'รหัสผ่าน',
                      controller: passwordController,
                      isPassword: true,
                    ),
                    SizedBox(height: 20),
                    _buildPasswordInputField(
                      icon: Icons.lock,
                      hint: 'ยืนยันรหัสผ่าน',
                      controller: confirmPasswordController,
                      isConfirmPassword: true,
                    ),
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, right: 100.0),
                        child: Text(
                          errorMessage,
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: 300,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isEmailValid && doPasswordsMatch ? _checkEmailAndRegister : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.lightBlueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text('สมัครใช้งานฟรี'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}


  Widget _buildInputField(IconData icon, String hint, TextEditingController controller, Function onChanged) {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(icon, color: Colors.lightBlueAccent),
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              onChanged(value); // Validate email when input changes
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordInputField({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    bool isConfirmPassword = false,
  }) {
    bool isVisible = isPassword ? isPasswordVisible : isConfirmPasswordVisible;

    return SizedBox(
      width: 300,
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(icon, color: Colors.lightBlueAccent),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.lightBlueAccent,
            ),
            onPressed: () {
              setState(() {
                if (isPassword) {
                  isPasswordVisible = !isPasswordVisible;
                } else if (isConfirmPassword) {
                  isConfirmPasswordVisible = !isConfirmPasswordVisible;
                }
              });
            },
          ),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          // Validate passwords match as they are typed
          validatePasswords();
        },
      ),
    );
  }

  Future<void> _checkEmailAndRegister() async {
    FocusScope.of(context).unfocus();

    // Check if the email already exists
    bool emailExistsFlag = await emailExists(emailController.text);
    if (emailExistsFlag) {
      setState(() {
        errorMessage = 'อีเมลนี้ถูกใช้ไปแล้ว'; // Email already in use
      });
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'รหัสผ่านไม่ตรงกัน', // Passwords do not match
            style: TextStyle(fontSize: 12),
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
          margin: EdgeInsets.only(bottom: 30, left: 0),
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      try {
        String userId = 'user_id_${DateTime.now().millisecondsSinceEpoch}';
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'email': emailController.text,
          'password': passwordController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลงทะเบียนสำเร็จ'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
