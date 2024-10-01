import 'package:flutter/material.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final double finalHeight;
    final double finalWidth;

    if (screenHeight < screenWidth) {
      finalHeight = screenHeight;
      finalWidth = screenWidth;
    } else {
      finalHeight = screenWidth;
      finalWidth = screenHeight;
    }

    final double profileImageRadius =
        finalHeight * 0.1; // 10% of the smaller side for profile image
    final double fontSize =
        finalHeight * 0.03; // 3% of the smaller side for font size
    final double iconSize =
        finalHeight * 0.04; // 4% of the smaller side for icons
    final double paddingHorizontal =
        finalWidth * 0.04; // Padding relative to screen width

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: const Color.fromARGB(255, 199, 108, 4),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.all(finalHeight * 0.02),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color.fromARGB(255, 243, 152, 33),
                    width: 2.0,
                  ),
                ),
                child: CircleAvatar(
                  radius: profileImageRadius,
                  backgroundImage: const AssetImage('assets/pp.png'),
                  backgroundColor:
                      Colors.grey[200], // can change bg color for profile
                ),
              ),
            ),
          ),

          Center(
            child: Padding(
              padding: EdgeInsets.only(
                  left: paddingHorizontal,
                  bottom: finalHeight *
                      0.05), // Added bottom padding to create space
              child: Text(
                'Joven Carl Rex Biaca',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Divider(
              thickness: 1,
              indent: finalWidth * 0.1,
              endIndent: finalWidth * 0.1), // divider

          Center(
            child: Padding(
              padding: EdgeInsets.only(
                  left: paddingHorizontal, bottom: finalHeight * 0.01),
              child: DataTable(
                columnSpacing: finalWidth * 0.05,
                columns: const [
                  DataColumn(
                    label:
                        Text('', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  DataColumn(
                    label:
                        Text('', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  DataColumn(
                    label:
                        Text('', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
                rows: [
                  DataRow(cells: [
                    DataCell(Icon(Icons.email, size: iconSize)),
                    DataCell(
                        Text('Email', style: TextStyle(fontSize: fontSize))),
                    DataCell(Text('jovskbiaca@example.com',
                        style: TextStyle(fontSize: fontSize))),
                  ]),
                  DataRow(cells: [
                    DataCell(Icon(Icons.call, size: iconSize)),
                    DataCell(Text('Contact Number',
                        style: TextStyle(fontSize: fontSize))),
                    DataCell(Text('+123456789',
                        style: TextStyle(fontSize: fontSize))),
                  ]),
                  DataRow(cells: [
                    DataCell(Icon(Icons.home, size: iconSize)),
                    DataCell(
                        Text('Address', style: TextStyle(fontSize: fontSize))),
                    DataCell(Text('Taga Sooc, Iloilo City',
                        style: TextStyle(fontSize: fontSize))),
                  ]),
                  DataRow(cells: [
                    DataCell(Icon(Icons.work, size: iconSize)),
                    DataCell(Text('Occupation',
                        style: TextStyle(fontSize: fontSize))),
                    DataCell(Text('Computer Science Student',
                        style: TextStyle(fontSize: fontSize))),
                  ]),
                  const DataRow(cells: [
                    DataCell(Text('')),
                    DataCell(Text('')),
                    DataCell(Text('')),
                  ]),
                ],
              ),
            ),
          ),

          Divider(
              thickness: 1,
              indent: finalWidth * 0.1,
              endIndent: finalWidth * 0.1),
        ],
      ),
    );
  }
}
