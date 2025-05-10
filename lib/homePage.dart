import 'package:flutter/material.dart';
import 'package:real/preview.dart';
import 'package:real/recicve.dart';
import 'package:real/pay.dart';
import 'package:real/store.dart';
import 'package:real/setting.dart';
import 'menu_bar.dart';
import 'paygraph.dart';
import 'CollectionGraph.dart';
import 'Combie_Graph.dart';

class HomePage extends StatefulWidget {
  final String companyName;
  final String userId;  

  const HomePage({
    Key? key,
    required this.companyName,
    required this.userId,  
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedTabIndex = 0;
  final PageController pageController = PageController();
  String currentPage = 'ภาพรวม';
  
  final List<String> tabs = ['ยอดเก็บเงิน', 'ยอดชำระเงิน', 'สรุปภาพรวม'];

  void _navigateToPage(String pageName) {
    setState(() {
      currentPage = pageName;
    });

    if (pageName == 'ใบเสนอราคา') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewPage(
            companyName: widget.companyName, 
            userId: widget.userId
          )
        ),
      );
    } else if (pageName == 'ใบเสร็จรับเงิน') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RecicvePage(
            companyName: widget.companyName, 
            userId: widget.userId
          )
        ),
      );
    } else if (pageName == 'ค่าใช้จ่าย') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PayPage(
            companyName: widget.companyName, 
            userId: widget.userId
          )
        ),
      );
    } else if (pageName == 'สินค้า') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StorePage(
            companyName: widget.companyName, 
            userId: widget.userId
          )
        ),
      );
    } else if (pageName == 'การตั้งค่า') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SettingPage(
            companyName: widget.companyName, 
            userId: widget.userId
          ),
        ),
      );
    } else if (pageName == 'ภาพรวม') {
      setState(() {
        currentPage = 'ภาพรวม';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ภาพรวม'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      drawer: Menu_Bar(
        userId: widget.userId,
        currentPage: currentPage,
        navigateToPage: _navigateToPage,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blue,
            child: Divider(
              thickness: 1,
              color: Colors.grey[300],
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                tabs.length,
                (index) => GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTabIndex = index;
                    });
                    pageController.jumpToPage(index);
                  },
                  child: Column(
                    children: [
                      Text(
                        tabs[index],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: selectedTabIndex == index
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selectedTabIndex == index
                              ? Colors.blue
                              : Colors.black,
                        ),
                      ),
                      if (selectedTabIndex == index)
                        Container(
                          margin: EdgeInsets.only(top: 4),
                          height: 2,
                          width: 90,
                          color: Colors.blue,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: PageView(
              controller: pageController,
              onPageChanged: (index) {
                setState(() {
                  selectedTabIndex = index;
                });
              },
              physics: ClampingScrollPhysics(),
              children: [
                CollectionGraph(userId: widget.userId),
                Column(
                  children: [
                    Expanded(child: Paygraph(userId: widget.userId)),
                  ],
                ),
                Column(
                  children: [
                    Expanded(child: CombieGraph(userId: widget.userId)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
