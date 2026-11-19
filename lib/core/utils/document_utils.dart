/// Masque un numéro de document : seuls les 2 premiers et 3 derniers
/// caractères restent visibles (ex. « TG•••••483 »).
String maskDocumentNumber(String? number) {
  final n = (number ?? '').replaceAll(RegExp(r'\s+'), '');
  if (n.isEmpty) return 'Numéro non renseigné';
  if (n.length <= 5) return '•' * n.length;
  final hidden = '•' * (n.length - 5);
  return '${n.substring(0, 2)}$hidden${n.substring(n.length - 3)}';
}

/// Libellé lisible d'une valeur de l'enum GraphQL `TypeDocument`.
String documentTypeLabel(String? type) {
  switch (type) {
    case 'CNI':
      return 'Carte Nationale d\'Identité (CNI)';
    case 'PASSEPORT':
      return 'Passeport';
    case 'PERMIS_CONDUIRE':
      return 'Permis de conduire';
    case 'CARTE_GRISE':
      return 'Carte grise';
    case 'CARTE_ETUDIANT':
      return 'Carte étudiant';
    case 'CARTE_PROFESSIONNELLE':
      return 'Carte professionnelle';
    case 'ACTE_NAISSANCE':
      return 'Acte de naissance';
    case 'CARTE_CONSULAIRE':
      return 'Carte consulaire';
    case 'CERTIFICAT_NATIONALITE':
      return 'Certificat de nationalité';
    default:
      return 'Autre document';
  }
}

/// Sépare « Ville, Quartier » (format du sélecteur de villes) pour l'API.
({String ville, String? quartier}) splitPlace(String text) {
  final t = text.trim();
  if (t.isEmpty) return (ville: 'Lomé', quartier: null);
  final i = t.indexOf(',');
  if (i < 0) return (ville: t, quartier: null);
  final ville = t.substring(0, i).trim();
  final quartier = t.substring(i + 1).trim();
  return (
    ville: ville.isEmpty ? 'Lomé' : ville,
    quartier: quartier.isEmpty ? null : quartier,
  );
}

/// Convertit l'enum API `TypeDocument` vers les codes des formulaires
/// de déclaration (CNI, PASSPORT, PERMIS, STUDENT, GRISE, AUTRE).
String formDocumentTypeFromApi(String? type) {
  switch (type) {
    case 'CNI':
      return 'CNI';
    case 'PASSEPORT':
      return 'PASSPORT';
    case 'PERMIS_CONDUIRE':
      return 'PERMIS';
    case 'CARTE_ETUDIANT':
      return 'STUDENT';
    case 'CARTE_GRISE':
      return 'GRISE';
    default:
      return 'AUTRE';
  }
}

/// Libellé court pour les étiquettes (cartes de résultats, puces).
String documentTypeShortLabel(String? type) {
  switch (type) {
    case 'CNI':
      return 'CNI';
    case 'PASSEPORT':
      return 'Passeport';
    case 'PERMIS_CONDUIRE':
      return 'Permis';
    case 'CARTE_GRISE':
      return 'Carte grise';
    case 'CARTE_ETUDIANT':
      return 'Carte étudiant';
    case 'CARTE_PROFESSIONNELLE':
      return 'Carte pro';
    case 'ACTE_NAISSANCE':
      return 'Acte naiss.';
    case 'CARTE_CONSULAIRE':
      return 'Consulaire';
    case 'CERTIFICAT_NATIONALITE':
      return 'Nationalité';
    default:
      return 'Autre';
  }
}
