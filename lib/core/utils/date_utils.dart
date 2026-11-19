/// Durée écoulée lisible : « Il y a 5 min », « Hier », « Il y a 3 semaines »,
/// « Il y a 7 mois », « Il y a 1 an »…
String relativeTime(String? iso, {DateTime? now}) {
  final date = iso == null ? null : DateTime.tryParse(iso);
  if (date == null) return '';
  final diff = (now ?? DateTime.now()).difference(date);

  if (diff.inMinutes < 1) return 'À l\'instant';
  if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';

  final days = diff.inDays;
  if (days == 1) return 'Hier';
  if (days < 7) return 'Il y a $days jours';
  if (days < 30) {
    final weeks = days ~/ 7;
    return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
  }
  if (days < 365) {
    final months = (days ~/ 30).clamp(1, 11);
    return 'Il y a $months mois';
  }
  final years = days ~/ 365;
  return 'Il y a $years an${years > 1 ? 's' : ''}';
}
