import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Données nécessaires à la génération d'un récépissé de déclaration Finds.
class ReceiptData {
  const ReceiptData({
    required this.reference,
    required this.category,
    required this.documentType,
    this.documentNumber = '',
    this.holderName = '',
    this.eventDate = '',
    this.eventLocation = '',
    this.description = '',
    this.contactMethod = '',
    this.declarantName = '',
  });

  /// Référence du dossier (ex: DEC-123456).
  final String reference;

  /// PERDU, TROUVE ou RESTITUE.
  final String category;
  final String documentType;
  final String documentNumber;
  final String holderName;
  final String eventDate;
  final String eventLocation;
  final String description;
  final String contactMethod;
  final String declarantName;

  String get categoryLabel {
    switch (category.toUpperCase()) {
      case 'PERDU':
        return 'Document perdu';
      case 'TROUVE':
        return 'Document trouvé';
      case 'RESTITUE':
        return 'Document restitué';
      default:
        return 'Déclaration';
    }
  }

  String get fileName {
    final safeRef = reference.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return 'recu_finds_$safeRef.pdf';
  }
}

/// Génère et partage le récépissé PDF officiel d'une déclaration.
class ReceiptPdfService {
  ReceiptPdfService._();

  static final PdfColor _primary = PdfColor.fromHex('2E7D32');
  static final PdfColor _dark = PdfColor.fromHex('1B1C1C');
  static final PdfColor _muted = PdfColor.fromHex('707A6C');
  static final PdfColor _soft = PdfColor.fromHex('F5F3F3');
  static final PdfColor _border = PdfColor.fromHex('E5E7EB');

  static pw.Font? _regularFont;
  static pw.Font? _boldFont;

  /// Charge les polices embarquées (accents, puces et apostrophes typographiques).
  static Future<void> _ensureFonts() async {
    if (_regularFont != null && _boldFont != null) return;
    final regular = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
    final bold = await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf');
    _regularFont = pw.Font.ttf(regular);
    _boldFont = pw.Font.ttf(bold);
  }

  /// Construit le PDF en mémoire.
  static Future<Uint8List> build(ReceiptData data) async {
    await _ensureFonts();

    final doc = pw.Document(
      title: 'Récépissé Finds ${data.reference}',
      author: 'Finds',
      subject: data.categoryLabel,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: pw.ThemeData.withFont(base: _regularFont, bold: _boldFont),
        build: (context) => [
          _buildHeader(data),
          pw.SizedBox(height: 24),
          pw.Text(
            'RÉCÉPISSÉ DE DÉCLARATION',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: _dark,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            data.categoryLabel,
            style: pw.TextStyle(fontSize: 12, color: _primary),
          ),
          pw.SizedBox(height: 18),
          _buildReferenceBox(data),
          pw.SizedBox(height: 18),
          _buildSection('Informations du document', [
            _row('Type de document', data.documentType),
            if (data.documentNumber.isNotEmpty)
              _row('Numéro (masqué)', data.documentNumber),
            if (data.holderName.isNotEmpty)
              _row('Titulaire présumé', data.holderName),
          ]),
          pw.SizedBox(height: 14),
          _buildSection('Circonstances', [
            if (data.eventDate.isNotEmpty)
              _row(
                data.category.toUpperCase() == 'PERDU'
                    ? 'Date de perte'
                    : 'Date de découverte',
                data.eventDate,
              ),
            if (data.eventLocation.isNotEmpty) _row('Lieu', data.eventLocation),
            if (data.description.isNotEmpty)
              _row('Précisions', data.description),
          ]),
          pw.SizedBox(height: 14),
          _buildSection('Contact & confidentialité', [
            _row('Mode de contact choisi', _contactLabel(data.contactMethod)),
            if (data.declarantName.isNotEmpty)
              _row('Déclarant', data.declarantName),
            _row('Confidentialité', 'Numéro de document partiellement masqué'),
          ]),
          pw.SizedBox(height: 22),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: _soft,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Déclaration certifiée sur l’honneur',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _primary,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Le déclarant certifie l’exactitude des informations fournies. '
                  'Ce récépissé atteste de l’enregistrement de la déclaration sur la '
                  'plateforme civique Finds. Il ne vaut pas titre de propriété du document.',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: _muted,
                    lineSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 28),
          pw.Divider(color: _border),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Finds • Plateforme civique',
                style: pw.TextStyle(fontSize: 9, color: _muted),
              ),
              pw.Text(
                'Généré le ${_formatDate(DateTime.now())}',
                style: pw.TextStyle(fontSize: 9, color: _muted),
              ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  /// Ouvre la feuille de partage Android/iOS avec le PDF généré.
  /// L'utilisateur peut alors l'enregistrer, l'imprimer ou l'envoyer.
  static Future<bool> share(ReceiptData data) async {
    final bytes = await build(data);
    return Printing.sharePdf(bytes: bytes, filename: data.fileName);
  }

  static pw.Widget _buildHeader(ReceiptData data) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 44,
          height: 44,
          decoration: pw.BoxDecoration(
            color: _primary,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Center(
            child: pw.Text(
              'F',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'FINDS',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: _primary,
                  letterSpacing: 1.5,
                ),
              ),
              pw.Text(
                'Retrouver. Restituer. Ensemble.',
                style: pw.TextStyle(fontSize: 10, color: _muted),
              ),
            ],
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('E8F5E9'),
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: pw.Text(
            data.reference,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _primary,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildReferenceBox(ReceiptData data) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RÉFÉRENCE DU DOSSIER',
                style: pw.TextStyle(fontSize: 8, color: _muted),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                data.reference,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: _dark,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'STATUT',
                style: pw.TextStyle(fontSize: 8, color: _muted),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Enregistrée',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSection(String title, List<pw.Widget> rows) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _soft,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _primary,
              letterSpacing: 0.6,
            ),
          ),
          pw.SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  static pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 9.5, color: _muted),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                color: _dark,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _contactLabel(String method) {
    switch (method.toLowerCase()) {
      case 'internal':
        return 'Messagerie Finds';
      case 'masked_phone':
        return 'Numéro masqué';
      default:
        return method.isEmpty ? 'Messagerie Finds' : method;
    }
  }

  static String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }
}
