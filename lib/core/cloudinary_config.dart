class CloudinaryConfig {
  static const cloudName = 'xo84avlq';
  static const uploadPreset = 'mend_unsigned';

  static bool get isConfigured =>
      cloudName != 'CLOUD_NAME' && uploadPreset != 'UNSIGNED_PRESET';
}