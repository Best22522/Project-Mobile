import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductSelectionModal extends StatefulWidget {
  final String userId;

  const ProductSelectionModal({Key? key, required this.userId}) : super(key: key);

  @override
  _ProductSelectionModalState createState() => _ProductSelectionModalState();
}

class _ProductSelectionModalState extends State<ProductSelectionModal> {
  Map<String, dynamic>? selectedProduct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      height: 450,
      child: Column(
        children: [
          Text(
            "เลือกสินค้า",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (selectedProduct != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  Text(
                    "เลือกสินค้า: ${selectedProduct!['name']}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "฿${selectedProduct!['price']}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "Stock: ${selectedProduct!['stock']}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          else
            Center(child: Text("No product selected.")),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .collection('store')
                  .doc('userstore')
                  .collection('products')
                  .where('stock', isGreaterThan: '0')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("ไม่มีสินค้าในสต็อก"));
                }

                final products = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    bool isSelected = selectedProduct?['id'] == product.id;

                    return ListTile(
                      title: Text(product['name'] ?? 'No Name'),
                      subtitle: Text("Stock: ${product['stock']}"),
                      trailing: Text("฿${product['price']}"),
                      tileColor: isSelected ? Colors.blue[100] : null,
                      onTap: () {
  final price = double.tryParse(product['price'].toString()) ?? 0.0;
  final stock = int.tryParse(product['stock'].toString()) ?? 0;

  if (product['name'] != null && price > 0 && stock > 0) {
    setState(() {
      selectedProduct = {
        'id': product.id,
        'name': product['name'],
        'price': price,
        'stock': stock,
      };
    });

    print("Selected Product: $selectedProduct");

    Navigator.pop(context, {
      'product': selectedProduct,
    });
  } else {
    print("Error: selectedProduct is null or missing data.");
  }
},
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
