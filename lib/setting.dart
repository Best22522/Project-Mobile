import 'package:flutter/material.dart';
import 'package:real/homePage.dart';
import 'package:real/preview.dart';
import 'package:real/recicve.dart';
import 'package:real/pay.dart';
import 'package:real/store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'menu_bar.dart'; 
import 'firstPage.dart' as first_page; 
import 'main.dart';


class SettingPage extends StatefulWidget {
  final String companyName;
  final String userId;

  const SettingPage({super.key, required this.companyName, required this.userId}); 

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  String currentPage = 'การตั้งค่า'; // Default page to display

  void _navigateToPage(String pageName) {
    setState(() {
      currentPage = pageName;
    });

    if (pageName == 'ใบเสนอราคา') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PreviewPage(companyName: widget.companyName, userId: widget.userId)
        ),
      );
    } else if (pageName == 'ค่าใช้จ่าย') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PayPage(companyName: widget.companyName, userId: widget.userId)
        ),
      );
    } else if (pageName == 'ใบเสร็จรับเงิน') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RecicvePage(companyName: widget.companyName, userId: widget.userId)
        ),
      );
    } else if (pageName == 'สินค้า') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => StorePage(companyName: widget.companyName, userId: widget.userId)
        ),
      );
    } else if (pageName == 'การตั้งค่า') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SettingPage(companyName: widget.companyName, userId: widget.userId)
        ),
      );
    } else if (pageName == 'ภาพรวม') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(companyName: widget.companyName, userId: widget.userId)
        ),
      );
    }
  }

void _editPersonalInfo() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => first_page.FirstPage(userId: widget.userId),
    ),
  );
}

 // Log out confirmation dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ออกจากระบบ'),
          content: Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
          actions: <Widget>[
            TextButton(
              child: Text('ยกเลิก'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('ยืนยัน'),
              onPressed: () async {
  // Clear shared preferences (remembered login)
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('rememberMe');
  await prefs.remove('email');
  await prefs.remove('password');

  // Navigate to login screen
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => MyApp()),
  );
},

            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('การตั้งค่า'),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        backgroundColor: const Color.fromARGB(255, 157, 123, 198),
      ),
      drawer: Menu_Bar(
        currentPage: currentPage,
        navigateToPage: _navigateToPage, userId: widget.userId,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: Colors.blue),
              title: Text('แก้ไขข้อมูลส่วนตัว',
                  style: TextStyle(fontSize: 18)),
              onTap: _editPersonalInfo,
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.blue),
              title: Text('ออกจากระบบ',
                  style: TextStyle(fontSize: 18)),
              onTap: _showLogoutDialog,
            ),
            Divider(),
          ],
        ),
      ),
    );
  }
}
