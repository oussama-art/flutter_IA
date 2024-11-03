import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/auth_service.dart';

class PanierScreen extends StatefulWidget {
  final AuthService authService;
  final String userId;

  const PanierScreen({Key? key, required this.authService, required this.userId}) : super(key: key);

  @override
  State<PanierScreen> createState() => _PanierScreenState();
}

class _PanierScreenState extends State<PanierScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _panierItems = []; // List to hold cart items

  @override
  void initState() {
    super.initState();
    _fetchPanierItems(); // Fetch items when screen initializes
  }

  Future<void> _fetchPanierItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> items = await widget.authService.fetchPanier(widget.userId);
      setState(() {
        _panierItems = items; // Update state with fetched items
      });
    } catch (e) {
      print("Erreur lors de la récupération des éléments du panier: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePanierItem(String panierId) async {
    try {
      await widget.authService.deletePanierItem(widget.userId, panierId);
      setState(() {
        _panierItems.removeWhere((item) => item['panierId'] == panierId);
      });
      _showNotification("Produit supprimé du panier."); // Show notification after deletion
    } catch (e) {
      print("Erreur lors de la suppression de l'élément du panier: $e");
    }
  }

  void _showNotification(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2), // Duration the SnackBar will be visible
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.green, // Change the background color if desired
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  double calculateTotal() {
    return _panierItems.fold(0.0, (total, item) {
      final price = item['vetementDetails']['prix'] as double? ?? 0.0;
      return total + price;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Mon Panier"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPanierItems, // Refresh cart items
          ),
        ],
        backgroundColor: Colors.white,
      ),
      body: Container(
        constraints: BoxConstraints.expand(),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _panierItems.isEmpty
                ? const Center(child: Text("Votre panier est vide"))
                : RefreshIndicator(
                    onRefresh: _fetchPanierItems,
                    child: ListView.builder(
                      itemCount: _panierItems.length,
                      itemBuilder: (context, index) {
                        final item = _panierItems[index];
                        final vetementDetails = item['vetementDetails'];

                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          elevation: 0,
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                MouseRegion(
                                  child: vetementDetails['imageUrl'] != null
                                      ? Image.memory(
                                          base64Decode(vetementDetails['imageUrl']),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        )
                                      : const SizedBox(
                                          width: 100,
                                          height: 100,
                                          child: Center(child: Text('No Image')),
                                        ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Titre: ${vetementDetails['titre'] ?? 'Pas de titre'}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      
                                      Text(
                                        'Taille: ${vetementDetails['taille'] ?? 'Pas de taille'}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Prix: \$${vetementDetails['prix']?.toStringAsFixed(2) ?? 'Pas de prix'}',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red), // Change to "X" icon
                                  onPressed: () => _deletePanierItem(item['panierId']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
      bottomNavigationBar: Container(
  color: const Color.fromARGB(255, 255, 255, 255),
  padding: const EdgeInsets.all(16.0),
  child: Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
    child: Container( // Add Container to set background color
      color: const Color.fromARGB(255, 255, 255, 255), // Set background color
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Total:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Row(
            children: [
              const Icon(Icons.attach_money, color: Color.fromARGB(255, 255, 255, 255)),
              Text(
                "\$${calculateTotal().toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
),


    );
  }
}
