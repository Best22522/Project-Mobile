import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

class PreviewDocumentPage extends StatelessWidget {
  final String companyName;
  final String documentNumber;
  final String customerName;
  final double totalAmount;
  final String notes;
  final double discount;
  final double discountBaht;
  final double vat;
  final List<Map<String, dynamic>> selectedProducts;
  final bool isInvoice; 

  const PreviewDocumentPage({
    Key? key,
    required this.companyName,
    required this.documentNumber,
    required this.customerName,
    required this.totalAmount,
    required this.notes,
    required this.discount,
    required this.discountBaht,
    required this.selectedProducts,
    required this.vat,
    required this.isInvoice,
  }) : super(key: key);

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    final font = await rootBundle.load("assets/fonts/Sarabun-Regular.ttf");
    final ttf = pw.Font.ttf(font);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(companyName,
                        style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            font: ttf)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(isInvoice ? "ใบเสร็จรับเงิน" : "ใบเสร็จรับเงิน",
                        style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green,
                            font: ttf)),
                    pw.SizedBox(height: 5),
                    pw.Text("เลขที่: $documentNumber",
                        style: pw.TextStyle(font: ttf)),
                    pw.Text("${DateTime.now()}",
                        style: pw.TextStyle(font: ttf)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Text("ลูกค้า: $customerName", style: pw.TextStyle(font: ttf)),
            pw.Divider(),

            // Product Table
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: pw.FlexColumnWidth(1),
                1: pw.FlexColumnWidth(3),
                2: pw.FlexColumnWidth(1),
                3: pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text("ลำดับ",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, font: ttf))),
                    pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text("รายละเอียด",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, font: ttf))),
                    pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text("จำนวน",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, font: ttf))),
                    pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text("ราคาต่อหน่วย",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, font: ttf))),
                  ],
                ),
                ...selectedProducts.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final product = entry.value;
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text("$index", style: pw.TextStyle(font: ttf))),
                      pw.Padding(
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text(product['name'] ?? '',
                              style: pw.TextStyle(font: ttf))),
                      pw.Padding(
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text("${product['quantity']}",
                              style: pw.TextStyle(font: ttf))),
                      pw.Padding(
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text("฿${product['price']}",
                              style: pw.TextStyle(font: ttf))),
                    ],
                  );
                }).toList(),
              ],
            ),

            pw.SizedBox(height: 345),
            // Discount Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text("ส่วนลด (%): ${discount.toStringAsFixed(2)}%",
                    style: pw.TextStyle(font: ttf)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text("ส่วนลด (บาท): ฿${discountBaht.toStringAsFixed(2)}",
                    style: pw.TextStyle(font: ttf)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text("ภาษีมูลค่าเพิ่ม (%): ${vat.toStringAsFixed(2)}%",
                    style: pw.TextStyle(font: ttf)),
              ],
            ),
            pw.SizedBox(height: 10),
            
            // Total Amount
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text("รวมเป็นเงิน: ฿${totalAmount.toStringAsFixed(2)}",
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green,
                        font: ttf)),
              ],
            ),

            pw.SizedBox(height: 10),

            // Notes Section
            pw.Text("หมายเหตุ: $notes", style: pw.TextStyle(font: ttf)),
            pw.SizedBox(height: 20),
            pw.Divider(),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Text("ลงชื่อ ลูกค้า", style: pw.TextStyle(font: ttf)),
                    pw.SizedBox(height: 30),
                    pw.Container(
                      width: 150,
                      height: 1,
                      color: PdfColors.black,
                    ),
                    pw.SizedBox(height: 15),
                    pw.Text("(………………………………)", style: pw.TextStyle(font: ttf)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text("ลงชื่อ ผู้ขาย", style: pw.TextStyle(font: ttf)),
                    pw.SizedBox(height: 30),
                    pw.Container(
                      width: 150,
                      height: 1,
                      color: PdfColors.black,
                    ),
                    pw.SizedBox(height: 15),
                    pw.Text("(………………………………)", style: pw.TextStyle(font: ttf)),
                  ],
                ),
              ],
            ),

          ],
        ),
      ),
    );
    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isInvoice ? "ใบเสร็จรับเงิน" : "ใบเสร็จรับเงิน"),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () async {

              final pdfBytes = await _generatePdf();

              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: "$documentNumber-$customerName.pdf",
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        useActions: true,
        canChangePageFormat: false,
        build: (format) => _generatePdf(),
      ),
    );
  }
}
