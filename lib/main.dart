// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import 'dart:convert';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await dotenv.load();  // Load environment variables
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Price Tag OCR',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: HomeScreen(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }
//
// class HomeScreen extends StatefulWidget {
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   File? _image;
//   String? _updatedImageUrl;
//   List<String> _prices = [];
//   bool _isLoading = false;
//   String _errorMessage = '';
//
//   final String apiUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:5000';
//
//   @override
//   void initState() {
//     super.initState();
//     testBackendConnection(); // Check backend on startup
//   }
//
//   // 🔥 Test Backend Connection
//   Future<void> testBackendConnection() async {
//     try {
//       var request = http.MultipartRequest(
//         'POST',
//         Uri.parse('$apiUrl/process_image'),
//       );
//       request.fields['currency'] = 'INR';
//
//       var response = await request.send();
//       var responseData = await response.stream.bytesToString();
//
//       print("🔥 Backend Response: $responseData");
//     } catch (e) {
//       print("⚠️ Error: Cannot connect to backend → $e");
//     }
//   }
//
//   // 📸 Pick Image from Gallery
//   Future<void> _pickImage() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//
//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path);
//         _updatedImageUrl = null;
//         _prices.clear();
//         _errorMessage = '';
//       });
//
//       // Process Image
//       _processImage();
//     }
//   }
//
//   // 🚀 Upload Image & Process
//   Future<void> _processImage() async {
//     if (_image == null) return;
//
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//     });
//
//     try {
//       var request = http.MultipartRequest(
//         'POST',
//         Uri.parse('$apiUrl/process_image'),
//       );
//       request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
//       request.fields['currency'] = 'INR'; // Change if needed
//
//       var response = await request.send();
//       var responseData = await response.stream.bytesToString();
//       var jsonResponse = json.decode(responseData);
//
//       if (response.statusCode == 200) {
//         setState(() {
//           _updatedImageUrl = jsonResponse['image_url'];
//           _prices = List<String>.from(jsonResponse['prices']);
//         });
//
//         print("🖼 Updated Image URL: $_updatedImageUrl");
//         print("💰 Extracted Prices: $_prices");
//       } else {
//         setState(() {
//           _errorMessage = "Failed to process image. Try again.";
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = "Error connecting to server: $e";
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Price Tag OCR'),
//         centerTitle: true,
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               if (_image != null)
//                 Column(
//                   children: [
//                     Image.file(_image!, height: 200),
//                     SizedBox(height: 10),
//                   ],
//                 ),
//
//               if (_isLoading) CircularProgressIndicator(), // ⏳ Show loading indicator
//
//               if (_errorMessage.isNotEmpty)
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 10),
//                   child: Text(
//                     _errorMessage,
//                     style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//
//               if (_updatedImageUrl != null)
//                 Column(
//                   children: [
//                     Image.network(
//                       '$apiUrl$_updatedImageUrl',
//                       height: 200,
//                       loadingBuilder: (context, child, progress) {
//                         if (progress == null) return child;
//                         return CircularProgressIndicator();
//                       },
//                       errorBuilder: (context, error, stackTrace) {
//                         return Text('❌ Failed to load processed image');
//                       },
//                     ),
//                     SizedBox(height: 10),
//                   ],
//                 ),
//
//               if (_prices.isNotEmpty)
//                 Column(
//                   children: [
//                     Text(
//                       "💰 Extracted Prices:",
//                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     SizedBox(height: 5),
//                     ..._prices.map((price) => Text(price, style: TextStyle(fontSize: 16))),
//                   ],
//                 ),
//
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _pickImage,
//                 child: Text('📸 Upload Image'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Price Tag OCR',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  String? _updatedImageUrl;
  List<String> _prices = [];
  bool _isLoading = false;
  String _errorMessage = '';

  final String apiUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:5000';

  @override
  void initState() {
    super.initState();
    testBackendConnection();
  }

  Future<void> testBackendConnection() async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiUrl/process_image'),
      );
      request.fields['currency'] = 'INR';

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      print("🔥 Backend Response: $responseData");
    } catch (e) {
      print("⚠️ Error: Cannot connect to backend → $e");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _updatedImageUrl = null;
        _prices.clear();
        _errorMessage = '';
      });

      _processImage();
    }
  }

  Future<void> _processImage() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiUrl/process_image'),
      );
      request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
      request.fields['currency'] = 'INR';

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        setState(() {
          _updatedImageUrl = jsonResponse['image_url'];
          _prices = List<String>.from(jsonResponse['prices']);
        });

        print("🖼 Updated Image URL: $_updatedImageUrl");
        print("💰 Extracted Prices: $_prices");
      } else {
        setState(() {
          _errorMessage = "Failed to process image. Try again.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error connecting to server: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Price Tag OCR'),
        centerTitle: true,
      ),
      body: SingleChildScrollView( // ⬅️ Makes the whole page scrollable
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_image != null)
                  InteractiveViewer( // ⬅️ Enables Zoom & Pan for Uploaded Image
                    boundaryMargin: EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Image.file(_image!, height: 200),
                  ),

                if (_isLoading) CircularProgressIndicator(),

                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),

                if (_updatedImageUrl != null)
                  InteractiveViewer( // ⬅️ Enables Zoom & Pan for Processed Image
                    boundaryMargin: EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Image.network(
                      '$apiUrl$_updatedImageUrl',
                      height: 300,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return CircularProgressIndicator();
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Text('❌ Failed to load processed image');
                      },
                    ),
                  ),

                if (_prices.isNotEmpty)
                  Column(
                    children: [
                      Text(
                        "💰 Extracted Prices:",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      ..._prices.map((price) => Text(price, style: TextStyle(fontSize: 16))),
                    ],
                  ),

                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('📸 Upload Image'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
