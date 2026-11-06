class CloudinaryConfig {
  static const cloudName = 'CLOUD_NAME';
  static const uploadPreset = 'UNSIGNED_PRESET';

  static bool get isConfigured =>
      cloudName != 'CLOUD_NAME' && uploadPreset != 'UNSIGNED_PRESET';
}