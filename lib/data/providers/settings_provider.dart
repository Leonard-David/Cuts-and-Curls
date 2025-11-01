import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

class SettingsProvider with ChangeNotifier {
  AppSettings _settings = const AppSettings();
  bool _isLoading = false;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  // Initialize settings
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadSettings();
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load settings from shared preferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _settings = AppSettings(
      isDarkMode: prefs.getBool('isDarkMode') ?? false,
      pushNotifications: prefs.getBool('pushNotifications') ?? true,
      emailNotifications: prefs.getBool('emailNotifications') ?? true,
      smsNotifications: prefs.getBool('smsNotifications') ?? false,
      language: prefs.getString('language') ?? 'en',
      currency: prefs.getString('currency') ?? 'USD',
      biometricAuth: prefs.getBool('biometricAuth') ?? false,
      autoSync: prefs.getBool('autoSync') ?? true,
      offlineMode: prefs.getBool('offlineMode') ?? true,
      cacheDuration: prefs.getInt('cacheDuration') ?? 7,
      highQualityImages: prefs.getBool('highQualityImages') ?? false,
      savePaymentMethods: prefs.getBool('savePaymentMethods') ?? false,
      showTutorial: prefs.getBool('showTutorial') ?? true,
    );
    
    notifyListeners();
  }

  // Save settings to shared preferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('isDarkMode', _settings.isDarkMode);
    await prefs.setBool('pushNotifications', _settings.pushNotifications);
    await prefs.setBool('emailNotifications', _settings.emailNotifications);
    await prefs.setBool('smsNotifications', _settings.smsNotifications);
    await prefs.setString('language', _settings.language);
    await prefs.setString('currency', _settings.currency);
    await prefs.setBool('biometricAuth', _settings.biometricAuth);
    await prefs.setBool('autoSync', _settings.autoSync);
    await prefs.setBool('offlineMode', _settings.offlineMode);
    await prefs.setInt('cacheDuration', _settings.cacheDuration);
    await prefs.setBool('highQualityImages', _settings.highQualityImages);
    await prefs.setBool('savePaymentMethods', _settings.savePaymentMethods);
    await prefs.setBool('showTutorial', _settings.showTutorial);
  }

  // Update settings
  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();
    notifyListeners();
  }

  // Toggle dark mode
  Future<void> toggleDarkMode(bool value) async {
    _settings = _settings.copyWith(isDarkMode: value);
    await _saveSettings();
    notifyListeners();
  }

  // Toggle push notifications
  Future<void> togglePushNotifications(bool value) async {
    _settings = _settings.copyWith(pushNotifications: value);
    await _saveSettings();
    notifyListeners();
  }

  // Toggle biometric authentication
  Future<void> toggleBiometricAuth(bool value) async {
    _settings = _settings.copyWith(biometricAuth: value);
    await _saveSettings();
    notifyListeners();
  }

  // Change language
  Future<void> changeLanguage(String language) async {
    _settings = _settings.copyWith(language: language);
    await _saveSettings();
    notifyListeners();
  }

  // Change currency
  Future<void> changeCurrency(String currency) async {
    _settings = _settings.copyWith(currency: currency);
    await _saveSettings();
    notifyListeners();
  }

  // Clear all settings (reset to default)
  Future<void> resetToDefaults() async {
    _settings = const AppSettings();
    await _saveSettings();
    notifyListeners();
  }
}