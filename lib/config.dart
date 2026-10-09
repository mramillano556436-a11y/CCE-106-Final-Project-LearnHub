/// App-wide settings. Keep secrets (like the Cloudinary API secret) out of
/// this file: everything here ships inside the app.
class AppConfig {
  /// The Google/Gmail account that is treated as the platform admin.
  /// Must match ADMIN_EMAIL in firestore.rules.
  static const adminEmail = 'ramillanomarky@gmail.com';

  /// Cloudinary cloud name and *unsigned* upload preset.
  static const cloudinaryCloudName = 'gwq8acdk';
  static const cloudinaryUploadPreset = 'leanrhub';

  /// Platform fee: 5% (1/20) of each payment, rounded down to the centavo.
  static const platformFeeDivisor = 20;

  static bool isAdminEmail(String? email) =>
      email != null && email.trim().toLowerCase() == adminEmail;
}
