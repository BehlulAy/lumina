import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/services/document_service.dart';

void main() {
  test('DocumentItem JSON serialization and deserialization test', () {
    final item = DocumentItem(
      name: 'Test Document',
      date: '2026-06-25 10:00',
      type: 'pdf',
      filePath: '/path/to/Test Document.pdf',
    );

    final jsonMap = item.toJson();
    expect(jsonMap['name'], 'Test Document');
    expect(jsonMap['date'], '2026-06-25 10:00');
    expect(jsonMap['type'], 'pdf');
    expect(jsonMap['filePath'], '/path/to/Test Document.pdf');

    final deserializedItem = DocumentItem.fromJson(jsonMap);
    expect(deserializedItem.name, 'Test Document');
    expect(deserializedItem.date, '2026-06-25 10:00');
    expect(deserializedItem.type, 'pdf');
    expect(deserializedItem.filePath, '/path/to/Test Document.pdf');
  });
}
