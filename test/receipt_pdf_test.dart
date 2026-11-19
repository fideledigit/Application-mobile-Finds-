import 'package:finds/core/services/receipt_pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('génère un récépissé PDF valide avec les accents', () async {
    final bytes = await ReceiptPdfService.build(
      const ReceiptData(
        reference: 'DEC-12345',
        category: 'PERDU',
        documentType: 'Carte nationale d\'identité',
        documentNumber: '•••• 42',
        holderName: 'Ama Koffi',
        eventDate: '12/10/2026',
        eventLocation: 'Lomé, quartier Bè',
        description: 'Perdue lors d\'un déplacement.',
        contactMethod: 'masked_phone',
        declarantName: 'Ama Koffi',
      ),
    );

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
