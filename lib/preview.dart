import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:real/homePage.dart';
import 'package:real/recicve.dart';
import 'package:real/pay.dart';
import 'package:real/store.dart';
import 'package:real/setting.dart';
import 'menu_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ProductSelect.dart';
import 'preview_pdf.dart';

class PreviewPage extends StatefulWidget {
  final String companyName;
  final String userId;

  const PreviewPage({
    Key? key,
    required this.companyName,
    required this.userId,
  }) : super(key: key);

  @override
  _PreviewPageState createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  String currentPage = 'ใบเสนอราคา'; // Default page to display
  late Stream<QuerySnapshot> _quotationStream;

  @override
  void initState() {
    super.initState();
    // Initialize the stream to fetch quotations data
    _quotationStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('preview')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
  void _navigateToPage(String pageName) {
    setState(() {
      currentPage = pageName;
    });

    Widget page;
    switch (pageName) {
      case 'ค่าใช้จ่าย':
        page = PayPage(companyName: widget.companyName, userId: widget.userId);
        break;
      case 'ใบเสร็จรับเงิน':
        page = RecicvePage(companyName: widget.companyName, userId: widget.userId);
        break;
      case 'สินค้า':
        page = StorePage(companyName: widget.companyName, userId: widget.userId);
        break;
      case 'การตั้งค่า':
        page = SettingPage(companyName: widget.companyName, userId: widget.userId);
        break;
      case 'ภาพรวม':
        page = HomePage(companyName: widget.companyName, userId: widget.userId);
        break;
      default:
        page = PreviewPage(companyName: widget.companyName, userId: widget.userId);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _onAddIconPressed() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return _QuotationForm(
        userId: widget.userId,
        discount: 0.00,
        discountBaht: 0.00,
        vat: 0.00,
        companyName: widget.companyName, // Pass companyName
      );
    },
  );
}

  void _editQuotation(QueryDocumentSnapshot quotation) {
  print('Editing QT: ${quotation['quotationNumber']}');
  
  // Pass the discount field along with other fields
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return _QuotationForm(
        userId: widget.userId,
        quotation: quotation, 
        discountBaht: quotation['discountBaht'] ?? 0.00, 
        discount: quotation['discount'] ?? 0.00, 
        vat: quotation['VAT'] ?? 0.00, 
        companyName: widget.companyName,
      );
    },
  );
}

void _deleteQuotation(String quotationId) async {
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('preview')
        .doc(quotationId)
        .delete();

    print("Quotation deleted successfully!");
  } catch (e) {
    print("Error deleting quotation: $e");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ใบเสนอราคา'),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: _onAddIconPressed,
          ),
        ],
      ),
      drawer: Menu_Bar(
        currentPage: currentPage,
        navigateToPage: _navigateToPage,
        userId: widget.userId,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _quotationStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final quotations = snapshot.data!.docs;

          if (quotations.isEmpty) {
            return Center(child: Text('No quotations available.'));
          }

          return ListView.builder(
            itemCount: quotations.length,
            itemBuilder: (context, index) {
              var quotation = quotations[index];
              String quotationNumber = quotation['quotationNumber'];
              String customerName = quotation['customerName'];
              double totalAmount = quotation['totalAmount'];
              String status = "รออนุมัติ";

              return Container(
  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8), 
  decoration: BoxDecoration(
    border: Border.all(color: Colors.grey, width: 1), 
    borderRadius: BorderRadius.circular(8),
    color: Colors.white, 
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 4,
        offset: Offset(2, 2), 
      ),
    ],
  ),
  child: ListTile(
    contentPadding: EdgeInsets.all(8),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$quotationNumber', 
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          '$customerName',  
          style: TextStyle(color: const Color.fromARGB(255, 18, 18, 18)),
        ),
      ],
    ),
    subtitle: Text('ยอดเงินทั้งหมด: ฿${totalAmount.toStringAsFixed(2)}'),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(status, style: TextStyle(color: Colors.blue)),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.blue),
          onSelected: (String value) {
            if (value == 'edit') {
              _editQuotation(quotation); 
            } else if (value == 'delete') {
              _deleteQuotation(quotation.id); 
            }
          },
          itemBuilder: (BuildContext context) {
            return ['edit', 'delete']
                .map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(choice == 'edit' ? 'Edit' : 'Delete'),
              );
            }).toList();
          },
        ),
      ],
    ),
    onTap: () {
      print('Previewing QT: $quotationNumber');
    },
  ),
);

            },
          );
        },
      ),
    );
  }
}

class _QuotationForm extends StatefulWidget {
  final String userId;
  final QueryDocumentSnapshot? quotation;
  final double discount;
  final double discountBaht; 
  final String companyName;
  final double vat; 
  

  const _QuotationForm({
    Key? key,
    required this.userId,
    this.quotation,
    required this.discount, 
    required this.discountBaht,
    required this.vat,
    required this.companyName,
  }) : super(key: key);

  @override
  _QuotationFormState createState() => _QuotationFormState();
}

class _QuotationFormState extends State<_QuotationForm> {
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _discountBahtController = TextEditingController();
  final TextEditingController _vatController = TextEditingController();

  double totalAmount = 0.00;
  double discount = 0.00;
  String quotationNumber = "";
  double discountBaht = 0.00;
  String _status = 'รออนุมัติ';
  double vat = 0.00;


  List<Map<String, dynamic>> selectedProducts = [];

  @override
  void initState() {
    super.initState();
    if (widget.quotation != null) {
      _customerNameController.text = widget.quotation!['customerName'] ?? '';
      _notesController.text = widget.quotation!['notes'] ?? '';
      quotationNumber = widget.quotation!['quotationNumber'] ?? '';
      totalAmount = widget.quotation!['totalAmount'] ?? 0.00;
      selectedProducts = widget.quotation!['selectedProducts'] is List
          ? List<Map<String, dynamic>>.from(widget.quotation!['selectedProducts'])
          : [];
      discountBaht = widget.quotation!['discountBaht'] ?? 0.00;
      _discountBahtController.text = discountBaht.toStringAsFixed(2);

      discount = widget.discount;
      _discountController.text = discount.toStringAsFixed(2);
      vat = widget.vat;
      _vatController.text = vat.toStringAsFixed(2);
    } else {
      _generateQuotationNumber().then((value) {
        setState(() {
          quotationNumber = value;
        });
      });
    }
  }

  Future<String> _generateQuotationNumber() async {
    final now = DateTime.now();
    final formattedDate = DateFormat('yyMMdd').format(now);

    var collectionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('preview');

    var querySnapshot = await collectionRef
        .where('quotationNumber', isGreaterThanOrEqualTo: 'QT$formattedDate' + '0001')
        .where('quotationNumber', isLessThanOrEqualTo: 'QT$formattedDate' + '9999')
        .orderBy('quotationNumber', descending: true)
        .limit(1)
        .get();

    int nextNumber = 1;

    if (querySnapshot.docs.isNotEmpty) {
      String lastQuotation = querySnapshot.docs.first['quotationNumber'];
      int lastNumber = int.parse(lastQuotation.substring(8, 12));  // Get the last number (after 'QTyyMMdd')
      nextNumber = lastNumber + 1;
    }

    String formattedNumber = nextNumber.toString().padLeft(4, '0');  // Ensure it's 4 digits
    return 'QT$formattedDate$formattedNumber';  // Return formatted quotation number
  }

  void _selectProduct() async {
  final selectedProduct = await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return ProductSelectionModal(userId: widget.userId);
    },
  );

  print("Selected Product from Modal: $selectedProduct");

  if (selectedProduct != null && selectedProduct.containsKey('product')) {
    final product = selectedProduct['product'];

    if (product != null) {
      setState(() {
        double price = double.tryParse(product['price'].toString()) ?? 0.00;
        selectedProducts.add({
          'name': product['name'] ?? 'Unnamed Product',
          'price': price,
          'quantity': 1,
          'amount': price,
          'originalStock': product['stock'], // Save original stock value
        });
        totalAmount += price; // Update total amount
      });

      int currentStock = int.tryParse(product['stock'].toString()) ?? 0;
      if (currentStock > 0) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('store')
            .doc('userstore')
            .collection('products')
            .doc(product['id'])
            .update({'stock': (currentStock - 1).toString()}); // Update stock, storing as string
      }
    }
  } else {
    print("Error: selectedProduct is null or missing data.");
  }
}

void _onCancel() {
  if (selectedProducts.isNotEmpty) {
    final lastSelectedProduct = selectedProducts.last;

    if (lastSelectedProduct != null && lastSelectedProduct.containsKey('originalStock')) {
      final productId = lastSelectedProduct['id'];
      final originalStock = int.tryParse(lastSelectedProduct['originalStock'].toString()) ?? 0;

      print("Reverting stock for product ID: $productId");
      print("Original stock: $originalStock");

      // Revert the stock by increasing it by 1
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('store')
          .doc('userstore')
          .collection('products')
          .doc(productId)
          .update({'stock': originalStock.toString()}) // Revert to original stock
          .then((_) {
            print("Stock reverted for product ${lastSelectedProduct['name']}, new stock: $originalStock");
          })
          .catchError((error) {
            print("Error updating stock: $error");
          });

      // Remove the last selected product from the list
      setState(() {
        selectedProducts.removeLast();
      });
    }
  }

  Navigator.pop(context);
}

  void _recalculateTotal() {
  setState(() {
    // Parse values from controllers
    discount = double.tryParse(_discountController.text) ?? 0.00;
    discountBaht = double.tryParse(_discountBahtController.text) ?? 0.00;
    vat = double.tryParse(_vatController.text) ?? 0.00;

    // Calculate subtotal
    double subtotal = selectedProducts.fold(0.0, (sum, product) {
      return sum + (double.tryParse(product['amount'].toString()) ?? 0.00);
    });

    // Apply discounts
    double percentDiscountAmount = subtotal * discount / 100;
    double afterDiscounts = subtotal - percentDiscountAmount - discountBaht;

    // Apply VAT
    totalAmount = afterDiscounts + (afterDiscounts * vat / 100);
  });
}

  void _onSubmit() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('preview')
          .doc(quotationNumber)
          .set({
        'quotationNumber': quotationNumber,
        'customerName': _customerNameController.text,
        'discount': discount,
        'discountBaht': discountBaht,
        'totalAmount': totalAmount,
        'notes': _notesController.text,
        'selectedProducts': selectedProducts,
        'timestamp': FieldValue.serverTimestamp(),
        'VAT': vat,
      });

      print("Quotation saved successfully!");
      Navigator.pop(context);
    } catch (e) {
      print("Error saving quotation: $e");
    }
  }

  void _previewDocument() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PreviewQuotationPage(
        companyName: widget.companyName,
        quotationNumber: quotationNumber,
        customerName: _customerNameController.text,
        totalAmount: totalAmount,
        selectedProducts: selectedProducts,
        notes: _notesController.text,
        discount: discount,
        discountBaht: discountBaht,
        vat:vat,
      ),
    ),
  );
}

void _approveQuotation(String quotationId, Map<String, dynamic> quotationData) {
  // Update status in Preview collection
  FirebaseFirestore.instance
      .collection('users')
      .doc(widget.userId)
      .collection('preview')
      .doc(quotationId)
      .update({'status': 'อนุมัติ'}); 

  // Move approved quotation to RecicvePage collection
  FirebaseFirestore.instance
      .collection('users')
      .doc(widget.userId)
      .collection('recieve') // Store approved quotations
      .doc(quotationId)
      .set(quotationData)
      .then((_) {
  FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('preview')
            .doc(quotationId)
            .delete();
        print("DELETE");
    });
}

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            Text(
              "ใบเสนอราคา",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text("สถานะ", style: TextStyle(fontSize: 16)),
    Text("   "),
    DropdownButton<String>(
  value: _status,
  items: ['รออนุมัติ', 'อนุมัติ'].map((String value) {
    return DropdownMenuItem<String>(
      value: value,
      child: Text(value),
    );
  }).toList(),
  onChanged: (newValue) {
    setState(() {
      _status = newValue!;
    });

    if (_status == 'อนุมัติ') {
      // Automatically close the form when status is changed to "อนุมัติ"
      _approveQuotation(widget.quotation!.id, widget.quotation!.data() as Map<String, dynamic>);
      Navigator.pop(context);
    }
  },
),
  ],
),
              ],
            ),
            Divider(),
            TextField(
              controller: _customerNameController,
              decoration: InputDecoration(labelText: "ชื่อลูกค้า", border: OutlineInputBorder()),
            ),
            Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: selectedProducts.length,
              itemBuilder: (context, index) {
                final product = selectedProducts[index];
                return ListTile(
  leading: Icon(Icons.inventory, color: Colors.blue),
  title: Text(product['name'] ?? 'Unnamed Product'),
  subtitle: Text("Price: ฿${product['price']}"),
  trailing: IconButton(
    icon: Icon(Icons.remove_circle, color: Colors.red),
    onPressed: () {
      setState(() {
        // Revert stock in Firestore before removing from selectedProducts
        int currentStock = int.tryParse(product['stock'].toString()) ?? 0;
        int originalStock = int.tryParse(product['originalStock'].toString()) ?? 0;

        // Revert stock: Increase it by 1
        int updatedStock = originalStock + 1;

        // Update the product's stock in Firestore
        FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('store')
          .doc('userstore')
          .collection('products')
          .doc(product['id'])
          .update({'stock': updatedStock.toString()})
          .then((_) {
            print("Stock updated for product ${product['name']}, new stock: $updatedStock");
          })
          .catchError((error) {
            print("Error updating stock: $error");
          });

        // Recalculate total amount
        totalAmount -= double.tryParse(product['price'].toString()) ?? 0.00;

        // Remove the selected product from the list
        selectedProducts.removeAt(index); 
      });
    },
  ),
);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.inventory, color: Colors.blue),
              title: Text("เลือกคลังสินค้า"),
              onTap: _selectProduct,
            ),
            Divider(),
            TextField(
              controller: _discountBahtController,
              decoration: InputDecoration(labelText: "ส่วนลด (บาท)", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (value) => _recalculateTotal(),
            ),
            Divider(),
            TextField(
              controller: _discountController,
              decoration: InputDecoration(labelText: "ส่วนลด (%)", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (value) => _recalculateTotal(),
            ),
            Divider(),
            TextField(
              controller: _vatController,
              decoration: InputDecoration(labelText: "ภาษีมูลค่าเพิ่ม (%)", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (value) => _recalculateTotal(),
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("จำนวนเงินหลังหักส่วนลด"),
                Text(totalAmount.toStringAsFixed(2)),
              ],
            ),
            Divider(),
            TextField(controller: _notesController, decoration: InputDecoration(labelText: "หมายเหตุ")),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(onPressed: _previewDocument, child: Text("พรีวิวเอกสาร")),
                Row(
                  children: [
                    TextButton(onPressed: _onCancel, child: Text("ยกเลิก", style: TextStyle(color: Colors.red))),
                    ElevatedButton(onPressed: _onSubmit, child: Text("บันทึก")),
                  ],
                ),
              ],
            ),
            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
