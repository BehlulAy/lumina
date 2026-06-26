import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lumina/screens/profile.dart';
import 'package:lumina/screens/uploaded_documents.dart';
import 'package:lumina/widgets/recent_documents.dart';
import 'package:lumina/widgets/upload_card.dart';
import 'package:lumina/screens/document_view.dart';
import 'package:lumina/screens/photo_approval.dart';
import 'package:lumina/services/document_service.dart';
import 'package:lumina/services/auth_service.dart';
import 'package:lumina/screens/summary_page.dart';
import 'package:lumina/screens/chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final DocumentService _documentService = DocumentService();

  @override
  void initState() {
    super.initState();
    _documentService.addListener(_onDocumentsChanged);
  }

  @override
  void dispose() {
    _documentService.removeListener(_onDocumentsChanged);
    super.dispose();
  }

  void _onDocumentsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickAndUploadDocument() async {
    final newDoc = await _documentService.pickAndUploadDocument();
    if (newDoc != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${newDoc.name}" başarıyla yüklendi!'),
          backgroundColor: const Color(0xFF5A4EE3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentView(
            documentName: newDoc.name,
            documentType: newDoc.type,
            documentDate: newDoc.date,
            filePath: newDoc.filePath,
          ),
        ),
      );
    }
  }

  Future<void> _scanNotes() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoApprovalPage(imagePath: image.path),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kamera açılırken hata oluştu: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Widget _buildHomeContent() {
    final primaryPurple = const Color(0xFF5A4EE3);
    final user = AuthService().currentUser;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Top Profile & Greeting Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Merhaba,',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.displayName != null
                          ? '${user!.displayName} 👋'
                          : 'Hoş Geldiniz 👋',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = 2;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryPurple.withAlpha(50),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: primaryPurple.withAlpha(25),
                      backgroundImage:
                          user?.photoURL != null && user!.photoURL!.isNotEmpty
                          ? NetworkImage(user.photoURL!) as ImageProvider
                          : null,
                      child:
                          user?.photoURL != null && user!.photoURL!.isNotEmpty
                          ? null
                          : Icon(
                              Icons.person_rounded,
                              color: primaryPurple,
                              size: 28,
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section Title
            const Text(
              'Belgelerim & İşlemler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),

            // Upload Action Cards Grid
            UploadCardsGrid(
              onUploadDocument: _pickAndUploadDocument,
              onScanNotes: _scanNotes,
              onSummarize: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SummaryPage()),
                );
              },
              onChatWithDocs: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatPage()),
                );
              },
            ),

            const SizedBox(height: 16),

            const Text(
              'En Son Ziyaret Edilenler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 16),

            ..._documentService.documents.take(4).map((doc) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: RecentDocuments(
                  text: doc.name,
                  date: doc.date,
                  docType: doc.type,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DocumentView(
                          documentName: doc.name,
                          documentType: doc.type,
                          documentDate: doc.date,
                          filePath: doc.filePath,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Colors.white;
    final primaryPurple = const Color(0xFF5A4EE3);

    final List<Widget> pages = [
      _buildHomeContent(),
      const UploadedDocumentsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: primaryPurple,
        unselectedItemColor: const Color(0xFF94A3B8),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            activeIcon: Icon(Icons.grid_view_rounded),
            label: 'Belgelerim',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
