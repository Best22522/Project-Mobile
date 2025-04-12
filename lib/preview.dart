import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:real/homePage.dart';
import 'package:real/recicve.dart';
import 'package:real/pay.dart';
import 'package:real/store.dart';
import 'package:real/setting.dart';
import 'menu_bar.dart'; // Import Menu_Bar widget
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
        companyName: widget.companyName, // Pass companyName
      );
    },
  );
}

  void _editQuotation(QueryDocumentSnapshot quotation) {
  // You can navigate to an editing screen or show a modal with the form pre-filled with the quotation data
  print('Editing QT: ${quotation['quotationNumber']}');
  
  // Pass the discount field along with other fields
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return _QuotationForm(
        userId: widget.userId,
        quotation: quotation,  // Pass the quotation data to the form for editing
        discountBaht: quotation['discountBaht'] ?? 0.00,  // Pass the discount value in Baht
        discount: quotation['discount'] ?? 0.00,  // Pass the discount value
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
              String status = "รออนุมัติ"; // Add your status logic here

              return Container(
  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8), // Adds spacing around each item
  decoration: BoxDecoration(
    border: Border.all(color: Colors.grey, width: 1), // Adds border
    borderRadius: BorderRadius.circular(8), // Rounded corners
    color: Colors.white, // Background color
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 4,
        offset: Offset(2, 2), // Adds slight shadow effect
      ),
    ],
  ),
  child: ListTile(
    contentPadding: EdgeInsets.all(8), // Adds padding inside the box
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$quotationNumber',  // QT is above
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          '$customerName',  // Name below QT
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
              _editQuotation(quotation);  // Add edit functionality
            } else if (value == 'delete') {
              _deleteQuotation(quotation.id);  // Add delete functionality
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
      // You can add functionality to preview or edit the quotation
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
  final double discount;  // Add the discount field here
  final double discountBaht; // Add the discount in Baht field here
  final String companyName;
  

  const _QuotationForm({
    Key? key,
    required this.userId,
    this.quotation,
    required this.discount, 
    required this.discountBaht,  // Include discount in the constructor
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

  double totalAmount = 0.00;
  double discount = 0.00;  // This will hold the discount value
  String quotationNumber = "";
  double discountBaht = 0.00; // Total amount in Baht
  String _status = 'รออนุมัติ'; // Default status


  List<Map<String, dynamic>> selectedProducts = []; // List of selected products

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
      discountBaht = widget.quotation!['discountBaht'] ?? 0.00; // Initialize the discount in Baht
      _discountBahtController.text = discountBaht.toStringAsFixed(2); // Pre-fill the discount in Baht input field
      // Initialize the discount controller with the passed discount value
      discount = widget.discount;
      _discountController.text = discount.toStringAsFixed(2);  // Pre-fill the discount input field
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

    // Query to get the most recent quotation for today
    var querySnapshot = await collectionRef
        .where('quotationNumber', isGreaterThanOrEqualTo: 'QT$formattedDate' + '0001')
        .where('quotationNumber', isLessThanOrEqualTo: 'QT$formattedDate' + '9999')
        .orderBy('quotationNumber', descending: true)
        .limit(1)
        .get();

    int nextNumber = 1;  // Default to 0001 if no quotations for today

    // If there are quotations for today, we increment the last number
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

  print("Selected Product from Modal: $selectedProduct"); // Debugging

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

      // Handling the stock and decrementing it after product selection
      int currentStock = int.tryParse(product['stock'].toString()) ?? 0; // Convert stock from string to int
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
  // Check if any products are selected
  if (selectedProducts.isNotEmpty) {
    final lastSelectedProduct = selectedProducts.last;

    // Make sure 'originalStock' is available before proceeding
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

  Navigator.pop(context); // Close the modal
}

  void _calculateTotal() {
    setState(() {
      discount = double.tryParse(_discountController.text) ?? 0.00;
      totalAmount = selectedProducts.fold(0.0, (sum, product) {
        return sum + (double.tryParse(product['amount'].toString()) ?? 0.00);
      });
      totalAmount = totalAmount - (totalAmount * discount / 100);
    });
  }

void _calculateTotalbaht(){
  setState(() {
    discountBaht = double.tryParse(_discountBahtController.text) ?? 0.00; // Store discountBaht correctly
    totalAmount = selectedProducts.fold(0.0, (sum, product) {
      return sum + (double.tryParse(product['amount'].toString()) ?? 0.00);
    });
    totalAmount = totalAmount - discountBaht;
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
        'discountBaht': discountBaht, // Ensure this is updated before saving
        'totalAmount': totalAmount,
        'notes': _notesController.text,
        'selectedProducts': selectedProducts,  // Save the selected products list
        'timestamp': FieldValue.serverTimestamp(),
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
        companyName: widget.companyName, // Pass companyName
        quotationNumber: quotationNumber,
        customerName: _customerNameController.text,
        totalAmount: totalAmount,
        selectedProducts: selectedProducts, // Pass the list of selected products
        notes: _notesController.text, // Pass notes
        discount: discount, // Pass the discount value
        discountBaht: discountBaht, // Pass the discount in Baht value
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
      Navigator.pop(context); // Close the form when status is "อนุมัติ"
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
        int currentStock = int.tryParse(product['stock'].toString()) ?? 0; // Get current stock
        int originalStock = int.tryParse(product['originalStock'].toString()) ?? 0; // Get original stock

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
          .update({'stock': updatedStock.toString()}) // Update stock in Firestore
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
              onChanged: (value) => _calculateTotalbaht(),
            ),
            Divider(),
            TextField(
              controller: _discountController,
              decoration: InputDecoration(labelText: "ส่วนลด (%)", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (value) => _calculateTotal(),
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
