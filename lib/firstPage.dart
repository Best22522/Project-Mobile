import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'homePage.dart';

class FirstPage extends StatefulWidget {
  final String userId;

  const FirstPage({super.key, required this.userId});

  @override
  _FirstPageState createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  // User Inputs
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _businessPhoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _taxIdController = TextEditingController();

  // Selection
  String _selectedRole = '';
  String _selectedBusinessType = '';
  String _selectedVAT = '';

  final Map<String, String> businessTypeInfo = {
    'นิติบุคคล': 'ธุรกิจที่เกิดจากการรวมกลุ่ม เเละจดทะเบียนตามกฎหมาย',
    'บุคคลธรรมดา': 'ธุรกิจที่เกิดจากบุคคลเพียงคนเดียว เเละไม่จดทะเบียนตามกฎหมาย',
  };

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('information')
        .doc('business')
        .get();

    if (userDoc.exists) {
      var data = userDoc.data() as Map<String, dynamic>;

      _nameController.text = data['name'] ?? '';
      _surnameController.text = data['surname'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _companyNameController.text = data['companyName'] ?? '';
      _businessPhoneController.text = data['businessPhone'] ?? '';
      _addressController.text = data['address'] ?? '';
      _taxIdController.text = data['taxId'] ?? '';
      _selectedRole = data['role'] ?? '';
      _selectedBusinessType = data['businessType'] ?? '';
      //_selectedVAT = data['VAT'] ?? '';

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('ข้อมูลผู้สมัครใช้งาน'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  SizedBox(height: 8),
                  Text(
                    'HIGHLIGHT',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            _buildSectionTitle(Icons.person, 'ข้อมูลผู้สมัครใช้งาน'),
            buildTextField('ชื่อ', _nameController),
            buildTextField('นามสกุล', _surnameController),
            buildTextField('เบอร์ติดต่อของผู้สมัครใช้งาน', _phoneController),

            SizedBox(height: 16),

            _buildSectionTitle(Icons.person, 'ตำเเหน่งของผู้สมัครใช้งาน'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildOutlinedButton('เจ้าของ'),
                buildOutlinedButton('นักบัญชี'),
                buildOutlinedButton('พนักงาน'),
              ],
            ),

            SizedBox(height: 24),

            _buildSectionTitle(Icons.insert_chart, 'เลือกประเภทธุรกิจ'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildBusinessTypeBox('นิติบุคคล'),
                buildBusinessTypeBox('บุคคลธรรมดา'),
              ],
            ),
            SizedBox(height: 16),
            if (_selectedBusinessType.isNotEmpty)
              _buildInfoBox(businessTypeInfo[_selectedBusinessType]!),

            SizedBox(height: 24),

            _buildSectionTitle(Icons.topic, 'ข้อมูลธุรกิจ'),
            buildTextField('ชื่อธุรกิจ', _companyNameController),
            buildTextField('เบอร์ติดต่อธุรกิจ(Optional)', _businessPhoneController),
            buildTextField('ที่อยู่ธุรกิจ', _addressController),
            buildTextField('เลขประจำตัวบัตรประชาชน/ผู้เสียภาษี', _taxIdController),

            SizedBox(height: 24),

            // VAT Selection
            //_buildSectionTitle(Icons.add_card, 'จดภาษีมูลค่าเพิ่มหรือไม่'),
            //Row(
              //mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //children: [
                //buildVATButton('จดภาษีมูลค่าเพิ่ม'),
                //buildVATButton('ไม่จดภาษีมูลค่าเพิ่ม'),
              //],
            //),

            SizedBox(height: 24),

            Center(
              child: ElevatedButton(
                onPressed: _saveDataToFirestore,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: const Color.fromARGB(255, 180, 176, 255),
                ),
                child: Text('ตกลง'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveDataToFirestore() {
  String userId = widget.userId;
  DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);

  userDocRef.collection('information').doc('business').set({
    'name': _nameController.text,
    'surname': _surnameController.text,
    'phone': _phoneController.text,
    'role': _selectedRole,
    'businessType': _selectedBusinessType,
    'companyName': _companyNameController.text,
    'businessPhone': _businessPhoneController.text,
    'address': _addressController.text,
    'taxId': _taxIdController.text,
    //'VAT': _selectedVAT,
  }).then((value) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(
          companyName: _companyNameController.text,
          userId: widget.userId,
        ),
      ),
    );
  }).catchError((error) {
    print("Failed to add information: $error");
  });
}

  Widget buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget buildOutlinedButton(String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: OutlinedButton(
          onPressed: () {
            setState(() {
              _selectedRole = label;
            });
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: _selectedRole == label ? Colors.blue : Colors.grey,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }

  Widget buildVATButton(String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: OutlinedButton(
          onPressed: () {
            setState(() {
              _selectedVAT = label;
            });
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: _selectedVAT == label ? Colors.blue : Colors.grey,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }

  Widget buildBusinessTypeBox(String type) {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _selectedBusinessType = type; // Update
          });
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: _selectedBusinessType == type ? Colors.blue : Colors.grey,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: Text(type),
      ),
    ),
  );
}



  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInfoBox(String text) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 16, color: Colors.blue.shade800),
      ),
    );
  }
}
