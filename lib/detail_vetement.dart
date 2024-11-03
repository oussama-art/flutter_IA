import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetailVetementScreen extends StatefulWidget {
  final Map<String, dynamic> vetement;
  final String documentId;

  const DetailVetementScreen({
    Key? key,
    required this.vetement,
    required this.documentId,
  }) : super(key: key);

  @override
  DetailVetementScreenState createState() => DetailVetementScreenState();
}

class DetailVetementScreenState extends State<DetailVetementScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    logVetementInfo();
  }

  void logVetementInfo() {
    print("Vetement Information: ${widget.vetement}");
    print("Document ID: ${widget.documentId}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détail vêtement'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.vetement['imageUrl'] != null)
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(widget.vetement['imageUrl']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              Text(
                'Titre: ${widget.vetement['titre'] ?? 'Pas de titre'}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'Categorie: ${widget.vetement['categorie'] ?? 'Pas de categorie'}',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blueGrey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Taille: ${widget.vetement['taille'] ?? 'Pas de taille'}',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blueGrey[600],
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Marque: ${widget.vetement['marque'] ?? 'Pas de marque'}',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blueGrey[600],
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Prix: \$${widget.vetement['prix']?.toStringAsFixed(2) ?? 'Pas de prix'}',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.blueAccent,
                    ),
                    onPressed: () {
                      addToCart(widget.documentId, context);
                    },
                    child: const Text(
                      'Ajouter au Panier',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Set background color for the Scaffold
      backgroundColor: const Color.fromARGB(255, 255, 255, 255), // Change to your desired color
    );
  }

  void addToCart(String vetementDocId, BuildContext context) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('Panier')
          .add({
            'vetementUid': vetementDocId,
          });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajouté au panier!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter pour ajouter au panier.')),
      );
    }
  }
}
