import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';  // Import for date formatting

class CollectionGraph extends StatefulWidget {
  final String userId;

  const CollectionGraph({Key? key, required this.userId}) : super(key: key);

  @override
  _CollectionGraphState createState() => _CollectionGraphState();
}

class _CollectionGraphState extends State<CollectionGraph> {
  int selectedMonths = 12;

  // Function to calculate the last N months
  List<int> getLastNMonths(int n) {
  DateTime now = DateTime.now();
  List<int> months = [];
  for (int i = 0; i < n; i++) {
    months.add((now.month - i - 1 + 12) % 12);  // Collect months in reverse order
  }
  return months.reversed.toList(); // Reversed to get them in chronological order
  }

  List<int> getNext3Months() {
  DateTime now = DateTime.now();
  return List.generate(3, (i) => (now.month - 1 + i) % 12);
}

  // Function to get the first N months
  List<int> getFirstNMonths(int n) {
    return List.generate(n, (index) => index);
  }

  // Function to determine whether to show the first 6 months or the last 6 months based on current month
  List<int> getMonthsToDisplay() {
    DateTime now = DateTime.now();
    int currentMonth = now.month - 1;  // Zero-based month index

    if (currentMonth < 6) {
      // If the current month is in the first 6 months, show the first 6 months
      return getFirstNMonths(6);
    } else {
      return getLastNMonths(6);
    }
  }

  // Function to get the days of the current month
  List<int> getDaysInCurrentMonth() {
    DateTime now = DateTime.now();
    int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return List.generate(daysInMonth, (index) => index + 1);
  }

Future<Map<int, double>> _fetchMonthlyCollection() async {
  final QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(widget.userId)
      .collection('recieve')
      .get();

  Map<int, double> monthlyData = {};
  double totalAmount = 0.0;

  List<int> monthsToShow;
  if (selectedMonths == 12) {
    monthsToShow = List.generate(12, (index) => index);
  } else if (selectedMonths == 6) {
    monthsToShow = getMonthsToDisplay();
  } else if (selectedMonths == 1) {
    monthsToShow = getDaysInCurrentMonth();
  } else if (selectedMonths == 3) {
    monthsToShow = getNext3Months();
  } else {
    monthsToShow = [];
  }

  for (var doc in snapshot.docs) {
    var data = doc.data() as Map<String, dynamic>;
    Timestamp timestamp = data['timestamp'];
    double amount = (data['totalAmount'] ?? 0).toDouble();

    DateTime date = timestamp.toDate();
    int monthIndex = date.month - 1;  // Get the month index
    int day = date.day;  // Get the day
    String year = DateFormat('yyyy').format(date);  // Year

    // Check if the data belongs to the selected months
    if (selectedMonths == 12 && year == DateFormat('yyyy').format(DateTime.now())) {
      monthlyData[monthIndex] = (monthlyData[monthIndex] ?? 0) + amount;
      totalAmount += amount;
    } else if (selectedMonths == 1 &&
    date.month == DateTime.now().month &&
    date.year == DateTime.now().year) {
  int dayOfMonth = date.day;
  monthlyData[dayOfMonth] = (monthlyData[dayOfMonth] ?? 0) + amount;
  totalAmount += amount;
    } else if (monthsToShow.contains(monthIndex)) {
      monthlyData[monthIndex] = (monthlyData[monthIndex] ?? 0) + amount;
      totalAmount += amount;
    }
  }

  // If 12 months are selected, ensure that all months are represented (Jan-Dec)
  if (selectedMonths == 12) {
    Map<int, double> sortedMonthlyData = {};
    for (int i = 0; i < 12; i++) {
      sortedMonthlyData[i] = monthlyData[i] ?? 0.0;  // Ensure every month has a value
    }
    monthlyData = sortedMonthlyData;
  } else if (selectedMonths == 1) {
    int daysInMonth = DateTime.now().day;
    int totalDays = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
    Map<int, double> sortedDailyData = {};
    for (int i = 1; i <= totalDays; i++) {
      sortedDailyData[i] = monthlyData[i] ?? 0.0;
    }
    monthlyData = sortedDailyData;
  }

  monthlyData = Map.fromEntries(monthlyData.entries.where((entry) => entry.value > 0));

  return monthlyData;
}


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          height: 70,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [12, 6, 3, 1].map((month) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedMonths == month ? Colors.blue : Colors.grey[300],
                      foregroundColor: selectedMonths == month ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        selectedMonths = month;
                      });
                    },
                    child: Text(
                      "$month เดือน",
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        Expanded(
          child: FutureBuilder<Map<int, double>>(
            future: _fetchMonthlyCollection(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text("ไม่มีข้อมูล", style: TextStyle(fontSize: 12)));
              }

              final data = snapshot.data!;

              final monthNames = [
                "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
              ];

              List<int> monthsToDisplay;
if (selectedMonths == 12) {
  monthsToDisplay = List.generate(12, (index) => index);
} else if (selectedMonths == 6) {
  monthsToDisplay = getMonthsToDisplay();
} else if (selectedMonths == 3) {
  monthsToDisplay = getNext3Months();
} else {
  monthsToDisplay = getDaysInCurrentMonth();
}


              final sortedData = monthsToDisplay.map((index) {
  final label = selectedMonths == 1
    ? "$index"
    : monthNames[index.clamp(0, 11)];

  final value = data[index] ?? 0.0;
  return BarChartGroupData(
    x: index,
    barRods: [
      BarChartRodData(toY: value, color: Colors.blue),
    ],
  );
}).toList();

              final totalAmount = monthsToDisplay.fold<double>(
  0.0,
  (sum, index) => sum + (data[index] ?? 0.0),
);


              return Column(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: 250,
                      child: BarChart(
                        BarChartData(
                          barGroups: sortedData,
                          gridData: FlGridData(
                            drawVerticalLine: false,
                            drawHorizontalLine: true,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey.shade400,
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          titlesData: FlTitlesData(
  leftTitles: AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      reservedSize: 40,
      getTitlesWidget: (double value, TitleMeta meta) {
        return Text(value.toInt().toString(),
            style: TextStyle(fontSize: 8));
      },
    ),
  ),
  bottomTitles: AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      getTitlesWidget: (double value, TitleMeta meta) {
        double fontSize = selectedMonths == 1 ? 5 : 10;
        return Text(
  selectedMonths == 1
      ? value.toInt().toString()
      : monthNames[value.toInt().clamp(0, 11)],
  style: TextStyle(fontSize: fontSize),
);
      },
    ),
  ),
  rightTitles: AxisTitles(
    sideTitles: SideTitles(showTitles: false),
  ),
  topTitles: AxisTitles(
    sideTitles: SideTitles(showTitles: false),
  ),
),

                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      children: [
                        Text(
                          "รายได้รวม: ${totalAmount.toStringAsFixed(2)} บาท",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}