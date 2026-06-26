import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina/services/ai_service.dart';
import 'package:lumina/services/document_service.dart';

class SummaryPage extends StatefulWidget {
  final DocumentItem? initialDocument;

  const SummaryPage({super.key, this.initialDocument});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> with SingleTickerProviderStateMixin {
  final DocumentService _documentService = DocumentService();
  final AiService _aiService = AiService();
  
  DocumentItem? _selectedDocument;
  TabController? _tabController;
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Summary Data
  String? _summaryText;
  List<String> _takeaways = [];
  List<Map<String, String>> _flashcards = [];
  
  // Flashcard states
  int _currentCardIndex = 0;
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    _selectedDocument = widget.initialDocument;
    _tabController = TabController(length: 3, vsync: this);
    
    if (_selectedDocument != null) {
      _generateSummary();
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _generateSummary() async {
    if (_selectedDocument == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _summaryText = null;
      _takeaways = [];
      _flashcards = [];
      _currentCardIndex = 0;
      _showAnswer = false;
    });

    try {
      if (!_aiService.hasApiKey) {
        throw ApiKeyMissingException();
      }

      final data = await _aiService.summarizeDocument(_selectedDocument!);
      setState(() {
        _summaryText = data['summary'] as String?;
        
        final rawTakeaways = data['takeaways'] as List<dynamic>?;
        _takeaways = rawTakeaways?.map((e) => e.toString()).toList() ?? [];
        
        final rawCards = data['flashcards'] as List<dynamic>?;
        _flashcards = rawCards?.map((e) {
          final m = e as Map<String, dynamic>;
          return {
            'question': (m['question'] ?? '').toString(),
            'answer': (m['answer'] ?? '').toString(),
          };
        }).toList() ?? [];
      });
    } on ApiKeyMissingException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Özet oluşturulurken bir hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Panoya kopyalandı!'),
        backgroundColor: const Color(0xFF5A4EE3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'AI Özetleme',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Document Selector or Active Doc card
            _buildHeaderSelector(),

            // Content Area
            Expanded(
              child: _isLoading
                  ? _buildLoadingWidget()
                  : _errorMessage != null
                      ? _buildErrorWidget()
                      : _summaryText == null
                          ? _buildEmptyStateWidget()
                          : Column(
                              children: [
                                _buildTabBar(),
                                Expanded(child: _buildTabBarView()),
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSelector() {
    final primaryPurple = const Color(0xFF5A4EE3);
    final documents = _documentService.documents;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFF5A4EE3)),
          const SizedBox(width: 8),
          const Text(
            'Özetlenen Belge:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DocumentItem?>(
                value: _selectedDocument,
                hint: const Text(
                  'Bir belge seçin...',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                isExpanded: true,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                items: [
                  ...documents.map((doc) {
                    IconData iconData = Icons.description_rounded;
                    if (doc.type == 'pdf') {
                      iconData = Icons.picture_as_pdf_rounded;
                    } else if (doc.type == 'image') {
                      iconData = Icons.image_rounded;
                    }
                    
                    return DropdownMenuItem<DocumentItem?>(
                      value: doc,
                      child: Row(
                        children: [
                          Icon(iconData, size: 16, color: primaryPurple),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              doc.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (_selectedDocument != null && !documents.contains(_selectedDocument))
                    DropdownMenuItem<DocumentItem?>(
                      value: _selectedDocument,
                      child: Row(
                        children: [
                          Icon(
                            _selectedDocument!.type == 'pdf'
                                ? Icons.picture_as_pdf_rounded
                                : _selectedDocument!.type == 'image'
                                    ? Icons.image_rounded
                                    : Icons.description_rounded,
                            size: 16,
                            color: primaryPurple,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _selectedDocument!.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                onChanged: _isLoading
                    ? null
                    : (doc) {
                        setState(() {
                          _selectedDocument = doc;
                        });
                        _generateSummary();
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF5A4EE3)),
            const SizedBox(height: 24),
            Text(
              'Yapay Zeka belgenizi okuyor...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bu işlem belgenizin boyutuna göre birkaç saniye sürebilir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber,
              size: 56,
            ),
            const SizedBox(height: 16),
            const Text(
              'Hata Oluştu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _generateSummary,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A4EE3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.summarize_rounded,
                color: Color(0xFF94A3B8),
                size: 56,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belge Seçilmedi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Yapay zeka ile özet oluşturmak için üst menüden bir belge seçin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final primaryPurple = const Color(0xFF5A4EE3);
    
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: primaryPurple,
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: primaryPurple,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [
          Tab(text: 'Özet'),
          Tab(text: 'Çıkarımlar'),
          Tab(text: 'Kartlar'),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSummaryTab(),
        _buildTakeawaysTab(),
        _buildFlashcardsTab(),
      ],
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'AI Genel Özet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF64748B)),
                      tooltip: 'Metni Kopyala',
                      onPressed: () => _copyToClipboard(_summaryText ?? ''),
                    ),
                  ],
                ),
                const Divider(height: 20, color: Color(0xFFE2E8F0)),
                Text(
                  _summaryText ?? '',
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.6,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTakeawaysTab() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: _takeaways.length,
      itemBuilder: (context, index) {
        final takeaway = _takeaways[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFEDEBF7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Color(0xFF5A4EE3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  takeaway,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFlashcardsTab() {
    if (_flashcards.isEmpty) {
      return const Center(child: Text('Çalışma kartı bulunamadı.'));
    }

    final card = _flashcards[_currentCardIndex];
    final primaryPurple = const Color(0xFF5A4EE3);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Counter
          Text(
            '${_currentCardIndex + 1} / ${_flashcards.length}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          
          // Flashcard layout
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showAnswer = !_showAnswer;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _showAnswer ? const Color(0xFFEDEBF7) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _showAnswer ? primaryPurple.withOpacity(0.3) : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _showAnswer ? Icons.visibility_rounded : Icons.quiz_rounded,
                      color: _showAnswer ? primaryPurple : const Color(0xFF94A3B8),
                      size: 32,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _showAnswer ? 'CEVAP' : 'SORU',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _showAnswer ? primaryPurple : const Color(0xFF94A3B8),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _showAnswer ? card['answer']! : card['question']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.bold,
                        color: _showAnswer ? const Color(0xFF5A4EE3) : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _showAnswer ? 'Soruya dönmek için dokunun' : 'Cevabı görmek için dokunun',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _currentCardIndex > 0
                    ? () {
                        setState(() {
                          _currentCardIndex--;
                          _showAnswer = false;
                        });
                      }
                    : null,
                icon: const Icon(Icons.arrow_back_ios_rounded),
                color: primaryPurple,
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showAnswer = !_showAnswer;
                  });
                },
                icon: Icon(_showAnswer ? Icons.flip_to_back_rounded : Icons.flip_to_front_rounded),
                label: Text(_showAnswer ? 'Soruyu Gör' : 'Cevabı Gör'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
                ),
              ),
              IconButton(
                onPressed: _currentCardIndex < _flashcards.length - 1
                    ? () {
                        setState(() {
                          _currentCardIndex++;
                          _showAnswer = false;
                        });
                      }
                    : null,
                icon: const Icon(Icons.arrow_forward_ios_rounded),
                color: primaryPurple,
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
