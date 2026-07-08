class ModerationService {
  // A simple list of inappropriate words for demonstration.
  // In a real app, this would be more comprehensive or use a third-party API.
  static const List<String> _profanityList = [
    'badword1',
    'badword2',
    'scam',
    'fraud',
    'fake',
    'hate',
    'abuse',
    // Add more words as needed
  ];

  static Map<String, dynamic> moderateContent(String text) {
    final lowercaseText = text.toLowerCase();
    final List<String> flaggedWords = [];

    for (final word in _profanityList) {
      if (lowercaseText.contains(word)) {
        flaggedWords.add(word);
      }
    }

    if (flaggedWords.isNotEmpty) {
      return {
        'status': 'flagged',
        'note': 'Contains inappropriate content: ${flaggedWords.join(', ')}',
      };
    }

    return {
      'status': 'approved',
      'note': null,
    };
  }
}
