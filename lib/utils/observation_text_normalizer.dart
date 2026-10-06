// lib/utils/observation_text_normalizer.dart

/// Utilitaire de normalisation automatique du texte des observations.
///
/// Objectif :
/// Permettre à l'inspecteur d'écrire rapidement au kilomètre sans se soucier
/// de la première majuscule.
///
/// Règles :
/// - Chaque phrase saisie débute automatiquement par une majuscule.
/// - Conserve intactes les majuscules internes (ex. acronymes comme TGBT, HTA, DDR, IP2X, etc.).
/// - Gère la ponctuation de fin de phrase (. ! ?) et les retours à la ligne (\n) / listes à puces.
/// - Ignore les séparateurs décimaux (ex. 2.5 mm², 0.5 MΩ, 30 mA).
/// - Est strictement idempotente : normalize(normalize(x)) == normalize(x).
/// - N'altère pas les observations historiques lors d'une simple lecture.
class ObservationTextNormalizer {
  const ObservationTextNormalizer._();

  /// Normalise une chaîne d'observation en s'assurant que chaque début de phrase
  /// commence par une majuscule, sans toucher aux acronymes ni aux majuscules existantes.
  static String? normalize(String? input) {
    if (input == null) return null;
    if (input.isEmpty) return input;

    final buffer = StringBuffer();
    bool isStartOfSentence = true;

    for (int i = 0; i < input.length; i++) {
      final char = input[i];

      if (isStartOfSentence) {
        if (_isSentencePrefix(char)) {
          buffer.write(char);
          continue;
        } else if (_isLetter(char)) {
          buffer.write(char.toUpperCase());
          isStartOfSentence = false;
        } else {
          // Chiffre ou autre caractère débutant la phrase
          buffer.write(char);
          isStartOfSentence = false;
        }
      } else {
        buffer.write(char);

        // Détection de fin de phrase ou saut de ligne
        if (char == '!' || char == '?') {
          isStartOfSentence = true;
        } else if (char == '\n') {
          isStartOfSentence = true;
        } else if (char == '.') {
          // Vérifier si le point est un séparateur décimal (ex: 2.5 ou 0.03)
          final isDecimal = (i > 0 && i + 1 < input.length) &&
              _isDigit(input[i - 1]) &&
              _isDigit(input[i + 1]);
          if (!isDecimal) {
            isStartOfSentence = true;
          }
        }
      }
    }

    return buffer.toString();
  }

  static bool _isDigit(String char) {
    final code = char.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  static bool _isLetter(String char) {
    return RegExp(r'[a-zA-ZàâäéèêëîïôöùûüÿçœæÀÂÄÉÈÊËÎÏÔÖÙÛÜŸÇŒÆ]').hasMatch(char);
  }

  static bool _isSentencePrefix(String char) {
    return char == ' ' ||
        char == '\t' ||
        char == '\r' ||
        char == '\n' ||
        char == '-' ||
        char == '•' ||
        char == '*' ||
        char == '"' ||
        char == '«' ||
        char == '»' ||
        char == '(' ||
        char == '[';
  }
}

/// Fonction utilitaire de raccourci
String? normalizeObservationText(String? input) =>
    ObservationTextNormalizer.normalize(input);
