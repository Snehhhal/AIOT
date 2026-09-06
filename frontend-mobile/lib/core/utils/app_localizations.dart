
enum AppLanguage { en, hi, mr }

extension AppLanguageExtension on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.en:
        return 'en';
      case AppLanguage.hi:
        return 'hi';
      case AppLanguage.mr:
        return 'mr';
    }
  }

  String get label {
    switch (this) {
      case AppLanguage.en:
        return 'English';
      case AppLanguage.hi:
        return 'हिंदी';
      case AppLanguage.mr:
        return 'मराठी';
    }
  }

  String get flag {
    switch (this) {
      case AppLanguage.en:
        return '🇬🇧';
      case AppLanguage.hi:
        return '🇮🇳';
      case AppLanguage.mr:
        return '🇮🇳';
    }
  }
}

class AppLocalizations {
  final AppLanguage language;
  AppLocalizations(this.language);

  static final Map<AppLanguage, Map<String, String>> _localizedValues = {
    AppLanguage.en: {
      'app_title': 'PoleGuard Life Safety',
      'app_subtitle': 'AI & IoT Electric Pole Leakage Detection and Municipal Safety Platform',
      'select_user_type': 'Select User Type',
      'select_role_desc': 'Choose your role to report electrical hazards or manage infrastructure safety',
      
      // Roles
      'role_citizen_title': 'Citizen',
      'role_citizen_tagline': 'Report electrical hazards and stay safe',
      'role_technician_title': 'Field Technician',
      'role_technician_tagline': 'Manage field requests and repairs',
      'role_engineer_title': 'Engineer / Supervisor',
      'role_engineer_tagline': 'Monitor poles, AI predictions and field operations',
      'role_authority_title': 'Authority',
      'role_authority_tagline': 'Monitor area safety and critical incidents',
      'role_admin_title': 'Admin',
      'role_admin_tagline': 'Manage users, poles and system configuration',

      // Citizen Safety Messages (Non-technical)
      'safe_title': 'SAFE: Area Clear',
      'safe_desc': 'No electrical hazards detected in your immediate area. Nearby poles are operating normally.',
      'warning_title': 'WARNING: Maintain Distance',
      'warning_desc': 'An abnormal electrical condition has been detected nearby. Please stay at least 3-5 meters away.',
      'danger_title': 'DANGER: Electrical Leakage Detected!',
      'danger_desc': '⚠️ This electric pole may be unsafe! Please stay at least 5-10 meters away from the pole and standing water. Wait for the safety team.',

      // Citizen Quick Actions
      'action_report_pole': 'Report Unsafe Pole',
      'action_report_pole_desc': 'Take photo & send live GPS alert',
      'action_nearby_poles': 'Nearby Poles & Safety',
      'action_nearby_poles_desc': 'Check live status of poles around you',
      'action_ai_assistant': 'AI Safety Assistant',
      'action_ai_assistant_desc': 'Instant guidance on shock hazards & rules',
      'action_my_reports': 'My Submitted Reports',
      'action_my_reports_desc': 'Track status of your hazard complaints',

      // Location & SOS
      'sos_emergency': 'EMERGENCY SOS (112)',
      'location_banner_title': 'Current Safety Location',
      'location_permission_needed': 'Location permission is required to show nearby poles.',
      'location_unavailable': 'Current location unavailable.',
      'no_nearby_poles_found': 'No nearby poles found. Please add or discover poles near your location.',
      'select_a_pole': 'Select a pole',
      'location_denied': 'Location permission is required to show nearby poles.',
      'location_disabled': 'Current location unavailable (Device GPS disabled).',
      'enable_gps': 'Enable GPS',
      'grant_permission': 'Grant Permission',
      'refresh_location': 'Refresh GPS',
      'live_gps': 'Live Phone GPS',
      'no_gps': 'Current location unavailable.',

      // Navigation & Auth
      'login': 'Sign In',
      'signup': 'Sign Up',
      'logout': 'Sign Out',
      'email': 'Email Address',
      'password': 'Password',
      'forgot_password': 'Forgot Password?',
      'dont_have_account': "Don't have an account?",
      'already_have_account': 'Already have an account?',
      'change_role': 'Change Role',
      'language': 'Language',
      'select_language': 'Select Language',
      'offline_mode': 'OFFLINE MODE',
      'online_mode': 'ONLINE',
      'syncing_mode': 'SYNCING...',
    },
    AppLanguage.hi: {
      'app_title': 'पोलगार्ड जीवन सुरक्षा',
      'app_subtitle': 'AI और IoT आधारित बिजली खंभा रिसाव पहचान एवं नागरिक सुरक्षा मंच',
      'select_user_type': 'उपयोगकर्ता प्रकार चुनें',
      'select_role_desc': 'बिजली के खतरों की रिपोर्ट करने या सुरक्षा प्रबंधित करने के लिए अपना पोर्टल चुनें',

      // Roles
      'role_citizen_title': 'नागरिक',
      'role_citizen_tagline': 'बिजली के खतरों की रिपोर्ट करें और सुरक्षित रहें',
      'role_technician_title': 'फील्ड तकनीशियन',
      'role_technician_tagline': 'फील्ड अनुरोध और मरम्मत का प्रबंधन करें',
      'role_engineer_title': 'इंजीनियर / पर्यवेक्षक',
      'role_engineer_tagline': 'खंभों की निगरानी, AI पूर्वानुमान और फील्ड संचालन',
      'role_authority_title': 'प्राधिकरण',
      'role_authority_tagline': 'क्षेत्र सुरक्षा और गंभीर घटनाओं की निगरानी करें',
      'role_admin_title': 'एडमिन',
      'role_admin_tagline': 'उपयोगकर्ता, खंभे और सिस्टम कॉन्फ़िगरेशन प्रबंधित करें',

      // Citizen Safety Messages (Non-technical)
      'safe_title': 'सुरक्षित: क्षेत्र सामान्य है',
      'safe_desc': 'आपके आसपास कोई विद्युत खतरा नहीं पाया गया। सभी खंभे सामान्य रूप से काम कर रहे हैं।',
      'warning_title': 'चेतावनी: सुरक्षित दूरी बनाए रखें',
      'warning_desc': 'आसपास असामान्य स्थिति पाई गई है। कृपया खंभे से कम से कम 3-5 मीटर की दूरी बनाए रखें।',
      'danger_title': 'खतरा: विद्युत रिसाव का पता चला!',
      'danger_desc': '⚠️ यह बिजली का खंभा असुरक्षित हो सकता है! कृपया खंभे और भरे पानी से 5-10 मीटर दूर रहें। सुरक्षा दल की प्रतीक्षा करें।',

      // Citizen Quick Actions
      'action_report_pole': 'असुरक्षित खंभे की रिपोर्ट करें',
      'action_report_pole_desc': 'फोटो खींचकर लाइव जीपीएस अलर्ट भेजें',
      'action_nearby_poles': 'आसपास के खंभों की स्थिति',
      'action_nearby_poles_desc': 'अपने आसपास के खंभों की लाइव सुरक्षा देखें',
      'action_ai_assistant': 'AI सुरक्षा सहायक',
      'action_ai_assistant_desc': 'करंट के खतरे और सुरक्षा नियमों पर तुरंत सहायता',
      'action_my_reports': 'मेरी दर्ज शिकायतें',
      'action_my_reports_desc': 'अपनी शिकायतों की प्रगति और स्थिति देखें',

      // Location & SOS
      'sos_emergency': 'आपातकालीन सहायता (112)',
      'location_banner_title': 'वर्तमान सुरक्षा स्थान',
      'location_permission_needed': 'Location permission is required to show nearby poles.',
      'location_unavailable': 'Current location unavailable.',
      'no_nearby_poles_found': 'पास में कोई पंजीकृत खंभा नहीं मिला।',
      'select_a_pole': 'एक खंभा चुनें',
      'location_denied': 'Location permission is required to show nearby poles.',
      'location_disabled': 'Current location unavailable.',
      'enable_gps': 'जीपीएस चालू करें',
      'grant_permission': 'अनुमति दें',
      'refresh_location': 'जीपीएस रीफ्रेश करें',
      'live_gps': 'लाइव फोन जीपीएस',
      'no_gps': 'Current location unavailable.',

      // Navigation & Auth
      'login': 'साइन इन करें',
      'signup': 'साइन अप करें',
      'logout': 'साइन आउट',
      'email': 'ईमेल पता',
      'password': 'पासवर्ड',
      'forgot_password': 'पासवर्ड भूल गए?',
      'dont_have_account': 'खाता नहीं है?',
      'already_have_account': 'पहले से खाता है?',
      'change_role': 'भूमिका बदलें',
      'language': 'भाषा',
      'select_language': 'भाषा चुनें',
      'offline_mode': 'ऑफलाइन मोड',
      'online_mode': 'ऑनलाइन',
      'syncing_mode': 'सिंक हो रहा है...',
    },
    AppLanguage.mr: {
      'app_title': 'पोलगार्ड जीवन सुरक्षा',
      'app_subtitle': 'AI आणि IoT आधारित वीज खांब गळती शोध व नागरी सुरक्षा प्रणाली',
      'select_user_type': 'वापरकर्ता प्रकार निवडा',
      'select_role_desc': 'विद्युत धोक्यांची नोंद करण्यासाठी किंवा सुरक्षा व्यवस्थापनासाठी आपले पोर्टल निवडा',

      // Roles
      'role_citizen_title': 'नागरिक',
      'role_citizen_tagline': 'विद्युत धोक्यांची नोंद करा आणि सुरक्षित राहा',
      'role_technician_title': 'फील्ड तंत्रज्ञ',
      'role_technician_tagline': 'फील्ड विनंत्या आणि दुरुस्ती व्यवस्थापित करा',
      'role_engineer_title': 'अभियंता / पर्यवेक्षक',
      'role_engineer_tagline': 'खांब देखरेख, AI अंदाज आणि फील्ड कामकाज',
      'role_authority_title': 'प्राधिकरण',
      'role_authority_tagline': 'परिसर सुरक्षा आणि गंभीर घटनांची देखरेख करा',
      'role_admin_title': 'प्रशासक',
      'role_admin_tagline': 'वापरकर्ते, खांब आणि प्रणाली संरचना व्यवस्थापित करा',

      // Citizen Safety Messages (Non-technical)
      'safe_title': 'सुरक्षित: परिसर निर्धोक आहे',
      'safe_desc': 'तुमच्या परिसरात कोणताही विद्युत धोका आढळला नाही. खांब सामान्यपणे कार्यरत आहेत.',
      'warning_title': 'इशारा: सुरक्षित अंतर ठेवा',
      'warning_desc': 'परिसरात असामान्य विद्युत प्रवाह आढळला आहे. कृपया किमान 3 ते 5 मीटर अंतर ठेवा.',
      'danger_title': 'धोका: वीज प्रवाह गळती आढळली!',
      'danger_desc': '⚠️ हा विजेचा खांब असुरक्षित असू शकतो! कृपया खांब आणि साचलेल्या पाण्यापासून 5-10 मीटर लांब राहा. दुरुस्ती पथकाची वाट पहा.',

      // Citizen Quick Actions
      'action_report_pole': 'असुरक्षित खांबाची नोंद करा',
      'action_report_pole_desc': 'फोटो काढून थेट GPS सूचना पाठवा',
      'action_nearby_poles': 'जवळच्या खांबांची स्थिती',
      'action_nearby_poles_desc': 'तुमच्या परिसरातील खांबांची थेट सुरक्षा तपासा',
      'action_ai_assistant': 'AI सुरक्षा सहाय्यक',
      'action_ai_assistant_desc': 'विद्युत शॉक प्रतिबंध आणि सुरक्षा नियमांचे मार्गदर्शन',
      'action_my_reports': 'माझ्या नोंदवलेल्या तक्रारी',
      'action_my_reports_desc': 'आपल्या तक्रारींची सद्यस्थिती आणि पाठपुरावा पहा',

      // Location & SOS
      'sos_emergency': 'तातडीची मदत (112)',
      'location_banner_title': 'सध्याचे सुरक्षा स्थान',
      'location_permission_needed': 'Location permission is required to show nearby poles.',
      'location_unavailable': 'Current location unavailable.',
      'no_nearby_poles_found': 'परिसरात कोणतेही खांब आढळले नाहीत.',
      'select_a_pole': 'खांब निवडा',
      'location_denied': 'Location permission is required to show nearby poles.',
      'location_disabled': 'Current location unavailable.',
      'enable_gps': 'जीपीएस सुरू करा',
      'grant_permission': 'परवानगी द्या',
      'refresh_location': 'GPS रीफ्रेश करा',
      'live_gps': 'थेट फोन GPS',
      'no_gps': 'Current location unavailable.',

      // Navigation & Auth
      'login': 'साइन इन करा',
      'signup': 'साइन अप करा',
      'logout': 'साइन आउट',
      'email': 'ईमेल पत्ता',
      'password': 'पासवर्ड',
      'forgot_password': 'पासवर्ड विसरलात?',
      'dont_have_account': 'खाते नाही का?',
      'already_have_account': 'आधीच खाते आहे?',
      'change_role': 'भूमिका बदला',
      'language': 'भाषा',
      'select_language': 'भाषा निवडा',
      'offline_mode': 'ऑफलाईन मोड',
      'online_mode': 'ऑनलाईन',
      'syncing_mode': 'सिंक होत आहे...',
    },
  };

  String tr(String key) {
    return _localizedValues[language]?[key] ?? _localizedValues[AppLanguage.en]?[key] ?? key;
  }
}

