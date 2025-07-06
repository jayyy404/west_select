import 'package:cc206_west_select/features/screens/listing/myShop.dart';
import 'package:flutter/material.dart';
import 'package:cc206_west_select/firebase/app_user.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.appUser,
    required this.isReadOnly,
  });

  final AppUser appUser;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: appUser.profilePictureUrl != null
                ? NetworkImage(appUser.profilePictureUrl!)
                : null,
            backgroundColor: Colors.grey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(appUser.displayName ?? "User's Name",
                  style: TextStyle(
                      fontSize: screenHeight * 0.02,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1976D2))),
              Text(appUser.email,
                  style: const TextStyle(fontSize: 14, color: Colors.grey))
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        Text(appUser.description ?? 'No description',
            style: const TextStyle(fontSize: 13, color: Colors.black87)),
        const SizedBox(height: 8),
        if (!isReadOnly)
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC67B),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(
                          color: Color(0xFFE6A954), width: 1))),
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => InventoryPage())),
              icon: Image.asset('assets/shop_icon.png', width: 20, height: 20),
              label: const Text('View my Shop',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          )
      ],
    );
  }
}
