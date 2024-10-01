import 'package:flutter/material.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color.fromARGB(255, 243, 152, 33),
                    width: 2.0,
                  ),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: const AssetImage('assets/pp.png'),
                  backgroundColor:
                      Colors.grey[200], // can change bg color for profile
                ),
              ),
            ),
          ),

          const Center(
            child: Padding(
              padding: EdgeInsets.only(
                  left: 16.0,
                  bottom: 50.0), // Added bottom padding to create space
              child: Text(
                'Joven Carl Rex Biaca',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const Divider(thickness: 1, indent: 40, endIndent: 40), // divider

          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: DataTable(
                columnSpacing: 16,
                columns: [
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
                    DataCell(Icon(Icons.email)),
                    DataCell(Text('Email')),
                    DataCell(Text('jovskbiaca@example.com')),
                  ]),
                  DataRow(cells: [
                    DataCell(Icon(Icons.call)),
                    DataCell(Text('Contact Number')),
                    DataCell(Text('+123456789')),
                  ]),
                  DataRow(cells: [
                    DataCell(Icon(Icons.home)),
                    DataCell(Text('Address')),
                    DataCell(Text('Taga Sooc, Iloilo City')),
                  ]),
                  DataRow(cells: [
                    DataCell(Icon(Icons.work)),
                    DataCell(Text('Occupation')),
                    DataCell(Text('Computer Science Student')),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('')),
                    DataCell(Text('')),
                    DataCell(Text('')),
                  ]),
                ],
              ),
            ),
          ),

          const Divider(thickness: 1, indent: 40, endIndent: 40),
        ],
      ),
    );
  }
}
