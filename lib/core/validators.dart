/// Form validators. Each returns `null` when the value is valid,
/// otherwise a message is shown under the field.
class Validators {
  Validators._();

  static const allowedDomains = ['alustudent.com', 'alueducation.com'];
  static final _emailPattern = RegExp(r'^[^@\s]+@([^@\s]+)$');

  static bool isAluEmail(String value) {
    final match = _emailPattern.firstMatch(value.trim().toLowerCase());
    return match != null && allowedDomains.contains(match.group(1));
  }

  static String? aluEmail(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Enter your ALU email';
    if (!_emailPattern.hasMatch(v)) return 'That doesn\'t look like an email address';
    if (!isAluEmail(v)) return 'Use an @alustudent.com or @alueducation.com address';
    return null;
  }

  static String? name(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Enter your name';
    if (v.length < 2) return 'Name is too short';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'\d').hasMatch(v)) return 'Include at least one number';
    return null;
  }

  static String? signInPassword(String? value) =>
      (value ?? '').isEmpty ? 'Enter your password' : null;

  static String? Function(String?) confirmPassword(String Function() original) =>
      (value) => value != original() ? 'Passwords don\'t match' : null;

  static String? title(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Give the issue a short title';
    if (v.length < 5) return 'A few more words, please';
    if (v.length > 80) return 'Keep the title under 80 characters';
    return null;
  }

  static String? description(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Describe what happened';
    if (v.length < 10) return 'Add a little more detail';
    if (v.length > 500) return 'Keep it under 500 characters';
    return null;
  }

  static String? statusNote(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Add a note so reporters know what changed';
    if (v.length > 300) return 'Keep the note under 300 characters';
    return null;
  }
}