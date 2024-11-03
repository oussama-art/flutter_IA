import 'dart:convert';
import 'dart:html' as html; // For web file picking
import 'dart:io' show File; // For mobile file handling
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data'; // For handling byte data
import 'package:http_parser/http_parser.dart'; // For handling media types

class AddVetementScreen extends StatefulWidget {
  const AddVetementScreen({Key? key}) : super(key: key);

  @override
  State<AddVetementScreen> createState() => _AddVetementScreenState();
}

class _AddVetementScreenState extends State<AddVetementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _categorieController = TextEditingController();
  final _tailleController = TextEditingController();
  final _marqueController = TextEditingController();
  final _prixController = TextEditingController();

  XFile? _selectedImage; // XFile is compatible with both web and mobile
  String? _imageBase64;

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      if (kIsWeb) {
        // Web file picker
        html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
        uploadInput.accept = 'image/jpeg, image/png'; // Accept both JPEG and PNG
        uploadInput.click();

        uploadInput.onChange.listen((e) async {
          final files = uploadInput.files;
          if (files!.isEmpty) return;

          final fileName = files[0].name.toLowerCase();
          if (!(fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || fileName.endsWith('.png'))) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Only JPEG and PNG files are allowed.")),
            );
            return;
          }

          final reader = html.FileReader();
          reader.readAsArrayBuffer(files[0]);
          reader.onLoadEnd.listen((e) async {
            final bytes = reader.result as Uint8List;
            setState(() {
              _imageBase64 = base64Encode(bytes);
              _selectedImage = XFile.fromData(bytes, name: files[0].name);
            });
            await _sendImageForClassification(); // Send for classification after selection
          });
        });
      } else {
        // Mobile image picker
        final pickedImage = await picker.pickImage(source: ImageSource.gallery);
        if (pickedImage != null) {
          final fileName = pickedImage.name.toLowerCase();
          if (!(fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || fileName.endsWith('.png'))) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Only JPEG and PNG files are allowed.")),
            );
            return;
          }

          final bytes = await pickedImage.readAsBytes();
          setState(() {
            _selectedImage = pickedImage;
            _imageBase64 = base64Encode(bytes);
          });
          await _sendImageForClassification(); // Send for classification after selection
        }
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<void> _sendImageForClassification() async {
    if (_selectedImage == null) return;

    try {
      final uri = Uri.parse('http://127.0.0.1:5000/predict'); // Update with your Flask API endpoint
      var request = http.MultipartRequest('POST', uri);

      final bytes = await _selectedImage!.readAsBytes();
      String contentType = 'image/jpeg'; // Default content type
      if (_selectedImage!.name.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      }

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: _selectedImage!.name,
        contentType: MediaType.parse(contentType),
      ));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final decodedResponse = jsonDecode(responseBody);
        final category = decodedResponse['detected_label']; // Ensure this key exists in the response

        // Check if category is not null before using it
        if (category != null && category is String) {
          setState(() {
            _categorieController.text = category; // Set the category controller
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Classification result: $category")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No valid category returned from API")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error during classification")),
        );
      }
    } catch (e) {
      print("Error sending image for classification: $e");
    }
  }

  Future<void> _addVetement() async {
    if (_formKey.currentState!.validate()) {
      final prix = double.tryParse(_prixController.text);
      if (prix == null) {
        // Handle invalid price input
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid price. Please enter a valid number.")),
        );
        return;
      }

      try {
        await FirebaseFirestore.instance.collection('vetements').add({
          'titre': _titreController.text,
          'categorie': _categorieController.text,
          'taille': _tailleController.text,
          'marque': _marqueController.text,
          'prix': prix,
          'imageUrl': _imageBase64,
        });

        // Show success notification
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product added successfully!")),
        );

        // Clear all fields after adding successfully
        _titreController.clear();
        _categorieController.clear();
        _tailleController.clear();
        _marqueController.clear();
        _prixController.clear();
        setState(() {
          _selectedImage = null;
          _imageBase64 = null;
        });
      } catch (e) {
        // Handle errors during the add operation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add product: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter un Vêtement"),
        backgroundColor: Colors.white, // Set app bar color to blue
      ),
      backgroundColor: Colors.white, // Set background color to white
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Image Picker Button with Circular Icon
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120, // Width of the image picker
                    height: 120, // Height of the image picker
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200], // Background color of the circle
                      border: Border.all(color: Colors.blue, width: 3), // Border color and width
                    ),
                    child: ClipOval(
                      child: _selectedImage != null
                          ? (kIsWeb
                              ? Image.memory(base64Decode(_imageBase64!), fit: BoxFit.cover)
                              : Image.file(File(_selectedImage!.path), fit: BoxFit.cover))
                          : const Icon(Icons.add_a_photo, size: 50, color: Colors.blue), // Icon for adding image
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Styled TextFormFields
              _buildTextFormField(_titreController, "Titre"),
              const SizedBox(height: 10),
              _buildTextFormField(_categorieController, "Catégorie", readOnly: true),
              const SizedBox(height: 10),
              _buildTextFormField(_tailleController, "Taille"),
              const SizedBox(height: 10),
              _buildTextFormField(_marqueController, "Marque"),
              const SizedBox(height: 10),
              _buildTextFormField(_prixController, "Prix", keyboardType: TextInputType.number),
              const SizedBox(height: 20),

              // Styled Submit Button
              ElevatedButton(
                onPressed: _addVetement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15), // Button padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Rounded button corners
                  ),
                ),
                child: const Text("Ajouter Vêtement", style: TextStyle(fontSize: 18, color: Colors.white)), // Button text
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String label, {bool readOnly = false, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // Label above the field
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.blue),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ce champ est requis.';
            }
            return null;
          },
        ),
      ],
    );
  }
}
