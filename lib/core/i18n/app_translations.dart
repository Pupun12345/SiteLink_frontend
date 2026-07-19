import 'package:get/get.dart';

// ═══════════════════════════════════════════════════════════════════
//  APP TRANSLATIONS — GetX i18n (en_US + hi_IN)
// ═══════════════════════════════════════════════════════════════════
// Har key `AppStrings` ke ek getter se `.tr` ke through use hoti hai
// (lib/core/constants/app_strings.dart). Nayi string add karni ho to:
//   1) yaha dono locale me key+value daalo
//   2) AppStrings me getter add karo (`static String get X => 'key'.tr;`)
// Locale switch `LocaleService.setLanguage(...)` se hota hai.
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': _en,
        'hi_IN': _hi,
      };
}

// ── English ────────────────────────────────────────────────────────
const Map<String, String> _en = {
  // App
  'site_link': 'SiteLink',
  'need_work_need_workers': 'Need Work? Need Workers?',
  'find_work_hire_workers': 'Find Work. Hire Workers.',
  'powered_by_smartnex': 'Powered by Smartnex technology',
  'skills_experience': 'Skills & Experience',

  // Auth
  'login': 'Login',
  'enter_mobile_number': 'Enter Mobile Number',
  'mobile_number': 'Mobile Number',
  'send_otp': 'Send OTP',
  'verify_otp': 'Verify OTP',
  'enter_otp': 'Enter OTP',
  'verify_continue': 'Verify & Continue',
  'resend_otp': 'Resend OTP',
  'six_digit_otp_sent_to': '6-digit OTP sent to',
  'otp_sent': 'OTP Sent',
  'by_continuing_you_agree': 'By continuing, you agree to our',
  'terms': 'Terms',
  'privacy_policy': 'Privacy Policy',

  // Language
  'choose_your_language': 'Choose Your Language',
  'choose_language': 'Choose Language',
  'hindi': 'Hindi',
  'english': 'English',
  'continue_': 'Continue',

  // Role
  'i_am': 'I Am',
  'select_your_role_to_continue': 'Select your role to continue',
  'select_role': 'Select Role',
  'vendor': 'Vendor',
  'i_want_to_hire_workers': 'I want to hire workers',
  'hire_workers': 'Hire workers',
  'worker': 'Worker',
  'i_am_looking_for_work': 'I am looking for work',
  'looking_for_work': 'Looking for work',

  // Vendor Registration
  'company_profile': 'Company Profile',
  'tell_us_about_your_company': 'Tell us about your company',
  'enter_company_details': 'Enter company details',
  'company_name': 'Company Name',
  'contact_person': 'Contact Person',
  'designation': 'Designation',
  'city': 'City',
  'work_area': 'Work Area',
  'gst_number': 'GST Number',
  'optional': '(Optional)',
  'create_account': 'Create Account',
  'account_activated_12_hours':
      'Your account will be activated within 12 hours after review.',
  'account_activated_soon': 'Account will be activated soon.',
  'profile_under_review_subtitle':
      'We\'ll notify you once your profile is approved',

  // Worker Registration
  'create_profile': 'Create Profile',
  'personal_details': 'Personal Details',
  'full_name': 'Full Name',
  'date_of_birth': 'Date of Birth',
  'gender': 'Gender',
  'male': 'Male',
  'female': 'Female',
  'other': 'Other',
  'your_skills': 'Your Skills',
  'primary_skill': 'Primary Skill',
  'additional_skills': 'Additional Skills',
  'total_experience': 'Total Experience',
  'experience_description': 'Experience Description',
  'describe_your_past_work': 'Describe your past work',
  'work_preferences': 'Work Preferences',
  'work_city': 'Work City',
  'preferred_area': 'Preferred Area',
  'willing_to_relocate': 'Willing to Relocate?',
  'yes': 'Yes',
  'no': 'No',
  'salary_type': 'Salary Type',
  'daily': 'Daily',
  'monthly': 'Monthly',
  'expected_salary': 'Expected Salary',
  'submit_profile': 'Submit Profile',
  'next': 'Next',

  // Document Upload
  'upload_documents': 'Upload Documents',
  'government_id': 'Government ID',
  'work_sample_photos': 'Work Sample Photos',
  'submit_for_verification': 'Submit for Verification',

  // Pending Screen
  'profile_under_review': 'Profile Under Review',
  'what_happens_next': 'What happens next?',
  'go_to_home': 'Go to Home',

  // Vendor Dashboard
  'welcome': 'Welcome',
  'active_requests': 'Active Requests',
  'workers_assigned': 'Workers Assigned',
  'replacements': 'Replacements',
  'recent_requests': 'Recent Requests',
  'view_all': 'View All',
  'new_request': 'New Request',

  // New Manpower Request
  'role_required': 'Role Required',
  'quantity': 'Quantity',
  'site_location': 'Site Location',
  'timeline': 'Timeline',
  'start_date': 'Start Date',
  'duration': 'Duration',
  'special_requirements': 'Special Requirements',
  'submit_request': 'Submit Request',

  // Request Detail
  'request_details': 'Request Details',
  'progress': 'Progress',
  'assigned_workers': 'Assigned Workers',
  'request_replacement': 'Request Replacement',

  // Replacement
  'replacement_guaranteed_48_hours': 'Replacement guaranteed within 48 hours',
  'reason_for_replacement': 'Reason for Replacement',
  'description': 'Description',

  // Rate Worker
  'rate_worker': 'Rate Worker',
  'rate_your_experience': 'Rate your experience',
  'submit_rating': 'Submit Rating',

  // Worker Dashboard
  'verified': 'Verified',
  'pending': 'Pending',
  'current_assignment': 'Current Assignment',
  'mark_arrived': 'Mark Arrived',
  'waiting_for_your_next_job': 'Waiting for your next job',
  'our_team_will_contact_you_soon': 'Our team will contact you soon',

  // Job Offer
  'new_job_offer': 'New Job Offer',
  'please_respond_within_2_hours': 'Please respond within 2 hours',
  'accept': 'Accept',
  'decline': 'Decline',

  // My Jobs
  'my_jobs': 'My Jobs',

  // Notifications
  'notifications': 'Notifications',
  'mark_all_read': 'Mark all read',

  // Profile
  'profile': 'Profile',
  'language': 'Language',
  'help_support': 'Help & Support',
  'about_site_link': 'About SiteLink',
  'logout': 'Logout',

  // Help
  'call_admin': 'Call Admin',
  'whatsapp': 'WhatsApp',
  'frequently_asked_questions': 'Frequently Asked Questions',
};

// ── हिंदी (Hindi) ──────────────────────────────────────────────────
const Map<String, String> _hi = {
  // App
  'site_link': 'SiteLink',
  'need_work_need_workers': 'काम चाहिए? मज़दूर चाहिए?',
  'find_work_hire_workers': 'काम पाएं। मज़दूर रखें।',
  'powered_by_smartnex': 'Smartnex तकनीक द्वारा संचालित',
  'skills_experience': 'कौशल और अनुभव',

  // Auth
  'login': 'लॉगिन',
  'enter_mobile_number': 'मोबाइल नंबर दर्ज करें',
  'mobile_number': 'मोबाइल नंबर',
  'send_otp': 'ओटीपी भेजें',
  'verify_otp': 'ओटीपी सत्यापित करें',
  'enter_otp': 'ओटीपी दर्ज करें',
  'verify_continue': 'सत्यापित करें और जारी रखें',
  'resend_otp': 'ओटीपी दोबारा भेजें',
  'six_digit_otp_sent_to': '6-अंकों का ओटीपी भेजा गया',
  'otp_sent': 'ओटीपी भेजा गया',
  'by_continuing_you_agree': 'जारी रखते हुए, आप हमारी',
  'terms': 'शर्तें',
  'privacy_policy': 'गोपनीयता नीति',

  // Language
  'choose_your_language': 'अपनी भाषा चुनें',
  'choose_language': 'भाषा चुनें',
  'hindi': 'हिंदी',
  'english': 'English',
  'continue_': 'जारी रखें',

  // Role
  'i_am': 'मैं हूँ',
  'select_your_role_to_continue': 'जारी रखने के लिए अपनी भूमिका चुनें',
  'select_role': 'भूमिका चुनें',
  'vendor': 'ठेकेदार',
  'i_want_to_hire_workers': 'मुझे मज़दूर रखने हैं',
  'hire_workers': 'मज़दूर रखें',
  'worker': 'मज़दूर',
  'i_am_looking_for_work': 'मैं काम ढूंढ रहा हूँ',
  'looking_for_work': 'काम की तलाश',

  // Vendor Registration
  'company_profile': 'कंपनी प्रोफ़ाइल',
  'tell_us_about_your_company': 'हमें अपनी कंपनी के बारे में बताएं',
  'enter_company_details': 'कंपनी की जानकारी दर्ज करें',
  'company_name': 'कंपनी का नाम',
  'contact_person': 'संपर्क व्यक्ति',
  'designation': 'पद',
  'city': 'शहर',
  'work_area': 'कार्य क्षेत्र',
  'gst_number': 'जीएसटी नंबर',
  'optional': '(वैकल्पिक)',
  'create_account': 'खाता बनाएं',
  'account_activated_12_hours':
      'समीक्षा के बाद आपका खाता 12 घंटे में सक्रिय हो जाएगा।',
  'account_activated_soon': 'खाता जल्द ही सक्रिय हो जाएगा।',
  'profile_under_review_subtitle':
      'आपकी प्रोफ़ाइल मंज़ूर होने पर हम आपको सूचित करेंगे',

  // Worker Registration
  'create_profile': 'प्रोफ़ाइल बनाएं',
  'personal_details': 'व्यक्तिगत विवरण',
  'full_name': 'पूरा नाम',
  'date_of_birth': 'जन्म तिथि',
  'gender': 'लिंग',
  'male': 'पुरुष',
  'female': 'महिला',
  'other': 'अन्य',
  'your_skills': 'आपके कौशल',
  'primary_skill': 'मुख्य कौशल',
  'additional_skills': 'अतिरिक्त कौशल',
  'total_experience': 'कुल अनुभव',
  'experience_description': 'अनुभव विवरण',
  'describe_your_past_work': 'अपने पिछले काम के बारे में बताएं',
  'work_preferences': 'कार्य प्राथमिकताएं',
  'work_city': 'कार्य शहर',
  'preferred_area': 'पसंदीदा क्षेत्र',
  'willing_to_relocate': 'स्थानांतरण के लिए तैयार?',
  'yes': 'हाँ',
  'no': 'नहीं',
  'salary_type': 'वेतन प्रकार',
  'daily': 'दैनिक',
  'monthly': 'मासिक',
  'expected_salary': 'अपेक्षित वेतन',
  'submit_profile': 'प्रोफ़ाइल जमा करें',
  'next': 'आगे',

  // Document Upload
  'upload_documents': 'दस्तावेज़ अपलोड करें',
  'government_id': 'सरकारी पहचान पत्र',
  'work_sample_photos': 'कार्य नमूना फ़ोटो',
  'submit_for_verification': 'सत्यापन के लिए जमा करें',

  // Pending Screen
  'profile_under_review': 'प्रोफ़ाइल समीक्षाधीन',
  'what_happens_next': 'आगे क्या होगा?',
  'go_to_home': 'होम पर जाएं',

  // Vendor Dashboard
  'welcome': 'स्वागत है',
  'active_requests': 'सक्रिय अनुरोध',
  'workers_assigned': 'नियुक्त मज़दूर',
  'replacements': 'बदलाव',
  'recent_requests': 'हाल के अनुरोध',
  'view_all': 'सभी देखें',
  'new_request': 'नया अनुरोध',

  // New Manpower Request
  'role_required': 'आवश्यक भूमिका',
  'quantity': 'संख्या',
  'site_location': 'साइट स्थान',
  'timeline': 'समय-सीमा',
  'start_date': 'आरंभ तिथि',
  'duration': 'अवधि',
  'special_requirements': 'विशेष आवश्यकताएं',
  'submit_request': 'अनुरोध जमा करें',

  // Request Detail
  'request_details': 'अनुरोध विवरण',
  'progress': 'प्रगति',
  'assigned_workers': 'नियुक्त मज़दूर',
  'request_replacement': 'बदलाव का अनुरोध',

  // Replacement
  'replacement_guaranteed_48_hours': '48 घंटे में बदलाव की गारंटी',
  'reason_for_replacement': 'बदलाव का कारण',
  'description': 'विवरण',

  // Rate Worker
  'rate_worker': 'मज़दूर को रेट करें',
  'rate_your_experience': 'अपना अनुभव रेट करें',
  'submit_rating': 'रेटिंग जमा करें',

  // Worker Dashboard
  'verified': 'सत्यापित',
  'pending': 'लंबित',
  'current_assignment': 'वर्तमान कार्य',
  'mark_arrived': 'पहुंच गया चिह्नित करें',
  'waiting_for_your_next_job': 'आपके अगले काम की प्रतीक्षा',
  'our_team_will_contact_you_soon': 'हमारी टीम जल्द ही आपसे संपर्क करेगी',

  // Job Offer
  'new_job_offer': 'नया काम मिला',
  'please_respond_within_2_hours': 'कृपया 2 घंटे में जवाब दें',
  'accept': 'स्वीकार करें',
  'decline': 'अस्वीकार करें',

  // My Jobs
  'my_jobs': 'मेरे काम',

  // Notifications
  'notifications': 'सूचनाएं',
  'mark_all_read': 'सभी पढ़ा हुआ चिह्नित करें',

  // Profile
  'profile': 'प्रोफ़ाइल',
  'language': 'भाषा',
  'help_support': 'सहायता और समर्थन',
  'about_site_link': 'SiteLink के बारे में',
  'logout': 'लॉगआउट',

  // Help
  'call_admin': 'एडमिन को कॉल करें',
  'whatsapp': 'WhatsApp',
  'frequently_asked_questions': 'अक्सर पूछे जाने वाले प्रश्न',
};
