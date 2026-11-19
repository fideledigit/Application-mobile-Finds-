import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

/// Service d'upload d'images vers le backend (/api/upload-mobile)
/// Utilisé pour les déclarations avec photos (hébergées sur CDN UploadThing).
class PhotoUploadService {
  PhotoUploadService._();

  /// Envoie une image sur le serveur via multipart/form-data (/api/upload-mobile)
  /// Retourne l'URL publique hébergée (sur UploadThing CDN) ou null en cas d'erreur.
  static Future<String?> uploadImageFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final filename = file.path.split(Platform.pathSeparator).last;
      return uploadImageBytes(bytes, filename: filename);
    } catch (e) {
      debugPrint('[PhotoUploadService] Erreur lecture fichier: $e');
      return null;
    }
  }

  /// Envoie des octets d'image (compatible Uint8List / mémoire)
  static Future<String?> uploadImageBytes(
    Uint8List bytes, {
    String filename = 'photo.jpg',
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.uploadEndpoint);
      final client = HttpClient();
      final httpRequest = await client.postUrl(uri);

      final boundary =
          '----FindsBoundary${DateTime.now().millisecondsSinceEpoch}';
      httpRequest.headers.set(
        'Content-Type',
        'multipart/form-data; boundary=$boundary',
      );

      final ext = filename.split('.').last.toLowerCase();
      final mimeType = ext == 'png'
          ? 'image/png'
          : ext == 'webp'
          ? 'image/webp'
          : 'image/jpeg';

      final header =
          '--$boundary\r\n'
          'Content-Disposition: form-data; name="file"; filename="$filename"\r\n'
          'Content-Type: $mimeType\r\n\r\n';
      final footer = '\r\n--$boundary--\r\n';

      httpRequest.add(utf8.encode(header));
      httpRequest.add(bytes);
      httpRequest.add(utf8.encode(footer));

      final response = await httpRequest.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(responseBody);
        if (data['success'] == true && data['url'] != null) {
          debugPrint('[PhotoUploadService] Upload réussi : ${data['url']}');
          return data['url'] as String;
        }
      }
      debugPrint(
        '[PhotoUploadService] Échec upload (${response.statusCode}): $responseBody',
      );
      return null;
    } catch (e) {
      debugPrint('[PhotoUploadService] Exception upload: $e');
      return null;
    }
  }
}
