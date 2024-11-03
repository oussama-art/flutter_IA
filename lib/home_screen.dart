import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/auth_service.dart';
import 'package:flutter_application_1/login.dart';
import 'package:flutter_application_1/profil.dart';
import 'package:flutter_application_1/detail_vetement.dart'; // Ensure this is imported
import 'package:flutter_application_1/panier.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService auth = AuthService();
  int _currentIndex = 0; // Index of the selected tab
  List<Map<String, dynamic>> _vetements = []; // List to hold fetched clothing items
  bool _isLoading = true; // Loading state
  String? userId; // Declare a class-level variable for userId

  @override
  void initState() {
    super.initState();
    _fetchVetements(); // Fetch the clothing items when the screen is initialized
  }

  // Fetch clothing items from AuthService
  Future<void> _fetchVetements() async {
    setState(() {
      _isLoading = true; // Set loading to true before fetching
    });

    try {
      List<Map<String, dynamic>> vetements = await auth.fetchVetements();
      setState(() {
        _vetements = vetements; // Update the list with fetched data
      });
    } catch (e) {
      _showErrorDialog("Erreur lors de la récupération des vêtements: $e");
    } finally {
      setState(() {
        _isLoading = false; // Set loading to false after fetching
      });
    }
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Erreur'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Method to handle tab selection
  void _onTabTapped(int index) async {
    if (index == 1 || index == 2) {
      userId = await auth.getCurrentUserId();

      if (userId == null) {
        goToLogin(context); // Navigate to LoginScreen if user is not logged in
      }
    }

    setState(() {
      _currentIndex = index; // Update current index
    });

    if (index == 0) {
      _fetchVetements(); // Refresh data when "Acheter" tab is tapped
    }
  }

  @override
  @override
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      toolbarHeight: _currentIndex == 0 ? kToolbarHeight : 0, // Set height based on the current tab
      title: _currentIndex == 0 ? const Text("Accueil") : null, // Title displayed only if "Acheter" tab is selected
      backgroundColor: Colors.white,
    ),
    body: Container(
      color: const Color.fromARGB(255, 255, 255, 255), // Set background color to white
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchVetements,
              child: _currentIndex == 0
                  ? ListView.builder(
                      itemCount: _vetements.length,
                      itemBuilder: (context, index) {
                        final vetement = _vetements[index];
                        return Card(
                          margin: const EdgeInsets.all(20.0),
                          elevation: 0, // Remove shadow
                          color: Colors.white, // Set the background color of the card to white
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: GestureDetector( // Use GestureDetector to handle taps
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailVetementScreen(
                                      vetement: vetement,
                                      documentId: vetement['id'],
                                    ),
                                  ),
                                );
                              },
                              child: Row(
  crossAxisAlignment: CrossAxisAlignment.start, // Align items at the start
  children: [
    MouseRegion(
      cursor: SystemMouseCursors.click, // Change cursor to pointer
      child: vetement['imageUrl'] != null
          ? Image.memory(
              base64Decode(vetement['imageUrl']),
              width: 120, // Increased width
              height: 120, // Increased height
              fit: BoxFit.cover,
            )
          : const SizedBox(
              width: 150,
              height: 150,
              child: Center(child: Text('No Image')),
            ),
    ),
    const SizedBox(width: 24), // Increased space between image and text
    Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click, // Change cursor to pointer
        child: Container(
          padding: const EdgeInsets.all(16.0), // Increased padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                vetement['titre'] ?? 'Pas de titre',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20, // Increased font size for title
                  color: Colors.black87, // Change text color for title
                ),
              ),
              Text(
                'Taille: ${vetement['taille'] ?? 'Pas de taille'}',
                style: const TextStyle(
                  fontSize: 16, // Increased font size for size
                  color: Colors.black, // Change text color for size
                  fontStyle: FontStyle.normal, // Make text italic
                ),
              ),
              const SizedBox(height: 8), // Increased space between size and price
              Text(
                'Prix: \$${vetement['prix']?.toStringAsFixed(2) ?? 'Pas de prix'}',
                style: const TextStyle(
                  fontSize: 16, // Increased font size for price
                  color: Colors.green, // Change text color for price
                  fontWeight: FontWeight.bold, // Make text bold
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ],
),

                            ),
                          ),
                        );
                      },
                    )
                  : _currentIndex == 1 && userId != null
                      ? PanierScreen(authService: auth, userId: userId!) // Render PanierScreen if index is 1
                      : _currentIndex == 2 && userId != null
                          ? ProfileScreen() // Render ProfileScreen if index is 2
                          : const Center(child: Text("Veuillez vous connecter pour accéder à cette section.")), // Message if userId is null
            ),
    ),
    bottomNavigationBar: BottomNavigationBar(
    onTap: _onTabTapped,
    currentIndex: _currentIndex,
    backgroundColor: Colors.grey[100], // Set a light background color
    selectedItemColor: Colors.green, // Set color for selected item
    unselectedItemColor: Colors.grey, // Set color for unselected items
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.attach_money),
        label: "Acheter",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.shopping_cart),
        label: "Panier",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: "Profil",
      ),
    ],
),

  );
}



  void goToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
}
