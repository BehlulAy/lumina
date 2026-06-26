import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lumina/widgets/custom_text_field.dart';
import 'package:lumina/widgets/recent_documents.dart';
import 'package:lumina/screens/document_view.dart';
import 'package:lumina/screens/photo_approval.dart';
import 'package:lumina/services/document_service.dart';

class UploadedDocumentsPage extends StatefulWidget {
  const UploadedDocumentsPage({super.key});

  @override
  State<UploadedDocumentsPage> createState() => _UploadedDocumentsPageState();
}

class _UploadedDocumentsPageState extends State<UploadedDocumentsPage> {
  final DocumentService _documentService = DocumentService();
  String _selectedFilter = 'all'; // 'all', 'pdf', 'text', 'image'
  String _searchQuery = '';

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
      // Automatically navigate to DocumentView to display the uploaded PDF
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

  void _showUploadOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final primaryPurple = const Color(0xFF5A4EE3);
        final titleColor = const Color(0xFF1E293B);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Belge Ekle',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEBF7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.upload_file_rounded, color: primaryPurple),
                  ),
                  title: const Text(
                    'Dosya Yükle',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('PDF, Word, TXT veya görsel seçin'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadDocument();
                  },
                ),
                const Divider(height: 20, color: Color(0xFFE2E8F0)),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF0E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF539165)),
                  ),
                  title: const Text(
                    'Kamera ile Çek',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Not veya belgenin fotoğrafını çekin'),
                  onTap: () {
                    Navigator.pop(context);
                    _scanNotes();
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Colors.white;

    // Filter items based on selected capsule and search query
    final filteredDocuments = _documentService.documents.where((doc) {
      final matchesFilter =
          _selectedFilter == 'all' || doc.type == _selectedFilter;
      final matchesSearch = doc.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Page Title
              const Text(
                'Belgelerim',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Search Bar using existing CustomTextField
              CustomTextField(
                type: CustomTextFieldType.search,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Capsule Filters Row
              _buildCapsuleFilters(),
              const SizedBox(height: 16),

              // Documents List or Empty State
              Expanded(
                child: filteredDocuments.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredDocuments.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final doc = filteredDocuments[index];
                          return RecentDocuments(
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
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadOptionsBottomSheet,
        backgroundColor: const Color(0xFF5A4EE3),
        icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
        label: const Text(
          'Belge Yükle',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCapsuleFilters() {
    final filters = [
      {'label': 'Tümü', 'value': 'all', 'icon': Icons.folder_rounded},
      {'label': 'PDF', 'value': 'pdf', 'icon': Icons.picture_as_pdf_rounded},
      {'label': 'Word', 'value': 'docx', 'icon': Icons.description_rounded},
      {'label': 'Yazı', 'value': 'text', 'icon': Icons.text_fields_rounded},
      {'label': 'Görsel', 'value': 'image', 'icon': Icons.image_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['value'];
          final primaryPurple = const Color(0xFF5A4EE3);

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter['value'] as String;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? primaryPurple : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryPurple.withAlpha(80),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                  border: Border.all(
                    color: isSelected ? primaryPurple : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      filter['icon'] as IconData,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      filter['label'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    final primaryPurple = const Color(0xFF5A4EE3);
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 64,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Arama Sonucu Bulunamadı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Filtreleme kriterlerinize veya arama teriminize uygun bir belge bulunamadı. Lütfen tekrar deneyin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedFilter = 'all';
                  _searchQuery = '';
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Filtreleri Temizle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
