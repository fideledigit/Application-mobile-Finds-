import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Fiche détail d'un document affichée depuis la recherche.
///
/// Montre le document de façon claire (type, statut, titulaire, lieu, date,
/// numéro masqué, photo floutée), explique ce qui se passe ensuite et propose
/// l'action inverse : « Je l'ai trouvé » sur une perte, « C'est le mien » sur
/// une découverte.
class DocumentDetailSheet extends StatelessWidget {
  const DocumentDetailSheet({
    super.key,
    required this.doc,
    required this.onDeclare,
    this.onContact,
  });

  final Map<String, dynamic> doc;
  final VoidCallback onDeclare;

  /// Ouvre la messagerie avec la personne à l'origine de l'annonce.
  /// `null` quand l'action n'est pas disponible (document déjà restitué).
  final VoidCallback? onContact;

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> doc,
    required VoidCallback onDeclare,
    VoidCallback? onContact,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DocumentDetailSheet(
        doc: doc,
        onDeclare: onDeclare,
        onContact: onContact,
      ),
    );
  }

  bool get _isLost => doc['category'] == 'lost';
  String? get _statut => doc['statut'] as String?;
  bool get _isResolved => _statut == 'RESOLUE';
  bool get _isMatched => _statut == 'MATCHEE';
  int get _matchesCount => (doc['matchesCount'] as num?)?.toInt() ?? 0;

  Color get _accent => _isLost ? AppColors.errorDark : AppColors.primary;
  Color get _accentSoft =>
      _isLost ? AppColors.errorSoft : AppColors.primarySoft;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Bouton fermer, seul sur sa ligne pour ne pas serrer le titre.
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Fermer',
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.inputFill,
                ),
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: AppColors.textSubtle,
                ),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  if (_isResolved || _isMatched) ...[
                    const SizedBox(height: 20),
                    _buildStatusBanner(),
                  ],
                  if (_photoUrl != null) ...[
                    const SizedBox(height: 20),
                    _buildPhoto(),
                  ],
                  const SizedBox(height: 28),
                  _buildOwnerCard(),
                  const SizedBox(height: 24),
                  _sectionTitle('Détails du document'),
                  _buildInfoCard(),
                  const SizedBox(height: 24),
                  _buildSafetyNote(),
                ],
              ),
            ),
          ),
          _buildActions(context),
        ],
      ),
    );
  }

  // ── En-tête ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final timeAgo = (doc['timeAgo'] as String? ?? '');
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _accentSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(_documentIcon, color: _accent, size: 30),
        ),
        const SizedBox(height: 16),
        Text(
          doc['type'] as String? ?? 'Document',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            height: 1.25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: AppColors.textStrong,
          ),
        ),
        if (timeAgo.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '${_isLost ? 'Signalé perdu' : 'Signalé trouvé'} '
            '${timeAgo.toLowerCase()}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSubtle),
          ),
        ],
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _pill(
              _isLost ? 'PERDU' : 'TROUVÉ',
              _accentSoft,
              _accent,
              icon: _isLost
                  ? Icons.report_gmailerrorred_rounded
                  : Icons.verified_rounded,
            ),
            _pill(
              doc['badge'] as String? ?? '',
              AppColors.chipBackground,
              AppColors.textBody,
            ),
            if (_matchesCount > 0 && !_isResolved)
              _pill(
                _matchesCount == 1
                    ? '1 correspondance trouvée'
                    : '$_matchesCount correspondances trouvées',
                AppColors.infoSoft,
                AppColors.infoDark,
                icon: Icons.bolt_rounded,
              ),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11.5,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w800,
          color: AppColors.textSubtle,
        ),
      ),
    );
  }

  Widget _pill(String text, Color bg, Color fg, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bandeau de statut ─────────────────────────────────────────────────────

  Widget _buildStatusBanner() {
    final resolved = _isResolved;
    final color = resolved ? AppColors.successDeep : AppColors.infoDark;
    final bg = resolved ? AppColors.primarySoft : AppColors.infoSoft;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            resolved ? Icons.task_alt_rounded : Icons.sync_alt_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              resolved
                  ? 'Ce document a déjà été restitué à son propriétaire. '
                        'Aucune action n\'est nécessaire.'
                  : 'Une correspondance est déjà en cours de vérification '
                        'pour ce document. Vous pouvez tout de même déclarer '
                        'si vous êtes concerné.',
              style: TextStyle(fontSize: 13, height: 1.45, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // ── Photo floutée ─────────────────────────────────────────────────────────

  String? get _photoUrl {
    final url = doc['photoFlouteeUrl'] as String?;
    if (url == null || !url.startsWith('http')) return null;
    return url;
  }

  Widget _buildPhoto() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              _photoUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : Container(color: AppColors.inputFill),
              errorBuilder: (_, _, _) => Container(
                color: AppColors.inputFill,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.textSubtle,
                ),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.blur_on_rounded, size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Photo floutée',
                      style: TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Titulaire du document ─────────────────────────────────────────────────

  Widget _buildOwnerCard() {
    final name = (doc['name'] as String? ?? '').trim();
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _accentSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _accent,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _isLost
                            ? 'TITULAIRE DU DOCUMENT'
                            : 'DOCUMENT AU NOM DE',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSubtle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  name.isEmpty ? 'Nom non renseigné' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textStrong,
                  ),
                ),
                if (!_isLost) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Annonce publiée par la personne qui l\'a trouvé',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: AppColors.textSubtle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Informations ──────────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    final description = (doc['description'] as String? ?? '').trim();
    final place = doc['place'] as String? ?? '';
    final date = _formattedDate;

    final rows = <Widget>[
      _infoRow(
        Icons.lock_rounded,
        'Numéro du document',
        doc['maskedNumber'] as String,
        hint: 'Masqué pour protéger le titulaire',
      ),
      _infoRow(
        Icons.location_on_rounded,
        _isLost ? 'Lieu de la perte' : 'Lieu de la découverte',
        place.isEmpty ? 'Non précisé' : place,
      ),
      if (date != null)
        _infoRow(Icons.event_rounded, 'Date de signalement', date),
      if (description.isNotEmpty)
        _infoRow(Icons.notes_rounded, 'Description', description),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: 64,
                endIndent: 16,
                color: AppColors.divider,
              ),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSubtle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.4,
                    color: AppColors.textStrong,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSubtle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Note de sécurité ──────────────────────────────────────────────────────

  Widget _buildSafetyNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 18, color: Color(0xFF8A5A00)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pour votre sécurité, ne communiquez jamais d\'argent ni vos '
              'informations personnelles en dehors de l\'application, et '
              'privilégiez un lieu public pour la remise.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: Color(0xFF6B4700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Widget _buildActions(BuildContext context) {
    final label = _isResolved
        ? 'Document déjà restitué'
        : _isLost
        ? 'Je l\'ai trouvé'
        : 'C\'est mon document';
    final sub = _isLost ? 'Déclarer la découverte' : 'Déclarer la perte';
    final canContact = !_isResolved && onContact != null;
    final contactLabel = _isLost
        ? 'Contacter le propriétaire'
        : 'Contacter la personne qui l\'a trouvé';

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _isResolved
                ? null
                : () {
                    Navigator.of(context).pop();
                    onDeclare();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.chipBackground,
              disabledForegroundColor: AppColors.textSubtle,
              minimumSize: const Size.fromHeight(58),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isResolved
                      ? Icons.task_alt_rounded
                      : _isLost
                      ? Icons.volunteer_activism_rounded
                      : Icons.badge_rounded,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (!_isResolved)
                        Text(
                          sub,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!_isResolved) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ],
            ),
          ),
          if (canContact) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onContact!();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(52),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.45),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.forum_rounded, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      contactLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSubtle,
              minimumSize: const Size.fromHeight(44),
            ),
            child: Text(
              _isResolved ? 'Fermer' : 'Ce n\'est pas le bon document',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Utilitaires ───────────────────────────────────────────────────────────

  IconData get _documentIcon {
    switch (doc['typeDocument'] as String?) {
      case 'PASSEPORT':
        return Icons.menu_book_rounded;
      case 'PERMIS_CONDUIRE':
      case 'CARTE_GRISE':
        return Icons.directions_car_rounded;
      case 'CARTE_ETUDIANT':
        return Icons.school_rounded;
      case 'CARTE_PROFESSIONNELLE':
        return Icons.work_rounded;
      case 'ACTE_NAISSANCE':
      case 'CERTIFICAT_NATIONALITE':
        return Icons.description_rounded;
      default:
        return Icons.badge_rounded;
    }
  }

  String? get _formattedDate {
    final iso = doc['createdAt'] as String?;
    final d = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
    if (d == null) return null;
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year} à ${hh}h$mm';
  }
}
