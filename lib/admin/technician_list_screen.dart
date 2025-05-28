import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TechnicianListScreen extends StatelessWidget {
  void _deleteTechnician(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance.collection('technicians').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Technician deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete technician')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // light grey background for subtle look
      appBar: AppBar(
        title: Text('Technicians List'),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.grey[900],
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
        iconTheme: IconThemeData(color: Colors.grey[900]),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('technicians').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.grey[700]));
          }

          final technicians = snapshot.data?.docs ?? [];

          if (technicians.isEmpty) {
            return Center(
              child: Text(
                'No technicians found.',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            itemCount: technicians.length,
            itemBuilder: (context, index) {
              final tech = technicians[index];
              final data = tech.data() as Map<String, dynamic>;

              return Card(
                color: Colors.white,
                margin: EdgeInsets.symmetric(vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  title: Text(
                    data['full_name'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.grey[900],
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email: ${data['email']}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Phone: ${data['phone']}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  trailing: SizedBox(
                    width: 96,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blueGrey[700]),
                          tooltip: 'Edit Technician',
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/editTechnician',
                              arguments: {
                                'id': tech.id,
                                'data': data,
                              },
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red[400]),
                          tooltip: 'Delete Technician',
                          onPressed: () => _deleteTechnician(context, tech.id),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/addTechnician');
        },
        backgroundColor: Colors.grey[850],
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Technician',
      ),
    );
  }
}
