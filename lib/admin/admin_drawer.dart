import 'package:flutter/material.dart';
import 'package:tahircoolpoint/admin/adminlogin.dart';

class AdminDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Admin Panel',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            onTap: () {
              // Navigator.push() for Dashboard page
            },
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Technicians'),
            onTap: () {
              // Navigator.push() for Manage Users page
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap:   () {
    // Optionally: session ya shared preferences clear karna
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // await prefs.clear();

    // Navigate to login screen and clear navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => AdminLogin()), // Replace with your login screen class
      (route) => false,
    );
  },
          ),
        ],
      ),
    );
  }
}
