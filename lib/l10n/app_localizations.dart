import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_nl.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('nl'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest For More'**
  String get appTitle;

  /// No description provided for @tabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tabToday;

  /// No description provided for @tabMoments.
  ///
  /// In en, this message translates to:
  /// **'Moments'**
  String get tabMoments;

  /// No description provided for @tabProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get tabProgress;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @progressNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Progress is not available yet.'**
  String get progressNotAvailable;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your settings and tags'**
  String get profileSubtitle;

  /// No description provided for @nfcTagsTitle.
  ///
  /// In en, this message translates to:
  /// **'NFC tags'**
  String get nfcTagsTitle;

  /// No description provided for @tagsPairPrompt.
  ///
  /// In en, this message translates to:
  /// **'Pair a tag to start and end moments with a tap.'**
  String get tagsPairPrompt;

  /// No description provided for @tagsNonePaired.
  ///
  /// In en, this message translates to:
  /// **'No tags paired yet.'**
  String get tagsNonePaired;

  /// No description provided for @tagsPaired.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 tag paired.} other{{count} tags paired.}}'**
  String tagsPaired(int count);

  /// No description provided for @manageTags.
  ///
  /// In en, this message translates to:
  /// **'Manage tags'**
  String get manageTags;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageDutch.
  ///
  /// In en, this message translates to:
  /// **'Nederlands'**
  String get languageDutch;

  /// No description provided for @appBlocked.
  ///
  /// In en, this message translates to:
  /// **'This app is blocked'**
  String get appBlocked;

  /// No description provided for @openRestForMore.
  ///
  /// In en, this message translates to:
  /// **'Open Rest For More'**
  String get openRestForMore;

  /// No description provided for @connectStartStep.
  ///
  /// In en, this message translates to:
  /// **'Connect onStartStep to your rest session screen.'**
  String get connectStartStep;

  /// No description provided for @whyThisStep.
  ///
  /// In en, this message translates to:
  /// **'Why this step?'**
  String get whyThisStep;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @dayOfTotal.
  ///
  /// In en, this message translates to:
  /// **'DAY {day} OF {total}'**
  String dayOfTotal(int day, int total);

  /// No description provided for @startTodaysStep.
  ///
  /// In en, this message translates to:
  /// **'Start today’s step'**
  String get startTodaysStep;

  /// No description provided for @makeItSmaller.
  ///
  /// In en, this message translates to:
  /// **'Make it smaller'**
  String get makeItSmaller;

  /// No description provided for @todaysInvitation.
  ///
  /// In en, this message translates to:
  /// **'TODAY’S INVITATION'**
  String get todaysInvitation;

  /// No description provided for @quietMomentMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minute quiet moment'**
  String quietMomentMinutes(int minutes);

  /// No description provided for @dayIsDone.
  ///
  /// In en, this message translates to:
  /// **'Day {day} is done.'**
  String dayIsDone(int day);

  /// No description provided for @todaysStepDone.
  ///
  /// In en, this message translates to:
  /// **'Today’s step is done'**
  String get todaysStepDone;

  /// No description provided for @dayReadyTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Day {day} is ready for you tomorrow. One step a day is enough.'**
  String dayReadyTomorrow(int day);

  /// No description provided for @allStepsDone.
  ///
  /// In en, this message translates to:
  /// **'All {totalDays} steps are done'**
  String allStepsDone(int totalDays);

  /// No description provided for @ownRoutineContinues.
  ///
  /// In en, this message translates to:
  /// **'Your own routine continues. Keep the phone location, the phone-away moment and the activity that fitted you best.'**
  String get ownRoutineContinues;

  /// No description provided for @momentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a space for mindful space'**
  String get momentsSubtitle;

  /// No description provided for @momentTagTitle.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get momentTagTitle;

  /// No description provided for @momentTagDescription.
  ///
  /// In en, this message translates to:
  /// **'Set your apps aside with a tap of your tag, and bring them back with the same tap.'**
  String get momentTagDescription;

  /// No description provided for @begin.
  ///
  /// In en, this message translates to:
  /// **'Begin'**
  String get begin;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @welcomeEyebrow.
  ///
  /// In en, this message translates to:
  /// **'WELCOME TO REST FOR MORE'**
  String get welcomeEyebrow;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'A thoughtful path to\nintentional rest'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'We believe that productivity is only half of life’s rhythm. Let us help you put the phone down, clear your thoughts, and create personal space for slow, deep recovery.'**
  String get welcomeBody;

  /// No description provided for @welcomeBenefit1.
  ///
  /// In en, this message translates to:
  /// **'No account needed to start your custom routine'**
  String get welcomeBenefit1;

  /// No description provided for @welcomeBenefit2.
  ///
  /// In en, this message translates to:
  /// **'A gentle, guided 14-day progressive plan'**
  String get welcomeBenefit2;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @stepOfFive.
  ///
  /// In en, this message translates to:
  /// **'STEP {n} OF 5'**
  String stepOfFive(int n);

  /// No description provided for @goalTitle.
  ///
  /// In en, this message translates to:
  /// **'What would you like to\nfocus on?'**
  String get goalTitle;

  /// No description provided for @goalPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Put the phone away earlier'**
  String get goalPhoneTitle;

  /// No description provided for @goalPhoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Build a comforting boundary between your screen and your evening sleep cycle.'**
  String get goalPhoneDesc;

  /// No description provided for @goalRoutineTitle.
  ///
  /// In en, this message translates to:
  /// **'Build a routine'**
  String get goalRoutineTitle;

  /// No description provided for @goalRoutineDesc.
  ///
  /// In en, this message translates to:
  /// **'Create small, nourishing daily rituals that signal your nervous system to recover.'**
  String get goalRoutineDesc;

  /// No description provided for @goalSocialTitle.
  ///
  /// In en, this message translates to:
  /// **'Use less social media'**
  String get goalSocialTitle;

  /// No description provided for @goalSocialDesc.
  ///
  /// In en, this message translates to:
  /// **'Step back from hyper-stimulating feeds and recapture your focus.'**
  String get goalSocialDesc;

  /// No description provided for @obstacleTitle.
  ///
  /// In en, this message translates to:
  /// **'What gets in the way\nof your rest?'**
  String get obstacleTitle;

  /// No description provided for @selectAllThatApply.
  ///
  /// In en, this message translates to:
  /// **'Select all that apply.'**
  String get selectAllThatApply;

  /// No description provided for @obstacleScrolling.
  ///
  /// In en, this message translates to:
  /// **'Scrolling'**
  String get obstacleScrolling;

  /// No description provided for @obstacleAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get obstacleAvailability;

  /// No description provided for @obstacleThoughts.
  ///
  /// In en, this message translates to:
  /// **'Restless thoughts'**
  String get obstacleThoughts;

  /// No description provided for @obstaclePlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get obstaclePlanning;

  /// No description provided for @obstacleAlarm.
  ///
  /// In en, this message translates to:
  /// **'Phone as alarm'**
  String get obstacleAlarm;

  /// No description provided for @obstacleNoRoutine.
  ///
  /// In en, this message translates to:
  /// **'No routine'**
  String get obstacleNoRoutine;

  /// No description provided for @rhythmTitle.
  ///
  /// In en, this message translates to:
  /// **'When does your day\nusually wind down?'**
  String get rhythmTitle;

  /// No description provided for @rhythmIntro.
  ///
  /// In en, this message translates to:
  /// **'Tell us roughly when your energy begins to slip. We’ll match your rest plan to your natural rhythm.'**
  String get rhythmIntro;

  /// No description provided for @rhythmEarlyTitle.
  ///
  /// In en, this message translates to:
  /// **'8:00 – 10:00 PM'**
  String get rhythmEarlyTitle;

  /// No description provided for @rhythmEarlyDesc.
  ///
  /// In en, this message translates to:
  /// **'I usually start winding down early.'**
  String get rhythmEarlyDesc;

  /// No description provided for @rhythmMidTitle.
  ///
  /// In en, this message translates to:
  /// **'10:00 PM – 12:00 AM'**
  String get rhythmMidTitle;

  /// No description provided for @rhythmMidDesc.
  ///
  /// In en, this message translates to:
  /// **'My evenings usually continue a little longer.'**
  String get rhythmMidDesc;

  /// No description provided for @rhythmLateTitle.
  ///
  /// In en, this message translates to:
  /// **'After midnight'**
  String get rhythmLateTitle;

  /// No description provided for @rhythmLateDesc.
  ///
  /// In en, this message translates to:
  /// **'I normally wind down quite late at night.'**
  String get rhythmLateDesc;

  /// No description provided for @activitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'What kind of activities\nappeal to you?'**
  String get activitiesTitle;

  /// No description provided for @activitiesIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose the kinds of restful activities that feel natural to you. You can select more than one.'**
  String get activitiesIntro;

  /// No description provided for @activityQuietTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiet moments'**
  String get activityQuietTitle;

  /// No description provided for @activityQuietDesc.
  ///
  /// In en, this message translates to:
  /// **'Slow down with a few peaceful minutes away from your screen.'**
  String get activityQuietDesc;

  /// No description provided for @activityReadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Paper reading'**
  String get activityReadingTitle;

  /// No description provided for @activityReadingDesc.
  ///
  /// In en, this message translates to:
  /// **'Put the phone aside and spend some time with a physical book.'**
  String get activityReadingDesc;

  /// No description provided for @activityBreathingTitle.
  ///
  /// In en, this message translates to:
  /// **'Evening breathing routines'**
  String get activityBreathingTitle;

  /// No description provided for @activityBreathingDesc.
  ///
  /// In en, this message translates to:
  /// **'Use simple breathing exercises to settle your body and mind.'**
  String get activityBreathingDesc;

  /// No description provided for @finalStep.
  ///
  /// In en, this message translates to:
  /// **'FINAL STEP'**
  String get finalStep;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Would you like a\ndaily reminder?'**
  String get reminderTitle;

  /// No description provided for @reminderIntro.
  ///
  /// In en, this message translates to:
  /// **'A gentle reminder can help you make space for rest without adding pressure.'**
  String get reminderIntro;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get dailyReminder;

  /// No description provided for @oneGentleReminder.
  ///
  /// In en, this message translates to:
  /// **'One gentle reminder each day'**
  String get oneGentleReminder;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTime;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get maybeLater;

  /// No description provided for @whyWeChoseThis.
  ///
  /// In en, this message translates to:
  /// **'Why we chose this for you'**
  String get whyWeChoseThis;

  /// No description provided for @dayRange.
  ///
  /// In en, this message translates to:
  /// **'Day {from}–{to}'**
  String dayRange(int from, int to);

  /// No description provided for @planTitle.
  ///
  /// In en, this message translates to:
  /// **'Here’s your\npersonal plan'**
  String get planTitle;

  /// No description provided for @planIntro.
  ///
  /// In en, this message translates to:
  /// **'A gentle 14-day plan designed around your goals, rhythm and preferred activities.'**
  String get planIntro;

  /// No description provided for @startYourPlan.
  ///
  /// In en, this message translates to:
  /// **'Start your plan'**
  String get startYourPlan;

  /// No description provided for @adjustPlanSettings.
  ///
  /// In en, this message translates to:
  /// **'Adjust plan settings'**
  String get adjustPlanSettings;

  /// No description provided for @dayWithTitle.
  ///
  /// In en, this message translates to:
  /// **'Day {day}: {title}'**
  String dayWithTitle(int day, String title);

  /// No description provided for @phaseN.
  ///
  /// In en, this message translates to:
  /// **'PHASE {n}'**
  String phaseN(int n);

  /// No description provided for @phase1Title.
  ///
  /// In en, this message translates to:
  /// **'Create some space'**
  String get phase1Title;

  /// No description provided for @phase1Desc.
  ///
  /// In en, this message translates to:
  /// **'Start small by creating a little distance between you and your phone.'**
  String get phase1Desc;

  /// No description provided for @phase1Item1.
  ///
  /// In en, this message translates to:
  /// **'Put your phone away for 10 minutes'**
  String get phase1Item1;

  /// No description provided for @phase1Item2.
  ///
  /// In en, this message translates to:
  /// **'Take one quiet moment'**
  String get phase1Item2;

  /// No description provided for @phase1Item3.
  ///
  /// In en, this message translates to:
  /// **'Notice how your evening feels'**
  String get phase1Item3;

  /// No description provided for @phase2Title.
  ///
  /// In en, this message translates to:
  /// **'Build your rhythm'**
  String get phase2Title;

  /// No description provided for @phase2Desc.
  ///
  /// In en, this message translates to:
  /// **'Turn your first small steps into a simple evening routine.'**
  String get phase2Desc;

  /// No description provided for @phase2Item1.
  ///
  /// In en, this message translates to:
  /// **'Begin winding down earlier'**
  String get phase2Item1;

  /// No description provided for @phase2Item2.
  ///
  /// In en, this message translates to:
  /// **'Choose a screen-free activity'**
  String get phase2Item2;

  /// No description provided for @phase2Item3.
  ///
  /// In en, this message translates to:
  /// **'Repeat your evening routine'**
  String get phase2Item3;

  /// No description provided for @phase3Title.
  ///
  /// In en, this message translates to:
  /// **'Make it yours'**
  String get phase3Title;

  /// No description provided for @phase3Desc.
  ///
  /// In en, this message translates to:
  /// **'Strengthen the habits that work best for you and your rest.'**
  String get phase3Desc;

  /// No description provided for @phase3Item1.
  ///
  /// In en, this message translates to:
  /// **'Keep your preferred routine'**
  String get phase3Item1;

  /// No description provided for @phase3Item2.
  ///
  /// In en, this message translates to:
  /// **'Reflect on what helped most'**
  String get phase3Item2;

  /// No description provided for @phase3Item3.
  ///
  /// In en, this message translates to:
  /// **'Prepare for life after day 14'**
  String get phase3Item3;

  /// No description provided for @adjustSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Your changes could not be saved. Please try again.'**
  String get adjustSaveFailed;

  /// No description provided for @reviewChanges.
  ///
  /// In en, this message translates to:
  /// **'Review changes'**
  String get reviewChanges;

  /// No description provided for @keepCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'Keep my current plan'**
  String get keepCurrentPlan;

  /// No description provided for @confirmChanges.
  ///
  /// In en, this message translates to:
  /// **'Confirm changes'**
  String get confirmChanges;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @adjustEyebrow.
  ///
  /// In en, this message translates to:
  /// **'ADJUST YOUR PLAN'**
  String get adjustEyebrow;

  /// No description provided for @adjustTitle.
  ///
  /// In en, this message translates to:
  /// **'Make the plan\nfit you'**
  String get adjustTitle;

  /// No description provided for @adjustIntro.
  ///
  /// In en, this message translates to:
  /// **'Change only what doesn’t fit. Your other answers stay as they are, so you don’t have to start over.'**
  String get adjustIntro;

  /// No description provided for @stepSizeQuestion.
  ///
  /// In en, this message translates to:
  /// **'How big should each step be?'**
  String get stepSizeQuestion;

  /// No description provided for @standardSteps.
  ///
  /// In en, this message translates to:
  /// **'Standard steps'**
  String get standardSteps;

  /// No description provided for @standardStepsDesc.
  ///
  /// In en, this message translates to:
  /// **'The full version of each day’s step.'**
  String get standardStepsDesc;

  /// No description provided for @smallerSteps.
  ///
  /// In en, this message translates to:
  /// **'Smaller steps'**
  String get smallerSteps;

  /// No description provided for @smallerStepsDesc.
  ///
  /// In en, this message translates to:
  /// **'A lighter version of each step. It counts just as much, and you keep all 14 days.'**
  String get smallerStepsDesc;

  /// No description provided for @yourGoal.
  ///
  /// In en, this message translates to:
  /// **'Your goal'**
  String get yourGoal;

  /// No description provided for @obstacleQuestion.
  ///
  /// In en, this message translates to:
  /// **'What gets in the way most?'**
  String get obstacleQuestion;

  /// No description provided for @calmActivity.
  ///
  /// In en, this message translates to:
  /// **'Calm activity'**
  String get calmActivity;

  /// No description provided for @reviewYourChanges.
  ///
  /// In en, this message translates to:
  /// **'Review your changes'**
  String get reviewYourChanges;

  /// No description provided for @nothingSavedUntilConfirm.
  ///
  /// In en, this message translates to:
  /// **'Nothing is saved until you confirm.'**
  String get nothingSavedUntilConfirm;

  /// No description provided for @adjustRunningStepSize.
  ///
  /// In en, this message translates to:
  /// **'The days still to come get the new step size. Days you already did stay as they are.'**
  String get adjustRunningStepSize;

  /// No description provided for @adjustRunningNewPlan.
  ///
  /// In en, this message translates to:
  /// **'Your new plan becomes your active plan and starts at day 1. What you already did stays saved.'**
  String get adjustRunningNewPlan;

  /// No description provided for @yourFirstDays.
  ///
  /// In en, this message translates to:
  /// **'Your first days'**
  String get yourFirstDays;

  /// No description provided for @momentFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get momentFocusTitle;

  /// No description provided for @momentFocusDescription.
  ///
  /// In en, this message translates to:
  /// **'Clear your mind to commit to a single quiet workflow.'**
  String get momentFocusDescription;

  /// No description provided for @momentFocusPill.
  ///
  /// In en, this message translates to:
  /// **'A quiet place'**
  String get momentFocusPill;

  /// No description provided for @momentFocusHeading.
  ///
  /// In en, this message translates to:
  /// **'Settle into the moment'**
  String get momentFocusHeading;

  /// No description provided for @momentFocusQuote.
  ///
  /// In en, this message translates to:
  /// **'One thing, fully attended.'**
  String get momentFocusQuote;

  /// No description provided for @momentFocusButton.
  ///
  /// In en, this message translates to:
  /// **'Start Focus'**
  String get momentFocusButton;

  /// No description provided for @momentFocusStep1.
  ///
  /// In en, this message translates to:
  /// **'Choose one meaningful task.'**
  String get momentFocusStep1;

  /// No description provided for @momentFocusStep2.
  ///
  /// In en, this message translates to:
  /// **'Let your breath settle for three slow counts.'**
  String get momentFocusStep2;

  /// No description provided for @momentFocusStep3.
  ///
  /// In en, this message translates to:
  /// **'Return gently whenever your attention wanders.'**
  String get momentFocusStep3;

  /// No description provided for @momentReadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get momentReadingTitle;

  /// No description provided for @momentReadingDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep distractions away while you read.'**
  String get momentReadingDescription;

  /// No description provided for @momentReadingPill.
  ///
  /// In en, this message translates to:
  /// **'One page at a time'**
  String get momentReadingPill;

  /// No description provided for @momentReadingHeading.
  ///
  /// In en, this message translates to:
  /// **'Settle into the moment'**
  String get momentReadingHeading;

  /// No description provided for @momentReadingQuote.
  ///
  /// In en, this message translates to:
  /// **'One page, fully attended.'**
  String get momentReadingQuote;

  /// No description provided for @momentReadingButton.
  ///
  /// In en, this message translates to:
  /// **'Start Reading'**
  String get momentReadingButton;

  /// No description provided for @momentReadingStep1.
  ///
  /// In en, this message translates to:
  /// **'Pick the book or article you want to read.'**
  String get momentReadingStep1;

  /// No description provided for @momentReadingStep2.
  ///
  /// In en, this message translates to:
  /// **'Let your shoulders drop and breathe out slowly.'**
  String get momentReadingStep2;

  /// No description provided for @momentReadingStep3.
  ///
  /// In en, this message translates to:
  /// **'When your mind drifts, return to the next line.'**
  String get momentReadingStep3;

  /// No description provided for @momentEveningTitle.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get momentEveningTitle;

  /// No description provided for @momentEveningDescription.
  ///
  /// In en, this message translates to:
  /// **'Wind down and put your phone away before bed.'**
  String get momentEveningDescription;

  /// No description provided for @momentEveningPill.
  ///
  /// In en, this message translates to:
  /// **'A gentle landing'**
  String get momentEveningPill;

  /// No description provided for @momentEveningHeading.
  ///
  /// In en, this message translates to:
  /// **'Close the day'**
  String get momentEveningHeading;

  /// No description provided for @momentEveningQuote.
  ///
  /// In en, this message translates to:
  /// **'The day is allowed to end.'**
  String get momentEveningQuote;

  /// No description provided for @momentEveningButton.
  ///
  /// In en, this message translates to:
  /// **'Plan your evening'**
  String get momentEveningButton;

  /// No description provided for @momentEveningStep1.
  ///
  /// In en, this message translates to:
  /// **'Choose when you want to be in bed.'**
  String get momentEveningStep1;

  /// No description provided for @momentEveningStep2.
  ///
  /// In en, this message translates to:
  /// **'Decide what your evening needs, and in what order.'**
  String get momentEveningStep2;

  /// No description provided for @momentEveningStep3.
  ///
  /// In en, this message translates to:
  /// **'Let your phone rest while you wind down.'**
  String get momentEveningStep3;

  /// No description provided for @momentMorningTitle.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get momentMorningTitle;

  /// No description provided for @momentMorningDescription.
  ///
  /// In en, this message translates to:
  /// **'Start the day before your phone does.'**
  String get momentMorningDescription;

  /// No description provided for @momentMorningPill.
  ///
  /// In en, this message translates to:
  /// **'A slow start'**
  String get momentMorningPill;

  /// No description provided for @momentMorningHeading.
  ///
  /// In en, this message translates to:
  /// **'Begin the day'**
  String get momentMorningHeading;

  /// No description provided for @momentMorningQuote.
  ///
  /// In en, this message translates to:
  /// **'Your morning is yours first.'**
  String get momentMorningQuote;

  /// No description provided for @momentMorningButton.
  ///
  /// In en, this message translates to:
  /// **'Plan your morning'**
  String get momentMorningButton;

  /// No description provided for @momentMorningStep1.
  ///
  /// In en, this message translates to:
  /// **'Choose when you wake up.'**
  String get momentMorningStep1;

  /// No description provided for @momentMorningStep2.
  ///
  /// In en, this message translates to:
  /// **'Pick what your morning needs before your phone.'**
  String get momentMorningStep2;

  /// No description provided for @momentMorningStep3.
  ///
  /// In en, this message translates to:
  /// **'Your phone returns when your morning is done.'**
  String get momentMorningStep3;

  /// No description provided for @aGentleReminder.
  ///
  /// In en, this message translates to:
  /// **'A GENTLE REMINDER'**
  String get aGentleReminder;

  /// No description provided for @backToMoments.
  ///
  /// In en, this message translates to:
  /// **'Back to Moments'**
  String get backToMoments;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{m} min'**
  String durationMinutes(int m);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{h} h'**
  String durationHours(int h);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{h} h {m} min'**
  String durationHoursMinutes(int h, String m);

  /// No description provided for @eveningEndAtBedtime.
  ///
  /// In en, this message translates to:
  /// **'At bedtime'**
  String get eveningEndAtBedtime;

  /// No description provided for @eveningEndAtNextScan.
  ///
  /// In en, this message translates to:
  /// **'At the next scan'**
  String get eveningEndAtNextScan;

  /// No description provided for @blockingStartsHere.
  ///
  /// In en, this message translates to:
  /// **'Blocking starts here.'**
  String get blockingStartsHere;

  /// No description provided for @saveEvening.
  ///
  /// In en, this message translates to:
  /// **'Save evening'**
  String get saveEvening;

  /// No description provided for @eveningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your bedtime. We count back from there.'**
  String get eveningSubtitle;

  /// No description provided for @bedtimePerDay.
  ///
  /// In en, this message translates to:
  /// **'Bedtime per day'**
  String get bedtimePerDay;

  /// No description provided for @bedtimeNote.
  ///
  /// In en, this message translates to:
  /// **'A bedtime between 00:00 and 05:59 belongs to the evening before, so a Friday evening can end on Saturday at 00:30.'**
  String get bedtimeNote;

  /// No description provided for @eveningAfterMidnight.
  ///
  /// In en, this message translates to:
  /// **'After midnight'**
  String get eveningAfterMidnight;

  /// No description provided for @yourEvening.
  ///
  /// In en, this message translates to:
  /// **'Your evening'**
  String get yourEvening;

  /// No description provided for @yourEveningNote.
  ///
  /// In en, this message translates to:
  /// **'Your evening starts early enough to fit every step before bedtime. Putting your phone away comes first.'**
  String get yourEveningNote;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @headsUpBefore.
  ///
  /// In en, this message translates to:
  /// **'Heads-up before your evening starts'**
  String get headsUpBefore;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{v} min'**
  String minutesShort(int v);

  /// No description provided for @secondReminder.
  ///
  /// In en, this message translates to:
  /// **'Second reminder if you have not started'**
  String get secondReminder;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @afterMinutes.
  ///
  /// In en, this message translates to:
  /// **'After {v} min'**
  String afterMinutes(int v);

  /// No description provided for @remindersNote.
  ///
  /// In en, this message translates to:
  /// **'Reminders are local notifications. The app can ask, but it cannot make you put your phone away, and your phone’s silent or Focus modes can still mute them.'**
  String get remindersNote;

  /// No description provided for @whenBlockingEnds.
  ///
  /// In en, this message translates to:
  /// **'When blocking ends'**
  String get whenBlockingEnds;

  /// No description provided for @strictOvernight.
  ///
  /// In en, this message translates to:
  /// **'Strict overnight: blocking stays on until you scan. A timer will not end it for you.'**
  String get strictOvernight;

  /// No description provided for @liftsAtBedtime.
  ///
  /// In en, this message translates to:
  /// **'Blocking lifts by itself at bedtime.'**
  String get liftsAtBedtime;

  /// No description provided for @yourWeekdayEvening.
  ///
  /// In en, this message translates to:
  /// **'Your {day} evening'**
  String yourWeekdayEvening(String day);

  /// No description provided for @headsUp.
  ///
  /// In en, this message translates to:
  /// **'Heads-up'**
  String get headsUp;

  /// No description provided for @headsUpDetail.
  ///
  /// In en, this message translates to:
  /// **'A reminder that your evening is about to start.'**
  String get headsUpDetail;

  /// No description provided for @bedtime.
  ///
  /// In en, this message translates to:
  /// **'Bedtime'**
  String get bedtime;

  /// No description provided for @bedtimeBlockingEnds.
  ///
  /// In en, this message translates to:
  /// **'Bedtime · blocking ends'**
  String get bedtimeBlockingEnds;

  /// No description provided for @blockingStaysUntilScan.
  ///
  /// In en, this message translates to:
  /// **'Blocking stays until your next scan.'**
  String get blockingStaysUntilScan;

  /// No description provided for @saveMorning.
  ///
  /// In en, this message translates to:
  /// **'Save morning'**
  String get saveMorning;

  /// No description provided for @wakeUpTimePerDay.
  ///
  /// In en, this message translates to:
  /// **'Wake-up time per day'**
  String get wakeUpTimePerDay;

  /// No description provided for @wakeUpNote.
  ///
  /// In en, this message translates to:
  /// **'This is not your phone alarm. The app cannot hook into the system alarm, so set the same time there. Your morning starts at the time you choose here.'**
  String get wakeUpNote;

  /// No description provided for @yourMorning.
  ///
  /// In en, this message translates to:
  /// **'Your morning'**
  String get yourMorning;

  /// No description provided for @yourMorningNote.
  ///
  /// In en, this message translates to:
  /// **'Everything you do before your phone comes back. Your phone is not a step. It is what comes after.'**
  String get yourMorningNote;

  /// No description provided for @yourWeekdayMorning.
  ///
  /// In en, this message translates to:
  /// **'Your {day} morning'**
  String yourWeekdayMorning(String day);

  /// No description provided for @timerOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Timer only: apps unlock by themselves when your steps are done. This is not a strict block.'**
  String get timerOnlyNote;

  /// No description provided for @timesFollowClock.
  ///
  /// In en, this message translates to:
  /// **'Times follow your phone’s clock and time zone.'**
  String get timesFollowClock;

  /// No description provided for @phoneIsBack.
  ///
  /// In en, this message translates to:
  /// **'Your phone is back'**
  String get phoneIsBack;

  /// No description provided for @appsUnlock.
  ///
  /// In en, this message translates to:
  /// **'Apps unlock.'**
  String get appsUnlock;

  /// No description provided for @couldNotSaveMoment.
  ///
  /// In en, this message translates to:
  /// **'Could not save your {name}. Please try again.'**
  String couldNotSaveMoment(String name);

  /// No description provided for @momentSaved.
  ///
  /// In en, this message translates to:
  /// **'{name} saved'**
  String momentSaved(String name);

  /// No description provided for @couldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load. Try again'**
  String get couldNotLoad;

  /// No description provided for @appsToBlock.
  ///
  /// In en, this message translates to:
  /// **'Apps to block'**
  String get appsToBlock;

  /// No description provided for @noAppsChosen.
  ///
  /// In en, this message translates to:
  /// **'No apps chosen yet.'**
  String get noAppsChosen;

  /// No description provided for @appsChosen.
  ///
  /// In en, this message translates to:
  /// **'Apps chosen.'**
  String get appsChosen;

  /// No description provided for @appsChosenCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 app chosen.} other{{count} apps chosen.}}'**
  String appsChosenCount(int count);

  /// No description provided for @onlyUsedFor.
  ///
  /// In en, this message translates to:
  /// **'Only used for {name}. The other moments keep their own choice.'**
  String onlyUsedFor(String name);

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @chooseApps.
  ///
  /// In en, this message translates to:
  /// **'Choose apps'**
  String get chooseApps;

  /// No description provided for @nfcOff.
  ///
  /// In en, this message translates to:
  /// **'NFC is turned off. Enable it in your phone settings.'**
  String get nfcOff;

  /// No description provided for @nfcUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This device does not support NFC.'**
  String get nfcUnsupported;

  /// No description provided for @holdNearTagToEnd.
  ///
  /// In en, this message translates to:
  /// **'Hold your iPhone near your tag to end'**
  String get holdNearTagToEnd;

  /// No description provided for @holdNearTagToBegin.
  ///
  /// In en, this message translates to:
  /// **'Hold your iPhone near your tag to begin'**
  String get holdNearTagToBegin;

  /// No description provided for @scanningStopped.
  ///
  /// In en, this message translates to:
  /// **'Scanning stopped: {message}'**
  String scanningStopped(String message);

  /// No description provided for @notYourTag.
  ///
  /// In en, this message translates to:
  /// **'This is not one of your paired tags.'**
  String get notYourTag;

  /// No description provided for @couldNotReadTag.
  ///
  /// In en, this message translates to:
  /// **'Could not read this tag. Please try again.'**
  String get couldNotReadTag;

  /// No description provided for @couldNotStartScanning.
  ///
  /// In en, this message translates to:
  /// **'Could not start scanning.'**
  String get couldNotStartScanning;

  /// No description provided for @waitingForTag.
  ///
  /// In en, this message translates to:
  /// **'Waiting for tag…'**
  String get waitingForTag;

  /// No description provided for @pairTagFirst.
  ///
  /// In en, this message translates to:
  /// **'Pair a tag first'**
  String get pairTagFirst;

  /// No description provided for @scanTagToEnd.
  ///
  /// In en, this message translates to:
  /// **'Scan tag to end'**
  String get scanTagToEnd;

  /// No description provided for @scanTagToBegin.
  ///
  /// In en, this message translates to:
  /// **'Scan tag to begin'**
  String get scanTagToBegin;

  /// No description provided for @tagMomentDescription.
  ///
  /// In en, this message translates to:
  /// **'Put your apps aside with a tap, and bring them back with the same tag.'**
  String get tagMomentDescription;

  /// No description provided for @tagMomentEyebrow.
  ///
  /// In en, this message translates to:
  /// **'TAG MOMENT'**
  String get tagMomentEyebrow;

  /// No description provided for @statusChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get statusChecking;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusNotActive.
  ///
  /// In en, this message translates to:
  /// **'Not active'**
  String get statusNotActive;

  /// No description provided for @tagActiveBody.
  ///
  /// In en, this message translates to:
  /// **'Your apps are set aside. Only your tag can end this moment.'**
  String get tagActiveBody;

  /// No description provided for @tagReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Ready when you are. Scan your tag to set your apps aside.'**
  String get tagReadyBody;

  /// No description provided for @tagPairBody.
  ///
  /// In en, this message translates to:
  /// **'Pair a tag to use this moment.'**
  String get tagPairBody;

  /// No description provided for @chooseAppsToSetAside.
  ///
  /// In en, this message translates to:
  /// **'Choose apps to set aside'**
  String get chooseAppsToSetAside;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWorks;

  /// No description provided for @tagStep1.
  ///
  /// In en, this message translates to:
  /// **'Choose the apps you want to set aside.'**
  String get tagStep1;

  /// No description provided for @tagStep2.
  ///
  /// In en, this message translates to:
  /// **'Scan your tag to begin.'**
  String get tagStep2;

  /// No description provided for @tagStep3.
  ///
  /// In en, this message translates to:
  /// **'Scan the same tag again to end.'**
  String get tagStep3;

  /// No description provided for @tagQuote.
  ///
  /// In en, this message translates to:
  /// **'Put it down. Pick it up when you choose.'**
  String get tagQuote;

  /// No description provided for @sessionFocusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick how long, and what to keep out of the way.'**
  String get sessionFocusSubtitle;

  /// No description provided for @sessionReadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick how long you want to read, and what stays quiet.'**
  String get sessionReadingSubtitle;

  /// No description provided for @startFocus.
  ///
  /// In en, this message translates to:
  /// **'Start Focus'**
  String get startFocus;

  /// No description provided for @startReading.
  ///
  /// In en, this message translates to:
  /// **'Start Reading'**
  String get startReading;

  /// No description provided for @presetQuick.
  ///
  /// In en, this message translates to:
  /// **'Quick'**
  String get presetQuick;

  /// No description provided for @presetStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get presetStandard;

  /// No description provided for @presetDeep.
  ///
  /// In en, this message translates to:
  /// **'Deep'**
  String get presetDeep;

  /// No description provided for @presetShort.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get presetShort;

  /// No description provided for @presetChapter.
  ///
  /// In en, this message translates to:
  /// **'Chapter'**
  String get presetChapter;

  /// No description provided for @presetLong.
  ///
  /// In en, this message translates to:
  /// **'Long'**
  String get presetLong;

  /// No description provided for @presetCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get presetCustom;

  /// No description provided for @howLong.
  ///
  /// In en, this message translates to:
  /// **'How long'**
  String get howLong;

  /// No description provided for @endsAfterMinutes.
  ///
  /// In en, this message translates to:
  /// **'Ends after {minutes} minutes. Stopping early asks you to confirm first and is logged as stopped early.'**
  String endsAfterMinutes(int minutes);

  /// No description provided for @fewerMinutes.
  ///
  /// In en, this message translates to:
  /// **'Fewer minutes'**
  String get fewerMinutes;

  /// No description provided for @moreMinutes.
  ///
  /// In en, this message translates to:
  /// **'More minutes'**
  String get moreMinutes;

  /// No description provided for @endSessionEarlyTitle.
  ///
  /// In en, this message translates to:
  /// **'End this session early?'**
  String get endSessionEarlyTitle;

  /// No description provided for @endSessionEarlyBody.
  ///
  /// In en, this message translates to:
  /// **'Your apps unlock now. This session will be logged as stopped early.'**
  String get endSessionEarlyBody;

  /// No description provided for @keepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get keepGoing;

  /// No description provided for @endEarly.
  ///
  /// In en, this message translates to:
  /// **'End early'**
  String get endEarly;

  /// No description provided for @sessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get sessionTitle;

  /// No description provided for @sessionStartBlockFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not set your apps aside, so nothing was started. Check that blocking is allowed for Rest For More and try again.'**
  String get sessionStartBlockFailed;

  /// No description provided for @sessionStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while starting. Please try again.'**
  String get sessionStartFailed;

  /// No description provided for @sessionEndFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while ending. Please try again.'**
  String get sessionEndFailed;

  /// No description provided for @appsStillSetAsideTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Your apps are still set aside. Please try again.'**
  String get appsStillSetAsideTryAgain;

  /// No description provided for @settingAppsAside.
  ///
  /// In en, this message translates to:
  /// **'Setting your apps aside…'**
  String get settingAppsAside;

  /// No description provided for @bringingAppsBack.
  ///
  /// In en, this message translates to:
  /// **'Bringing your apps back…'**
  String get bringingAppsBack;

  /// No description provided for @timeLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String timeLeft(String time);

  /// No description provided for @appsSetAsideUntil.
  ///
  /// In en, this message translates to:
  /// **'Your apps are set aside until {time}.'**
  String appsSetAsideUntil(String time);

  /// No description provided for @sessionEnded.
  ///
  /// In en, this message translates to:
  /// **'Session ended'**
  String get sessionEnded;

  /// No description provided for @wellDone.
  ///
  /// In en, this message translates to:
  /// **'Well done'**
  String get wellDone;

  /// No description provided for @sessionEndedEarlyBody.
  ///
  /// In en, this message translates to:
  /// **'Your apps are back. That is fine. Begin again whenever you like.'**
  String get sessionEndedEarlyBody;

  /// No description provided for @sessionCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Your time is complete and your apps are back.'**
  String get sessionCompleteBody;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get somethingWentWrong;

  /// No description provided for @appsStillSetAside.
  ///
  /// In en, this message translates to:
  /// **'Your apps are still set aside'**
  String get appsStillSetAside;

  /// No description provided for @releaseFailedBody.
  ///
  /// In en, this message translates to:
  /// **'The session is over, but we could not bring your apps back. Try again, or open Help if it keeps happening.'**
  String get releaseFailedBody;

  /// No description provided for @needAnApp.
  ///
  /// In en, this message translates to:
  /// **'Need an app?'**
  String get needAnApp;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @unblockFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not unblock this right now. Please try again.'**
  String get unblockFailed;

  /// No description provided for @cancelKeepBlocked.
  ///
  /// In en, this message translates to:
  /// **'Cancel and keep it blocked'**
  String get cancelKeepBlocked;

  /// No description provided for @whichAppNeeded.
  ///
  /// In en, this message translates to:
  /// **'Which app do you need?'**
  String get whichAppNeeded;

  /// No description provided for @onlyOneOpens.
  ///
  /// In en, this message translates to:
  /// **'Only the one you choose opens, and only for a little while.'**
  String get onlyOneOpens;

  /// No description provided for @couldNotReadBlocked.
  ///
  /// In en, this message translates to:
  /// **'Could not read your blocked apps.'**
  String get couldNotReadBlocked;

  /// No description provided for @nothingBlocked.
  ///
  /// In en, this message translates to:
  /// **'Nothing is blocked right now.'**
  String get nothingBlocked;

  /// No description provided for @howLongNeed.
  ///
  /// In en, this message translates to:
  /// **'How long do you really need?'**
  String get howLongNeed;

  /// No description provided for @minutesToUnblock.
  ///
  /// In en, this message translates to:
  /// **'Minutes to unblock'**
  String get minutesToUnblock;

  /// No description provided for @minutesCount.
  ///
  /// In en, this message translates to:
  /// **'{n} minutes'**
  String minutesCount(int n);

  /// No description provided for @minuteUnit.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{minute} other{minutes}}'**
  String minuteUnit(int n);

  /// No description provided for @appsAvailableUntil.
  ///
  /// In en, this message translates to:
  /// **'Your apps will be available until {time}.'**
  String appsAvailableUntil(String time);

  /// No description provided for @nameAvailableUntil.
  ///
  /// In en, this message translates to:
  /// **'{name} will be available until {time}.'**
  String nameAvailableUntil(String name, String time);

  /// No description provided for @unblocking.
  ///
  /// In en, this message translates to:
  /// **'Unblocking…'**
  String get unblocking;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @unblocked.
  ///
  /// In en, this message translates to:
  /// **'Unblocked'**
  String get unblocked;

  /// No description provided for @appsNowAvailable.
  ///
  /// In en, this message translates to:
  /// **'Your apps are available until {time}. It locks again by itself.'**
  String appsNowAvailable(String time);

  /// No description provided for @appNowAvailable.
  ///
  /// In en, this message translates to:
  /// **'{name} is available until {time}. It locks again by itself.'**
  String appNowAvailable(String name, String time);

  /// No description provided for @openApp.
  ///
  /// In en, this message translates to:
  /// **'Open {name}'**
  String openApp(String name);

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @youCanContinueNow.
  ///
  /// In en, this message translates to:
  /// **'You can continue now.'**
  String get youCanContinueNow;

  /// No description provided for @takeMomentBreathe.
  ///
  /// In en, this message translates to:
  /// **'Take a moment to breathe'**
  String get takeMomentBreathe;

  /// No description provided for @wheneverReady.
  ///
  /// In en, this message translates to:
  /// **'Whenever you are ready.'**
  String get wheneverReady;

  /// No description provided for @needOrReachedFor.
  ///
  /// In en, this message translates to:
  /// **'Is this something you need, or something you reached for?'**
  String get needOrReachedFor;

  /// No description provided for @pauseFinished.
  ///
  /// In en, this message translates to:
  /// **'Pause finished'**
  String get pauseFinished;

  /// No description provided for @pauseInProgress.
  ///
  /// In en, this message translates to:
  /// **'Pause in progress, a few seconds'**
  String get pauseInProgress;

  /// No description provided for @stopMomentTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop this moment?'**
  String get stopMomentTitle;

  /// No description provided for @dailyStepUnfinished.
  ///
  /// In en, this message translates to:
  /// **'Your daily step will stay unfinished.'**
  String get dailyStepUnfinished;

  /// No description provided for @stopMoment.
  ///
  /// In en, this message translates to:
  /// **'Stop moment'**
  String get stopMoment;

  /// No description provided for @useStopHint.
  ///
  /// In en, this message translates to:
  /// **'Use Stop to end this moment, or leave the app to keep it going.'**
  String get useStopHint;

  /// No description provided for @quietMomentHyphen.
  ///
  /// In en, this message translates to:
  /// **'{minutes}-minute quiet moment'**
  String quietMomentHyphen(int minutes);

  /// No description provided for @littleSpaceWellDone.
  ///
  /// In en, this message translates to:
  /// **'A little space for yourself. Well done.'**
  String get littleSpaceWellDone;

  /// No description provided for @fewMinutesAway.
  ///
  /// In en, this message translates to:
  /// **'Take a few minutes away from your phone.'**
  String get fewMinutesAway;

  /// No description provided for @finishDailyStep.
  ///
  /// In en, this message translates to:
  /// **'Finish daily step'**
  String get finishDailyStep;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @shortOnTime.
  ///
  /// In en, this message translates to:
  /// **'Short on time or energy? That’s okay. You can still take a small step.'**
  String get shortOnTime;

  /// No description provided for @originalOption.
  ///
  /// In en, this message translates to:
  /// **'ORIGINAL OPTION'**
  String get originalOption;

  /// No description provided for @recommendedAlternative.
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED ALTERNATIVE'**
  String get recommendedAlternative;

  /// No description provided for @startMinuteVersion.
  ///
  /// In en, this message translates to:
  /// **'Start {minutes}-minute version'**
  String startMinuteVersion(int minutes);

  /// No description provided for @keepMinuteVersion.
  ///
  /// In en, this message translates to:
  /// **'Keep {minutes}-minute version'**
  String keepMinuteVersion(int minutes);

  /// No description provided for @keepOriginal.
  ///
  /// In en, this message translates to:
  /// **'Keep the original'**
  String get keepOriginal;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @saveWithCount.
  ///
  /// In en, this message translates to:
  /// **'Save · {count} selected'**
  String saveWithCount(int count);

  /// No description provided for @searchApps.
  ///
  /// In en, this message translates to:
  /// **'Search apps'**
  String get searchApps;

  /// No description provided for @couldNotReadApps.
  ///
  /// In en, this message translates to:
  /// **'Could not read your apps.'**
  String get couldNotReadApps;

  /// No description provided for @appsForMoment.
  ///
  /// In en, this message translates to:
  /// **'Apps for {name}'**
  String appsForMoment(String name);

  /// No description provided for @couldNotSaveApps.
  ///
  /// In en, this message translates to:
  /// **'Could not save your apps. Try again.'**
  String get couldNotSaveApps;

  /// No description provided for @saveAppsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Save 1 app} other{Save {count} apps}}'**
  String saveAppsCount(int count);

  /// No description provided for @chooseApps2.
  ///
  /// In en, this message translates to:
  /// **'Choose apps'**
  String get chooseApps2;

  /// No description provided for @pickAppsToSetAside.
  ///
  /// In en, this message translates to:
  /// **'Pick the apps you want to set aside.'**
  String get pickAppsToSetAside;

  /// No description provided for @appsWillBeSetAside.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 app will be set aside.} other{{count} apps will be set aside.}}'**
  String appsWillBeSetAside(int count);

  /// No description provided for @androidOnlyList.
  ///
  /// In en, this message translates to:
  /// **'Choosing apps from this list is only available on Android.'**
  String get androidOnlyList;

  /// No description provided for @noAppsFound.
  ///
  /// In en, this message translates to:
  /// **'No apps found.'**
  String get noAppsFound;

  /// No description provided for @allowAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Allow accessibility'**
  String get allowAccessibility;

  /// No description provided for @accessibilityBody.
  ///
  /// In en, this message translates to:
  /// **'To set your apps aside, Rest4More needs its accessibility service switched on. It only notices which app opens, so it can step in front of the ones you chose.'**
  String get accessibilityBody;

  /// No description provided for @inSettings.
  ///
  /// In en, this message translates to:
  /// **'In Settings'**
  String get inSettings;

  /// No description provided for @accStep1.
  ///
  /// In en, this message translates to:
  /// **'Open Installed apps or Downloaded apps.'**
  String get accStep1;

  /// No description provided for @accStep2.
  ///
  /// In en, this message translates to:
  /// **'Choose Rest4More.'**
  String get accStep2;

  /// No description provided for @accStep3.
  ///
  /// In en, this message translates to:
  /// **'Switch it on and confirm.'**
  String get accStep3;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @accessIsOff.
  ///
  /// In en, this message translates to:
  /// **'Access is off'**
  String get accessIsOff;

  /// No description provided for @screenTimeAccess.
  ///
  /// In en, this message translates to:
  /// **'Screen Time access'**
  String get screenTimeAccess;

  /// No description provided for @allowScreenTimeInSettings.
  ///
  /// In en, this message translates to:
  /// **'Allow Screen Time access in Settings, then come back to choose your apps.'**
  String get allowScreenTimeInSettings;

  /// No description provided for @screenTimeNeeded.
  ///
  /// In en, this message translates to:
  /// **'Rest4More needs Screen Time access to set your chosen apps aside. Your choices stay on this phone.'**
  String get screenTimeNeeded;

  /// No description provided for @allowAccess.
  ///
  /// In en, this message translates to:
  /// **'Allow access'**
  String get allowAccess;

  /// No description provided for @couldNotLoadTags.
  ///
  /// In en, this message translates to:
  /// **'Could not load your tags.'**
  String get couldNotLoadTags;

  /// No description provided for @couldNotRemoveTag.
  ///
  /// In en, this message translates to:
  /// **'Could not remove the tag.'**
  String get couldNotRemoveTag;

  /// No description provided for @holdNearTag.
  ///
  /// In en, this message translates to:
  /// **'Hold your iPhone near the tag'**
  String get holdNearTag;

  /// No description provided for @tagNoLink.
  ///
  /// In en, this message translates to:
  /// **'This tag does not hold a Rest4More link.'**
  String get tagNoLink;

  /// No description provided for @tagAdded.
  ///
  /// In en, this message translates to:
  /// **'Tag added.'**
  String get tagAdded;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get addTag;

  /// No description provided for @pairTagOnce.
  ///
  /// In en, this message translates to:
  /// **'Pair a tag once. Then a tap starts or ends your Tag moment.'**
  String get pairTagOnce;

  /// No description provided for @holdPhoneAgainstTag.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone against the tag you want to add.'**
  String get holdPhoneAgainstTag;

  /// No description provided for @noTagsAddOne.
  ///
  /// In en, this message translates to:
  /// **'No tags paired yet. Add one to get started.'**
  String get noTagsAddOne;

  /// No description provided for @tagNumber.
  ///
  /// In en, this message translates to:
  /// **'Tag {n}'**
  String tagNumber(int n);

  /// No description provided for @removeTag.
  ///
  /// In en, this message translates to:
  /// **'Remove tag'**
  String get removeTag;

  /// No description provided for @noStepsYet.
  ///
  /// In en, this message translates to:
  /// **'No steps yet. Add the first one.'**
  String get noStepsYet;

  /// No description provided for @editStep.
  ///
  /// In en, this message translates to:
  /// **'Edit step'**
  String get editStep;

  /// No description provided for @newStep.
  ///
  /// In en, this message translates to:
  /// **'New step'**
  String get newStep;

  /// No description provided for @addAStep.
  ///
  /// In en, this message translates to:
  /// **'Add a step'**
  String get addAStep;

  /// No description provided for @yourOwnStep.
  ///
  /// In en, this message translates to:
  /// **'Your own step'**
  String get yourOwnStep;

  /// No description provided for @totalDuration.
  ///
  /// In en, this message translates to:
  /// **'Total {duration}'**
  String totalDuration(String duration);

  /// No description provided for @addStep.
  ///
  /// In en, this message translates to:
  /// **'Add step'**
  String get addStep;

  /// No description provided for @stepSemantics.
  ///
  /// In en, this message translates to:
  /// **'{title}, {duration}. Tap to edit.'**
  String stepSemantics(String title, String duration);

  /// No description provided for @removeStep.
  ///
  /// In en, this message translates to:
  /// **'Remove {title}'**
  String removeStep(String title);

  /// No description provided for @stepName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get stepName;

  /// No description provided for @shorter.
  ///
  /// In en, this message translates to:
  /// **'Shorter'**
  String get shorter;

  /// No description provided for @longer.
  ///
  /// In en, this message translates to:
  /// **'Longer'**
  String get longer;

  /// No description provided for @openAppFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while opening the app.'**
  String get openAppFailed;

  /// No description provided for @phraseReadingActivity.
  ///
  /// In en, this message translates to:
  /// **'reading a few pages'**
  String get phraseReadingActivity;

  /// No description provided for @phraseReadingMaterial.
  ///
  /// In en, this message translates to:
  /// **'your book'**
  String get phraseReadingMaterial;

  /// No description provided for @phraseQuietActivity.
  ///
  /// In en, this message translates to:
  /// **'sitting quietly for a few minutes'**
  String get phraseQuietActivity;

  /// No description provided for @phraseQuietMaterial.
  ///
  /// In en, this message translates to:
  /// **'a comfortable place to sit'**
  String get phraseQuietMaterial;

  /// No description provided for @phraseBreathingActivity.
  ///
  /// In en, this message translates to:
  /// **'a few minutes of slow breathing'**
  String get phraseBreathingActivity;

  /// No description provided for @phraseBreathingMaterial.
  ///
  /// In en, this message translates to:
  /// **'a quiet corner'**
  String get phraseBreathingMaterial;

  /// No description provided for @phrasePreparationActivity.
  ///
  /// In en, this message translates to:
  /// **'preparing for tomorrow'**
  String get phrasePreparationActivity;

  /// No description provided for @phrasePreparationMaterial.
  ///
  /// In en, this message translates to:
  /// **'what you need for tomorrow'**
  String get phrasePreparationMaterial;

  /// No description provided for @phraseDefaultActivity.
  ///
  /// In en, this message translates to:
  /// **'a calm activity of your choice'**
  String get phraseDefaultActivity;

  /// No description provided for @phraseDefaultMaterial.
  ///
  /// In en, this message translates to:
  /// **'what you need for it'**
  String get phraseDefaultMaterial;

  /// No description provided for @planDefaultAnchor.
  ///
  /// In en, this message translates to:
  /// **'your usual evening routine'**
  String get planDefaultAnchor;

  /// No description provided for @planContextRestnest.
  ///
  /// In en, this message translates to:
  /// **'Use your RestNest as the fixed phone location.'**
  String get planContextRestnest;

  /// No description provided for @planContextNoRestnest.
  ///
  /// In en, this message translates to:
  /// **'Choose a fixed place for your phone; a RestNest is not required.'**
  String get planContextNoRestnest;

  /// No description provided for @planCardOn.
  ///
  /// In en, this message translates to:
  /// **'Use your paired card when card functionality is available on this device.'**
  String get planCardOn;

  /// No description provided for @planCardOff.
  ///
  /// In en, this message translates to:
  /// **'Use manual start; physical card release is unavailable without a card.'**
  String get planCardOff;

  /// No description provided for @planWhyThis.
  ///
  /// In en, this message translates to:
  /// **'This fits your goal to {goal} and your selected obstacle: {obstacle}.'**
  String planWhyThis(String goal, String obstacle);

  /// No description provided for @planTimingRegular.
  ///
  /// In en, this message translates to:
  /// **'Use your selected daily time.'**
  String get planTimingRegular;

  /// No description provided for @planTimingOther.
  ///
  /// In en, this message translates to:
  /// **'Check whether your selected time fits today; otherwise use your activity anchor.'**
  String get planTimingOther;

  /// No description provided for @obstaclePhraseScrolling.
  ///
  /// In en, this message translates to:
  /// **'scrolling'**
  String get obstaclePhraseScrolling;

  /// No description provided for @obstaclePhraseAvailability.
  ///
  /// In en, this message translates to:
  /// **'staying available'**
  String get obstaclePhraseAvailability;

  /// No description provided for @obstaclePhraseThoughts.
  ///
  /// In en, this message translates to:
  /// **'restless thoughts'**
  String get obstaclePhraseThoughts;

  /// No description provided for @obstaclePhrasePlanning.
  ///
  /// In en, this message translates to:
  /// **'planning'**
  String get obstaclePhrasePlanning;

  /// No description provided for @obstaclePhraseAlarm.
  ///
  /// In en, this message translates to:
  /// **'using your phone as an alarm'**
  String get obstaclePhraseAlarm;

  /// No description provided for @obstaclePhraseNoRoutine.
  ///
  /// In en, this message translates to:
  /// **'not having a routine yet'**
  String get obstaclePhraseNoRoutine;

  /// No description provided for @planPreviewReason.
  ///
  /// In en, this message translates to:
  /// **'Chosen for your goal to {goal} and your main obstacle: {obstacle}.'**
  String planPreviewReason(String goal, String obstacle);

  /// No description provided for @planDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This plan is a suggestion based on your answers, not medical advice. It can’t promise better sleep, and you can change it whenever you like.'**
  String get planDisclaimer;

  /// No description provided for @goalEffectPhone.
  ///
  /// In en, this message translates to:
  /// **'Each day has one step that puts a little more distance between you and your phone in the evening.'**
  String get goalEffectPhone;

  /// No description provided for @goalEffectRoutine.
  ///
  /// In en, this message translates to:
  /// **'Each day adds one small, repeatable part to your evening, so it slowly becomes a routine.'**
  String get goalEffectRoutine;

  /// No description provided for @goalEffectSocial.
  ///
  /// In en, this message translates to:
  /// **'Each day helps you notice one automatic check and choose what to do instead.'**
  String get goalEffectSocial;

  /// No description provided for @goalEffectDefault.
  ///
  /// In en, this message translates to:
  /// **'Each day has one step towards your goal.'**
  String get goalEffectDefault;

  /// No description provided for @reasonYourGoal.
  ///
  /// In en, this message translates to:
  /// **'Your goal'**
  String get reasonYourGoal;

  /// No description provided for @reasonObstacle.
  ///
  /// In en, this message translates to:
  /// **'What gets in the way'**
  String get reasonObstacle;

  /// No description provided for @reasonObstacleText.
  ///
  /// In en, this message translates to:
  /// **'You told us about this, so every step comes with a tip for it: {tip}'**
  String reasonObstacleText(String tip);

  /// No description provided for @reasonRhythm.
  ///
  /// In en, this message translates to:
  /// **'Your rhythm'**
  String get reasonRhythm;

  /// No description provided for @reasonRhythmVariable.
  ///
  /// In en, this message translates to:
  /// **'Your days are not always the same, so each step is linked to a moment in your day instead of a fixed hour.'**
  String get reasonRhythmVariable;

  /// No description provided for @reasonRhythmWindow.
  ///
  /// In en, this message translates to:
  /// **'You usually wind down {window}, so the steps are meant for that part of your evening.'**
  String reasonRhythmWindow(String window);

  /// No description provided for @windDownEarly.
  ///
  /// In en, this message translates to:
  /// **'between 8 and 10 PM'**
  String get windDownEarly;

  /// No description provided for @windDownMid.
  ///
  /// In en, this message translates to:
  /// **'between 10 PM and midnight'**
  String get windDownMid;

  /// No description provided for @windDownLate.
  ///
  /// In en, this message translates to:
  /// **'after midnight'**
  String get windDownLate;

  /// No description provided for @reasonAnchor.
  ///
  /// In en, this message translates to:
  /// **'Your fixed moment'**
  String get reasonAnchor;

  /// No description provided for @reasonAnchorText.
  ///
  /// In en, this message translates to:
  /// **'Steps start after something you already do: {anchor}.'**
  String reasonAnchorText(String anchor);

  /// No description provided for @reasonEnjoy.
  ///
  /// In en, this message translates to:
  /// **'What you enjoy'**
  String get reasonEnjoy;

  /// No description provided for @reasonEnjoyText.
  ///
  /// In en, this message translates to:
  /// **'You picked “{activity}”, so that is the calm alternative in your steps.'**
  String reasonEnjoyText(String activity);

  /// No description provided for @reasonStepSize.
  ///
  /// In en, this message translates to:
  /// **'Step size'**
  String get reasonStepSize;

  /// No description provided for @reasonStepSizeSmaller.
  ///
  /// In en, this message translates to:
  /// **'You chose smaller steps. They count just as much, and you can make them bigger later if you want to.'**
  String get reasonStepSizeSmaller;

  /// No description provided for @reasonStepSizeStandard.
  ///
  /// In en, this message translates to:
  /// **'If a step feels too big, you can switch to a smaller version at any time.'**
  String get reasonStepSizeStandard;

  /// No description provided for @reasonProducts.
  ///
  /// In en, this message translates to:
  /// **'Your products'**
  String get reasonProducts;

  /// No description provided for @productRestnest.
  ///
  /// In en, this message translates to:
  /// **'Your RestNest is used as the place for your phone.'**
  String get productRestnest;

  /// No description provided for @productCard.
  ///
  /// In en, this message translates to:
  /// **'You can start and end a moment with your card.'**
  String get productCard;

  /// No description provided for @changeGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get changeGoal;

  /// No description provided for @notChosen.
  ///
  /// In en, this message translates to:
  /// **'Not chosen'**
  String get notChosen;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @progressLoadError.
  ///
  /// In en, this message translates to:
  /// **'Progress could not be loaded.'**
  String get progressLoadError;

  /// No description provided for @progressMoments.
  ///
  /// In en, this message translates to:
  /// **'Moments'**
  String get progressMoments;

  /// No description provided for @progressNoMoments.
  ///
  /// In en, this message translates to:
  /// **'No completed moments yet. They appear here once you finish one.'**
  String get progressNoMoments;

  /// No description provided for @progressMomentsCompleted.
  ///
  /// In en, this message translates to:
  /// **'completed in total'**
  String get progressMomentsCompleted;

  /// No description provided for @progressLast7Days.
  ///
  /// In en, this message translates to:
  /// **'in the last 7 days'**
  String get progressLast7Days;

  /// No description provided for @progressInTotal.
  ///
  /// In en, this message translates to:
  /// **'in total'**
  String get progressInTotal;

  /// No description provided for @progressDaysWithMoment.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day with a moment} other{days with a moment}}'**
  String progressDaysWithMoment(int count);

  /// No description provided for @progressPlannedVsActual.
  ///
  /// In en, this message translates to:
  /// **'Planned vs actual'**
  String get progressPlannedVsActual;

  /// No description provided for @progressActualOfPlannedValue.
  ///
  /// In en, this message translates to:
  /// **'{actual} of {planned} min'**
  String progressActualOfPlannedValue(int actual, int planned);

  /// No description provided for @progressActualOfPlanned.
  ///
  /// In en, this message translates to:
  /// **'actual of planned time'**
  String get progressActualOfPlanned;

  /// No description provided for @progressCountOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total}'**
  String progressCountOfTotal(int count, int total);

  /// No description provided for @progressFullLength.
  ///
  /// In en, this message translates to:
  /// **'lasted their full planned time'**
  String get progressFullLength;

  /// No description provided for @progressDailySteps.
  ///
  /// In en, this message translates to:
  /// **'Daily steps'**
  String get progressDailySteps;

  /// No description provided for @progressNoPlan.
  ///
  /// In en, this message translates to:
  /// **'No plan started yet.'**
  String get progressNoPlan;

  /// No description provided for @progressStepsDone.
  ///
  /// In en, this message translates to:
  /// **'steps done'**
  String get progressStepsDone;

  /// No description provided for @progressStatusDone.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get progressStatusDone;

  /// No description provided for @progressStatusSkipped.
  ///
  /// In en, this message translates to:
  /// **'skipped'**
  String get progressStatusSkipped;

  /// No description provided for @progressStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get progressStatusOpen;

  /// No description provided for @progressLegendSwapped.
  ///
  /// In en, this message translates to:
  /// **'swapped for a shorter step'**
  String get progressLegendSwapped;

  /// No description provided for @progressDayStatus.
  ///
  /// In en, this message translates to:
  /// **'Day {day}: {status}'**
  String progressDayStatus(int day, String status);

  /// No description provided for @progressDayStatusSwapped.
  ///
  /// In en, this message translates to:
  /// **'Day {day}: {status}, swapped'**
  String progressDayStatusSwapped(int day, String status);

  /// No description provided for @progressDayNoMoment.
  ///
  /// In en, this message translates to:
  /// **'{date}: no moment'**
  String progressDayNoMoment(String date);

  /// No description provided for @progressDayMoments.
  ///
  /// In en, this message translates to:
  /// **'{date}: {count, plural, =1{1 moment} other{{count} moments}}'**
  String progressDayMoments(String date, int count);

  /// No description provided for @progressPhoneAway.
  ///
  /// In en, this message translates to:
  /// **'Phone-away'**
  String get progressPhoneAway;

  /// No description provided for @progressNoBlocked.
  ///
  /// In en, this message translates to:
  /// **'No blocked time yet.'**
  String get progressNoBlocked;

  /// No description provided for @progressBlockedTotal.
  ///
  /// In en, this message translates to:
  /// **'apps blocked in total'**
  String get progressBlockedTotal;

  /// No description provided for @setTimeForAllDays.
  ///
  /// In en, this message translates to:
  /// **'Set time for all days'**
  String get setTimeForAllDays;

  /// No description provided for @couldNotSaveEvening.
  ///
  /// In en, this message translates to:
  /// **'Could not save evening. Please try again.'**
  String get couldNotSaveEvening;

  /// No description provided for @couldNotSaveMorning.
  ///
  /// In en, this message translates to:
  /// **'Could not save morning. Please try again.'**
  String get couldNotSaveMorning;

  /// No description provided for @blockStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start blocking. Check permissions and try again.'**
  String get blockStartFailed;

  /// No description provided for @strictEveningActive.
  ///
  /// In en, this message translates to:
  /// **'Your apps are set aside. In strict mode, blocking stays on until your next NFC scan, even if you leave this screen.'**
  String get strictEveningActive;

  /// No description provided for @scanNfcToEnd.
  ///
  /// In en, this message translates to:
  /// **'Scan NFC to end'**
  String get scanNfcToEnd;

  /// No description provided for @nfcScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan NFC tag'**
  String get nfcScanTitle;

  /// No description provided for @nfcChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking NFC...'**
  String get nfcChecking;

  /// No description provided for @nfcDisabled.
  ///
  /// In en, this message translates to:
  /// **'NFC is turned off. Enable it in your phone settings and come back.'**
  String get nfcDisabled;

  /// No description provided for @nfcHoldToUnblock.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone against an NFC tag to unblock your apps'**
  String get nfcHoldToUnblock;

  /// No description provided for @nfcHoldToBlock.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone against an NFC tag to block your apps'**
  String get nfcHoldToBlock;

  /// No description provided for @nfcChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change blocking. Please try again.'**
  String get nfcChangeFailed;

  /// No description provided for @notifAllowTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications?'**
  String get notifAllowTitle;

  /// No description provided for @notifAllowBody.
  ///
  /// In en, this message translates to:
  /// **'To send your daily reminder at {time}, Rest4More needs permission to show notifications. Your phone will ask you next.\n\nReminders are optional. If you say no, you can still use everything in the app.'**
  String notifAllowBody(String time);

  /// No description provided for @notifDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'No reminders for now'**
  String get notifDeniedTitle;

  /// No description provided for @notifDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'That\'s okay. You can use Rest4More as usual, you just won\'t get a daily reminder.\n\nIf you change your mind, you can allow notifications for Rest4More in your phone\'s settings.'**
  String get notifDeniedBody;

  /// No description provided for @notifBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off'**
  String get notifBlockedTitle;

  /// No description provided for @notifBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'Rest4More is not allowed to send notifications on this phone, so we can\'t send your daily reminder.\n\nYou can allow notifications in Settings, or continue without reminders. Everything else in the app works the same.'**
  String get notifBlockedBody;

  /// No description provided for @notifContinueWithout.
  ///
  /// In en, this message translates to:
  /// **'Continue without reminders'**
  String get notifContinueWithout;

  /// No description provided for @dailyReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get dailyReminderTitle;

  /// No description provided for @dailyReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A gentle nudge for your daily step'**
  String get dailyReminderSubtitle;

  /// No description provided for @reminderTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTimeLabel;

  /// No description provided for @reminderOnNote.
  ///
  /// In en, this message translates to:
  /// **'One reminder a day at this time. On days you have already done your step, we stay quiet.'**
  String get reminderOnNote;

  /// No description provided for @reminderOffNote.
  ///
  /// In en, this message translates to:
  /// **'Reminders are off. You can use everything in the app without them.'**
  String get reminderOffNote;
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
      <String>['en', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
