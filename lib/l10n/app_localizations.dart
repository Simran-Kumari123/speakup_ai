import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// Title for the Help and Support screen
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @gettingStarted.
  ///
  /// In en, this message translates to:
  /// **'GETTING STARTED'**
  String get gettingStarted;

  /// No description provided for @commonQuestions.
  ///
  /// In en, this message translates to:
  /// **'COMMON QUESTIONS'**
  String get commonQuestions;

  /// No description provided for @troubleshooting.
  ///
  /// In en, this message translates to:
  /// **'TROUBLESHOOTING'**
  String get troubleshooting;

  /// No description provided for @contactCommunity.
  ///
  /// In en, this message translates to:
  /// **'CONTACT & COMMUNITY'**
  String get contactCommunity;

  /// No description provided for @helpAppBasicsTitle.
  ///
  /// In en, this message translates to:
  /// **'App Basics'**
  String get helpAppBasicsTitle;

  /// No description provided for @helpAppBasicsDesc.
  ///
  /// In en, this message translates to:
  /// **'Track your daily streaks and XP on the Home Dashboard. Navigate through Speaking, Vocabulary, and Interviews using the bottom bar.'**
  String get helpAppBasicsDesc;

  /// No description provided for @helpSpeechTitle.
  ///
  /// In en, this message translates to:
  /// **'Speech Practice'**
  String get helpSpeechTitle;

  /// No description provided for @helpSpeechDesc.
  ///
  /// In en, this message translates to:
  /// **'Hold the microphone to speak. The AI analyzes your fluency and grammar in real-time.'**
  String get helpSpeechDesc;

  /// No description provided for @helpProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress Tracking'**
  String get helpProgressTitle;

  /// No description provided for @helpProgressDesc.
  ///
  /// In en, this message translates to:
  /// **'Visit the Statistics page to see your skill matrix (Fluency, Grammar, Confidence) improve over time.'**
  String get helpProgressDesc;

  /// No description provided for @faqAccuracyQ.
  ///
  /// In en, this message translates to:
  /// **'How accurate is the AI feedback?'**
  String get faqAccuracyQ;

  /// No description provided for @faqAccuracyA.
  ///
  /// In en, this message translates to:
  /// **'SpeakUp AI uses the Groq LLaMA-3 engine, which is highly accurate for grammatical analysis. For best results, ensure you speak clearly in a quiet environment.'**
  String get faqAccuracyA;

  /// No description provided for @faqOfflineQ.
  ///
  /// In en, this message translates to:
  /// **'Does the app work offline?'**
  String get faqOfflineQ;

  /// No description provided for @faqOfflineA.
  ///
  /// In en, this message translates to:
  /// **'Most practice features require an internet connection to communicate with our AI services. However, your vocabulary and progress can be viewed offline.'**
  String get faqOfflineA;

  /// No description provided for @faqResetQ.
  ///
  /// In en, this message translates to:
  /// **'How can I reset my progress?'**
  String get faqResetQ;

  /// No description provided for @faqResetA.
  ///
  /// In en, this message translates to:
  /// **'Go to Profile > Preferences > Clear All Data to reset your local progress. All XP, streaks, and session history will be removed.'**
  String get faqResetA;

  /// No description provided for @faqSecurityQ.
  ///
  /// In en, this message translates to:
  /// **'Is my data secure?'**
  String get faqSecurityQ;

  /// No description provided for @faqSecurityA.
  ///
  /// In en, this message translates to:
  /// **'Yes. We do not store your voice recordings. Only text transcripts are used temporarily for analysis to provide you with feedback.'**
  String get faqSecurityA;

  /// No description provided for @faqVoiceQ.
  ///
  /// In en, this message translates to:
  /// **'Can I customize the AI voice?'**
  String get faqVoiceQ;

  /// No description provided for @faqVoiceA.
  ///
  /// In en, this message translates to:
  /// **'Yes! Go to Profile > Preferences to change the AI personality, voice speed, and translation language.'**
  String get faqVoiceA;

  /// No description provided for @troubleMicTitle.
  ///
  /// In en, this message translates to:
  /// **'Mic not working?'**
  String get troubleMicTitle;

  /// No description provided for @troubleMicDesc.
  ///
  /// In en, this message translates to:
  /// **'Ensure that SpeakUp AI has microphone permissions enabled in your device settings. Check if another app is using the mic.'**
  String get troubleMicDesc;

  /// No description provided for @troubleSlowTitle.
  ///
  /// In en, this message translates to:
  /// **'AI is slow to respond?'**
  String get troubleSlowTitle;

  /// No description provided for @troubleSlowDesc.
  ///
  /// In en, this message translates to:
  /// **'This usually happens due to a weak internet connection. Try switching to Wi-Fi for a faster experience.'**
  String get troubleSlowDesc;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get contactEmail;

  /// No description provided for @contactEmailValue.
  ///
  /// In en, this message translates to:
  /// **'support@speakup.ai'**
  String get contactEmailValue;

  /// No description provided for @contactHelpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get contactHelpCenter;

  /// No description provided for @contactHelpCenterValue.
  ///
  /// In en, this message translates to:
  /// **'help.speakup.ai'**
  String get contactHelpCenterValue;

  /// No description provided for @contactYouTube.
  ///
  /// In en, this message translates to:
  /// **'Video Tutorials'**
  String get contactYouTube;

  /// No description provided for @contactYouTubeValue.
  ///
  /// In en, this message translates to:
  /// **'Watch on YouTube'**
  String get contactYouTubeValue;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'SpeakUp AI v3.0.2'**
  String get appVersion;

  /// No description provided for @madeWithLove.
  ///
  /// In en, this message translates to:
  /// **'Made with ❤️ for English Learners'**
  String get madeWithLove;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @accountInformation.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT INFORMATION'**
  String get accountInformation;

  /// No description provided for @activityOverview.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY OVERVIEW'**
  String get activityOverview;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'APP SETTINGS'**
  String get appSettings;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'HELP & SUPPORT'**
  String get helpAndSupport;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get account;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @targetRole.
  ///
  /// In en, this message translates to:
  /// **'Target Role'**
  String get targetRole;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get memberSince;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @chatSessions.
  ///
  /// In en, this message translates to:
  /// **'Chat Sessions'**
  String get chatSessions;

  /// No description provided for @interviews.
  ///
  /// In en, this message translates to:
  /// **'Interviews'**
  String get interviews;

  /// No description provided for @vocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get vocabulary;

  /// No description provided for @quizzes.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get quizzes;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @preferencesDesc.
  ///
  /// In en, this message translates to:
  /// **'AI personality, difficulty, language'**
  String get preferencesDesc;

  /// No description provided for @howToUse.
  ///
  /// In en, this message translates to:
  /// **'How to Use'**
  String get howToUse;

  /// No description provided for @howToUseDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete guide to all features'**
  String get howToUseDesc;

  /// No description provided for @rateOnPlayStore.
  ///
  /// In en, this message translates to:
  /// **'Rate on Play Store'**
  String get rateOnPlayStore;

  /// No description provided for @rateOnPlayStoreDesc.
  ///
  /// In en, this message translates to:
  /// **'Enjoying the app? Leave a review!'**
  String get rateOnPlayStoreDesc;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign Out?'**
  String get signOutConfirm;

  /// No description provided for @signOutMessage.
  ///
  /// In en, this message translates to:
  /// **'Your progress and XP are saved. You can sign back in anytime.'**
  String get signOutMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved ✅'**
  String get profileSaved;

  /// No description provided for @avatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Avatar updated! ✨'**
  String get avatarUpdated;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings ⚙️'**
  String get settings;

  /// No description provided for @difficultyLevel.
  ///
  /// In en, this message translates to:
  /// **'DIFFICULTY LEVEL'**
  String get difficultyLevel;

  /// No description provided for @aiPersonality.
  ///
  /// In en, this message translates to:
  /// **'AI PERSONALITY'**
  String get aiPersonality;

  /// No description provided for @voiceSpeed.
  ///
  /// In en, this message translates to:
  /// **'VOICE SPEED'**
  String get voiceSpeed;

  /// No description provided for @translationLanguage.
  ///
  /// In en, this message translates to:
  /// **'TRANSLATION LANGUAGE'**
  String get translationLanguage;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notifications;

  /// No description provided for @practiceReminders.
  ///
  /// In en, this message translates to:
  /// **'Practice Reminders'**
  String get practiceReminders;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTime;

  /// No description provided for @testNotification.
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get testNotification;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'DATA'**
  String get data;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearAllData;

  /// No description provided for @clearAllDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Reset all progress and settings'**
  String get clearAllDataDesc;

  /// No description provided for @clearAllDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data?'**
  String get clearAllDataConfirm;

  /// No description provided for @clearAllDataMessage.
  ///
  /// In en, this message translates to:
  /// **'This will reset all your progress, XP, streaks, and settings. This cannot be undone.'**
  String get clearAllDataMessage;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @privacyFirst.
  ///
  /// In en, this message translates to:
  /// **'SpeakUp AI — Privacy First'**
  String get privacyFirst;

  /// No description provided for @voiceQuality.
  ///
  /// In en, this message translates to:
  /// **'VOICE QUALITY & TONE'**
  String get voiceQuality;

  /// No description provided for @vocalTone.
  ///
  /// In en, this message translates to:
  /// **'Vocal Tone (Pitch)'**
  String get vocalTone;

  /// No description provided for @testVoice.
  ///
  /// In en, this message translates to:
  /// **'Test My Voice'**
  String get testVoice;

  /// No description provided for @neuralVoiceDesc.
  ///
  /// In en, this message translates to:
  /// **'Using High-Quality Natural Voice Engine'**
  String get neuralVoiceDesc;

  /// No description provided for @beginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get beginner;

  /// No description provided for @beginnerDesc.
  ///
  /// In en, this message translates to:
  /// **'Simple vocabulary, slow pacing'**
  String get beginnerDesc;

  /// No description provided for @intermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get intermediate;

  /// No description provided for @intermediateDesc.
  ///
  /// In en, this message translates to:
  /// **'Professional language'**
  String get intermediateDesc;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @advancedDesc.
  ///
  /// In en, this message translates to:
  /// **'Complex structures, fast pacing'**
  String get advancedDesc;

  /// No description provided for @slow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get slow;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @fast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get fast;

  /// No description provided for @aiVoiceGallery.
  ///
  /// In en, this message translates to:
  /// **'AI VOICE GALLERY'**
  String get aiVoiceGallery;

  /// No description provided for @interviewPrep.
  ///
  /// In en, this message translates to:
  /// **'Interview Prep 🎯'**
  String get interviewPrep;

  /// No description provided for @practiceSettings.
  ///
  /// In en, this message translates to:
  /// **'Practice Settings'**
  String get practiceSettings;

  /// No description provided for @resumeMode.
  ///
  /// In en, this message translates to:
  /// **'Resume mode'**
  String get resumeMode;

  /// No description provided for @vocabularyBuilder.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary Builder'**
  String get vocabularyBuilder;

  /// No description provided for @newWord.
  ///
  /// In en, this message translates to:
  /// **'New Word'**
  String get newWord;

  /// No description provided for @wordOfTheDay.
  ///
  /// In en, this message translates to:
  /// **'Word of the Day'**
  String get wordOfTheDay;

  /// No description provided for @practiceUseIt.
  ///
  /// In en, this message translates to:
  /// **'Practice Use it'**
  String get practiceUseIt;

  /// No description provided for @buildSentence.
  ///
  /// In en, this message translates to:
  /// **'Build a sentence around \"{word}\"'**
  String buildSentence(String word);

  /// No description provided for @analyzeSentence.
  ///
  /// In en, this message translates to:
  /// **'Analyze Sentence'**
  String get analyzeSentence;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get excellent;

  /// No description provided for @needsWork.
  ///
  /// In en, this message translates to:
  /// **'Needs Work'**
  String get needsWork;

  /// No description provided for @betterVersion.
  ///
  /// In en, this message translates to:
  /// **'BETTER VERSION'**
  String get betterVersion;

  /// No description provided for @awardedXP.
  ///
  /// In en, this message translates to:
  /// **'Awarded +{xp} XP ⭐'**
  String awardedXP(int xp);

  /// No description provided for @howScenarioWorks.
  ///
  /// In en, this message translates to:
  /// **'How Scenario Practice Works'**
  String get howScenarioWorks;

  /// No description provided for @scenarioStep1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Pick a Situation'**
  String get scenarioStep1Title;

  /// No description provided for @scenarioStep1Desc.
  ///
  /// In en, this message translates to:
  /// **'Select a real-world context like \'Ordering Food\' or \'Job Interview\'.'**
  String get scenarioStep1Desc;

  /// No description provided for @scenarioStep2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Follow the Prompt'**
  String get scenarioStep2Title;

  /// No description provided for @scenarioStep2Desc.
  ///
  /// In en, this message translates to:
  /// **'AI will start the roleplay with a realistic question or situation.'**
  String get scenarioStep2Desc;

  /// No description provided for @scenarioStep3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Speak Naturally'**
  String get scenarioStep3Title;

  /// No description provided for @scenarioStep3Desc.
  ///
  /// In en, this message translates to:
  /// **'Use the microphone to respond naturally as you would in real life.'**
  String get scenarioStep3Desc;

  /// No description provided for @scenarioStep4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Get AI Coaching'**
  String get scenarioStep4Title;

  /// No description provided for @scenarioStep4Desc.
  ///
  /// In en, this message translates to:
  /// **'AI evaluates your response and keeps the conversation flowing.'**
  String get scenarioStep4Desc;

  /// No description provided for @roleSoftwareEngineer.
  ///
  /// In en, this message translates to:
  /// **'Software Engineer'**
  String get roleSoftwareEngineer;

  /// No description provided for @roleDataAnalyst.
  ///
  /// In en, this message translates to:
  /// **'Data Analyst'**
  String get roleDataAnalyst;

  /// No description provided for @roleProductManager.
  ///
  /// In en, this message translates to:
  /// **'Product Manager'**
  String get roleProductManager;

  /// No description provided for @roleBusinessAnalyst.
  ///
  /// In en, this message translates to:
  /// **'Business Analyst'**
  String get roleBusinessAnalyst;

  /// No description provided for @roleFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get roleFinance;

  /// No description provided for @roleExplorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get roleExplorer;

  /// No description provided for @roleOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get roleOther;

  /// No description provided for @levelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get levelBeginner;

  /// No description provided for @levelFresher.
  ///
  /// In en, this message translates to:
  /// **'Fresher'**
  String get levelFresher;

  /// No description provided for @levelYears12.
  ///
  /// In en, this message translates to:
  /// **'1-2 Years'**
  String get levelYears12;

  /// No description provided for @levelYears35.
  ///
  /// In en, this message translates to:
  /// **'3-5 Years'**
  String get levelYears35;

  /// No description provided for @levelYears5Plus.
  ///
  /// In en, this message translates to:
  /// **'5+ Years'**
  String get levelYears5Plus;

  /// No description provided for @personalityFriendly.
  ///
  /// In en, this message translates to:
  /// **'Friendly Coach'**
  String get personalityFriendly;

  /// No description provided for @personalityStrict.
  ///
  /// In en, this message translates to:
  /// **'Strict Coach'**
  String get personalityStrict;

  /// No description provided for @personalityHR.
  ///
  /// In en, this message translates to:
  /// **'HR Manager'**
  String get personalityHR;

  /// No description provided for @personalityDebate.
  ///
  /// In en, this message translates to:
  /// **'Debate Partner'**
  String get personalityDebate;

  /// No description provided for @refreshVoiceList.
  ///
  /// In en, this message translates to:
  /// **'Refresh Voice List'**
  String get refreshVoiceList;

  /// No description provided for @experienceLevel.
  ///
  /// In en, this message translates to:
  /// **'Experience Level'**
  String get experienceLevel;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @nameValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get nameValidation;

  /// No description provided for @emailValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get emailValidation;

  /// No description provided for @practiceCoachHindi.
  ///
  /// In en, this message translates to:
  /// **'नमस्ते! मैं आपका स्पीकअप एआई कोच हूँ। क्या आप आज अभ्यास के लिए तैयार हैं?'**
  String get practiceCoachHindi;

  /// No description provided for @practiceCoachEnglish.
  ///
  /// In en, this message translates to:
  /// **'Hello! I am your SpeakUp AI coach. Are you ready for some practice today?'**
  String get practiceCoachEnglish;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
