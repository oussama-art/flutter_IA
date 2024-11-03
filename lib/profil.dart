import 'package:flutter/material.dart';
import 'package:flutter_application_1/add_vetement.dart';
import 'package:flutter_application_1/auth_service.dart';
import 'package:flutter_application_1/login.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();

  // Controllers for user info fields
  final TextEditingController _codepostalController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _email = ""; // Variable to store the email
  bool _isLoading = true;
  bool _showPassword = false; // State for showing the password
  

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Retrieve email directly from the authentication service
      _email = await _auth.getUserEmail(); // Method to get the user's email

      // Fetch other user details from the user collection
      final user = await _auth.getCurrentUserDetails();
      if (user != null) {
        // Handle CodePostal as an integer
        _codepostalController.text = (user['CodePostal'] ?? '').toString();

        _addressController.text = user['address'] ?? '';

        // Handle birthday as a Firestore Timestamp
        if (user['birthday'] != null) {
          var birthdayTimestamp = user['birthday']; // Assuming it's stored as a Firestore Timestamp
          DateTime birthdayDate;

          // Check if it's a Timestamp or a regular int (milliseconds since epoch)
          if (birthdayTimestamp is int) {
            birthdayDate = DateTime.fromMillisecondsSinceEpoch(birthdayTimestamp);
          } else if (birthdayTimestamp is Timestamp) {
            birthdayDate = birthdayTimestamp.toDate(); // Convert Firestore Timestamp to DateTime
          } else {
            birthdayDate = DateTime.now(); // Default value if none matches
          }

          _birthdayController.text = DateFormat("dd/MM/yyyy").format(birthdayDate); // Format for display
        } else {
          _birthdayController.text = ''; // Handle empty birthday case
        }

        _cityController.text = user['city'] ?? '';
        _emailController.text = _email;

        // Debug: print the user data to the console
        print("User data fetched: $user");

        // Fetch and set the password in the controller
        String currentPassword = user['password'] ?? ''; // Now get the plain password
        _passwordController.text = currentPassword; // Set current password to password field
        print("Current Password: $_passwordController.text"); // Debug the password
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${e.toString()}")),
      );
    }
  }

  // Uncomment and modify this function to update user info
 Future<void> _updateUserInfo() async {
  try {
    // Ensure the code postal is valid and handle parsing errors
    int codePostal;
    try {
      codePostal = int.parse(_codepostalController.text);
    } catch (e) {
      print("Error parsing Code Postal: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Code Postal invalide")),
      );
      return; // Exit if invalid
    }

    // Convert the birthday string to DateTime
    DateTime birthday;
    try {
      birthday = DateFormat("dd/MM/yyyy").parse(_birthdayController.text);
    } catch (e) {
      print("Error parsing Birthday: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Date de naissance invalide")),
      );
      return; // Exit if invalid
    }

    // Convert DateTime to Firestore Timestamp
    Timestamp birthdayTimestamp = Timestamp.fromMillisecondsSinceEpoch(birthday.millisecondsSinceEpoch);

    // Update user info
    await _auth.updateUserInfo(
      codePostal: codePostal, // Convert int to String
      address: _addressController.text,
      birthday: birthdayTimestamp, // Store as Timestamp
      city: _cityController.text,
    );

    // Update password if not empty
    if (_passwordController.text.isNotEmpty) {
      await _auth.updateUserPassword(_passwordController.text);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Informations mises à jour")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erreur: ${e.toString()}")),
    );
  }
}




  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _navigateToAddVetement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddVetementScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.logout, color: Color.fromARGB(255, 68, 152, 255)),
            label: const Text(
              "Se Déconnecter",
              style: TextStyle(color: Color.fromARGB(255, 68, 152, 255)),
            ),
            onPressed: _logout,
          ),
        ],
      ),
      backgroundColor: Colors.white,  
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(20.0), // Padding around the form
                color: Colors.white, // Background color for the form
                child: Form(
                  child: ListView(
                    children: [
                      // Displaying the user's email at the top
                     TextFormField(
  controller: _emailController,
  readOnly: true, // Make the input field read-only
  decoration: InputDecoration(
    filled: true,
    fillColor: Colors.white,
    labelText: "Login",
    labelStyle: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 25.0,
      color: Colors.blueAccent,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: BorderSide(color: Colors.lightBlueAccent, width: 2.0),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: BorderSide(color: Colors.blueAccent, width: 1.0),
    ),
  ),
  style: TextStyle(fontSize: 16.0, color: Colors.black),
),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          labelText: "Password",
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25.0,
                            color: Colors.blueAccent,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(color: Colors.lightBlueAccent, width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(color: Colors.blueAccent, width: 1.0),
                          ),
                        ),
                        obscureText: !_showPassword,
                        style: TextStyle(fontSize: 16.0, color: Colors.black),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _birthdayController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          labelText: "Anniversaire",
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25.0,
                            color: Colors.blueAccent,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(color: Colors.lightBlueAccent, width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(color: Colors.blueAccent, width: 1.0),
                          ),
                        ),
                        style: TextStyle(fontSize: 16.0, color: Colors.black),
                      ),
                      const SizedBox(height: 20),

                      // TextFormField(
                      //   controller: _codepostalController,
                      //   decoration: InputDecoration(
                      //     filled: true,
                      //     fillColor: Colors.white,
                      //     labelText: "Code Postal",
                      //     labelStyle: TextStyle(
                      //       fontWeight: FontWeight.bold,
                      //       fontSize: 25.0,
                      //       color: Colors.blueAccent,
                      //     ),
                      //     border: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(10.0),
                      //       borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                      //     ),
                      //     focusedBorder: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(10.0),
                      //       borderSide: BorderSide(color: Colors.lightBlueAccent, width: 2.0),
                      //     ),
                      //     enabledBorder: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(10.0),
                      //       borderSide: BorderSide(color: Colors.blueAccent, width: 1.0),
                      //     ),
                      //   ),
                      //   style: TextStyle(fontSize: 16.0, color: Colors.black),
                      //   keyboardType: TextInputType.number, // Ensures numeric keyboard
                      // ),
                      TextFormField(
  controller: _codepostalController,
  decoration: InputDecoration(
    filled: true,
    fillColor: Colors.white,
    labelText: "Code Postal",
    labelStyle: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 25.0,
      color: Colors.blueAccent,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: BorderSide(color: Colors.lightBlueAccent, width: 2.0),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: BorderSide(color: Colors.blueAccent, width: 1.0),
    ),
  ),
  style: TextStyle(fontSize: 16.0, color: Colors.black),
  keyboardType: TextInputType.number, // Ensures numeric keyboard
  inputFormatters: <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly // Restricts input to digits only
  ],
),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          labelText: "Ville",
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25.0,
                            color: Colors.blueAccent,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(color: Colors.lightBlueAccent, width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(color: Colors.blueAccent, width: 1.0),
                          ),
                        ),
                        style: TextStyle(fontSize: 16.0, color: Colors.black),
                      ),
                      const SizedBox(height: 20),

                      
                      ElevatedButton.icon(
          onPressed: _updateUserInfo,
          icon: const Icon(Icons.check),
          label: const Text("Valider"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 115, 207, 230),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle: const TextStyle(fontSize: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0), // Rounded corners for the button
            ),
          ),
        ),
        const SizedBox(height: 10), // Space between buttons
        ElevatedButton.icon(
          onPressed: _navigateToAddVetement,
          icon: const Icon(Icons.add),
          label: const Text("Ajouter Vêtement"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 237, 84, 84),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle: const TextStyle(fontSize: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0), // Rounded corners for the button
            ),
          ),
        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
