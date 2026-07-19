// AppStrings getters intentionally PascalCase (backward-compat with
// existing call-sites) — naming lint yahan expected hai.
// ignore_for_file: non_constant_identifier_names
import 'package:get/get.dart';

// ═══════════════════════════════════════════════════════════════════
//  APP STRINGS — locale-aware (GetX .tr backed)
// ═══════════════════════════════════════════════════════════════════
// Har string ab `AppTranslations` (lib/core/i18n/app_translations.dart)
// ki key se `.tr` ke through aati hai — locale switch hone par live
// badalti hai. Call-sites waise hi hain: `AppStrings.SendOTP`.
// Lists (allSkills/durations/idTypes/replacementReasons) backend ko
// as-is bheji jaati hain (enum-like values) — inhe translate NAHI karte.
class AppStrings {
  AppStrings._();

  // ── App ───────────────────────────────────────────────────────
  static String get SiteLink => 'site_link'.tr;
  static String get NeedWorkNeedWorkers => 'need_work_need_workers'.tr;
  static String get FindWorkHireWorkers => 'find_work_hire_workers'.tr;
  static String get PoweredBySmartnexTechnology => 'powered_by_smartnex'.tr;
  static String get SkillsExperience => 'skills_experience'.tr;

  // ── Auth ──────────────────────────────────────────────────────
  static String get Login => 'login'.tr;
  static String get EnterMobileNumber => 'enter_mobile_number'.tr;
  static String get MobileNumber => 'mobile_number'.tr;
  static String get SendOTP => 'send_otp'.tr;
  static String get VerifyOTP => 'verify_otp'.tr;
  static String get EnterOTP => 'enter_otp'.tr;
  static String get VerifyContinue => 'verify_continue'.tr;
  static String get ResendOTP => 'resend_otp'.tr;
  static String get SixDigitOTPSentTo => 'six_digit_otp_sent_to'.tr;
  static String get OTPSent => 'otp_sent'.tr;
  static String get ByContinuingYouAgreeToOur => 'by_continuing_you_agree'.tr;
  static String get Terms => 'terms'.tr;
  static String get PrivacyPolicy => 'privacy_policy'.tr;

  // ── Language ──────────────────────────────────────────────────
  static String get ChooseYourLanguage => 'choose_your_language'.tr;
  static String get ChooseLanguage => 'choose_language'.tr;
  static String get Hindi => 'hindi'.tr;
  static String get English => 'english'.tr;
  static String get Continue => 'continue_'.tr;

  // ── Role ──────────────────────────────────────────────────────
  static String get IAm => 'i_am'.tr;
  static String get SelectYourRoleToContinue =>
      'select_your_role_to_continue'.tr;
  static String get SelectRole => 'select_role'.tr;
  static String get Vendor => 'vendor'.tr;
  static String get IWantToHireWorkers => 'i_want_to_hire_workers'.tr;
  static String get HireWorkers => 'hire_workers'.tr;
  static String get Worker => 'worker'.tr;
  static String get IAmLookingForWork => 'i_am_looking_for_work'.tr;
  static String get LookingForWork => 'looking_for_work'.tr;

  // ── Vendor Registration ───────────────────────────────────────
  static String get CompanyProfile => 'company_profile'.tr;
  static String get TellUsAboutYourCompany => 'tell_us_about_your_company'.tr;
  static String get EnterCompanyDetails => 'enter_company_details'.tr;
  static String get CompanyName => 'company_name'.tr;
  static String get ContactPerson => 'contact_person'.tr;
  static String get Designation => 'designation'.tr;
  static String get City => 'city'.tr;
  static String get WorkArea => 'work_area'.tr;
  static String get GSTNumber => 'gst_number'.tr;
  static String get Optional => 'optional'.tr;
  static String get CreateAccount => 'create_account'.tr;
  static String get YourAccountWillBeActivatedWithin12HoursAfterReview =>
      'account_activated_12_hours'.tr;
  static String get AccountWillBeActivatedSoon => 'account_activated_soon'.tr;
  static String get ProfileUnderReviewSubtitle =>
      'profile_under_review_subtitle'.tr;

  // ── Worker Registration ───────────────────────────────────────
  static String get CreateProfile => 'create_profile'.tr;
  static String get PersonalDetails => 'personal_details'.tr;
  static String get FullName => 'full_name'.tr;
  static String get DateOfBirth => 'date_of_birth'.tr;
  static String get Gender => 'gender'.tr;
  static String get Male => 'male'.tr;
  static String get Female => 'female'.tr;
  static String get Other => 'other'.tr;
  static String get YourSkills => 'your_skills'.tr;
  static String get PrimarySkill => 'primary_skill'.tr;
  static String get AdditionalSkills => 'additional_skills'.tr;
  static String get TotalExperience => 'total_experience'.tr;
  static String get ExperienceDescription => 'experience_description'.tr;
  static String get DescribeYourPastWork => 'describe_your_past_work'.tr;
  static String get WorkPreferences => 'work_preferences'.tr;
  static String get WorkCity => 'work_city'.tr;
  static String get PreferredArea => 'preferred_area'.tr;
  static String get WillingToRelocate => 'willing_to_relocate'.tr;
  static String get Yes => 'yes'.tr;
  static String get No => 'no'.tr;
  static String get SalaryType => 'salary_type'.tr;
  static String get Daily => 'daily'.tr;
  static String get Monthly => 'monthly'.tr;
  static String get ExpectedSalary => 'expected_salary'.tr;
  static String get SubmitProfile => 'submit_profile'.tr;
  static String get Next => 'next'.tr;

  // ── Document Upload ───────────────────────────────────────────
  static String get UploadDocuments => 'upload_documents'.tr;
  static String get GovernmentID => 'government_id'.tr;
  static String get WorkSamplePhotos => 'work_sample_photos'.tr;
  static String get SubmitForVerification => 'submit_for_verification'.tr;

  // ── Pending Screen ────────────────────────────────────────────
  static String get ProfileUnderReview => 'profile_under_review'.tr;
  static String get WhatHappensNext => 'what_happens_next'.tr;
  static String get GoToHome => 'go_to_home'.tr;

  // ── Vendor Dashboard ──────────────────────────────────────────
  static String get Welcome => 'welcome'.tr;
  static String get ActiveRequests => 'active_requests'.tr;
  static String get WorkersAssigned => 'workers_assigned'.tr;
  static String get Replacements => 'replacements'.tr;
  static String get RecentRequests => 'recent_requests'.tr;
  static String get ViewAll => 'view_all'.tr;
  static String get NewRequest => 'new_request'.tr;

  // ── New Manpower Request ──────────────────────────────────────
  static String get RoleRequired => 'role_required'.tr;
  static String get Quantity => 'quantity'.tr;
  static String get SiteLocation => 'site_location'.tr;
  static String get Timeline => 'timeline'.tr;
  static String get StartDate => 'start_date'.tr;
  static String get Duration => 'duration'.tr;
  static String get SpecialRequirements => 'special_requirements'.tr;
  static String get SubmitRequest => 'submit_request'.tr;

  // ── Request Detail ────────────────────────────────────────────
  static String get RequestDetails => 'request_details'.tr;
  static String get Progress => 'progress'.tr;
  static String get AssignedWorkers => 'assigned_workers'.tr;
  static String get RequestReplacement => 'request_replacement'.tr;

  // ── Replacement ───────────────────────────────────────────────
  static String get ReplacementGuaranteedWithin48Hours =>
      'replacement_guaranteed_48_hours'.tr;
  static String get ReasonForReplacement => 'reason_for_replacement'.tr;
  static String get Description => 'description'.tr;

  // ── Rate Worker ───────────────────────────────────────────────
  static String get RateWorker => 'rate_worker'.tr;
  static String get RateYourExperience => 'rate_your_experience'.tr;
  static String get SubmitRating => 'submit_rating'.tr;

  // ── Worker Dashboard ──────────────────────────────────────────
  static String get Verified => 'verified'.tr;
  static String get Pending => 'pending'.tr;
  static String get CurrentAssignment => 'current_assignment'.tr;
  static String get MarkArrived => 'mark_arrived'.tr;
  static String get WaitingForYourNextJob => 'waiting_for_your_next_job'.tr;
  static String get OurTeamWillContactYouSoon =>
      'our_team_will_contact_you_soon'.tr;

  // ── Job Offer ─────────────────────────────────────────────────
  static String get NewJobOffer => 'new_job_offer'.tr;
  static String get PleaseRespondWithin2Hours =>
      'please_respond_within_2_hours'.tr;
  static String get Accept => 'accept'.tr;
  static String get Decline => 'decline'.tr;

  // ── My Jobs ───────────────────────────────────────────────────
  static String get MyJobs => 'my_jobs'.tr;

  // ── Notifications ─────────────────────────────────────────────
  static String get Notifications => 'notifications'.tr;
  static String get MarkAllRead => 'mark_all_read'.tr;

  // ── Profile ───────────────────────────────────────────────────
  static String get Profile => 'profile'.tr;
  static String get Language => 'language'.tr;
  static String get HelpSupport => 'help_support'.tr;
  static String get AboutSiteLink => 'about_site_link'.tr;
  static String get Logout => 'logout'.tr;

  // ── Help ──────────────────────────────────────────────────────
  static String get CallAdmin => 'call_admin'.tr;
  static String get WhatsApp => 'whatsapp'.tr;
  static String get FrequentlyAskedQuestions =>
      'frequently_asked_questions'.tr;

  // ── Skills (backend values — translate NAHI karte) ────────────
  static const List<String> allSkills = [
    'Mason',
    'Carpenter',
    'Plumber',
    'Electrician',
    'Painter',
    'Helper',
    'Welder',
    'Tile Worker',
    'Other',
  ];

  static const List<String> durations = [
    '1 Week',
    '2 Weeks',
    '1 Month',
    '2 Months',
    '3 Months',
    'Custom',
  ];

  static const List<String> idTypes = [
    'Aadhaar',
    'Voter ID',
    'Driving Licence',
  ];

  static const List<String> replacementReasons = [
    'Worker Left Site',
    'Unsatisfactory Work',
    'Absent',
    'Other',
  ];
}
