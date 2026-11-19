import 'package:url_launcher/url_launcher.dart';

/// Actions de partage externes (WhatsApp, e-mail).
class ShareService {
  ShareService._();

  /// Ouvre WhatsApp avec un message pré-rempli.
  ///
  /// On passe par `https://wa.me` (plutôt que le schéma `whatsapp://`) :
  /// le lien est intercepté par WhatsApp s'il est installé, sinon il s'ouvre
  /// dans le navigateur. Cela évite les problèmes de `queries` Android 11+.
  static Future<bool> shareOnWhatsApp(String message) {
    final uri = Uri.https('wa.me', '/', {'text': message});
    return _launch(uri);
  }

  /// Ouvre l'application e-mail avec un brouillon pré-rempli.
  static Future<bool> sendEmail({
    required String to,
    required String subject,
    required String body,
  }) {
    final uri = Uri(
      scheme: 'mailto',
      path: to,
      query:
          'subject=${Uri.encodeComponent(subject)}'
          '&body=${Uri.encodeComponent(body)}',
    );
    return _launch(uri);
  }

  static Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
