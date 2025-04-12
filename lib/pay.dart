import 'package:flutter/material.dart';
import 'package:real/homePage.dart';
import 'package:real/preview.dart';
import 'package:real/recicve.dart';     
import 'package:real/store.dart';
import 'package:real/setting.dart';
import 'menu_bar.dart'; // Import Menu_Bar widget
import 'package:cloud_firestore/cloud_firestore.dart';


class PayPage extends StatefulWidget {
  final String companyName;
  final String userId;

  const PayPage({super.key, required this.companyName, required this.userId});

  @override
  _PayPageState createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> {
  String currentPage = 'ค่าใช้จ่าย'; // Default page to display

  // Controllers for text fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  // Variable for selected date
  DateTime selectedDate = DateTime.now();

  // List to store product information
  List<Map<String, dynamic>> products = [];

  // Function to pick the date
  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> _fetchProducts() async {
  try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentReference userDocRef = firestore
        .collection('users')
        .doc(widget.userId)
        .collection('pay')
        .doc('userpay');

    // Fetch all transactions
    QuerySnapshot snapshot = await userDocRef.collection('transactions').get();

    setState(() {
      products = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'name': data['name'] ?? 'No name',
          'price': data['price']?.toString() ?? '0',
          'note': data['note'] ?? '',
          'date': data['date'] ?? '',
          'id': doc.id, // Add the document ID here
        };
      }).toList();
    });
  } catch (e) {
    print('Error fetching products: $e');
  }
}


  @override
  void initState() {
    super.initState();
    _fetchProducts(); // Fetch products when the page is initialized
  }

void _saveProduct() async {
  if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
    try {
      // Reference to Firestore
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Reference to user's pay collection
      DocumentReference userDocRef = firestore
          .collection('users')
          .doc(widget.userId) // User ID as document name
          .collection('pay')
          .doc('userpay'); // Single document to store all payments

      // Create subcollection inside 'userpay'
      CollectionReference payCollectionRef = userDocRef.collection('transactions');

      // Add data to Firestore
      await payCollectionRef.add({
        'name': nameController.text,
        'price': priceController.text,
        'note': noteController.text,
        'date': selectedDate.toLocal().toString().split(' ')[0], // Format the date
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        products.add({
          'name': nameController.text,
          'price': priceController.text,
          'note': noteController.text,
          'date': "${selectedDate.toLocal()}".split(' ')[0],
        });
      });

      // Clear fields
      nameController.clear();
      priceController.clear();
      noteController.clear();
      setState(() {
        selectedDate = DateTime.now();
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เพิ่มข้อมูลค่าใช้จ่ายเรียบร้อย!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('กรุณากรอกชื่อและราคา')),
    );
  }
}


void _editProduct(int index) async {
  final product = products[index];
  nameController.text = product['name']!;
  priceController.text = product['price']!;
  noteController.text = product['note']!;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('แก้ไขข้อมูลค่าใช้จ่าย'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'ชื่อสินค้า'),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'ราคา'),
              ),
              TextField(
                controller: noteController,
                decoration: InputDecoration(labelText: 'โน้ต'),
              ),
              Row(
                children: [
                  Text("วันที่: ${selectedDate.toLocal()}".split(' ')[0]),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: _pickDate, // Pick date when pressed
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('ยกเลิก'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: Text('บันทึก'),
            onPressed: () async {
              FirebaseFirestore firestore = FirebaseFirestore.instance;

              // Get the document ID for the product
              String productId = product['id']; // Assuming you are passing the id in the 'id' field

              // Update the product in Firestore using the productId
              DocumentReference productRef = firestore
                  .collection('users')
                  .doc(widget.userId)
                  .collection('pay')
                  .doc('userpay')
                  .collection('transactions')
                  .doc(productId); // Use productId here

              await productRef.update({
                'name': nameController.text,
                'price': priceController.text,
                'note': noteController.text,
                'date': "${selectedDate.toLocal()}".split(' ')[0],
                'timestamp': FieldValue.serverTimestamp(),
              });

              setState(() {
                products[index] = {
                  'name': nameController.text,
                  'price': priceController.text,
                  'note': noteController.text,
                  'date': "${selectedDate.toLocal()}".split(' ')[0],
                  'id': productId, // Ensure the id is stored here
                };
              });

              // Clear the fields after editing
              nameController.clear();
              priceController.clear();
              noteController.clear();
              setState(() {
                selectedDate = DateTime.now();
              });
              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}



// Function to delete the product
void _deleteProduct(int index) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  final product = products[index];
  
  // Delete the product from Firestore
  DocumentReference productRef = firestore
      .collection('users')
      .doc(widget.userId)
      .collection('pay')
      .doc('userpay')
      .collection('transactions')
      .doc(product['id']); // Assuming each product has an 'id'

  await productRef.delete();

  setState(() {
    products.removeAt(index);
  });
}


  // Function to navigate to different pages
  void _navigateToPage(String pageName) {
    setState(() {
      currentPage = pageName;
    });

    if (pageName == 'ใบเสนอราคา') {
      Navigator.push(
        context,
        MaterialPageRoute(
        builder: (context) => PreviewPage(companyName: widget.companyName, userId: widget.userId)
        ),
      );
    } else if (pageName == 'ค่าใช้จ่าย') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PreviewPage(companyName: widget.companyName, userId: widget.userId)
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

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ค่าใช้จ่าย'),
        backgroundColor: const Color.fromARGB(255, 235, 84, 134),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),  // "+" symbol icon
            onPressed: () {
              // Show a dialog to enter product details
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('เพิ่มข้อมูลค่าใช้จ่าย'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(labelText: 'ชื่อสินค้า'),
                          ),
                          TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: 'ราคา'),
                          ),
                          TextField(
                            controller: noteController,
                            decoration: InputDecoration(labelText: 'โน้ต'),
                          ),
                          Row(
                            children: [
                              Text("วันที่: ${selectedDate.toLocal()}".split(' ')[0]),
                              IconButton(
                                icon: Icon(Icons.calendar_today),
                                onPressed: _pickDate, // Pick date when pressed
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text('ยกเลิก'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      TextButton(
                        onPressed: _saveProduct,
                        child: Text('บันทึก'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      drawer: Menu_Bar(
        currentPage: currentPage,
        navigateToPage: _navigateToPage, userId: widget.userId,
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            title: Text(product['name'] ?? 'No name'),
            subtitle: Text('Price: ${product['price']} | Date: ${product['date']}'),
            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'Edit') {
                  _editProduct(index); // Edit the selected product
                } else if (value == 'Delete') {
                  _deleteProduct(index); // Delete the selected product
                }
              },
              itemBuilder: (context) {
                return [
                  PopupMenuItem<String>(
                    value: 'Edit',
                    child: Text('เเก้ไข'),
                  ),
                  PopupMenuItem<String>(
                    value: 'Delete',
                    child: Text('ลบรายการ'),
                  ),
                ];
              },
            ),
          );
        },
      ),
    );
  }
}
