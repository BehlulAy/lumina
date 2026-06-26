import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lumina/config/api_config.dart';
import 'package:lumina/services/document_service.dart';
import 'package:archive/archive.dart';

class ApiKeyMissingException implements Exception {
  final String message;
  ApiKeyMissingException([this.message = 'Gemini API anahtarı bulunamadı. Lütfen "lib/config/api_config.dart" dosyasına geçerli bir API anahtarı ekleyin.']);
  
  @override
  String toString() => message;
}

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  String get _apiKey => ApiConfig.geminiApiKey.trim();

  bool get hasApiKey => _apiKey.isNotEmpty && _apiKey != 'YOUR_GEMINI_API_KEY_HERE';

  GenerativeModel _getModel({Content? systemInstruction}) {
    if (!hasApiKey) {
      throw ApiKeyMissingException();
    }
    return GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: systemInstruction,
    );
  }

  /// Helper to extract text from a Word document (.docx)
  Future<String> _extractDocxText(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return '';
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
            textBuffer.write(' ');
          }
        }
        return textBuffer.toString().trim();
      }
    } catch (e) {
      debugPrint('Error extracting text from docx: $e');
    }
    return '';
  }

  /// Helper to extract text from a plain text file (.txt)
  Future<String> _readTextFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      debugPrint('Error reading text file: $e');
    }
    return '';
  }

  /// Generates a structured summary of the given [DocumentItem].
  /// Returns a map containing:
  /// - 'summary': The general summary text.
  /// - 'takeaways': A list of key takeaways.
  /// - 'flashcards': A list of Map objects representing flashcards with 'question' and 'answer'.
  Future<Map<String, dynamic>> summarizeDocument(DocumentItem doc) async {
    if (!hasApiKey) {
      throw ApiKeyMissingException();
    }

    final systemPrompt = Content.system(
      'Sen akıllı bir eğitim asistanısın. Görevin, sana verilen belgeyi analiz etmek ve öğrencilerin çalışmasını kolaylaştırmak için Türkçe dilinde şu JSON yapısında çıktı üretmektir:\n'
      '{\n'
      '  "summary": "Belgenin ne hakkında olduğunu açıklayan akıcı, anlaşılır ve eğitici bir genel özet paragrafı.",\n'
      '  "takeaways": [\n'
      '    "Belgeden çıkarılacak en önemli 1. anahtar fikir veya bilgi.",\n'
      '    "Belgeden çıkarılacak en önemli 2. anahtar fikir veya bilgi.",\n'
      '    "..." \n'
      '  ],\n'
      '  "flashcards": [\n'
      '    {"question": "Önemli bir kavram veya konu hakkında soru?", "answer": "Bu sorunun belgedeki bilgilere dayanan net açıklaması."},\n'
      '    {"question": "...", "answer": "..."}\n'
      '  ]\n'
      '}\n'
      'NOT: Çıktı sadece bu JSON formatında olmalı, başında veya sonunda markdown kod blokları (```json ... ```) veya başka açıklama metinleri yer almamalıdır. JSON tamamen geçerli olmalıdır.'
    );

    final model = _getModel(systemInstruction: systemPrompt);
    final responseContent = await _generateContentWithDoc(model, doc, 'Lütfen bu belgeyi analiz et ve özetini çıkar.');
    
    if (responseContent == null) {
      throw Exception('Yapay zeka yanıt üretemedi.');
    }

    try {
      // Clean up response string if the model wrapped it in markdown code blocks
      var cleanJson = responseContent.trim();
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.substring(cleanJson.indexOf('\n') + 1);
      }
      if (cleanJson.endsWith('```')) {
        cleanJson = cleanJson.substring(0, cleanJson.lastIndexOf('```'));
      }
      cleanJson = cleanJson.trim();

      final parsed = json.decode(cleanJson) as Map<String, dynamic>;
      return parsed;
    } catch (e) {
      debugPrint('JSON parsing error of model response: $e\nResponse content: $responseContent');
      
      // Fallback parser if JSON fails
      return _generateFallbackSummary(responseContent);
    }
  }

  /// Helper to generate a fallback structure if the AI doesn't output valid JSON
  Map<String, dynamic> _generateFallbackSummary(String rawText) {
    return {
      'summary': rawText,
      'takeaways': [
        'Belge başarıyla analiz edildi.',
        'Detaylı çıkarımlar için lütfen içeriği kontrol edin.'
      ],
      'flashcards': [
        {
          'question': 'Bu belgenin ana konusu nedir?',
          'answer': 'Belge içeriği ana sayfada gösterilen özet bilgilerden oluşmaktadır.'
        }
      ]
    };
  }

  /// Helper to send document to Gemini either as text context or DataPart
  Future<String?> _generateContentWithDoc(GenerativeModel model, DocumentItem doc, String userPrompt) async {
    if (doc.filePath == null) {
      // No file path, just send prompt
      final response = await model.generateContent([Content.text(userPrompt)]);
      return response.text;
    }

    final file = File(doc.filePath!);
    if (!await file.exists()) {
      final response = await model.generateContent([Content.text(userPrompt)]);
      return response.text;
    }

    if (doc.type == 'text' || doc.type == 'docx') {
      final textContent = doc.type == 'text'
          ? await _readTextFile(doc.filePath!)
          : await _extractDocxText(doc.filePath!);

      final fullPrompt = 'Aşağıdaki belgenin içeriğini kullanarak soruyu cevapla:\n\n'
          '--- BELGE İÇERİĞİ ---\n'
          '$textContent\n'
          '---------------------\n\n'
          'Soru/Talep: $userPrompt';

      final response = await model.generateContent([Content.text(fullPrompt)]);
      return response.text;
    } else {
      // PDF or Image (multimodal)
      final bytes = await file.readAsBytes();
      String mimeType = 'application/pdf';
      if (doc.type == 'image') {
        final ext = doc.filePath!.split('.').last.toLowerCase();
        if (ext == 'png') {
          mimeType = 'image/png';
        } else if (ext == 'webp') {
          mimeType = 'image/webp';
        } else {
          mimeType = 'image/jpeg';
        }
      }

      final dataPart = DataPart(mimeType, bytes);
      final response = await model.generateContent([
        Content.multi([
          TextPart(userPrompt),
          dataPart,
        ])
      ]);
      return response.text;
    }
  }

  /// Creates a Chat session with Gemini model.
  /// If a [doc] is provided, it is sent as the initial context.
  Future<ChatSession> startChatSession({DocumentItem? doc}) async {
    String systemInstructionText = 'Sen Lumina öğrenme platformunun akıllı AI asistanısın. Kullanıcılara derslerinde yardımcı oluyorsun. Nazik, destekleyici ve eğitici bir dille Türkçe konuşmalısın.';
    
    if (doc != null && (doc.type == 'text' || doc.type == 'docx')) {
      final textContent = doc.type == 'text'
          ? await _readTextFile(doc.filePath!)
          : await _extractDocxText(doc.filePath!);

      systemInstructionText += '\n\nKullanıcı "${doc.name}" adlı bir belge üzerinde çalışıyor. Aşağıdaki belge içeriğini temel alarak sorularını cevaplamalısın:\n'
          '--- BELGE İÇERİĞİ ---\n'
          '$textContent\n'
          '---------------------\n';
    }

    final systemInstruction = Content.system(systemInstructionText);
    final model = _getModel(systemInstruction: systemInstruction);

    List<Content>? history;

    // For multimodal documents, we seed the chat history with the document
    if (doc != null && doc.filePath != null && doc.type != 'text' && doc.type != 'docx') {
      final file = File(doc.filePath!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        String mimeType = doc.type == 'pdf' ? 'application/pdf' : 'image/jpeg';
        final ext = doc.filePath!.split('.').last.toLowerCase();
        if (doc.type == 'image') {
          if (ext == 'png') {
            mimeType = 'image/png';
          } else if (ext == 'webp') {
            mimeType = 'image/webp';
          }
        }
        
        history = [
          Content.multi([
            TextPart('Sohbetimizi bu belgeye dayandıracağız. İşte belge:'),
            DataPart(mimeType, bytes),
          ]),
          Content.model([
            TextPart('"${doc.name}" belgesini başarıyla aldım ve analiz ettim. Bu belge hakkında ne sormak istersiniz? Size yardımcı olmaktan mutluluk duyarım.')
          ])
        ];
      }
    }

    return model.startChat(history: history);
  }
}
