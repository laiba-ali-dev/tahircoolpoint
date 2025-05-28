import 'package:flutter/material.dart';
import 'admin_drawer.dart'; // Drawer wali file ka path

class AdminHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Home'),
      ),
      drawer: AdminDrawer(), // Drawer use kiya
      body: Center(
        child: Text(
          'Welcome Admin!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
