class AppSettings {
  final bool isDarkMode;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;
  final String language;
  final String currency;
  final bool biometricAuth;
  final bool autoSync;
  final bool offlineMode;
  final int cacheDuration; // in days
  final bool highQualityImages;
  final bool savePaymentMethods;
  final bool showTutorial;

  const AppSettings({
    this.isDarkMode = false,
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.smsNotifications = false,
    this.language = 'en',
    this.currency = 'USD',
    this.biometricAuth = false,
    this.autoSync = true,
    this.offlineMode = true,
    this.cacheDuration = 7,
    this.highQualityImages = false,
    this.savePaymentMethods = false,
    this.showTutorial = true,
  });

  // Convert model to map
  Map<String, dynamic> toMap() {
    return {
      'isDarkMode': isDarkMode,
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'smsNotifications': smsNotifications,
      'language': language,
      'currency': currency,
      'biometricAuth': biometricAuth,
      'autoSync': autoSync,
      'offlineMode': offlineMode,
      'cacheDuration': cacheDuration,
      'highQualityImages': highQualityImages,
      'savePaymentMethods': savePaymentMethods,
      'showTutorial': showTutorial,
    };
  }

  // Create model from map
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      isDarkMode: map['isDarkMode'] ?? false,
      pushNotifications: map['pushNotifications'] ?? true,
      emailNotifications: map['emailNotifications'] ?? true,
      smsNotifications: map['smsNotifications'] ?? false,
      language: map['language'] ?? 'en',
      currency: map['currency'] ?? 'USD',
      biometricAuth: map['biometricAuth'] ?? false,
      autoSync: map['autoSync'] ?? true,
      offlineMode: map['offlineMode'] ?? true,
      cacheDuration: map['cacheDuration'] ?? 7,
      highQualityImages: map['highQualityImages'] ?? false,
      savePaymentMethods: map['savePaymentMethods'] ?? false,
      showTutorial: map['showTutorial'] ?? true,
    );
  }

  // Create copy with method for updates
  AppSettings copyWith({
    bool? isDarkMode,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? smsNotifications,
    String? language,
    String? currency,
    bool? biometricAuth,
    bool? autoSync,
    bool? offlineMode,
    int? cacheDuration,
    bool? highQualityImages,
    bool? savePaymentMethods,
    bool? showTutorial,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      language: language ?? this.language,
      currency: currency ?? this.currency,
      biometricAuth: biometricAuth ?? this.biometricAuth,
      autoSync: autoSync ?? this.autoSync,
      offlineMode: offlineMode ?? this.offlineMode,
      cacheDuration: cacheDuration ?? this.cacheDuration,
      highQualityImages: highQualityImages ?? this.highQualityImages,
      savePaymentMethods: savePaymentMethods ?? this.savePaymentMethods,
      showTutorial: showTutorial ?? this.showTutorial,
    );
  }
}