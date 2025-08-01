import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real/homePage.dart';
import 'package:real/preview.dart';
import 'package:real/recicve.dart';     
import 'package:real/pay.dart';
import 'package:real/setting.dart';
import 'menu_bar.dart';

class StorePage extends StatefulWidget {
  final String companyName;
  final String userId;

  const StorePage({super.key, required this.companyName, required this.userId});

  @override
  _StorePageState createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  String currentPage = 'สินค้า'; // Default page to display

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();

  List<Map<String, dynamic>> products = [];

  Future<void> _fetchProducts() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentReference userDocRef = firestore
          .collection('users')
          .doc(widget.userId)
          .collection('store')
          .doc('userstore');

      QuerySnapshot snapshot = await userDocRef.collection('products').get();

      setState(() {
        products = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return {
            'name': data['name'] ?? 'No name',
            'price': data['price']?.toString() ?? '0',
            'stock': data['stock']?.toString() ?? '0',
            'id': doc.id, // Store Firestore document ID
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  void _saveProduct() async {
    if (nameController.text.isNotEmpty && priceController.text.isNotEmpty && stockController.text.isNotEmpty) {
      try {
        FirebaseFirestore firestore = FirebaseFirestore.instance;
        DocumentReference userDocRef = firestore
            .collection('users')
            .doc(widget.userId)
            .collection('store')
            .doc('userstore'); 

        CollectionReference productsCollection = userDocRef.collection('products');

        await productsCollection.add({
          'name': nameController.text,
          'price': priceController.text,
          'stock': stockController.text,
        });

        _fetchProducts();

        nameController.clear();
        priceController.clear();
        stockController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('กรุณากรอกให้ครบทุกช่อง')));
    }
  }

  void _deleteProduct(int index) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    final product = products[index];

    try {
      DocumentReference productRef = firestore
          .collection('users')
          .doc(widget.userId)
          .collection('store')
          .doc('userstore')
          .collection('products')
          .doc(product['id']); 
      await productRef.delete();

      _fetchProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')));
    }
  }

  // Function to edit a product
  void _editProduct(int index) async {
    final product = products[index];
    nameController.text = product['name']!;
    priceController.text = product['price']!;
    stockController.text = product['stock']!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('แก้ไขสินค้า'),
          content: Column(
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
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'จำนวนคงเหลือ'),
              ),
            ],
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

                DocumentReference productRef = firestore
                    .collection('users')
                    .doc(widget.userId)
                    .collection('store')
                    .doc('userstore')
                    .collection('products')
                    .doc(product['id']);

                await productRef.update({
                  'name': nameController.text,
                  'price': priceController.text,
                  'stock': stockController.text,
                });

                _fetchProducts();

                nameController.clear();
                priceController.clear();
                stockController.clear();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToPage(String pageName) {
    setState(() {
      currentPage = pageName;
    });

    if (pageName == 'ใบเสนอราคา') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PreviewPage(companyName: widget.companyName, userId: widget.userId )),
      );
    } else if (pageName == 'ค่าใช้จ่าย') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PayPage(companyName: widget.companyName, userId: widget.userId)),
      );
    } else if (pageName == 'ใบเสร็จรับเงิน') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RecicvePage(companyName: widget.companyName, userId: widget.userId)),
      );
    } else if (pageName == 'สินค้า') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => StorePage(companyName: widget.companyName, userId: widget.userId)),
      );
    } else if (pageName == 'การตั้งค่า') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SettingPage(companyName: widget.companyName, userId: widget.userId)),
      );
    } else if (pageName == 'ภาพรวม') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(companyName: widget.companyName, userId: widget.userId)),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('สินค้า'),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        backgroundColor: const Color.fromARGB(255, 140, 93, 76),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('เพิ่มสินค้า'),
                    content: Column(
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
                          controller: stockController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'จำนวนคงเหลือ'),
                        ),
                      ],
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
                        onPressed: () {
                          _saveProduct();
                          Navigator.pop(context);
                        },
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
        navigateToPage: _navigateToPage,
        userId: widget.userId,
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            title: Text(product['name'] ?? 'No name'),
            subtitle: Text('Price: ${product['price']} | Stock: ${product['stock']}'),
            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert),
              onSelected: (String value) {
                if (value == 'Edit') {
                  _editProduct(index);
                } else if (value == 'Delete') {
                  _deleteProduct(index);
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'Edit',
                    child: Text('เเก้ไข'),
                  ),
                  PopupMenuItem<String>(
                    value: 'Delete',
                    child: Text('ลบสินค้า'),
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
