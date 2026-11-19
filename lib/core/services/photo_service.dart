import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Photo choisie par l'utilisateur (appareil photo ou galerie).
class PickedPhoto {
  const PickedPhoto({
    required this.bytes,
    required this.name,
    required this.sizeLabel,
  });

  final Uint8List bytes;
  final String name;
  final String sizeLabel;

  int get sizeInBytes => bytes.length;
}

class PhotoTooLargeException implements Exception {
  const PhotoTooLargeException(this.maxMegabytes);

  final int maxMegabytes;

  @override
  String toString() =>
      'La photo dépasse la taille maximale de $maxMegabytes Mo.';
}

/// Sélection de photos avec compression légère et contrôle de taille.
class PhotoService {
  PhotoService._();

  static final ImagePicker _picker = ImagePicker();

  static const int maxBytes = 5 * 1024 * 1024;

  static Future<PickedPhoto?> pick({required ImageSource source}) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    if (bytes.length > maxBytes) {
      throw const PhotoTooLargeException(5);
    }

    return PickedPhoto(
      bytes: bytes,
      name: file.name.isNotEmpty ? file.name : 'photo_finds.jpg',
      sizeLabel: formatBytes(bytes.length),
    );
  }

  static String formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} Ko';
    }
    return '$bytes octets';
  }
}
