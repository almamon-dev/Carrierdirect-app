class SettingsModel {
  final bool pushNotificationsEnabled;
  final bool soundAlertsEnabled;
  final bool locationAlwaysAllow;
  final String language;

  const SettingsModel({
    this.pushNotificationsEnabled = true,
    this.soundAlertsEnabled = true,
    this.locationAlwaysAllow = true,
    this.language = 'en',
  });
}
