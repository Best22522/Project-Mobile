import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Menu_Bar extends StatefulWidget {
  final String userId;
  final String currentPage;
  final Function(String) navigateToPage;

  const Menu_Bar({
    Key? key,
    required this.userId,
    required this.currentPage,
    required this.navigateToPage,
  }) : super(key: key);

  @override
  _Menu_BarState createState() => _Menu_BarState();
}

class _Menu_BarState extends State<Menu_Bar> {
  String? companyName;

  @override
  void initState() {
    super.initState();
    _fetchCompanyName();
  }

Future<void> _fetchCompanyName() async {
  try {
    print("Fetching data for userId: ${widget.userId}");

    if (widget.userId.isEmpty) {
      print("Error: userId is empty!");
      return;
    }

    DocumentSnapshot businessDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('information')
        .doc('business')
        .get();

    print("Document exists: ${businessDoc.exists}");

    if (businessDoc.exists) {
      print("Fetched Data: ${businessDoc.data()}");
      setState(() {
        companyName = businessDoc['companyName'] ?? 'Unknown Company';
      });
    } else {
      print("Document does not exist.");
    }
  } catch (e) {
    print('Error fetching company name: $e');
  }
}



  Widget _buildMenuItem(String title, IconData icon, String pageName) {
    bool isSelected = widget.currentPage == pageName;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue : Colors.black,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.blue : Colors.black,
        ),
      ),
      tileColor: isSelected ? Colors.blue.shade50 : null,
      selected: isSelected,
      selectedTileColor: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () {
        widget.navigateToPage(pageName);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.business,
                  color: Colors.white,
                  size: 40,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    companyName ?? 'Loading...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16.0),
              children: [
                _buildMenuItem('ภาพรวม', Icons.dashboard, 'ภาพรวม'),
                _buildMenuItem('ใบเสนอราคา', Icons.receipt_long, 'ใบเสนอราคา'),
                _buildMenuItem('ใบเสร็จรับเงิน', Icons.receipt, 'ใบเสร็จรับเงิน'),
                _buildMenuItem('ค่าใช้จ่าย', Icons.money_off, 'ค่าใช้จ่าย'),
                _buildMenuItem('สินค้า', Icons.store, 'สินค้า'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildMenuItem('การตั้งค่า', Icons.settings, 'การตั้งค่า'),
          ),
        ],
      ),
    );
  }
}
