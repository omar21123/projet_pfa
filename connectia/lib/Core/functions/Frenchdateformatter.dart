const List<String> _frenchMonthsAbbrev = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

/// Formate une date en français abrégé, ex: "22 juil. 2026".
/// Volontairement sans dépendance sur `intl` — si le package est déjà
/// utilisé ailleurs dans le projet, remplacer par
/// `DateFormat('d MMM y', 'fr_FR').format(date)`.
String formatFrenchDate(DateTime date) {
  final month = _frenchMonthsAbbrev[date.month - 1];
  return '${date.day} $month ${date.year}';
}