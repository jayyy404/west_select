import 'package:flutter/material.dart';
import 'package:cc206_west_select/firebase/app_user.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({
    super.key,
    required this.appUser,
    required this.onEditProfile,
    required this.onDeleteAccount,
    required this.onLogout,
  });

  final AppUser appUser;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  Widget _section(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      child: Text(t,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600])));

  Widget _item(BuildContext ctx,
      {required IconData icon,
      required String title,
      Color? textColor,
      VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
          color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon, color: textColor ?? Colors.grey[700]),
        title: Text(title,
            style: TextStyle(fontSize: 16, color: textColor ?? Colors.black87)),
        trailing: textColor == null
            ? Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400])
            : null,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
        height: MediaQuery.of(context).size.height * .7,
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context)),
                const SizedBox(width: 10),
                const Text('Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
              ])),
          Expanded(
              child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                _section('Account'),
                _item(context, icon: Icons.person, title: 'Edit profile',
                    onTap: () {
                  Navigator.pop(context);
                  onEditProfile();
                }),
                _item(context,
                    icon: Icons.delete,
                    title: 'Delete account',
                    textColor: Colors.red,
                onTap: onDeleteAccount),
                _item(context,
                    icon: Icons.logout, title: 'Log out', onTap: onLogout),
                const SizedBox(height: 20),
                _section('General'),
                _item(context, icon: Icons.help, title: 'Help Centre'),
                const SizedBox(height: 20),
                _section('About'),
                _item(context,
                    icon: Icons.description, title: 'User Agreement'),
                _item(context, icon: Icons.privacy_tip, title: 'Privacy'),
                _item(context, icon: Icons.gavel, title: 'Legal'),
                const SizedBox(height: 20),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Version',
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600])),
                      Text('6.24.0.0',
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600]))
                    ]),
                const SizedBox(height: 50)
              ]))
        ]),
      );
}
