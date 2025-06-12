import 'package:flutter/material.dart';
//import 'package:notepad/screen/pages/archive_page.dart';
//import 'package:notepad/screen/pages/trash_page.dart';
//import 'package:notepad/screen/pages/settings_page.dart';
//import 'package:notepad/screen/pages/label_page.dart';

class DrawerMenu extends StatelessWidget {
  final Function(String) onItemSelected;

  const DrawerMenu({super.key, required this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.black,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              child: Text(
                'TulisAja',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // 🔥 Tambahin item Catatan di atas
            _buildDrawerItem(
              context,
              icon: Icons.note_outlined,
              text: 'Catatan',
              onTap: () => onItemSelected('catatan'),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.archive_outlined,
              text: 'Arsip',
              onTap: () => onItemSelected('arsip'),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.delete_outline,
              text: 'Sampah',
              onTap: () => onItemSelected('sampah'),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.settings_outlined,
              text: 'Setelan',
              onTap: () => onItemSelected('setelan'),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.label_outline,
              text: 'Label',
              onTap: () => onItemSelected('label'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context,
      {required IconData icon, required String text, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: onTap,
    );
  }
}
