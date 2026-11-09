// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Rest For More';

  @override
  String get tabToday => 'Today';

  @override
  String get tabMoments => 'Moments';

  @override
  String get tabProgress => 'Progress';

  @override
  String get tabProfile => 'Profile';

  @override
  String get progressNotAvailable => 'Progress is not available yet.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSubtitle => 'Your settings and tags';

  @override
  String get nfcTagsTitle => 'NFC tags';

  @override
  String get tagsPairPrompt =>
      'Pair a tag to start and end moments with a tap.';

  @override
  String get tagsNonePaired => 'No tags paired yet.';

  @override
  String tagsPaired(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags paired.',
      one: '1 tag paired.',
    );
    return '$_temp0';
  }

  @override
  String get manageTags => 'Manage tags';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get appBlocked => 'This app is blocked';

  @override
  String get openRestForMore => 'Open Rest For More';

  @override
  String get connectStartStep =>
      'Connect onStartStep to your rest session screen.';

  @override
  String get whyThisStep => 'Why this step?';

  @override
  String get gotIt => 'Got it';

  @override
  String dayOfTotal(int day, int total) {
    return 'DAY $day OF $total';
  }

  @override
  String get startTodaysStep => 'Start today’s step';

  @override
  String get makeItSmaller => 'Make it smaller';

  @override
  String get todaysInvitation => 'TODAY’S INVITATION';

  @override
  String quietMomentMinutes(int minutes) {
    return '$minutes minute quiet moment';
  }

  @override
  String dayIsDone(int day) {
    return 'Day $day is done.';
  }

  @override
  String get todaysStepDone => 'Today’s step is done';

  @override
  String dayReadyTomorrow(int day) {
    return 'Day $day is ready for you tomorrow. One step a day is enough.';
  }

  @override
  String allStepsDone(int totalDays) {
    return 'All $totalDays steps are done';
  }

  @override
  String get ownRoutineContinues =>
      'Your own routine continues. Keep the phone location, the phone-away moment and the activity that fitted you best.';

  @override
  String get momentsSubtitle => 'Choose a space for mindful space';

  @override
  String get momentTagTitle => 'Tag';

  @override
  String get momentTagDescription =>
      'Set your apps aside with a tap of your tag, and bring them back with the same tap.';

  @override
  String get begin => 'Begin';

  @override
  String get back => 'Back';

  @override
  String get continueLabel => 'Continue';

  @override
  String get welcomeEyebrow => 'WELCOME TO REST FOR MORE';

  @override
  String get welcomeTitle => 'A thoughtful path to\nintentional rest';

  @override
  String get welcomeBody =>
      'We believe that productivity is only half of life’s rhythm. Let us help you put the phone down, clear your thoughts, and create personal space for slow, deep recovery.';

  @override
  String get welcomeBenefit1 =>
      'No account needed to start your custom routine';

  @override
  String get welcomeBenefit2 => 'A gentle, guided 14-day progressive plan';

  @override
  String get getStarted => 'Get started';

  @override
  String stepOfFive(int n) {
    return 'STEP $n OF 5';
  }

  @override
  String get goalTitle => 'What would you like to\nfocus on?';

  @override
  String get goalPhoneTitle => 'Put the phone away earlier';

  @override
  String get goalPhoneDesc =>
      'Build a comforting boundary between your screen and your evening sleep cycle.';

  @override
  String get goalRoutineTitle => 'Build a routine';

  @override
  String get goalRoutineDesc =>
      'Create small, nourishing daily rituals that signal your nervous system to recover.';

  @override
  String get goalSocialTitle => 'Use less social media';

  @override
  String get goalSocialDesc =>
      'Step back from hyper-stimulating feeds and recapture your focus.';

  @override
  String get obstacleTitle => 'What gets in the way\nof your rest?';

  @override
  String get selectAllThatApply => 'Select all that apply.';

  @override
  String get obstacleScrolling => 'Scrolling';

  @override
  String get obstacleAvailability => 'Availability';

  @override
  String get obstacleThoughts => 'Restless thoughts';

  @override
  String get obstaclePlanning => 'Planning';

  @override
  String get obstacleAlarm => 'Phone as alarm';

  @override
  String get obstacleNoRoutine => 'No routine';

  @override
  String get rhythmTitle => 'When does your day\nusually wind down?';

  @override
  String get rhythmIntro =>
      'Tell us roughly when your energy begins to slip. We’ll match your rest plan to your natural rhythm.';

  @override
  String get rhythmEarlyTitle => '8:00 – 10:00 PM';

  @override
  String get rhythmEarlyDesc => 'I usually start winding down early.';

  @override
  String get rhythmMidTitle => '10:00 PM – 12:00 AM';

  @override
  String get rhythmMidDesc => 'My evenings usually continue a little longer.';

  @override
  String get rhythmLateTitle => 'After midnight';

  @override
  String get rhythmLateDesc => 'I normally wind down quite late at night.';

  @override
  String get activitiesTitle => 'What kind of activities\nappeal to you?';

  @override
  String get activitiesIntro =>
      'Choose the kinds of restful activities that feel natural to you. You can select more than one.';

  @override
  String get activityQuietTitle => 'Quiet moments';

  @override
  String get activityQuietDesc =>
      'Slow down with a few peaceful minutes away from your screen.';

  @override
  String get activityReadingTitle => 'Paper reading';

  @override
  String get activityReadingDesc =>
      'Put the phone aside and spend some time with a physical book.';

  @override
  String get activityBreathingTitle => 'Evening breathing routines';

  @override
  String get activityBreathingDesc =>
      'Use simple breathing exercises to settle your body and mind.';

  @override
  String get finalStep => 'FINAL STEP';

  @override
  String get reminderTitle => 'Would you like a\ndaily reminder?';

  @override
  String get reminderIntro =>
      'A gentle reminder can help you make space for rest without adding pressure.';

  @override
  String get dailyReminder => 'Daily reminder';

  @override
  String get oneGentleReminder => 'One gentle reminder each day';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get done => 'Done';

  @override
  String get maybeLater => 'Maybe later';

  @override
  String get whyWeChoseThis => 'Why we chose this for you';

  @override
  String dayRange(int from, int to) {
    return 'Day $from–$to';
  }

  @override
  String get planTitle => 'Here’s your\npersonal plan';

  @override
  String get planIntro =>
      'A gentle 14-day plan designed around your goals, rhythm and preferred activities.';

  @override
  String get startYourPlan => 'Start your plan';

  @override
  String get adjustPlanSettings => 'Adjust plan settings';

  @override
  String dayWithTitle(int day, String title) {
    return 'Day $day: $title';
  }

  @override
  String phaseN(int n) {
    return 'PHASE $n';
  }

  @override
  String get phase1Title => 'Create some space';

  @override
  String get phase1Desc =>
      'Start small by creating a little distance between you and your phone.';

  @override
  String get phase1Item1 => 'Put your phone away for 10 minutes';

  @override
  String get phase1Item2 => 'Take one quiet moment';

  @override
  String get phase1Item3 => 'Notice how your evening feels';

  @override
  String get phase2Title => 'Build your rhythm';

  @override
  String get phase2Desc =>
      'Turn your first small steps into a simple evening routine.';

  @override
  String get phase2Item1 => 'Begin winding down earlier';

  @override
  String get phase2Item2 => 'Choose a screen-free activity';

  @override
  String get phase2Item3 => 'Repeat your evening routine';

  @override
  String get phase3Title => 'Make it yours';

  @override
  String get phase3Desc =>
      'Strengthen the habits that work best for you and your rest.';

  @override
  String get phase3Item1 => 'Keep your preferred routine';

  @override
  String get phase3Item2 => 'Reflect on what helped most';

  @override
  String get phase3Item3 => 'Prepare for life after day 14';

  @override
  String get adjustSaveFailed =>
      'Your changes could not be saved. Please try again.';

  @override
  String get reviewChanges => 'Review changes';

  @override
  String get keepCurrentPlan => 'Keep my current plan';

  @override
  String get confirmChanges => 'Confirm changes';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get adjustEyebrow => 'ADJUST YOUR PLAN';

  @override
  String get adjustTitle => 'Make the plan\nfit you';

  @override
  String get adjustIntro =>
      'Change only what doesn’t fit. Your other answers stay as they are, so you don’t have to start over.';

  @override
  String get stepSizeQuestion => 'How big should each step be?';

  @override
  String get standardSteps => 'Standard steps';

  @override
  String get standardStepsDesc => 'The full version of each day’s step.';

  @override
  String get smallerSteps => 'Smaller steps';

  @override
  String get smallerStepsDesc =>
      'A lighter version of each step. It counts just as much, and you keep all 14 days.';

  @override
  String get yourGoal => 'Your goal';

  @override
  String get obstacleQuestion => 'What gets in the way most?';

  @override
  String get calmActivity => 'Calm activity';

  @override
  String get reviewYourChanges => 'Review your changes';

  @override
  String get nothingSavedUntilConfirm => 'Nothing is saved until you confirm.';

  @override
  String get adjustRunningStepSize =>
      'The days still to come get the new step size. Days you already did stay as they are.';

  @override
  String get adjustRunningNewPlan =>
      'Your new plan becomes your active plan and starts at day 1. What you already did stays saved.';

  @override
  String get yourFirstDays => 'Your first days';

  @override
  String get momentFocusTitle => 'Focus';

  @override
  String get momentFocusDescription =>
      'Clear your mind to commit to a single quiet workflow.';

  @override
  String get momentFocusPill => 'A quiet place';

  @override
  String get momentFocusHeading => 'Settle into the moment';

  @override
  String get momentFocusQuote => 'One thing, fully attended.';

  @override
  String get momentFocusButton => 'Start Focus';

  @override
  String get momentFocusStep1 => 'Choose one meaningful task.';

  @override
  String get momentFocusStep2 =>
      'Let your breath settle for three slow counts.';

  @override
  String get momentFocusStep3 =>
      'Return gently whenever your attention wanders.';

  @override
  String get momentReadingTitle => 'Reading';

  @override
  String get momentReadingDescription =>
      'Keep distractions away while you read.';

  @override
  String get momentReadingPill => 'One page at a time';

  @override
  String get momentReadingHeading => 'Settle into the moment';

  @override
  String get momentReadingQuote => 'One page, fully attended.';

  @override
  String get momentReadingButton => 'Start Reading';

  @override
  String get momentReadingStep1 => 'Pick the book or article you want to read.';

  @override
  String get momentReadingStep2 =>
      'Let your shoulders drop and breathe out slowly.';

  @override
  String get momentReadingStep3 =>
      'When your mind drifts, return to the next line.';

  @override
  String get momentEveningTitle => 'Evening';

  @override
  String get momentEveningDescription =>
      'Wind down and put your phone away before bed.';

  @override
  String get momentEveningPill => 'A gentle landing';

  @override
  String get momentEveningHeading => 'Close the day';

  @override
  String get momentEveningQuote => 'The day is allowed to end.';

  @override
  String get momentEveningButton => 'Plan your evening';

  @override
  String get momentEveningStep1 => 'Choose when you want to be in bed.';

  @override
  String get momentEveningStep2 =>
      'Decide what your evening needs, and in what order.';

  @override
  String get momentEveningStep3 => 'Let your phone rest while you wind down.';

  @override
  String get momentMorningTitle => 'Morning';

  @override
  String get momentMorningDescription =>
      'Start the day before your phone does.';

  @override
  String get momentMorningPill => 'A slow start';

  @override
  String get momentMorningHeading => 'Begin the day';

  @override
  String get momentMorningQuote => 'Your morning is yours first.';

  @override
  String get momentMorningButton => 'Plan your morning';

  @override
  String get momentMorningStep1 => 'Choose when you wake up.';

  @override
  String get momentMorningStep2 =>
      'Pick what your morning needs before your phone.';

  @override
  String get momentMorningStep3 =>
      'Your phone returns when your morning is done.';

  @override
  String get aGentleReminder => 'A GENTLE REMINDER';

  @override
  String get backToMoments => 'Back to Moments';

  @override
  String durationMinutes(int m) {
    return '$m min';
  }

  @override
  String durationHours(int h) {
    return '$h h';
  }

  @override
  String durationHoursMinutes(int h, String m) {
    return '$h h $m min';
  }

  @override
  String get eveningEndAtBedtime => 'At bedtime';

  @override
  String get eveningEndAtNextScan => 'At the next scan';

  @override
  String get blockingStartsHere => 'Blocking starts here.';

  @override
  String get saveEvening => 'Save evening';

  @override
  String get eveningSubtitle => 'Pick your bedtime. We count back from there.';

  @override
  String get bedtimePerDay => 'Bedtime per day';

  @override
  String get bedtimeNote =>
      'A bedtime between 00:00 and 05:59 belongs to the evening before, so a Friday evening can end on Saturday at 00:30.';

  @override
  String get eveningAfterMidnight => 'After midnight';

  @override
  String get yourEvening => 'Your evening';

  @override
  String get yourEveningNote =>
      'Your evening starts early enough to fit every step before bedtime. Putting your phone away comes first.';

  @override
  String get reminders => 'Reminders';

  @override
  String get headsUpBefore => 'Heads-up before your evening starts';

  @override
  String minutesShort(int v) {
    return '$v min';
  }

  @override
  String get secondReminder => 'Second reminder if you have not started';

  @override
  String get off => 'Off';

  @override
  String afterMinutes(int v) {
    return 'After $v min';
  }

  @override
  String get remindersNote =>
      'Reminders are local notifications. The app can ask, but it cannot make you put your phone away, and your phone’s silent or Focus modes can still mute them.';

  @override
  String get whenBlockingEnds => 'When blocking ends';

  @override
  String get strictOvernight =>
      'Strict overnight: blocking stays on until you scan. A timer will not end it for you.';

  @override
  String get liftsAtBedtime => 'Blocking lifts by itself at bedtime.';

  @override
  String yourWeekdayEvening(String day) {
    return 'Your $day evening';
  }

  @override
  String get headsUp => 'Heads-up';

  @override
  String get headsUpDetail => 'A reminder that your evening is about to start.';

  @override
  String get bedtime => 'Bedtime';

  @override
  String get bedtimeBlockingEnds => 'Bedtime · blocking ends';

  @override
  String get blockingStaysUntilScan => 'Blocking stays until your next scan.';

  @override
  String get saveMorning => 'Save morning';

  @override
  String get wakeUpTimePerDay => 'Wake-up time per day';

  @override
  String get wakeUpNote =>
      'This is not your phone alarm. The app cannot hook into the system alarm, so set the same time there. Your morning starts at the time you choose here.';

  @override
  String get yourMorning => 'Your morning';

  @override
  String get yourMorningNote =>
      'Everything you do before your phone comes back. Your phone is not a step. It is what comes after.';

  @override
  String yourWeekdayMorning(String day) {
    return 'Your $day morning';
  }

  @override
  String get timerOnlyNote =>
      'Timer only: apps unlock by themselves when your steps are done. This is not a strict block.';

  @override
  String get timesFollowClock =>
      'Times follow your phone’s clock and time zone.';

  @override
  String get phoneIsBack => 'Your phone is back';

  @override
  String get appsUnlock => 'Apps unlock.';

  @override
  String couldNotSaveMoment(String name) {
    return 'Could not save your $name. Please try again.';
  }

  @override
  String momentSaved(String name) {
    return '$name saved';
  }

  @override
  String get couldNotLoad => 'Could not load. Try again';

  @override
  String get appsToBlock => 'Apps to block';

  @override
  String get noAppsChosen => 'No apps chosen yet.';

  @override
  String get appsChosen => 'Apps chosen.';

  @override
  String appsChosenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps chosen.',
      one: '1 app chosen.',
    );
    return '$_temp0';
  }

  @override
  String onlyUsedFor(String name) {
    return 'Only used for $name. The other moments keep their own choice.';
  }

  @override
  String get change => 'Change';

  @override
  String get chooseApps => 'Choose apps';

  @override
  String get nfcOff => 'NFC is turned off. Enable it in your phone settings.';

  @override
  String get nfcUnsupported => 'This device does not support NFC.';

  @override
  String get holdNearTagToEnd => 'Hold your iPhone near your tag to end';

  @override
  String get holdNearTagToBegin => 'Hold your iPhone near your tag to begin';

  @override
  String scanningStopped(String message) {
    return 'Scanning stopped: $message';
  }

  @override
  String get notYourTag => 'This is not one of your paired tags.';

  @override
  String get couldNotReadTag => 'Could not read this tag. Please try again.';

  @override
  String get couldNotStartScanning => 'Could not start scanning.';

  @override
  String get waitingForTag => 'Waiting for tag…';

  @override
  String get pairTagFirst => 'Pair a tag first';

  @override
  String get scanTagToEnd => 'Scan tag to end';

  @override
  String get scanTagToBegin => 'Scan tag to begin';

  @override
  String get tagMomentDescription =>
      'Put your apps aside with a tap, and bring them back with the same tag.';

  @override
  String get tagMomentEyebrow => 'TAG MOMENT';

  @override
  String get statusChecking => 'Checking';

  @override
  String get statusActive => 'Active';

  @override
  String get statusNotActive => 'Not active';

  @override
  String get tagActiveBody =>
      'Your apps are set aside. Only your tag can end this moment.';

  @override
  String get tagReadyBody =>
      'Ready when you are. Scan your tag to set your apps aside.';

  @override
  String get tagPairBody => 'Pair a tag to use this moment.';

  @override
  String get chooseAppsToSetAside => 'Choose apps to set aside';

  @override
  String get howItWorks => 'How it works';

  @override
  String get tagStep1 => 'Choose the apps you want to set aside.';

  @override
  String get tagStep2 => 'Scan your tag to begin.';

  @override
  String get tagStep3 => 'Scan the same tag again to end.';

  @override
  String get tagQuote => 'Put it down. Pick it up when you choose.';

  @override
  String get sessionFocusSubtitle =>
      'Pick how long, and what to keep out of the way.';

  @override
  String get sessionReadingSubtitle =>
      'Pick how long you want to read, and what stays quiet.';

  @override
  String get startFocus => 'Start Focus';

  @override
  String get startReading => 'Start Reading';

  @override
  String get presetQuick => 'Quick';

  @override
  String get presetStandard => 'Standard';

  @override
  String get presetDeep => 'Deep';

  @override
  String get presetShort => 'Short';

  @override
  String get presetChapter => 'Chapter';

  @override
  String get presetLong => 'Long';

  @override
  String get presetCustom => 'Custom';

  @override
  String get howLong => 'How long';

  @override
  String endsAfterMinutes(int minutes) {
    return 'Ends after $minutes minutes. Stopping early asks you to confirm first and is logged as stopped early.';
  }

  @override
  String get fewerMinutes => 'Fewer minutes';

  @override
  String get moreMinutes => 'More minutes';

  @override
  String get endSessionEarlyTitle => 'End this session early?';

  @override
  String get endSessionEarlyBody =>
      'Your apps unlock now. This session will be logged as stopped early.';

  @override
  String get keepGoing => 'Keep going';

  @override
  String get endEarly => 'End early';

  @override
  String get sessionTitle => 'Session';

  @override
  String get sessionStartBlockFailed =>
      'We could not set your apps aside, so nothing was started. Check that blocking is allowed for Rest For More and try again.';

  @override
  String get sessionStartFailed =>
      'Something went wrong while starting. Please try again.';

  @override
  String get sessionEndFailed =>
      'Something went wrong while ending. Please try again.';

  @override
  String get appsStillSetAsideTryAgain =>
      'Your apps are still set aside. Please try again.';

  @override
  String get settingAppsAside => 'Setting your apps aside…';

  @override
  String get bringingAppsBack => 'Bringing your apps back…';

  @override
  String timeLeft(String time) {
    return '$time left';
  }

  @override
  String appsSetAsideUntil(String time) {
    return 'Your apps are set aside until $time.';
  }

  @override
  String get sessionEnded => 'Session ended';

  @override
  String get wellDone => 'Well done';

  @override
  String get sessionEndedEarlyBody =>
      'Your apps are back. That is fine. Begin again whenever you like.';

  @override
  String get sessionCompleteBody =>
      'Your time is complete and your apps are back.';

  @override
  String get somethingWentWrong => 'Something went wrong.';

  @override
  String get appsStillSetAside => 'Your apps are still set aside';

  @override
  String get releaseFailedBody =>
      'The session is over, but we could not bring your apps back. Try again, or open Help if it keeps happening.';

  @override
  String get needAnApp => 'Need an app?';

  @override
  String get tryAgain => 'Try again';

  @override
  String get unblockFailed =>
      'We could not unblock this right now. Please try again.';

  @override
  String get cancelKeepBlocked => 'Cancel and keep it blocked';

  @override
  String get whichAppNeeded => 'Which app do you need?';

  @override
  String get onlyOneOpens =>
      'Only the one you choose opens, and only for a little while.';

  @override
  String get couldNotReadBlocked => 'Could not read your blocked apps.';

  @override
  String get nothingBlocked => 'Nothing is blocked right now.';

  @override
  String get howLongNeed => 'How long do you really need?';

  @override
  String get minutesToUnblock => 'Minutes to unblock';

  @override
  String minutesCount(int n) {
    return '$n minutes';
  }

  @override
  String minuteUnit(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'minutes',
      one: 'minute',
    );
    return '$_temp0';
  }

  @override
  String appsAvailableUntil(String time) {
    return 'Your apps will be available until $time.';
  }

  @override
  String nameAvailableUntil(String name, String time) {
    return '$name will be available until $time.';
  }

  @override
  String get unblocking => 'Unblocking…';

  @override
  String get unblock => 'Unblock';

  @override
  String get unblocked => 'Unblocked';

  @override
  String appsNowAvailable(String time) {
    return 'Your apps are available until $time. It locks again by itself.';
  }

  @override
  String appNowAvailable(String name, String time) {
    return '$name is available until $time. It locks again by itself.';
  }

  @override
  String openApp(String name) {
    return 'Open $name';
  }

  @override
  String get notNow => 'Not now';

  @override
  String get youCanContinueNow => 'You can continue now.';

  @override
  String get takeMomentBreathe => 'Take a moment to breathe';

  @override
  String get wheneverReady => 'Whenever you are ready.';

  @override
  String get needOrReachedFor =>
      'Is this something you need, or something you reached for?';

  @override
  String get pauseFinished => 'Pause finished';

  @override
  String get pauseInProgress => 'Pause in progress, a few seconds';

  @override
  String get stopMomentTitle => 'Stop this moment?';

  @override
  String get dailyStepUnfinished => 'Your daily step will stay unfinished.';

  @override
  String get stopMoment => 'Stop moment';

  @override
  String get useStopHint =>
      'Use Stop to end this moment, or leave the app to keep it going.';

  @override
  String quietMomentHyphen(int minutes) {
    return '$minutes-minute quiet moment';
  }

  @override
  String get littleSpaceWellDone => 'A little space for yourself. Well done.';

  @override
  String get fewMinutesAway => 'Take a few minutes away from your phone.';

  @override
  String get finishDailyStep => 'Finish daily step';

  @override
  String get stop => 'Stop';

  @override
  String get start => 'Start';

  @override
  String get shortOnTime =>
      'Short on time or energy? That’s okay. You can still take a small step.';

  @override
  String get originalOption => 'ORIGINAL OPTION';

  @override
  String get recommendedAlternative => 'RECOMMENDED ALTERNATIVE';

  @override
  String startMinuteVersion(int minutes) {
    return 'Start $minutes-minute version';
  }

  @override
  String keepMinuteVersion(int minutes) {
    return 'Keep $minutes-minute version';
  }

  @override
  String get keepOriginal => 'Keep the original';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String saveWithCount(int count) {
    return 'Save · $count selected';
  }

  @override
  String get searchApps => 'Search apps';

  @override
  String get couldNotReadApps => 'Could not read your apps.';

  @override
  String appsForMoment(String name) {
    return 'Apps for $name';
  }

  @override
  String get couldNotSaveApps => 'Could not save your apps. Try again.';

  @override
  String saveAppsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Save $count apps',
      one: 'Save 1 app',
    );
    return '$_temp0';
  }

  @override
  String get chooseApps2 => 'Choose apps';

  @override
  String get pickAppsToSetAside => 'Pick the apps you want to set aside.';

  @override
  String appsWillBeSetAside(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps will be set aside.',
      one: '1 app will be set aside.',
    );
    return '$_temp0';
  }

  @override
  String get androidOnlyList =>
      'Choosing apps from this list is only available on Android.';

  @override
  String get noAppsFound => 'No apps found.';

  @override
  String get allowAccessibility => 'Allow accessibility';

  @override
  String get accessibilityBody =>
      'To set your apps aside, Rest4More needs its accessibility service switched on. It only notices which app opens, so it can step in front of the ones you chose.';

  @override
  String get inSettings => 'In Settings';

  @override
  String get accStep1 => 'Open Installed apps or Downloaded apps.';

  @override
  String get accStep2 => 'Choose Rest4More.';

  @override
  String get accStep3 => 'Switch it on and confirm.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get accessIsOff => 'Access is off';

  @override
  String get screenTimeAccess => 'Screen Time access';

  @override
  String get allowScreenTimeInSettings =>
      'Allow Screen Time access in Settings, then come back to choose your apps.';

  @override
  String get screenTimeNeeded =>
      'Rest4More needs Screen Time access to set your chosen apps aside. Your choices stay on this phone.';

  @override
  String get allowAccess => 'Allow access';

  @override
  String get couldNotLoadTags => 'Could not load your tags.';

  @override
  String get couldNotRemoveTag => 'Could not remove the tag.';

  @override
  String get holdNearTag => 'Hold your iPhone near the tag';

  @override
  String get tagNoLink => 'This tag does not hold a Rest4More link.';

  @override
  String get tagAdded => 'Tag added.';

  @override
  String get addTag => 'Add tag';

  @override
  String get pairTagOnce =>
      'Pair a tag once. Then a tap starts or ends your Tag moment.';

  @override
  String get holdPhoneAgainstTag =>
      'Hold your phone against the tag you want to add.';

  @override
  String get noTagsAddOne => 'No tags paired yet. Add one to get started.';

  @override
  String tagNumber(int n) {
    return 'Tag $n';
  }

  @override
  String get removeTag => 'Remove tag';

  @override
  String get noStepsYet => 'No steps yet. Add the first one.';

  @override
  String get editStep => 'Edit step';

  @override
  String get newStep => 'New step';

  @override
  String get addAStep => 'Add a step';

  @override
  String get yourOwnStep => 'Your own step';

  @override
  String totalDuration(String duration) {
    return 'Total $duration';
  }

  @override
  String get addStep => 'Add step';

  @override
  String stepSemantics(String title, String duration) {
    return '$title, $duration. Tap to edit.';
  }

  @override
  String removeStep(String title) {
    return 'Remove $title';
  }

  @override
  String get stepName => 'Name';

  @override
  String get shorter => 'Shorter';

  @override
  String get longer => 'Longer';

  @override
  String get openAppFailed => 'Something went wrong while opening the app.';

  @override
  String get phraseReadingActivity => 'reading a few pages';

  @override
  String get phraseReadingMaterial => 'your book';

  @override
  String get phraseQuietActivity => 'sitting quietly for a few minutes';

  @override
  String get phraseQuietMaterial => 'a comfortable place to sit';

  @override
  String get phraseBreathingActivity => 'a few minutes of slow breathing';

  @override
  String get phraseBreathingMaterial => 'a quiet corner';

  @override
  String get phrasePreparationActivity => 'preparing for tomorrow';

  @override
  String get phrasePreparationMaterial => 'what you need for tomorrow';

  @override
  String get phraseDefaultActivity => 'a calm activity of your choice';

  @override
  String get phraseDefaultMaterial => 'what you need for it';

  @override
  String get planDefaultAnchor => 'your usual evening routine';

  @override
  String get planContextRestnest =>
      'Use your RestNest as the fixed phone location.';

  @override
  String get planContextNoRestnest =>
      'Choose a fixed place for your phone; a RestNest is not required.';

  @override
  String get planCardOn =>
      'Use your paired card when card functionality is available on this device.';

  @override
  String get planCardOff =>
      'Use manual start; physical card release is unavailable without a card.';

  @override
  String planWhyThis(String goal, String obstacle) {
    return 'This fits your goal to $goal and your selected obstacle: $obstacle.';
  }

  @override
  String get planTimingRegular => 'Use your selected daily time.';

  @override
  String get planTimingOther =>
      'Check whether your selected time fits today; otherwise use your activity anchor.';

  @override
  String get obstaclePhraseScrolling => 'scrolling';

  @override
  String get obstaclePhraseAvailability => 'staying available';

  @override
  String get obstaclePhraseThoughts => 'restless thoughts';

  @override
  String get obstaclePhrasePlanning => 'planning';

  @override
  String get obstaclePhraseAlarm => 'using your phone as an alarm';

  @override
  String get obstaclePhraseNoRoutine => 'not having a routine yet';

  @override
  String planPreviewReason(String goal, String obstacle) {
    return 'Chosen for your goal to $goal and your main obstacle: $obstacle.';
  }

  @override
  String get planDisclaimer =>
      'This plan is a suggestion based on your answers, not medical advice. It can’t promise better sleep, and you can change it whenever you like.';

  @override
  String get goalEffectPhone =>
      'Each day has one step that puts a little more distance between you and your phone in the evening.';

  @override
  String get goalEffectRoutine =>
      'Each day adds one small, repeatable part to your evening, so it slowly becomes a routine.';

  @override
  String get goalEffectSocial =>
      'Each day helps you notice one automatic check and choose what to do instead.';

  @override
  String get goalEffectDefault => 'Each day has one step towards your goal.';

  @override
  String get reasonYourGoal => 'Your goal';

  @override
  String get reasonObstacle => 'What gets in the way';

  @override
  String reasonObstacleText(String tip) {
    return 'You told us about this, so every step comes with a tip for it: $tip';
  }

  @override
  String get reasonRhythm => 'Your rhythm';

  @override
  String get reasonRhythmVariable =>
      'Your days are not always the same, so each step is linked to a moment in your day instead of a fixed hour.';

  @override
  String reasonRhythmWindow(String window) {
    return 'You usually wind down $window, so the steps are meant for that part of your evening.';
  }

  @override
  String get windDownEarly => 'between 8 and 10 PM';

  @override
  String get windDownMid => 'between 10 PM and midnight';

  @override
  String get windDownLate => 'after midnight';

  @override
  String get reasonAnchor => 'Your fixed moment';

  @override
  String reasonAnchorText(String anchor) {
    return 'Steps start after something you already do: $anchor.';
  }

  @override
  String get reasonEnjoy => 'What you enjoy';

  @override
  String reasonEnjoyText(String activity) {
    return 'You picked “$activity”, so that is the calm alternative in your steps.';
  }

  @override
  String get reasonStepSize => 'Step size';

  @override
  String get reasonStepSizeSmaller =>
      'You chose smaller steps. They count just as much, and you can make them bigger later if you want to.';

  @override
  String get reasonStepSizeStandard =>
      'If a step feels too big, you can switch to a smaller version at any time.';

  @override
  String get reasonProducts => 'Your products';

  @override
  String get productRestnest =>
      'Your RestNest is used as the place for your phone.';

  @override
  String get productCard => 'You can start and end a moment with your card.';

  @override
  String get changeGoal => 'Goal';

  @override
  String get notChosen => 'Not chosen';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get progressLoadError => 'Progress could not be loaded.';

  @override
  String get progressMoments => 'Moments';

  @override
  String get progressNoMoments =>
      'No completed moments yet. They appear here once you finish one.';

  @override
  String get progressMomentsCompleted => 'completed in total';

  @override
  String get progressLast7Days => 'in the last 7 days';

  @override
  String get progressInTotal => 'in total';

  @override
  String progressDaysWithMoment(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days with a moment',
      one: 'day with a moment',
    );
    return '$_temp0';
  }

  @override
  String get progressPlannedVsActual => 'Planned vs actual';

  @override
  String progressActualOfPlannedValue(int actual, int planned) {
    return '$actual of $planned min';
  }

  @override
  String get progressActualOfPlanned => 'actual of planned time';

  @override
  String progressCountOfTotal(int count, int total) {
    return '$count of $total';
  }

  @override
  String get progressFullLength => 'lasted their full planned time';

  @override
  String get progressDailySteps => 'Daily steps';

  @override
  String get progressNoPlan => 'No plan started yet.';

  @override
  String get progressStepsDone => 'steps done';

  @override
  String get progressStatusDone => 'done';

  @override
  String get progressStatusSkipped => 'skipped';

  @override
  String get progressStatusOpen => 'open';

  @override
  String get progressLegendSwapped => 'swapped for a shorter step';

  @override
  String progressDayStatus(int day, String status) {
    return 'Day $day: $status';
  }

  @override
  String progressDayStatusSwapped(int day, String status) {
    return 'Day $day: $status, swapped';
  }

  @override
  String progressDayNoMoment(String date) {
    return '$date: no moment';
  }

  @override
  String progressDayMoments(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moments',
      one: '1 moment',
    );
    return '$date: $_temp0';
  }

  @override
  String get progressPhoneAway => 'Phone-away';

  @override
  String get progressNoBlocked => 'No blocked time yet.';

  @override
  String get progressBlockedTotal => 'apps blocked in total';

  @override
  String get setTimeForAllDays => 'Set time for all days';

  @override
  String get couldNotSaveEvening => 'Could not save evening. Please try again.';

  @override
  String get couldNotSaveMorning => 'Could not save morning. Please try again.';

  @override
  String get blockStartFailed =>
      'Could not start blocking. Check permissions and try again.';

  @override
  String get strictEveningActive =>
      'Your apps are set aside. In strict mode, blocking stays on until your next NFC scan, even if you leave this screen.';

  @override
  String get scanNfcToEnd => 'Scan NFC to end';

  @override
  String get nfcScanTitle => 'Scan NFC tag';

  @override
  String get nfcChecking => 'Checking NFC...';

  @override
  String get nfcDisabled =>
      'NFC is turned off. Enable it in your phone settings and come back.';

  @override
  String get nfcHoldToUnblock =>
      'Hold your phone against an NFC tag to unblock your apps';

  @override
  String get nfcHoldToBlock =>
      'Hold your phone against an NFC tag to block your apps';

  @override
  String get nfcChangeFailed => 'Could not change blocking. Please try again.';

  @override
  String get notifAllowTitle => 'Allow notifications?';

  @override
  String notifAllowBody(String time) {
    return 'To send your daily reminder at $time, Rest4More needs permission to show notifications. Your phone will ask you next.\n\nReminders are optional. If you say no, you can still use everything in the app.';
  }

  @override
  String get notifDeniedTitle => 'No reminders for now';

  @override
  String get notifDeniedBody =>
      'That\'s okay. You can use Rest4More as usual, you just won\'t get a daily reminder.\n\nIf you change your mind, you can allow notifications for Rest4More in your phone\'s settings.';

  @override
  String get notifBlockedTitle => 'Notifications are turned off';

  @override
  String get notifBlockedBody =>
      'Rest4More is not allowed to send notifications on this phone, so we can\'t send your daily reminder.\n\nYou can allow notifications in Settings, or continue without reminders. Everything else in the app works the same.';

  @override
  String get notifContinueWithout => 'Continue without reminders';

  @override
  String get dailyReminderTitle => 'Daily reminder';

  @override
  String get dailyReminderSubtitle => 'A gentle nudge for your daily step';

  @override
  String get reminderTimeLabel => 'Reminder time';

  @override
  String get reminderOnNote =>
      'One reminder a day at this time. On days you have already done your step, we stay quiet.';

  @override
  String get reminderOffNote =>
      'Reminders are off. You can use everything in the app without them.';

  @override
  String get unblockedLockingSoonChip => 'LOCKING SOON';

  @override
  String get unblockedAvailableChip => 'APPS AVAILABLE';

  @override
  String get unblockedAlmostTime => 'Almost time';

  @override
  String get unblockedTitle => 'Apps unlocked';

  @override
  String get unblockedLockSoonSemantics => 'Apps lock in under a minute';

  @override
  String unblockedLockAgainIn(String duration) {
    return 'Apps lock again in $duration';
  }

  @override
  String get unblockedLockSoonNote => 'Apps lock in under a minute.';

  @override
  String unblockedAppsLockAgainAt(String time) {
    return 'Your apps lock again at $time.';
  }

  @override
  String unblockedAppLocksAgainAt(String name, String time) {
    return '$name locks again at $time.';
  }

  @override
  String get unblockedBlocking => 'Blocking…';

  @override
  String get unblockedBlockAgain => 'Block apps again';

  @override
  String get unblockedBlockNoteSession =>
      'Blocks your apps now and resumes your focus timer.';

  @override
  String get unblockedBlockNote => 'Blocks your apps now.';

  @override
  String get unblockedRelockFailed =>
      'We could not block your apps right now. Please try again.';

  @override
  String get unblockedTimerPaused => 'Focus timer paused';

  @override
  String unblockedPausedSemantics(String name, String duration) {
    return 'Focus timer paused. $name, $duration remaining';
  }

  @override
  String unblockedPausedRemaining(String name, String clock) {
    return '$name · $clock remaining';
  }

  @override
  String get endEarlyCloseTooltip => 'Close and keep going';

  @override
  String get endEarlyReadyTitle => 'Ready when you are';

  @override
  String get endEarlyReadyBody =>
      'Would you like to end this session early, or keep going?';

  @override
  String get endEarlyWaitBody =>
      'Is this something you need, or something you reached for?';

  @override
  String get endEarlyLogged => 'Ending early is logged as a stopped session.';

  @override
  String endEarlyUnlockAfter(int seconds) {
    return 'Buttons unlock after $seconds seconds.';
  }

  @override
  String get endEarlyChooseNow => 'You can choose now.';

  @override
  String endEarlyChooseIn(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'seconds',
      one: 'second',
    );
    return 'You can choose in $seconds $_temp0. Buttons are disabled until then.';
  }

  @override
  String endEarlyChooseInShort(int seconds) {
    return 'You can choose in $seconds s';
  }

  @override
  String get endSessionButton => 'End session';

  @override
  String get sessionOvertimeBody =>
      'Your planned time is over. Your apps will stay set aside until you end the session.';

  @override
  String get sessionOvertimeHint =>
      'You can end your session whenever you’re ready.';

  @override
  String sessionEndNotifTitle(String name) {
    return '$name time is complete';
  }

  @override
  String get sessionEndNotifBody =>
      'You’ve made space for yourself. Return when you’re ready.';

  @override
  String get pickerNotSavedStale =>
      'Nothing was saved. Stop the app and run it again so the new picker code is built (a hot reload is not enough).';
}
