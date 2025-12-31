// l10n/app_localizations.dart
import 'package:flutter/material.dart';

/// Abstract base class for all localization implementations
abstract class AppLocalizations {
  String locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Abstract getters - must be implemented by subclasses
  String get dashboard;
  String get jobs;
  String get clients;
  String get invoices;
  String get inventory;
  String get expenses;
  String get calendar;
  String get team;
  String get reports;
  String get settings;
  String get aiChat;
  String get leads;
  String get kpi;
  String get aiExecutives;
  String get copilot;
  String get dispatch;
  String get add;
  String get edit;
  String get delete;
  String get save;
  String get cancel;
  String get search;
  String get filter;
  String get export;
  String get import;
  String get refresh;
  String get loading;
  String get noData;
  String get error;
  String get success;
  String get confirm;
  String get close;
  String get viewAll;
  String get create;
  String get update;
  String get back;
  String get next;
  String get done;
  String get yes;
  String get no;
  String get language;
  String get theme;
  String get appearance;
  String get notifications;
  String get security;
  String get privacy;
  String get account;
  String get logout;
  String get languageChanged;
  String get quickActions;
  String get profile;
  String get myProfile;
  String get editProfile;
  String get changePassword;
  String get about;
  String get helpSupport;
  String get feedback;
  String get rateApp;
  String get version;
  String get terms;
  String get privacyPolicy;
  String get cookiePolicy;
  String get gdpr;
  String get aiFeatures;
  String get automation;
  String get securityPrivacy;
  String get deviceFeatures;
  String get dataLegal;
  String get personalization;
  String get invoiceBranding;
  String get fraudProtection;
  String get darkMode;
  String get exportData;
  String get termsOfService;
  String get totalRevenue;
  String get totalJobs;
  String get totalClients;
  String get pendingInvoices;
  String get thisMonth;
  String get thisWeek;
  String get today;
  String get welcomeBack;
  String get overview;
  String get recentActivity;
  String get newJob;
  String get jobTitle;
  String get jobStatus;
  String get jobDate;
  String get jobClient;
  String get pending;
  String get inProgress;
  String get completed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return [
      'pt',
      'en',
      'es',
      'de',
      'fr',
      'it',
      'pl',
      'ru',
      'bg',
      'ar',
    ].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return _load(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;

  Future<AppLocalizations> _load(Locale locale) async {
    // Import localization files as needed
    // This is a placeholder - actual implementations would be imported
    throw UnimplementedError(
      'Localization for ${locale.languageCode} not implemented',
    );
  }
}
