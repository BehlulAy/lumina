import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:lumina/services/document_service.dart';
import 'package:lumina/screens/summary_page.dart';
import 'package:lumina/screens/chat_page.dart';

class DocumentView extends StatefulWidget {
  final String documentName;
  final String documentType; // 'pdf', 'image', 'text'
  final String documentDate;
  final String? filePath;

  const DocumentView({
    super.key,
    required this.documentName,
    required this.documentType,
    required this.documentDate,
    this.filePath,
  });

  @override
  State<DocumentView> createState() => _DocumentViewState();
}

class _DocumentViewState extends State<DocumentView> {
  // Common states
  bool _isFavorite = false;

  // PDF specific states
  String? _pdfPath;
  bool _isPdfLoading = true;
  int _pdfTotalPages = 0;
  int _pdfCurrentPage = 0;
  bool _isPdfReady = false;
  String _pdfError = '';
  PDFViewController? _pdfViewController;

  // Text specific states
  double _textSize = 15.0;
  String? _fileTextContent;
  bool _isTextLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.documentType == 'pdf') {
      _initPdf();
    } else if (widget.documentType == 'text' && widget.filePath != null) {
      _readTextFile();
    } else if (widget.documentType == 'docx' && widget.filePath != null) {
      _readDocxFile();
    }
  }

  Future<void> _readTextFile() async {
    setState(() {
      _isTextLoading = true;
    });
    try {
      final file = File(widget.filePath!);
      if (await file.exists()) {
        final content = await file.readAsString();
        setState(() {
          _fileTextContent = content;
          _isTextLoading = false;
        });
      } else {
        setState(() {
          _fileTextContent = 'Dosya bulunamadı.';
          _isTextLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _fileTextContent = 'Metin dosyası okunurken hata: $e';
        _isTextLoading = false;
      });
    }
  }

  Future<void> _readDocxFile() async {
    setState(() {
      _isTextLoading = true;
    });
    try {
      final file = File(widget.filePath!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        String? docXmlText;
        
        for (final fileEntry in archive) {
          if (fileEntry.name == 'word/document.xml') {
            final contentBytes = fileEntry.content as List<int>;
            docXmlText = utf8.decode(contentBytes);
            break;
          }
        }
        
        if (docXmlText != null) {
          final regExp = RegExp(r'<w:t[^>]*>(.*?)</w:t>');
          final matches = regExp.allMatches(docXmlText);
          final textBuffer = StringBuffer();
          
          for (final match in matches) {
            final text = match.group(1);
            if (text != null) {
              textBuffer.write(text
                  .replaceAll('&amp;', '&')
                  .replaceAll('&lt;', '<')
                  .replaceAll('&gt;', '>')
                  .replaceAll('&quot;', '"')
                  .replaceAll('&apos;', "'"));
              textBuffer.write('\n\n'); // Add paragraph spacing
            }
          }
          
          setState(() {
            _fileTextContent = textBuffer.toString().trim();
            _isTextLoading = false;
          });
        } else {
          setState(() {
            _fileTextContent = 'Word döküman içeriği (document.xml) bulunamadı.';
            _isTextLoading = false;
          });
        }
      } else {
        setState(() {
          _fileTextContent = 'Dosya bulunamadı.';
          _isTextLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _fileTextContent = 'Word dökümanı okunurken hata: $e';
        _isTextLoading = false;
      });
    }
  }

  Future<void> _initPdf() async {
    setState(() {
      _isPdfLoading = true;
      _pdfError = '';
    });
    try {
      if (widget.filePath != null) {
        setState(() {
          _pdfPath = widget.filePath;
          _isPdfLoading = false;
        });
        return;
      }
      final tempDir = Directory.systemTemp;
      // Ensure file name is filesystem safe
      final safeName = widget.documentName
          .replaceAll(RegExp(r'[^\w\s\-]'), '')
          .replaceAll(' ', '_');
      final file = File('${tempDir.path}/$safeName.pdf');

      // Define dynamic title and lines based on documentName to simulate real content
      final title = widget.documentName;
      final List<String> lines = [
        'Ders Calisma Notlari',
        'Lumina Akilli Ogrenme Platformu',
        'Tarih: ${widget.documentDate}',
      ];

      if (title.contains('Limit')) {
        lines.addAll([
          '1. Limit Tanimi',
          'Bir fonksiyonun x degiskeni a sayisina yaklasirken',
          'f(x) fonksiyonunun aldigi limit degeridir.',
          'Formul: lim x->a f(x) = L',
          '',
          '2. Sag ve Sol Limitler',
          'Bir fonksiyonun limiti olmasi icin sagdan ve soldan',
          'limitlerinin esit olmasi gerekir.',
          'Sagdan Limit: lim x->a+ f(x) = L1',
          'Soldan Limit: lim x->a- f(x) = L2',
          'Eger L1 = L2 ise limit vardir ve degeri L1 dir.',
        ]);
      } else if (title.contains('Dalgalar')) {
        lines.addAll([
          '1. Temel Dalga Parametreleri',
          'Dalga Boyu (lambda): Iki dalga tepesi arasi mesafe.',
          'Frekans (f): Bir saniyedeki dalga sayisi (Hertz).',
          'Hiz (v): Dalganin yayilma hizidir.',
          'Formul: v = lambda * f',
          '',
          '2. Dalga Turleri',
          'Mekanik Dalgalar: Yayilmak icin ortama ihtiyac duyarlar.',
          'Elektromanyetik Dalgalar: Boslukta yayilabilirler.',
          'Enine Dalgalar: Titresim yonu yayilma yonune diktir.',
          'Boyuna Dalgalar: Titresim yonu yayilma yonune paraleldir.',
        ]);
      } else if (title.contains('Paragraf')) {
        lines.addAll([
          '1. Paragrafta Ana Dusunce',
          'Yazarin okuyucuya iletmek istedigi asil mesajdir.',
          'Genellikle giris veya sonuc cumlelerinde yer alir.',
          '',
          '2. Paragrafta Yardimci Dusunceler',
          'Ana dusunceyi destekleyen, aciklayan detaylardir.',
          'Soru koklerinde "deginilmemistir", "ulasilamaz"',
          'gibi olumsuz ifadelerle karsimiza cikar.',
          '',
          '3. Paragraf Cozme Taktikleri',
          '- Once soru kokunu ve secenekleri okuyun.',
          '- Anahtar kelimelerin altini cizin.',
          '- Paragrafi tarafsiz bir gozle okuyun.',
        ]);
      } else {
        lines.addAll([
          'Bu belge Lumina tarafindan olusturulmustur.',
          'Detayli icerik icin lutfen orijinal dosyayi kontrol edin.',
          'Dosya Tipi: PDF',
          'Olusturma Tarihi: ${widget.documentDate}',
        ]);
      }

      final bytes = SimplePdfGenerator.generate(title: title, lines: lines);
      await file.writeAsBytes(bytes);

      setState(() {
        _pdfPath = file.path;
        _isPdfLoading = false;
      });
    } catch (e) {
      setState(() {
        _pdfError = e.toString();
        _isPdfLoading = false;
      });
    }
  }

  void _showDocumentInfo() {
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
                  'Belge Bilgileri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  Icons.description_rounded,
                  'Belge Adı',
                  widget.documentName,
                ),
                _buildInfoRow(
                  Icons.category_rounded,
                  'Dosya Türü',
                  widget.documentType.toUpperCase(),
                ),
                _buildInfoRow(
                  Icons.calendar_month_rounded,
                  'Yükleme Tarihi',
                  widget.documentDate,
                ),
                _buildInfoRow(
                  Icons.sd_storage_rounded,
                  'Boyut',
                  _getFileSizeString(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Kapat',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getFileSizeString() {
    if (widget.filePath != null) {
      try {
        final file = File(widget.filePath!);
        if (file.existsSync()) {
          final bytes = file.lengthSync();
          if (bytes < 1024) {
            return '$bytes B';
          }
          if (bytes < 1024 * 1024) {
            return '${(bytes / 1024).toStringAsFixed(1)} KB';
          }
          return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
        }
      } catch (_) {}
    }
    return widget.documentType == 'pdf'
        ? '124 KB'
        : widget.documentType == 'image'
        ? '1.8 MB'
        : '4.2 KB';
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryPurple = const Color(0xFF5A4EE3);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Belge Görüntüleyici',
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
        actions: [
          // Text size controls if document is a text file
          if (widget.documentType == 'text') ...[
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline_rounded,
                color: Color(0xFF64748B),
              ),
              tooltip: 'Yazıyı Küçült',
              onPressed: () {
                if (_textSize > 10.0) {
                  setState(() => _textSize -= 1.5);
                }
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: Color(0xFF64748B),
              ),
              tooltip: 'Yazıyı Büyüt',
              onPressed: () {
                if (_textSize < 30.0) {
                  setState(() => _textSize += 1.5);
                }
              },
            ),
          ],
          IconButton(
            icon: Icon(
              _isFavorite
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_outline_rounded,
              color: _isFavorite ? primaryPurple : const Color(0xFF64748B),
            ),
            tooltip: 'Kaydet',
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isFavorite
                        ? 'Belge kaydedilenlere eklendi.'
                        : 'Belge kaydedilenlerden çıkarıldı.',
                  ),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF5A4EE3), // Purple accent for AI
            ),
            tooltip: 'AI ile Özetle',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SummaryPage(
                    initialDocument: DocumentItem(
                      name: widget.documentName,
                      date: widget.documentDate,
                      type: widget.documentType,
                      filePath: widget.filePath,
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Color(0xFF64748B),
            ),
            tooltip: 'AI ile Sohbet',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    initialDocument: DocumentItem(
                      name: widget.documentName,
                      date: widget.documentDate,
                      type: widget.documentType,
                      filePath: widget.filePath,
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF64748B),
            ),
            tooltip: 'Bilgi',
            onPressed: _showDocumentInfo,
          ),
        ],
      ),
      body: SafeArea(child: _buildDocumentBody()),
    );
  }

  Widget _buildDocumentBody() {
    switch (widget.documentType) {
      case 'pdf':
        return _buildPdfView();
      case 'image':
        return _buildImageView();
      case 'text':
        return _buildTextView();
      case 'docx':
        return _buildDocxView();
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: Colors.amber,
              ),
              const SizedBox(height: 16),
              Text('Desteklenmeyen Dosya Türü: ${widget.documentType}'),
            ],
          ),
        );
    }
  }

  Widget _buildDocxView() {
    if (_isTextLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: Color(0xFF5A4EE3)),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Word Document Page Layout resembling a real page sheet
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Word Header Title
                Text(
                  widget.documentName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    fontFamily: 'Georgia', // Serif font for Word document feel
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Yükleme Tarihi: ${widget.documentDate}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const Divider(height: 32, color: Color(0xFFE2E8F0)),
                
                // Document Body Content
                Text(
                  _fileTextContent != null && _fileTextContent!.isNotEmpty
                      ? _fileTextContent!
                      : '1. Giriş ve Amaç\n\nBu belge, Lumina akıllı öğrenme platformu üzerinde incelenmek üzere yüklenmiştir. Belge içeriği sisteme başarıyla kaydedilmiş olup, dökümanın yapısı analiz edilmiştir.\n\n2. Konu Başlıkları ve Özet\n\nYüklenen "${widget.documentName}" isimli döküman içerisindeki veriler, ders çalışma notları, soru çözümleri ve akademik özetler barındırmaktadır. AI asistanı ile bu başlıklar altındaki konuları detaylandırabilir, testler oluşturabilir veya özet çıkartabilirsiniz.\n\n3. Sonuç ve Değerlendirme\n\nMetin tabanlı içeriklerin tamamı yapay zeka analizine hazır durumdadır.',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Color(0xFF334155),
                    fontFamily: 'Georgia', // Serif font for Word document feel
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextView() {
    if (_isTextLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: Color(0xFF5A4EE3)),
        ),
      );
    }
    final title = widget.documentName;
    String heading = title;
    String bodyContent = '';

    if (_fileTextContent != null) {
      bodyContent = _fileTextContent!;
    } else if (title.contains('Kelime')) {
      heading = 'İngilizce Kelime Listesi';
      bodyContent = '''
1. Luminary (n.) /'luːmɪnəri/
• Anlamı: Işık kaynağı, önder, alanında tanınmış kimse.
• Örnek: She is a luminary in the field of artificial intelligence. (Yapay zeka alanında öncü bir şahasidir.)

2. Evocative (adj.) /ɪˈvɒkətɪv/
• Anlamı: Çağrıştıran, akla getiren, hisleri uyandıran.
• Örnek: The music was deeply evocative of his childhood. (Müzik, çocukluğunu derinden çağrıştırıyordu.)

3. Ephemeral (adj.) /ɪˈfemərəl/
• Anlamı: Geçici, ömrü kısa olan.
• Örnek: Fame in the internet age is often ephemeral. (İnternet çağında şöhret genellikle geçicidir.)

4. Sagacious (adj.) /səˈɡeɪʃəs/
• Anlamı: Öngörülü, akıllıca, bilgece.
• Örnek: The leader gave a sagacious speech. (Lider bilgece bir konuşma yaptı.)

5. Resilient (adj.) /rɪˈzɪliənt/
• Anlamı: Kendini çabuk toparlayan, esnek.
• Örnek: She is a resilient child who recovers quickly. (O, aksiliklerin üstesinden hızla gelen dirençli bir çocuktur.)
''';
    } else if (title.contains('Deney')) {
      heading = 'Kimya Deney Raporu';
      bodyContent = '''
DENEY ADI: Asit-Baz Titrasyonu
DENEY TARİHİ: 2026-06-15
RAPORU HAZIRLAYAN: Lumina Öğrencisi

1. AMAÇ
Bilinmeyen bir hidroklorik asit (HCl) çözeltisinin derişimini, standart bir sodyum hidroksit (NaOH) çözeltisi yardımıyla tam olarak belirlemek.

2. ARAÇ VE GEREÇLER
• Büret, Erlenmayer, Pipet (25 mL)
• Mezür, Balon joje
• Fenolftalein indikatörü
• Standart 0.1 M NaOH çözeltisi
• Derişimi bilinmeyen HCl çözeltisi

3. TEORİK BİLGİ
Asit ve bazların reaksiyona girerek tuz ve su oluşturmasına nötralleşme denir. Eşdeğerlik noktasında, asitten gelen H+ iyonlarının mol sayısı bazdan gelen OH- iyonlarının mol sayısına eşittir:
n(H+) = n(OH-) => M_asit * V_asit = M_baz * V_baz

4. GÖZLEMLER VE VERİLER
• Erlenmayere 25 mL HCl çözeltisi konuldu.
• 2-3 damla fenolftalein indikatörü damlatıldı (çözelti renksiz).
• Büret 0.1 M NaOH ile dolduruldu.
• Yavaş yavaş titrasyon yapıldı. Çözelti kalıcı açık pembe renge döndüğünde titrasyon durduruldu.
• Harcanan NaOH hacmi: 12.4 mL olarak ölçüldü.

5. HESAPLAMALAR VE SONUÇ
M_HCl * V_HCl = M_NaOH * V_NaOH
M_HCl * 25.0 mL = 0.1 M * 12.4 mL
M_HCl = (0.1 * 12.4) / 25.0 = 0.0496 M

Sonuç olarak, incelenen hidroklorik asit çözeltisinin derişimi 0.0496 M olarak tespit edilmiştir.
''';
    } else {
      bodyContent =
          '''
Belge Adı: $title
Tarih: ${widget.documentDate}
Dosya Türü: Yazı Dokümanı

Lumina Akıllı Doküman Okuyucuya Hoş Geldiniz!

Bu panel, yazı dosyalarınızı en yüksek okunabilirlikle görüntülemeniz için tasarlanmıştır. Yukarıdaki menüden yazı boyutunu ayarlayabilir, metni kaydedebilir veya not alabilirsiniz.

Lumina ders çalışma asistanı ile:
• Belgelerinizi özetleyebilirsiniz.
• Belgelerinizle alakalı yapay zekaya sorular sorabilirsiniz.
• Önemli kısımları işaretleyip çalışma kartları (flashcard) oluşturabilirsiniz.
''';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF92b29c).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.text_fields_rounded,
                    color: Color(0xFF92b29c),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        heading,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Metin Dosyası • ${widget.documentDate}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32, color: Color(0xFFE2E8F0)),
            Text(
              bodyContent,
              style: TextStyle(
                fontSize: _textSize,
                color: const Color(0xFF334155),
                height: 1.6,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageView() {
    final title = widget.documentName;
    String imageUrl =
        'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=800'; // Default books

    if (title.contains('Tarih')) {
      imageUrl =
          'https://images.unsplash.com/photo-1447069387593-a5de0862481e?w=800'; // History notes / old documents
    } else if (title.contains('Hücre') || title.contains('Biyoloji')) {
      imageUrl =
          'https://images.unsplash.com/photo-1530026405186-ed1ea0ac7a63?w=800'; // Cells
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF5d88b1).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.image_rounded,
                  color: Color(0xFF5d88b1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.documentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Görsel Doküman • ${widget.documentDate}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: widget.filePath != null && widget.filePath!.isNotEmpty
                  ? Image.file(
                      File(widget.filePath!),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFF1F5F9),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.broken_image_rounded,
                                size: 64,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.documentName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Görsel dosyası yerel depolamadan yüklenemedi.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            color: const Color(0xFF5A4EE3),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback beautiful graphic layout if offline or loading fails
                        return Container(
                          color: const Color(0xFFF1F5F9),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.broken_image_rounded,
                                size: 64,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.documentName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Görsel yüklenemedi. Çevrimdışı modda görsel şemalar simüle edilir.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              // Premium local graphic mock using container
                              Container(
                                width: double.infinity,
                                height: 180,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Center(
                                  child: Icon(
                                    title.contains('Tarih')
                                        ? Icons.menu_book_rounded
                                        : Icons.biotech_rounded,
                                    size: 48,
                                    color: const Color(0xFF5A4EE3).withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPdfView() {
    if (_isPdfLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5A4EE3)),
      );
    }

    if (_pdfError.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'PDF Yüklenirken Hata Oluştu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _pdfError,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfPath == null) {
      return const Center(child: Text('PDF Dosyası bulunamadı.'));
    }

    return Column(
      children: [
        // PDF Title and Info Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFe05d4b).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Color(0xFFe05d4b),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.documentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PDF Dokümanı • ${widget.documentDate}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // PDF Viewer container
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: PDFView(
              filePath: _pdfPath!,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              pageSnap: true,
              defaultPage: _pdfCurrentPage,
              fitPolicy: FitPolicy.WIDTH,
              preventLinkNavigation: false,
              onRender: (pages) {
                setState(() {
                  _pdfTotalPages = pages ?? 0;
                  _isPdfReady = true;
                });
              },
              onError: (error) {
                setState(() {
                  _pdfError = error.toString();
                });
              },
              onPageError: (page, error) {
                setState(() {
                  _pdfError = 'Sayfa $page hatası: $error';
                });
              },
              onViewCreated: (PDFViewController pdfViewController) {
                _pdfViewController = pdfViewController;
              },
              onPageChanged: (int? page, int? total) {
                setState(() {
                  _pdfCurrentPage = page ?? 0;
                });
              },
            ),
          ),
        ),
        // PDF navigation controls
        if (_isPdfReady && _pdfTotalPages > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0, left: 20, right: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: const Color(0xFF5A4EE3),
                    onPressed: _pdfCurrentPage > 0
                        ? () {
                            _pdfCurrentPage--;
                            _pdfViewController?.setPage(_pdfCurrentPage);
                          }
                        : null,
                  ),
                  Text(
                    'Sayfa ${_pdfCurrentPage + 1} / $_pdfTotalPages',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    color: const Color(0xFF5A4EE3),
                    onPressed: _pdfCurrentPage < _pdfTotalPages - 1
                        ? () {
                            _pdfCurrentPage++;
                            _pdfViewController?.setPage(_pdfCurrentPage);
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Simple PDF Generator class to write valid PDF bytes dynamically.
class SimplePdfGenerator {
  static Uint8List generate({
    required String title,
    required List<String> lines,
  }) {
    final buffer = BytesBuilder();

    void write(String s) {
      buffer.add(utf8.encode(s));
    }

    final offsets = <int>[];

    write('%PDF-1.4\n');

    void startObj(int id) {
      offsets.add(buffer.length);
      write('$id 0 obj\n');
    }

    // Obj 1: Catalog
    startObj(1);
    write('<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');

    // Obj 2: Pages
    startObj(2);
    write('<< /Type /Pages /Kids [3 0 R 4 0 R] /Count 2 >>\nendobj\n');

    // Obj 3: Page 1
    startObj(3);
    write(
      '<< /Type /Page /Parent 2 0 R /Resources << /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >> >> >> /MediaBox [0 0 595 842] /Contents 5 0 R >>\nendobj\n',
    );

    // Obj 4: Page 2
    startObj(4);
    write(
      '<< /Type /Page /Parent 2 0 R /Resources << /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> >> /MediaBox [0 0 595 842] /Contents 6 0 R >>\nendobj\n',
    );

    // Page 1 content stream
    final cleanTitle = title.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
    final page1Content =
        'BT\n/F1 24 Tf\n50 750 Td\n(LUMINA DERSE HAZIRLIK NOTLARI) Tj\n/F1 16 Tf\n0 -50 Td\n($cleanTitle) Tj\n/F1 12 Tf\n0 -40 Td\n(Asagidaki sayfaya gecmek icin saga/asagi kaydirin.) Tj\nET\n';
    final page1Bytes = utf8.encode(page1Content);
    startObj(5);
    write('<< /Length ${page1Bytes.length} >>\nstream\n');
    buffer.add(page1Bytes);
    write('\nendstream\nendobj\n');

    // Page 2 content stream
    final page2Buffer = StringBuffer();
    page2Buffer.write(
      'BT\n/F1 16 Tf\n50 750 Td\n(Konu Detaylari ve Calisma Ozeti) Tj\n/F1 12 Tf\n',
    );
    double yOffset = -40;
    for (final line in lines) {
      final asciiLine = line.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
      page2Buffer.write('0 $yOffset Td\n($asciiLine) Tj\n');
      yOffset = -22; // spacing
    }
    page2Buffer.write('ET\n');
    final page2Bytes = utf8.encode(page2Buffer.toString());

    startObj(6);
    write('<< /Length ${page2Bytes.length} >>\nstream\n');
    buffer.add(page2Bytes);
    write('\nendstream\nendobj\n');

    // Xref Table
    final xrefOffset = buffer.length;
    write('xref\n0 ${offsets.length + 1}\n0000000000 65535 f \n');
    for (final offset in offsets) {
      final pad = offset.toString().padLeft(10, '0');
      write('$pad 00000 n \n');
    }

    // Trailer
    write(
      'trailer\n<< /Size ${offsets.length + 1} /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF\n',
    );

    return buffer.toBytes();
  }
}
