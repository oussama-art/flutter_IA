import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Logs in a user with email and password and fetches their details from Firestore.
  Future<Map<String, dynamic>?> loginUserWithEmailAndPassword(
      String email, String password) async {
    try {
      // Attempt to sign in the user
      final UserCredential cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      final User? user = cred.user;

      // Check if the user is successfully authenticated
      if (user != null) {
        // Fetch user details from Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

        // Check if user document exists
        if (userDoc.exists) {
          // Return the user data as a map
          return userDoc.data() as Map<String, dynamic>?;
        } else {
          log("User document does not exist in Firestore.");
          return null;
        }
      }
    } catch (e) {
      log("Login failed: $e");
    }
    return null; // Return null if login fails
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      log("User signed out successfully.");
    } catch (e) {
      log("Error during sign out: $e");
    }
  }

  /// Fetches the current user's details from Firestore.
    Future<Map<String, dynamic>?> getCurrentUserDetails() async {
  User? user = FirebaseAuth.instance.currentUser; // Get the currently authenticated user

  if (user != null) {
    // Fetch user details from Firestore
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    // Check if user document exists
    if (userDoc.exists) {
      // Extract data from the document
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Convert CodePostal to an integer if it exists
      if (userData.containsKey('CodePostal')) {
        userData['CodePostal'] = userData['CodePostal'] is int 
            ? userData['CodePostal'] 
            : int.tryParse(userData['CodePostal'].toString()) ?? 0; // Default to 0 if parsing fails
      }

      // Convert birthday to DateTime if it exists
      if (userData.containsKey('birthday')) {
        Timestamp? timestamp = userData['birthday'] as Timestamp?;
        userData['birthday'] = timestamp?.toDate(); // Convert Timestamp to DateTime
      }

      // Log the user data for debugging purposes
      log("User data retrieved: $userData");

      return userData; // Return the modified user data
    } else {
      log("Current user document does not exist in Firestore.");
      return null;
    }
  }
  log("No user is currently logged in.");
  return null; // Return null if no user is logged in
}


  Future<List<Map<String, dynamic>>> fetchVetements() async {
    QuerySnapshot snapshot = await _firestore.collection('vetements').get();

    // Map each document to a Map including the document ID
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Add the document ID to the data map
      return data;
    }).toList();
  }


  Future<void> updateUserInfo({
    required int codePostal,  // Changed to int
    required String address,
    required Timestamp birthday, // Changed to Timestamp
    required String city,
  }) async {
    User? user = _auth.currentUser; // Get the currently authenticated user

    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'CodePostal': codePostal,
          'address': address,
          'birthday': birthday,
          'city': city,
        });
        log("User information updated successfully.");
      } catch (e) {
        log("Failed to update user info: $e");
      }
    } else {
      log("No user is currently logged in.");
    }
  }

  // Method to fetch user's cart items
   // Method to fetch user's cart items along with their corresponding clothing items
  Future<List<Map<String, dynamic>>> fetchPanier(String userId) async {
  try {
    // Access the user's document in the 'users' collection
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
    print("User infos ");
    print(userDoc.data());

    // Check if the user document exists
    if (userDoc.exists) {
      // Fetch the panier collection for the user
      QuerySnapshot panierSnapshot = await userDoc.reference.collection('Panier').get();
      print(panierSnapshot);

      List<Map<String, dynamic>> panierItemsWithDetails = [];

      // Iterate over each panier document
      for (var panierDoc in panierSnapshot.docs) {
        // Get the data from the panier document
        var panierData = panierDoc.data() as Map<String, dynamic>;
        print(panierDoc);

        // Get the vetementUid from the panier item
        String vetementUid = panierData['vetementUid'];

        try {
          // Fetch the corresponding vetement document using vetementUid
          DocumentSnapshot vetementDoc = await _firestore.collection('vetements').doc(vetementUid).get();

          // Check if the vetement document exists
          if (vetementDoc.exists) {
            var vetementData = vetementDoc.data() as Map<String, dynamic>;
            // Combine panier and vetement data, including the panier document ID
            panierItemsWithDetails.add({
              'panierId': panierDoc.id, // Add the document ID of the panier item
              ...panierData, // Include the existing panier data
              'vetementDetails': vetementData, // Include the corresponding vetement details
            });
          } else {
            // Log if the vetement document doesn't exist
            print("Vetement document not found: $vetementUid. Check permissions for the 'vetements' collection.");
          }
        } catch (e) {
          // Log specific errors related to fetching the vetement document
          print("Error fetching vetement document for panier item ${panierDoc.id}: $e");
        }
      }

      return panierItemsWithDetails; // Return the combined list of panier and vetement details
    } else {
      print("User document not found: $userId. Check permissions for the 'users' collection.");
    }
    return []; // Return an empty list if user document doesn't exist
  } catch (e) {
    // Log any errors when accessing the user document
    print("Error fetching user document: $e");
    return []; // Return an empty list in case of an error
  }
}

  Future<String?> getCurrentUserId() async {
  User? user = _auth.currentUser; // Get the currently authenticated user
  return user?.uid; // Return user ID if user is logged in, else return null
}

 Future<void> deletePanierItem(String userId, String panierId) async {
    try {
      // Access the user's document in the 'users' collection
      DocumentReference userRef = _firestore.collection('users').doc(userId);

      // Delete the specified panier item
      await userRef.collection('Panier').doc(panierId).delete();
      log("Item deleted from panier successfully.");
    } catch (e) {
      log("Failed to delete item from panier: $e");
      throw e; // Rethrow the error to be handled in the UI
    }
  }

  Future<void> updateUserPassword(String newPassword) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }
  Future<String> getUserEmail() async {
    final user = await FirebaseAuth.instance.currentUser; // Example for Firebase
    return user?.email ?? '';
  }

  Future<void> storeUserEmailAndPassword(String email, String password) async {
    User? user = _auth.currentUser; // Get the currently authenticated user

    if (user != null) {
      try {

        // Store only the hashed password
        await _firestore.collection('users').doc(user.uid).set({
          'password': password, // Store hashed password instead of plain text
        }, SetOptions(merge: true)); // Use merge to avoid overwriting existing data
        log("User password stored successfully.");
      } catch (e) {
        log("Failed to store user password: $e");
      }
    } else {
      log("No user is currently logged in.");
    }
}
Future<void> retryRequest(Future<void> Function() requestFunction, {int retries = 3}) async {
  for (int i = 0; i < retries; i++) {
    try {
      await requestFunction();
      return; // Success, exit the function
    } catch (e) {
      log("Attempt ${i + 1} failed: $e");
      if (i == retries - 1) {
        throw e; // Rethrow on the last attempt
      }
      await Future.delayed(Duration(seconds: 2)); // Wait before retrying
    }
  }
}

}
