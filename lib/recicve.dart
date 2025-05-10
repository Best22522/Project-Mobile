import 'package:flutter/material.dart';
import 'package:real/homePage.dart';
import 'package:real/preview.dart';
import 'package:real/pay.dart';
import 'package:real/store.dart';
import 'package:real/setting.dart';
import 'menu_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'recieve_pdf.dart';

class RecicvePage extends StatefulWidget {
  final String companyName;
  final String userId;

  const RecicvePage({super.key, required this.companyName, required this.userId});

  @override
  _RecicvePageState createState() => _RecicvePageState();
}

class _RecicvePageState extends State<RecicvePage> {
  Stream<QuerySnapshot> _fetchApprovedQuotations() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('recieve')
        .snapshots();
  }

  String currentPage = 'ใบเสร็จรับเงิน'; // Default page to display

  void _navigateToPage(String pageName) {
    setState(() {
      currentPage = pageName;
    });

    if (pageName == 'ใบเสนอราคา') {
      Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => PreviewPage(companyName: widget.companyName, userId: widget.userId)),
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

  void _deleteQuotation(String quotationId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('recieve')
        .doc(quotationId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ใบเสร็จรับเงิน'),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        backgroundColor: const Color.fromARGB(255, 22, 163, 86),
      ),
      drawer: Menu_Bar(
        currentPage: currentPage,
        navigateToPage: _navigateToPage, userId: widget.userId,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchApprovedQuotations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('ไม่มีใบเสร็จที่อนุมัติ'));
          }

          var approvedQuotations = snapshot.data!.docs;

          return ListView.builder(
            itemCount: approvedQuotations.length,
            itemBuilder: (context, index) {
              var data = approvedQuotations[index].data() as Map<String, dynamic>;
              var quotationId = approvedQuotations[index].id;

              return Container(
                margin: EdgeInsets.all(8),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1, 
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${data['quotationNumber']}'),
                              Text('ลูกค้า: ${data['customerName']}'),
                              SizedBox(height: 4),
                              Text('ยอดเงินทั้งหมด: ${data['totalAmount']} บาท', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'preview') {
                              
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PreviewDocumentPage(
                                    companyName: widget.companyName,
                                    documentNumber: data['quotationNumber'],
                                    customerName: data['customerName'],
                                    totalAmount: data['totalAmount'],
                                    notes: data['notes'] ?? '',
                                    discount: data['discount'] ?? 0,
                                    discountBaht: data['discountBaht'] ?? 0,
                                    vat: data['VAT'] ?? 0,
                                    selectedProducts: List<Map<String, dynamic>>.from(data['selectedProducts'] ?? []),
                                    isInvoice: data['isInvoice'] ?? false,
                                  ),
                                ),
                              );
                            } else if (value == 'delete') {
                              
                              _deleteQuotation(quotationId);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'preview',
                              child: Text('พรีวิวเอกสาร'),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('ลบ'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
