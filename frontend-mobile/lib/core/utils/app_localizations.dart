import 'package:flutter/material.dart';

enum AppLanguage { en, hi, mr }

class AppLocalizations {
  final AppLanguage language;
  AppLocalizations(this.language);

  static final Map<AppLanguage, Map<String, String>> _localizedValues = {
    AppLanguage.en: {
      'app_title': 'Electric Pole Safety',
      'safe_title': 'SAFE',
      'safe_desc': 'This pole is currently operating normally.',
      'warning_title': 'WARNING',
      'warning_desc': 'An abnormal condition has been detected. Please maintain a safe distance.',
      'danger_title': 'ELECTRICAL DANGER',
      'danger_desc': 'Electrical danger detected! Stay away from the pole and standing water.',
      'report_hazard': 'REPORT HAZARD',
      'sos_emergency': 'EMERGENCY HELP (112)',
      'quick_role_switch': 'Demo Role Switcher',
      'switch_role': 'Switch Role',
      'offline_mode': 'OFFLINE MODE',
      'online_mode': 'ONLINE',
      'syncing_mode': 'SYNCING...',
    },
    AppLanguage.hi: {
      'app_title': 'बिजली खंभा सुरक्षा',
      'safe_title': 'सुरक्षित',
      'safe_desc': 'यह खंभा वर्तमान में सामान्य रूप से काम कर रहा है।',
      'warning_title': 'चेतावनी',
      'warning_desc': 'असामान्य स्थिति पाई गई है। कृपया सुरक्षित दूरी बनाए रखें।',
      'danger_title': 'विद्युत खतरा',
      'danger_desc': 'खतरनाक करंट का रिसाव! खंभे और आसपास के पानी से तुरंत दूर रहें।',
      'report_hazard': 'खतरे की सूचना दें',
      'sos_emergency': 'आपातकालीन सहायता (112)',
      'quick_role_switch': 'डेमो रोल बदलें',
      'switch_role': 'भूमिका बदलें',
      'offline_mode': 'ऑफलाइन मोड',
      'online_mode': 'ऑनलाइन',
      'syncing_mode': 'सिंक हो रहा है...',
    },
    AppLanguage.mr: {
      'app_title': 'वीज खांब सुरक्षा',
      'safe_title': 'सुरक्षित',
      'safe_desc': 'हा खांब सध्या सामान्यपणे कार्यरत आहे.',
      'warning_title': 'इशारा',
      'warning_desc': 'खांबामध्ये दोष आढळला आहे. कृपया सुरक्षित अंतर ठेवा.',
      'danger_title': 'विद्युत धोका',
      'danger_desc': 'धोकादायक वीज प्रवाह गळती! खांब व साचलेल्या पाण्यापासून तात्काळ दूर राहा.',
      'report_hazard': 'धोक्याची नोंद करा',
      'sos_emergency': 'तातडीची मदत (112)',
      'quick_role_switch': 'डेमो भूमिका बदला',
      'switch_role': 'भूमिका बदला',
      'offline_mode': 'ऑफलाईन मोड',
      'online_mode': 'ऑनलाईन',
      'syncing_mode': 'सिंक होत आहे...',
    },
  };

  String tr(String key) {
    return _localizedValues[language]?[key] ?? _localizedValues[AppLanguage.en]?[key] ?? key;
  }
}
