import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lumina/services/ai_service.dart';
import 'package:lumina/services/document_service.dart';

class ChatPage extends StatefulWidget {
  final DocumentItem? initialDocument;

  const ChatPage({super.key, this.initialDocument});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DocumentService _documentService = DocumentService();
  final AiService _aiService = AiService();

  DocumentItem? _selectedDocument;
  ChatSession? _chatSession;
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDocument = widget.initialDocument;
    _initChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _messages.clear();
    });

    try {
      if (!_aiService.hasApiKey) {
        throw ApiKeyMissingException();
      }

      _chatSession = await _aiService.startChatSession(doc: _selectedDocument);
      
      // If we initialized history from the session (multimodal documents seed a message)
      if (_chatSession?.history != null && _chatSession!.history.isNotEmpty) {
        for (final content in _chatSession!.history) {
          if (content.role == 'user') {
            // Check if there is text in user message
            final text = content.parts.whereType<TextPart>().map((e) => e.text).join('\n');
            if (text.isNotEmpty && !text.startsWith('Sohbetimizi bu belgeye')) {
              _messages.add(_ChatMessage(text: text, isUser: true));
            }
          } else if (content.role == 'model') {
            final text = content.parts.whereType<TextPart>().map((e) => e.text).join('\n');
            if (text.isNotEmpty) {
              _messages.add(_ChatMessage(text: text, isUser: false));
            }
          }
        }
      }

      if (_messages.isEmpty) {
        if (_selectedDocument != null) {
          _messages.add(_ChatMessage(
            text: 'Merhaba! "${_selectedDocument!.name}" belgesini analiz ettim. Bu belgeyle ilgili ne sormak istersiniz?',
            isUser: false,
          ));
        } else {
          _messages.add(_ChatMessage(
            text: 'Merhaba! Ben Lumina öğrenme asistanıyım. Çalıştığınız konular hakkında bana sorular sorabilirsiniz.',
            isUser: false,
          ));
        }
      }
    } on ApiKeyMissingException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Sohbet başlatılırken bir hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatSession == null || _isLoading) return;

    _messageController.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _chatSession!.sendMessage(Content.text(text));
      if (response.text != null && response.text!.isNotEmpty) {
        setState(() {
          _messages.add(_ChatMessage(text: response.text!, isUser: false));
        });
      } else {
        setState(() {
          _messages.add(_ChatMessage(text: 'Maalesef yanıt oluşturulamadı.', isUser: false));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(text: 'Hata: Mesaj iletilemedi. ($e)', isUser: false));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _selectedDocument != null ? 'Belgeyle Sohbet' : 'Yapay Zekaya Sor',
          style: TextStyle(
            color: titleColor,
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
            // Document selector bar at the top
            _buildDocumentSelectorBar(),

            // Error display or Chat messages list
            Expanded(
              child: _errorMessage != null
                  ? _buildErrorWidget()
                  : _buildMessagesList(),
            ),

            // Message Input bar
            if (_errorMessage == null) _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentSelectorBar() {
    final primaryPurple = const Color(0xFF5A4EE3);
    final documents = _documentService.documents;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file_rounded, size: 18, color: Color(0xFF64748B)),
          const SizedBox(width: 8),
          const Text(
            'Bağlam:',
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
                  'Genel Sohbet (Belge Yok)',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
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
                  const DropdownMenuItem<DocumentItem?>(
                    value: null,
                    child: Text('Genel Sohbet (Belge Yok)'),
                  ),
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
                        _initChat();
                      },
              ),
            ),
          ),
        ],
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
              'API Yapılandırması Eksik',
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
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildLoadingBubble();
        }
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final primaryPurple = const Color(0xFF5A4EE3);
    
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser ? primaryPurple : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
          border: message.isUser 
              ? null 
              : Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 14.5,
            color: message.isUser ? Colors.white : const Color(0xFF1E293B),
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            _buildDot(1),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    final primaryPurple = const Color(0xFF5A4EE3);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: primaryPurple.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildInputBar() {
    final primaryPurple = const Color(0xFF5A4EE3);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              onSubmitted: (_) => _sendMessage(),
              style: const TextStyle(fontSize: 14.5, color: Color(0xFF1E293B)),
              decoration: InputDecoration(
                hintText: 'Bir şeyler sorun...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: primaryPurple,
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  _ChatMessage({required this.text, required this.isUser});
}
