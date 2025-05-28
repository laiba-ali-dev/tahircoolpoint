import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    checkLoginStatusAndFetchUser();
  }

  void checkLoginStatusAndFetchUser() async {
    User? user = _auth.currentUser;

    if (user == null) {
      // User not logged in
      await Future.delayed(Duration.zero); // Ensure context is available
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Not Logged In"),
          content: const Text("Please login first to view your profile."),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pushReplacementNamed('/login');
              },
            )
          ],
        ),
      );
    } else {
      fetchUserData(user.uid);
    }
  }

  void fetchUserData(String uid) async {
    DocumentSnapshot doc =
        await _firestore.collection('signup').doc(uid).get();

    if (doc.exists) {
      setState(() {
        userData = doc.data() as Map<String, dynamic>;
      });
    } else {
      print("User document does not exist");
    }
  }

  void logout() async {
    await _auth.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.red[700],
        title: const Text("User Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: logout,
          ),
        ],
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.red.shade200, width: 1),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.red[200],
                        child: const Icon(Icons.person, size: 40, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        userData!['name'],
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.red),
                    const SizedBox(height: 10),
                    infoRow("📧 Email", userData!['email']),
                    const SizedBox(height: 15),
                    infoRow("📱 Phone", userData!['phone']),
                  ],
                ),
              ),
            ),
    );
  }

  Widget infoRow(String label, String value) {
    return Row(
      children: [
        Text(
          "$label: ",
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.red),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
