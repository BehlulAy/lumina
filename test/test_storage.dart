import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:lumina/firebase_options.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Starting test with appspot.com bucket...';

  @override
  void initState() {
    super.initState();
    _runTest();
  }

  Future<void> _runTest() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _log('Firebase initialized.');
    } catch (e) {
      _log('Initialization error: $e');
      return;
    }

    // Initialize Firebase Storage with appspot.com bucket name explicitly
    final storage = FirebaseStorage.instanceFor(
      app: Firebase.app(),
      bucket: 'lumina-8b5cb.appspot.com',
    );
    _log('Storage bucket configured: ${storage.bucket}');

    // Let's create a temporary file in documents directory
    final directory = await getTemporaryDirectory();
    final tempFile = File('${directory.path}/test_upload.txt');
    await tempFile.writeAsString('Lumina test upload contents');

    try {
      final ref = storage.ref().child('profile_pictures/test_upload.txt');
      _log('Attempting to upload to: ${ref.fullPath}');
      
      final task = await ref.putFile(tempFile);
      _log('Upload state: ${task.state}');
      
      final url = await ref.getDownloadURL();
      _log('Success! Download URL: $url');
    } catch (e) {
      _log('Upload/Download failed: $e');
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  void _log(String message) {
    debugPrint('TEST_LOG: $message');
    setState(() {
      _status += '\n$message';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Firebase Storage Test')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text(
            _status,
            style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
          ),
        ),
      ),
    );
  }
}
