// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Rest For More';

  @override
  String get tabToday => 'Vandaag';

  @override
  String get tabMoments => 'Momenten';

  @override
  String get tabProgress => 'Voortgang';

  @override
  String get tabProfile => 'Profiel';

  @override
  String get progressNotAvailable => 'Voortgang is nog niet beschikbaar.';

  @override
  String get profileTitle => 'Profiel';

  @override
  String get profileSubtitle => 'Je instellingen en tags';

  @override
  String get nfcTagsTitle => 'NFC-tags';

  @override
  String get tagsPairPrompt =>
      'Koppel een tag om momenten met één tik te starten en te beëindigen.';

  @override
  String get tagsNonePaired => 'Nog geen tags gekoppeld.';

  @override
  String tagsPaired(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags gekoppeld.',
      one: '1 tag gekoppeld.',
    );
    return '$_temp0';
  }

  @override
  String get manageTags => 'Tags beheren';

  @override
  String get languageTitle => 'Taal';

  @override
  String get languageSystem => 'Systeemstandaard';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get appBlocked => 'Deze app is geblokkeerd';

  @override
  String get openRestForMore => 'Open Rest For More';

  @override
  String get connectStartStep =>
      'Koppel onStartStep aan het scherm voor je rustsessie.';

  @override
  String get whyThisStep => 'Waarom deze stap?';

  @override
  String get gotIt => 'Begrepen';

  @override
  String dayOfTotal(int day, int total) {
    return 'DAG $day VAN $total';
  }

  @override
  String get startTodaysStep => 'Start de stap van vandaag';

  @override
  String get makeItSmaller => 'Maak het kleiner';

  @override
  String get todaysInvitation => 'UITNODIGING VAN VANDAAG';

  @override
  String quietMomentMinutes(int minutes) {
    return 'Rustmoment van $minutes minuten';
  }

  @override
  String dayIsDone(int day) {
    return 'Dag $day is voltooid.';
  }

  @override
  String get todaysStepDone => 'De stap van vandaag is klaar';

  @override
  String dayReadyTomorrow(int day) {
    return 'Dag $day staat morgen voor je klaar. Eén stap per dag is genoeg.';
  }

  @override
  String allStepsDone(int totalDays) {
    return 'Alle $totalDays stappen zijn gedaan';
  }

  @override
  String get ownRoutineContinues =>
      'Je eigen routine gaat verder. Houd de plek voor je telefoon, het moment zonder telefoon en de activiteit die het best bij je paste vast.';

  @override
  String get momentsSubtitle => 'Kies een plek voor bewuste rust';

  @override
  String get momentTagTitle => 'Tag';

  @override
  String get momentTagDescription =>
      'Leg je apps opzij met een tik op je tag en haal ze terug met dezelfde tik.';

  @override
  String get begin => 'Begin';

  @override
  String get back => 'Terug';

  @override
  String get continueLabel => 'Doorgaan';

  @override
  String get welcomeEyebrow => 'WELKOM BIJ REST FOR MORE';

  @override
  String get welcomeTitle => 'Een zorgvuldige weg naar\nbewuste rust';

  @override
  String get welcomeBody =>
      'Wij geloven dat productiviteit maar de helft is van het ritme van het leven. Laat ons je helpen om je telefoon weg te leggen, je gedachten te ordenen en persoonlijke ruimte te maken voor langzaam, diep herstel.';

  @override
  String get welcomeBenefit1 =>
      'Geen account nodig om je eigen routine te starten';

  @override
  String get welcomeBenefit2 =>
      'Een rustig, begeleid plan van 14 dagen dat stap voor stap opbouwt';

  @override
  String get getStarted => 'Aan de slag';

  @override
  String stepOfFive(int n) {
    return 'STAP $n VAN 5';
  }

  @override
  String get goalTitle => 'Waar wil je je op\nrichten?';

  @override
  String get goalPhoneTitle => 'Je telefoon eerder weglegen';

  @override
  String get goalPhoneDesc =>
      'Bouw een geruststellende grens tussen je scherm en je avondritme voor het slapen.';

  @override
  String get goalRoutineTitle => 'Een routine opbouwen';

  @override
  String get goalRoutineDesc =>
      'Maak kleine, voedende dagelijkse rituelen die je zenuwstelsel laten weten dat het mag herstellen.';

  @override
  String get goalSocialTitle => 'Minder social media gebruiken';

  @override
  String get goalSocialDesc =>
      'Stap weg van overprikkelende feeds en krijg je focus terug.';

  @override
  String get obstacleTitle => 'Wat staat je rust\nin de weg?';

  @override
  String get selectAllThatApply => 'Selecteer alles wat van toepassing is.';

  @override
  String get obstacleScrolling => 'Scrollen';

  @override
  String get obstacleAvailability => 'Bereikbaarheid';

  @override
  String get obstacleThoughts => 'Onrustige gedachten';

  @override
  String get obstaclePlanning => 'Plannen';

  @override
  String get obstacleAlarm => 'Telefoon als wekker';

  @override
  String get obstacleNoRoutine => 'Geen routine';

  @override
  String get rhythmTitle => 'Wanneer komt je dag\nmeestal tot rust?';

  @override
  String get rhythmIntro =>
      'Vertel ons ongeveer wanneer je energie begint weg te zakken. We stemmen je rustplan af op je natuurlijke ritme.';

  @override
  String get rhythmEarlyTitle => '20:00 – 22:00 uur';

  @override
  String get rhythmEarlyDesc => 'Ik begin meestal vroeg af te bouwen.';

  @override
  String get rhythmMidTitle => '22:00 – 00:00 uur';

  @override
  String get rhythmMidDesc => 'Mijn avonden duren meestal wat langer.';

  @override
  String get rhythmLateTitle => 'Na middernacht';

  @override
  String get rhythmLateDesc => 'Ik bouw meestal pas laat in de nacht af.';

  @override
  String get activitiesTitle => 'Welke soort activiteiten\nspreekt je aan?';

  @override
  String get activitiesIntro =>
      'Kies de rustgevende activiteiten die bij je passen. Je kunt er meer dan één kiezen.';

  @override
  String get activityQuietTitle => 'Rustmomenten';

  @override
  String get activityQuietDesc =>
      'Kom tot rust met een paar vredige minuten weg van je scherm.';

  @override
  String get activityReadingTitle => 'Lezen op papier';

  @override
  String get activityReadingDesc =>
      'Leg je telefoon weg en neem de tijd voor een echt boek.';

  @override
  String get activityBreathingTitle => 'Ademhalingsroutines voor de avond';

  @override
  String get activityBreathingDesc =>
      'Gebruik eenvoudige ademhalingsoefeningen om lichaam en geest tot rust te brengen.';

  @override
  String get finalStep => 'LAATSTE STAP';

  @override
  String get reminderTitle => 'Wil je een\ndagelijkse herinnering?';

  @override
  String get reminderIntro =>
      'Een zachte herinnering helpt je ruimte te maken voor rust, zonder druk.';

  @override
  String get dailyReminder => 'Dagelijkse herinnering';

  @override
  String get oneGentleReminder => 'Elke dag één zachte herinnering';

  @override
  String get reminderTime => 'Tijdstip van herinnering';

  @override
  String get done => 'Klaar';

  @override
  String get maybeLater => 'Misschien later';

  @override
  String get whyWeChoseThis => 'Waarom we dit voor je kozen';

  @override
  String dayRange(int from, int to) {
    return 'Dag $from–$to';
  }

  @override
  String get planTitle => 'Dit is jouw\npersoonlijke plan';

  @override
  String get planIntro =>
      'Een rustig plan van 14 dagen, afgestemd op je doelen, ritme en favoriete activiteiten.';

  @override
  String get startYourPlan => 'Start je plan';

  @override
  String get adjustPlanSettings => 'Planinstellingen aanpassen';

  @override
  String dayWithTitle(int day, String title) {
    return 'Dag $day: $title';
  }

  @override
  String phaseN(int n) {
    return 'FASE $n';
  }

  @override
  String get phase1Title => 'Maak wat ruimte';

  @override
  String get phase1Desc =>
      'Begin klein door wat afstand te creëren tussen jou en je telefoon.';

  @override
  String get phase1Item1 => 'Leg je telefoon 10 minuten weg';

  @override
  String get phase1Item2 => 'Neem één rustmoment';

  @override
  String get phase1Item3 => 'Merk op hoe je avond aanvoelt';

  @override
  String get phase2Title => 'Bouw je ritme op';

  @override
  String get phase2Desc =>
      'Maak van je eerste kleine stappen een eenvoudige avondroutine.';

  @override
  String get phase2Item1 => 'Begin eerder met afbouwen';

  @override
  String get phase2Item2 => 'Kies een activiteit zonder scherm';

  @override
  String get phase2Item3 => 'Herhaal je avondroutine';

  @override
  String get phase3Title => 'Maak het van jou';

  @override
  String get phase3Desc =>
      'Versterk de gewoontes die het best werken voor jou en je rust.';

  @override
  String get phase3Item1 => 'Houd je favoriete routine vast';

  @override
  String get phase3Item2 => 'Kijk terug op wat het meest hielp';

  @override
  String get phase3Item3 => 'Bereid je voor op het leven na dag 14';

  @override
  String get adjustSaveFailed =>
      'Je wijzigingen konden niet worden opgeslagen. Probeer het opnieuw.';

  @override
  String get reviewChanges => 'Wijzigingen bekijken';

  @override
  String get keepCurrentPlan => 'Mijn huidige plan houden';

  @override
  String get confirmChanges => 'Wijzigingen bevestigen';

  @override
  String get keepEditing => 'Verder aanpassen';

  @override
  String get adjustEyebrow => 'PAS JE PLAN AAN';

  @override
  String get adjustTitle => 'Laat het plan\nbij je passen';

  @override
  String get adjustIntro =>
      'Pas alleen aan wat niet past. Je andere antwoorden blijven zoals ze zijn, dus je hoeft niet opnieuw te beginnen.';

  @override
  String get stepSizeQuestion => 'Hoe groot moet elke stap zijn?';

  @override
  String get standardSteps => 'Standaardstappen';

  @override
  String get standardStepsDesc =>
      'De volledige versie van de stap van elke dag.';

  @override
  String get smallerSteps => 'Kleinere stappen';

  @override
  String get smallerStepsDesc =>
      'Een lichtere versie van elke stap. Hij telt even zwaar mee en je houdt alle 14 dagen.';

  @override
  String get yourGoal => 'Jouw doel';

  @override
  String get obstacleQuestion => 'Wat staat je het meest in de weg?';

  @override
  String get calmActivity => 'Rustige activiteit';

  @override
  String get reviewYourChanges => 'Bekijk je wijzigingen';

  @override
  String get nothingSavedUntilConfirm =>
      'Er wordt niets opgeslagen voordat je bevestigt.';

  @override
  String get adjustRunningStepSize =>
      'De komende dagen krijgen de nieuwe stapgrootte. Dagen die je al deed blijven zoals ze zijn.';

  @override
  String get adjustRunningNewPlan =>
      'Je nieuwe plan wordt je actieve plan en begint bij dag 1. Wat je al deed blijft bewaard.';

  @override
  String get yourFirstDays => 'Je eerste dagen';

  @override
  String get momentFocusTitle => 'Focus';

  @override
  String get momentFocusDescription =>
      'Maak je hoofd leeg om je te richten op één rustige taak.';

  @override
  String get momentFocusPill => 'Een rustige plek';

  @override
  String get momentFocusHeading => 'Kom tot rust in het moment';

  @override
  String get momentFocusQuote => 'Eén ding, met volle aandacht.';

  @override
  String get momentFocusButton => 'Start Focus';

  @override
  String get momentFocusStep1 => 'Kies één betekenisvolle taak.';

  @override
  String get momentFocusStep2 =>
      'Laat je adem tot rust komen in drie langzame tellen.';

  @override
  String get momentFocusStep3 =>
      'Keer rustig terug zodra je aandacht afdwaalt.';

  @override
  String get momentReadingTitle => 'Lezen';

  @override
  String get momentReadingDescription => 'Houd afleiding weg terwijl je leest.';

  @override
  String get momentReadingPill => 'Eén pagina tegelijk';

  @override
  String get momentReadingHeading => 'Kom tot rust in het moment';

  @override
  String get momentReadingQuote => 'Eén pagina, met volle aandacht.';

  @override
  String get momentReadingButton => 'Start met lezen';

  @override
  String get momentReadingStep1 =>
      'Kies het boek of artikel dat je wilt lezen.';

  @override
  String get momentReadingStep2 =>
      'Laat je schouders zakken en adem langzaam uit.';

  @override
  String get momentReadingStep3 =>
      'Als je gedachten afdwalen, ga terug naar de volgende regel.';

  @override
  String get momentEveningTitle => 'Avond';

  @override
  String get momentEveningDescription =>
      'Bouw af en leg je telefoon weg voor het slapen.';

  @override
  String get momentEveningPill => 'Een zachte landing';

  @override
  String get momentEveningHeading => 'Sluit de dag af';

  @override
  String get momentEveningQuote => 'De dag mag eindigen.';

  @override
  String get momentEveningButton => 'Plan je avond';

  @override
  String get momentEveningStep1 => 'Kies wanneer je in bed wilt liggen.';

  @override
  String get momentEveningStep2 =>
      'Bepaal wat je avond nodig heeft en in welke volgorde.';

  @override
  String get momentEveningStep3 =>
      'Laat je telefoon rusten terwijl je afbouwt.';

  @override
  String get momentMorningTitle => 'Ochtend';

  @override
  String get momentMorningDescription =>
      'Begin de dag voordat je telefoon dat doet.';

  @override
  String get momentMorningPill => 'Een rustige start';

  @override
  String get momentMorningHeading => 'Begin de dag';

  @override
  String get momentMorningQuote => 'Je ochtend is eerst van jou.';

  @override
  String get momentMorningButton => 'Plan je ochtend';

  @override
  String get momentMorningStep1 => 'Kies wanneer je wakker wordt.';

  @override
  String get momentMorningStep2 =>
      'Kies wat je ochtend nodig heeft vóór je telefoon.';

  @override
  String get momentMorningStep3 =>
      'Je telefoon komt terug als je ochtend klaar is.';

  @override
  String get aGentleReminder => 'EEN ZACHTE HERINNERING';

  @override
  String get backToMoments => 'Terug naar Momenten';

  @override
  String durationMinutes(int m) {
    return '$m min';
  }

  @override
  String durationHours(int h) {
    return '$h u';
  }

  @override
  String durationHoursMinutes(int h, String m) {
    return '$h u $m min';
  }

  @override
  String get eveningEndAtBedtime => 'Op bedtijd';

  @override
  String get eveningEndAtNextScan => 'Bij de volgende scan';

  @override
  String get blockingStartsHere => 'Blokkeren begint hier.';

  @override
  String get saveEvening => 'Avond opslaan';

  @override
  String get eveningSubtitle => 'Kies je bedtijd. Daar rekenen we vanaf terug.';

  @override
  String get bedtimePerDay => 'Bedtijd per dag';

  @override
  String get bedtimeNote =>
      'Een bedtijd tussen 00:00 en 05:59 hoort bij de avond ervoor, dus een vrijdagavond kan eindigen op zaterdag om 00:30.';

  @override
  String get eveningAfterMidnight => 'Na middernacht';

  @override
  String get yourEvening => 'Jouw avond';

  @override
  String get yourEveningNote =>
      'Je avond begint op tijd om elke stap voor bedtijd te passen. Je telefoon weglegen komt eerst.';

  @override
  String get reminders => 'Herinneringen';

  @override
  String get headsUpBefore => 'Waarschuwing voordat je avond begint';

  @override
  String minutesShort(int v) {
    return '$v min';
  }

  @override
  String get secondReminder =>
      'Tweede herinnering als je nog niet bent begonnen';

  @override
  String get off => 'Uit';

  @override
  String afterMinutes(int v) {
    return 'Na $v min';
  }

  @override
  String get remindersNote =>
      'Herinneringen zijn lokale meldingen. De app kan het vragen, maar kan je niet dwingen je telefoon weg te leggen, en de stille modus of Focus-modus van je telefoon kan ze nog dempen.';

  @override
  String get whenBlockingEnds => 'Wanneer het blokkeren stopt';

  @override
  String get strictOvernight =>
      'Strikt overnacht: het blokkeren blijft aan tot je scant. Een timer beëindigt het niet voor je.';

  @override
  String get liftsAtBedtime => 'Het blokkeren stopt vanzelf op bedtijd.';

  @override
  String yourWeekdayEvening(String day) {
    return 'Jouw ${day}avond';
  }

  @override
  String get headsUp => 'Waarschuwing';

  @override
  String get headsUpDetail => 'Een herinnering dat je avond zo begint.';

  @override
  String get bedtime => 'Bedtijd';

  @override
  String get bedtimeBlockingEnds => 'Bedtijd · blokkeren stopt';

  @override
  String get blockingStaysUntilScan =>
      'Het blokkeren blijft tot je volgende scan.';

  @override
  String get saveMorning => 'Ochtend opslaan';

  @override
  String get wakeUpTimePerDay => 'Wektijd per dag';

  @override
  String get wakeUpNote =>
      'Dit is niet je wekker. De app kan niet bij de wekker van je telefoon, dus stel daar dezelfde tijd in. Je ochtend begint op de tijd die je hier kiest.';

  @override
  String get yourMorning => 'Jouw ochtend';

  @override
  String get yourMorningNote =>
      'Alles wat je doet voordat je telefoon terugkomt. Je telefoon is geen stap. Het is wat erna komt.';

  @override
  String yourWeekdayMorning(String day) {
    return 'Jouw ${day}ochtend';
  }

  @override
  String get timerOnlyNote =>
      'Alleen timer: apps worden vanzelf ontgrendeld als je stappen klaar zijn. Dit is geen strikte blokkade.';

  @override
  String get timesFollowClock =>
      'Tijden volgen de klok en tijdzone van je telefoon.';

  @override
  String get phoneIsBack => 'Je telefoon is terug';

  @override
  String get appsUnlock => 'Apps worden ontgrendeld.';

  @override
  String couldNotSaveMoment(String name) {
    return 'Je $name kon niet worden opgeslagen. Probeer het opnieuw.';
  }

  @override
  String momentSaved(String name) {
    return '$name opgeslagen';
  }

  @override
  String get couldNotLoad => 'Laden mislukt. Probeer opnieuw';

  @override
  String get appsToBlock => 'Apps om te blokkeren';

  @override
  String get noAppsChosen => 'Nog geen apps gekozen.';

  @override
  String get appsChosen => 'Apps gekozen.';

  @override
  String appsChosenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps gekozen.',
      one: '1 app gekozen.',
    );
    return '$_temp0';
  }

  @override
  String onlyUsedFor(String name) {
    return 'Alleen gebruikt voor $name. De andere momenten houden hun eigen keuze.';
  }

  @override
  String get change => 'Wijzigen';

  @override
  String get chooseApps => 'Apps kiezen';

  @override
  String get nfcOff =>
      'NFC staat uit. Zet het aan in de instellingen van je telefoon.';

  @override
  String get nfcUnsupported => 'Dit apparaat ondersteunt geen NFC.';

  @override
  String get holdNearTagToEnd => 'Houd je iPhone bij je tag om te beëindigen';

  @override
  String get holdNearTagToBegin => 'Houd je iPhone bij je tag om te beginnen';

  @override
  String scanningStopped(String message) {
    return 'Scannen gestopt: $message';
  }

  @override
  String get notYourTag => 'Dit is geen van je gekoppelde tags.';

  @override
  String get couldNotReadTag =>
      'Deze tag kon niet worden gelezen. Probeer het opnieuw.';

  @override
  String get couldNotStartScanning => 'Scannen kon niet worden gestart.';

  @override
  String get waitingForTag => 'Wachten op tag…';

  @override
  String get pairTagFirst => 'Koppel eerst een tag';

  @override
  String get scanTagToEnd => 'Scan tag om te beëindigen';

  @override
  String get scanTagToBegin => 'Scan tag om te beginnen';

  @override
  String get tagMomentDescription =>
      'Leg je apps opzij met een tik en haal ze terug met dezelfde tag.';

  @override
  String get tagMomentEyebrow => 'TAGMOMENT';

  @override
  String get statusChecking => 'Controleren';

  @override
  String get statusActive => 'Actief';

  @override
  String get statusNotActive => 'Niet actief';

  @override
  String get tagActiveBody =>
      'Je apps staan opzij. Alleen je tag kan dit moment beëindigen.';

  @override
  String get tagReadyBody =>
      'Klaar als jij het bent. Scan je tag om je apps opzij te zetten.';

  @override
  String get tagPairBody => 'Koppel een tag om dit moment te gebruiken.';

  @override
  String get chooseAppsToSetAside => 'Kies apps om opzij te zetten';

  @override
  String get howItWorks => 'Hoe het werkt';

  @override
  String get tagStep1 => 'Kies de apps die je opzij wilt zetten.';

  @override
  String get tagStep2 => 'Scan je tag om te beginnen.';

  @override
  String get tagStep3 => 'Scan dezelfde tag opnieuw om te beëindigen.';

  @override
  String get tagQuote => 'Leg het neer. Pak het op wanneer jij dat kiest.';

  @override
  String get sessionFocusSubtitle =>
      'Kies hoe lang en wat je uit de weg wilt houden.';

  @override
  String get sessionReadingSubtitle =>
      'Kies hoe lang je wilt lezen en wat stil blijft.';

  @override
  String get startFocus => 'Start Focus';

  @override
  String get startReading => 'Start met lezen';

  @override
  String get presetQuick => 'Kort';

  @override
  String get presetStandard => 'Standaard';

  @override
  String get presetDeep => 'Diep';

  @override
  String get presetShort => 'Kort';

  @override
  String get presetChapter => 'Hoofdstuk';

  @override
  String get presetLong => 'Lang';

  @override
  String get presetCustom => 'Eigen keuze';

  @override
  String get howLong => 'Hoe lang';

  @override
  String endsAfterMinutes(int minutes) {
    return 'Eindigt na $minutes minuten. Eerder stoppen vraagt eerst om bevestiging en wordt vastgelegd als eerder gestopt.';
  }

  @override
  String get fewerMinutes => 'Minder minuten';

  @override
  String get moreMinutes => 'Meer minuten';

  @override
  String get endSessionEarlyTitle => 'Deze sessie eerder beëindigen?';

  @override
  String get endSessionEarlyBody =>
      'Je apps worden nu ontgrendeld. Deze sessie wordt vastgelegd als eerder gestopt.';

  @override
  String get keepGoing => 'Ga door';

  @override
  String get endEarly => 'Eerder stoppen';

  @override
  String get sessionTitle => 'Sessie';

  @override
  String get sessionStartBlockFailed =>
      'We konden je apps niet opzij zetten, dus er is niets gestart. Controleer of blokkeren is toegestaan voor Rest For More en probeer het opnieuw.';

  @override
  String get sessionStartFailed =>
      'Er ging iets mis bij het starten. Probeer het opnieuw.';

  @override
  String get sessionEndFailed =>
      'Er ging iets mis bij het beëindigen. Probeer het opnieuw.';

  @override
  String get appsStillSetAsideTryAgain =>
      'Je apps staan nog opzij. Probeer het opnieuw.';

  @override
  String get settingAppsAside => 'Je apps worden opzij gezet…';

  @override
  String get bringingAppsBack => 'Je apps worden teruggezet…';

  @override
  String timeLeft(String time) {
    return '$time over';
  }

  @override
  String appsSetAsideUntil(String time) {
    return 'Je apps staan opzij tot $time.';
  }

  @override
  String get sessionEnded => 'Sessie beëindigd';

  @override
  String get wellDone => 'Goed gedaan';

  @override
  String get sessionEndedEarlyBody =>
      'Je apps zijn terug. Dat is prima. Begin opnieuw wanneer je wilt.';

  @override
  String get sessionCompleteBody => 'Je tijd is om en je apps zijn terug.';

  @override
  String get somethingWentWrong => 'Er ging iets mis.';

  @override
  String get appsStillSetAside => 'Je apps staan nog opzij';

  @override
  String get releaseFailedBody =>
      'De sessie is voorbij, maar we konden je apps niet terugzetten. Probeer het opnieuw of open Help als het blijft gebeuren.';

  @override
  String get needAnApp => 'Heb je een app nodig?';

  @override
  String get tryAgain => 'Opnieuw proberen';

  @override
  String get unblockFailed =>
      'We konden dit nu niet deblokkeren. Probeer het opnieuw.';

  @override
  String get cancelKeepBlocked => 'Annuleren en geblokkeerd houden';

  @override
  String get whichAppNeeded => 'Welke app heb je nodig?';

  @override
  String get onlyOneOpens =>
      'Alleen de app die je kiest gaat open, en maar voor even.';

  @override
  String get couldNotReadBlocked =>
      'Je geblokkeerde apps konden niet worden gelezen.';

  @override
  String get nothingBlocked => 'Er is nu niets geblokkeerd.';

  @override
  String get howLongNeed => 'Hoe lang heb je het echt nodig?';

  @override
  String get minutesToUnblock => 'Minuten om te deblokkeren';

  @override
  String minutesCount(int n) {
    return '$n minuten';
  }

  @override
  String minuteUnit(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'minuten',
      one: 'minuut',
    );
    return '$_temp0';
  }

  @override
  String appsAvailableUntil(String time) {
    return 'Je apps zijn beschikbaar tot $time.';
  }

  @override
  String nameAvailableUntil(String name, String time) {
    return '$name is beschikbaar tot $time.';
  }

  @override
  String get unblocking => 'Deblokkeren…';

  @override
  String get unblock => 'Deblokkeren';

  @override
  String get unblocked => 'Gedeblokkeerd';

  @override
  String appsNowAvailable(String time) {
    return 'Je apps zijn beschikbaar tot $time. Ze gaan vanzelf weer op slot.';
  }

  @override
  String appNowAvailable(String name, String time) {
    return '$name is beschikbaar tot $time. De app gaat vanzelf weer op slot.';
  }

  @override
  String openApp(String name) {
    return 'Open $name';
  }

  @override
  String get notNow => 'Niet nu';

  @override
  String get youCanContinueNow => 'Je kunt nu doorgaan.';

  @override
  String get takeMomentBreathe => 'Neem even de tijd om adem te halen';

  @override
  String get wheneverReady => 'Wanneer je er klaar voor bent.';

  @override
  String get needOrReachedFor =>
      'Heb je dit echt nodig, of greep je er automatisch naar?';

  @override
  String get pauseFinished => 'Pauze klaar';

  @override
  String get pauseInProgress => 'Pauze bezig, een paar seconden';

  @override
  String get stopMomentTitle => 'Dit moment stoppen?';

  @override
  String get dailyStepUnfinished => 'Je dagelijkse stap blijft onafgerond.';

  @override
  String get stopMoment => 'Moment stoppen';

  @override
  String get useStopHint =>
      'Gebruik Stop om dit moment te beëindigen, of verlaat de app om het door te laten lopen.';

  @override
  String quietMomentHyphen(int minutes) {
    return 'Rustmoment van $minutes minuten';
  }

  @override
  String get littleSpaceWellDone => 'Even ruimte voor jezelf. Goed gedaan.';

  @override
  String get fewMinutesAway => 'Neem een paar minuten afstand van je telefoon.';

  @override
  String get finishDailyStep => 'Dagelijkse stap afronden';

  @override
  String get stop => 'Stop';

  @override
  String get start => 'Start';

  @override
  String get shortOnTime =>
      'Weinig tijd of energie? Dat is oké. Je kunt nog steeds een kleine stap zetten.';

  @override
  String get originalOption => 'OORSPRONKELIJKE OPTIE';

  @override
  String get recommendedAlternative => 'AANBEVOLEN ALTERNATIEF';

  @override
  String startMinuteVersion(int minutes) {
    return 'Start de versie van $minutes minuten';
  }

  @override
  String keepMinuteVersion(int minutes) {
    return 'Houd de versie van $minutes minuten';
  }

  @override
  String get keepOriginal => 'Houd het origineel';

  @override
  String get save => 'Opslaan';

  @override
  String get cancel => 'Annuleren';

  @override
  String saveWithCount(int count) {
    return 'Opslaan · $count geselecteerd';
  }

  @override
  String get searchApps => 'Apps zoeken';

  @override
  String get couldNotReadApps => 'Je apps konden niet worden gelezen.';

  @override
  String appsForMoment(String name) {
    return 'Apps voor $name';
  }

  @override
  String get couldNotSaveApps =>
      'Je apps konden niet worden opgeslagen. Probeer het opnieuw.';

  @override
  String saveAppsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps opslaan',
      one: '1 app opslaan',
    );
    return '$_temp0';
  }

  @override
  String get chooseApps2 => 'Apps kiezen';

  @override
  String get pickAppsToSetAside => 'Kies de apps die je opzij wilt zetten.';

  @override
  String appsWillBeSetAside(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps worden opzij gezet.',
      one: '1 app wordt opzij gezet.',
    );
    return '$_temp0';
  }

  @override
  String get androidOnlyList =>
      'Apps kiezen uit deze lijst kan alleen op Android.';

  @override
  String get noAppsFound => 'Geen apps gevonden.';

  @override
  String get allowAccessibility => 'Toegankelijkheid toestaan';

  @override
  String get accessibilityBody =>
      'Om je apps opzij te zetten, moet de toegankelijkheidsservice van Rest4More aan staan. Die merkt alleen op welke app opent, zodat hij voor de apps die je koos kan gaan staan.';

  @override
  String get inSettings => 'In Instellingen';

  @override
  String get accStep1 => 'Open Geïnstalleerde apps of Gedownloade apps.';

  @override
  String get accStep2 => 'Kies Rest4More.';

  @override
  String get accStep3 => 'Zet hem aan en bevestig.';

  @override
  String get openSettings => 'Instellingen openen';

  @override
  String get accessIsOff => 'Toegang staat uit';

  @override
  String get screenTimeAccess => 'Toegang tot Schermtijd';

  @override
  String get allowScreenTimeInSettings =>
      'Sta toegang tot Schermtijd toe in Instellingen en kom dan terug om je apps te kiezen.';

  @override
  String get screenTimeNeeded =>
      'Rest4More heeft toegang tot Schermtijd nodig om je gekozen apps opzij te zetten. Je keuzes blijven op deze telefoon.';

  @override
  String get allowAccess => 'Toegang toestaan';

  @override
  String get couldNotLoadTags => 'Je tags konden niet worden geladen.';

  @override
  String get couldNotRemoveTag => 'De tag kon niet worden verwijderd.';

  @override
  String get holdNearTag => 'Houd je iPhone bij de tag';

  @override
  String get tagNoLink => 'Deze tag bevat geen Rest4More-link.';

  @override
  String get tagAdded => 'Tag toegevoegd.';

  @override
  String get addTag => 'Tag toevoegen';

  @override
  String get pairTagOnce =>
      'Koppel een tag één keer. Daarna start of beëindigt een tik je Tagmoment.';

  @override
  String get holdPhoneAgainstTag =>
      'Houd je telefoon tegen de tag die je wilt toevoegen.';

  @override
  String get noTagsAddOne =>
      'Nog geen tags gekoppeld. Voeg er een toe om te beginnen.';

  @override
  String tagNumber(int n) {
    return 'Tag $n';
  }

  @override
  String get removeTag => 'Tag verwijderen';

  @override
  String get noStepsYet => 'Nog geen stappen. Voeg de eerste toe.';

  @override
  String get editStep => 'Stap bewerken';

  @override
  String get newStep => 'Nieuwe stap';

  @override
  String get addAStep => 'Een stap toevoegen';

  @override
  String get yourOwnStep => 'Je eigen stap';

  @override
  String totalDuration(String duration) {
    return 'Totaal $duration';
  }

  @override
  String get addStep => 'Stap toevoegen';

  @override
  String stepSemantics(String title, String duration) {
    return '$title, $duration. Tik om te bewerken.';
  }

  @override
  String removeStep(String title) {
    return '$title verwijderen';
  }

  @override
  String get stepName => 'Naam';

  @override
  String get shorter => 'Korter';

  @override
  String get longer => 'Langer';

  @override
  String get openAppFailed => 'Er ging iets mis bij het openen van de app.';

  @override
  String get phraseReadingActivity => 'een paar pagina’s lezen';

  @override
  String get phraseReadingMaterial => 'je boek';

  @override
  String get phraseQuietActivity => 'een paar minuten rustig zitten';

  @override
  String get phraseQuietMaterial => 'een comfortabele plek om te zitten';

  @override
  String get phraseBreathingActivity => 'een paar minuten rustig ademhalen';

  @override
  String get phraseBreathingMaterial => 'een rustige hoek';

  @override
  String get phrasePreparationActivity => 'je voorbereiden op morgen';

  @override
  String get phrasePreparationMaterial => 'wat je morgen nodig hebt';

  @override
  String get phraseDefaultActivity => 'een rustige activiteit naar keuze';

  @override
  String get phraseDefaultMaterial => 'wat je ervoor nodig hebt';

  @override
  String get planDefaultAnchor => 'je gebruikelijke avondroutine';

  @override
  String get planContextRestnest =>
      'Gebruik je RestNest als vaste plek voor je telefoon.';

  @override
  String get planContextNoRestnest =>
      'Kies een vaste plek voor je telefoon; een RestNest is niet nodig.';

  @override
  String get planCardOn =>
      'Gebruik je gekoppelde kaart wanneer kaartfunctionaliteit op dit apparaat beschikbaar is.';

  @override
  String get planCardOff =>
      'Start handmatig; fysiek vrijgeven met een kaart kan niet zonder kaart.';

  @override
  String planWhyThis(String goal, String obstacle) {
    return 'Dit past bij je doel “$goal” en je gekozen obstakel: $obstacle.';
  }

  @override
  String get planTimingRegular => 'Gebruik je gekozen tijdstip van de dag.';

  @override
  String get planTimingOther =>
      'Kijk of je gekozen tijd vandaag past; gebruik anders je activiteitenanker.';

  @override
  String get obstaclePhraseScrolling => 'scrollen';

  @override
  String get obstaclePhraseAvailability => 'bereikbaar blijven';

  @override
  String get obstaclePhraseThoughts => 'onrustige gedachten';

  @override
  String get obstaclePhrasePlanning => 'plannen';

  @override
  String get obstaclePhraseAlarm => 'je telefoon als wekker gebruiken';

  @override
  String get obstaclePhraseNoRoutine => 'nog geen routine hebben';

  @override
  String planPreviewReason(String goal, String obstacle) {
    return 'Gekozen voor je doel “$goal” en je grootste obstakel: $obstacle.';
  }

  @override
  String get planDisclaimer =>
      'Dit plan is een suggestie op basis van je antwoorden, geen medisch advies. Het kan geen betere slaap beloven en je kunt het aanpassen wanneer je wilt.';

  @override
  String get goalEffectPhone =>
      'Elke dag heeft één stap die in de avond wat meer afstand tussen jou en je telefoon brengt.';

  @override
  String get goalEffectRoutine =>
      'Elke dag voegt één klein, herhaalbaar onderdeel aan je avond toe, zodat het langzaam een routine wordt.';

  @override
  String get goalEffectSocial =>
      'Elke dag helpt je één automatische check op te merken en te kiezen wat je in plaats daarvan doet.';

  @override
  String get goalEffectDefault => 'Elke dag heeft één stap richting je doel.';

  @override
  String get reasonYourGoal => 'Jouw doel';

  @override
  String get reasonObstacle => 'Wat je in de weg zit';

  @override
  String reasonObstacleText(String tip) {
    return 'Dat heb je ons verteld, dus bij elke stap hoort een tip daarvoor: $tip';
  }

  @override
  String get reasonRhythm => 'Jouw ritme';

  @override
  String get reasonRhythmVariable =>
      'Je dagen zijn niet altijd hetzelfde, dus elke stap is gekoppeld aan een moment in je dag in plaats van aan een vast uur.';

  @override
  String reasonRhythmWindow(String window) {
    return 'Je bouwt meestal $window af, dus de stappen zijn bedoeld voor dat deel van je avond.';
  }

  @override
  String get windDownEarly => 'tussen 20:00 en 22:00 uur';

  @override
  String get windDownMid => 'tussen 22:00 uur en middernacht';

  @override
  String get windDownLate => 'na middernacht';

  @override
  String get reasonAnchor => 'Jouw vaste moment';

  @override
  String reasonAnchorText(String anchor) {
    return 'Stappen beginnen na iets wat je al doet: $anchor.';
  }

  @override
  String get reasonEnjoy => 'Waar je van geniet';

  @override
  String reasonEnjoyText(String activity) {
    return 'Je koos “$activity”, dus dat is het rustige alternatief in je stappen.';
  }

  @override
  String get reasonStepSize => 'Stapgrootte';

  @override
  String get reasonStepSizeSmaller =>
      'Je koos kleinere stappen. Ze tellen even zwaar mee en je kunt ze later groter maken als je wilt.';

  @override
  String get reasonStepSizeStandard =>
      'Als een stap te groot voelt, kun je op elk moment overstappen op een kleinere versie.';

  @override
  String get reasonProducts => 'Jouw producten';

  @override
  String get productRestnest =>
      'Je RestNest wordt gebruikt als plek voor je telefoon.';

  @override
  String get productCard =>
      'Je kunt een moment starten en beëindigen met je kaart.';

  @override
  String get changeGoal => 'Doel';

  @override
  String get notChosen => 'Niet gekozen';

  @override
  String get greetingMorning => 'Goedemorgen';

  @override
  String get greetingAfternoon => 'Goedemiddag';

  @override
  String get greetingEvening => 'Goedenavond';
}
