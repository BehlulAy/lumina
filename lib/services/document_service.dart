import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lumina/services/auth_service.dart';

class DocumentItem {
  final String name;
  final String date;
  final String type; // "pdf", "text", "image"
  final String? filePath; // Path on disk, if custom uploaded

  DocumentItem({
    required this.name,
    required this.date,
    required this.type,
    this.filePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date,
      'type': type,
      'filePath': filePath,
    };
  }

  factory DocumentItem.fromJson(Map<String, dynamic> json) {
    return DocumentItem(
      name: json['name'] as String,
      date: json['date'] as String,
      type: json['type'] as String,
      filePath: json['filePath'] as String?,
    );
  }

  Future<String?> getBase64String() async {
    if (filePath == null) return null;
    try {
      final file = File(filePath!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return base64Encode(bytes);
      }
    } catch (e) {
      debugPrint('Error converting file to base64: $e');
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentItem &&
        other.name == name &&
        other.date == date &&
        other.type == type &&
        other.filePath == filePath;
  }

  @override
  int get hashCode {
    return Object.hash(name, date, type, filePath);
  }
}

class DocumentService extends ChangeNotifier {
  static final DocumentService _instance = DocumentService._internal();

  factory DocumentService() {
    return _instance;
  }

  DocumentService._internal() {
    // Load documents for current user immediately if already logged in on startup
    final currentUser = AuthService().currentUser;
    if (currentUser != null) {
      loadDocumentsForUser(currentUser.email);
    }

    // Listen to authentication changes to load/clear documents accordingly
    AuthService().authStateChanges.listen((user) {
      loadDocumentsForUser(user?.email);
    });
  }

  final List<DocumentItem> _documents = [];

  List<DocumentItem> get documents => List.unmodifiable(_documents);

  Future<void> loadDocumentsForUser(String? email) async {
    if (email == null || email.isEmpty) {
      _documents.clear();
      notifyListeners();
      return;
    }
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final safeEmail = email.replaceAll(RegExp(r'[^\w\s\-\.]'), '_');
      final file = File('${appDir.path}/documents_$safeEmail.json');
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = json.decode(jsonString);
        _documents.clear();
        for (var item in jsonList) {
          final doc = DocumentItem.fromJson(item);
          String? updatedPath = doc.filePath;
          if (updatedPath != null) {
            // Reconstruct absolute path using current application documents directory to handle dynamic app path changes
            final fileName = updatedPath.split('/').last.split('\\').last;
            updatedPath = '${appDir.path}/$fileName';
          }
          _documents.add(DocumentItem(
            name: doc.name,
            date: doc.date,
            type: doc.type,
            filePath: updatedPath,
          ));
        }
      } else {
        _documents.clear();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading documents for user $email: $e');
    }
  }

  Future<void> saveDocuments() async {
    final email = AuthService().currentUser?.email;
    if (email == null || email.isEmpty) return;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final safeEmail = email.replaceAll(RegExp(r'[^\w\s\-\.]'), '_');
      final file = File('${appDir.path}/documents_$safeEmail.json');
      final jsonList = _documents.map((item) => item.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      debugPrint('Error saving documents for user $email: $e');
    }
  }

  void addDocument(DocumentItem document) {
    // Insert at the beginning of the list so it is shown as the most recent document
    _documents.insert(0, document);
    saveDocuments();
    notifyListeners();
  }

  /// Picks a document from the device, saves it to the app's documents directory,
  /// adds it to the documents list, and returns the created DocumentItem.
  Future<DocumentItem?> pickAndUploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
      );

      if (result != null && result.files.single.path != null) {
        final pickedFile = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final extension = result.files.single.extension?.toLowerCase() ?? '';

        // Copy file to application documents directory for permanent local storage
        final appDir = await getApplicationDocumentsDirectory();
        final savedFile = await pickedFile.copy('${appDir.path}/$fileName');

        // Determine document type based on file extension
        String docType = 'text';
        if (extension == 'pdf') {
          docType = 'pdf';
        } else if (extension == 'png' || extension == 'jpg' || extension == 'jpeg') {
          docType = 'image';
        } else if (extension == 'docx' || extension == 'doc') {
          docType = 'docx';
        }

        // Format current date and time
        final now = DateTime.now();
        final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

        final newDoc = DocumentItem(
          name: fileName.contains('.')
              ? fileName.substring(0, fileName.lastIndexOf('.'))
              : fileName,
          date: dateStr,
          type: docType,
          filePath: savedFile.path,
        );

        addDocument(newDoc);
        return newDoc;
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
    return null;
  }

  /// Saves a captured photo from the temporary directory to the application's
  /// documents directory, adds it to the documents list, and returns it.
  Future<DocumentItem?> addCapturedPhoto(String tempPath, String documentName) async {
    try {
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        final extension = tempPath.split('.').last.toLowerCase();
        final finalExtension = extension.isEmpty ? 'jpg' : extension;

        // Generate clean name and filesystem safe name
        final now = DateTime.now();
        final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
        
        final cleanDocName = documentName.trim().isEmpty 
            ? "Tarama ${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}"
            : documentName.trim();
        
        final safeFileName = "${cleanDocName.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(' ', '_')}_${now.millisecondsSinceEpoch}.$finalExtension";

        // Copy file to application documents directory for permanent local storage
        final appDir = await getApplicationDocumentsDirectory();
        final savedFile = await tempFile.copy('${appDir.path}/$safeFileName');

        final newDoc = DocumentItem(
          name: cleanDocName,
          date: dateStr,
          type: 'image',
          filePath: savedFile.path,
        );

        addDocument(newDoc);
        return newDoc;
      }
    } catch (e) {
      debugPrint('Error saving captured photo: $e');
    }
    return null;
  }
}
