import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('ar'),
    Locale('en')
  ];

  /// Validation error text for family member dropdown
  ///
  /// In en, this message translates to:
  /// **'Please select a person'**
  String get selectPersonValidateErr;

  /// Label for main menu select
  ///
  /// In en, this message translates to:
  /// **'Choose Family'**
  String get selectFamily;

  /// Validation error text for main menu family dropdown
  ///
  /// In en, this message translates to:
  /// **'Please select a family'**
  String get selectFamilyValidateErr;

  /// Button text to enter family menu
  ///
  /// In en, this message translates to:
  /// **'Enter family\'s page'**
  String get enterFamily;

  /// Button text in family menu to navigate to family tree
  ///
  /// In en, this message translates to:
  /// **'Family Tree'**
  String get showTree;

  /// Submit text
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Label text for choosing family member dropdown
  ///
  /// In en, this message translates to:
  /// **'Choose a family member'**
  String get familyChooseMember;

  /// Button text for entering a selected person's profile
  ///
  /// In en, this message translates to:
  /// **'Enter person\'s profile'**
  String get familyEnterProfile;

  /// Button text for showing relationship between two people
  ///
  /// In en, this message translates to:
  /// **'Find relationship'**
  String get familyCompareMembers;

  /// Button text for contacting family admin
  ///
  /// In en, this message translates to:
  /// **'Contact family admin'**
  String get familyContactAdmin;

  /// Modal title when no admin phone is registered
  ///
  /// In en, this message translates to:
  /// **'No contact number'**
  String get noAdminPhone;

  /// Modal body when no admin phone is registered
  ///
  /// In en, this message translates to:
  /// **'No phone number has been registered for this family\'s admin yet.'**
  String get noAdminPhoneBody;

  /// Button to close a modal
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// Title of profile screen
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Header for children if male
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get profileSonM;

  /// Header for father if male
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get profileParentM;

  /// Header for grandfather if male
  ///
  /// In en, this message translates to:
  /// **'Grandfather'**
  String get profileGrandparentM;

  /// Header for father if female
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get profileParentF;

  /// Header for grandfather if female
  ///
  /// In en, this message translates to:
  /// **'Grandfather'**
  String get profileGrandparentF;

  /// Button text in main menu
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get optionsButton;

  /// Title for options screen appbar
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get optionsTitle;

  /// Label of radio list for number of names
  ///
  /// In en, this message translates to:
  /// **'Number of Names:'**
  String get optNameLengthLabel;

  /// Radio list option 1
  ///
  /// In en, this message translates to:
  /// **'Three'**
  String get nameLengthThree;

  /// Radio list option 2
  ///
  /// In en, this message translates to:
  /// **'Four'**
  String get nameLengthFour;

  /// Radio list option 3
  ///
  /// In en, this message translates to:
  /// **'Five'**
  String get nameLengthFive;

  /// Label for choosing theme mode radio list
  ///
  /// In en, this message translates to:
  /// **'Theme Mode:'**
  String get optDarkModeLabel;

  /// Label for males only checkbox
  ///
  /// In en, this message translates to:
  /// **'Show males only in tree'**
  String get optMalesOnlyLabel;

  /// Label for text size radio list
  ///
  /// In en, this message translates to:
  /// **'Text Size:'**
  String get optTextSizeLabel;

  /// Text size option: use system setting
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get textSizeSystem;

  /// Text size option: large
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textSizeLarge;

  /// Text size option: extra large
  ///
  /// In en, this message translates to:
  /// **'Extra Large'**
  String get textSizeXLarge;

  /// Field label for username field in login page
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get loginUsernameLabel;

  /// Error text when username field is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your username'**
  String get loginUsernameWarning;

  /// Error text when password field is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get loginPasswordWarning;

  /// Error text when login form submitted with details wrong
  ///
  /// In en, this message translates to:
  /// **'Please fill in details correctly'**
  String get loginFormSubmitWarning;

  /// Field label for password field in login page
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// Button text for submitting login form
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// Button text in main menu
  ///
  /// In en, this message translates to:
  /// **'Family Admin'**
  String get adminButton;

  /// Button text for admin adding person
  ///
  /// In en, this message translates to:
  /// **'Add Person'**
  String get adminAddPerson;

  /// Button text for admin editing person
  ///
  /// In en, this message translates to:
  /// **'Edit Person'**
  String get adminEditPerson;

  /// Form field label for name field
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get adminFormName;

  /// Form field label for gender field
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get adminFormGender;

  /// Form field label for male option
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get adminFormMale;

  /// Form field label for female option
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get adminFormFemale;

  /// Form field label for year born field
  ///
  /// In en, this message translates to:
  /// **'Year Born'**
  String get adminFormYearBorn;

  /// Form field label for year died field
  ///
  /// In en, this message translates to:
  /// **'Year Died'**
  String get adminFormYearDied;

  /// Form field label for parent field
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get adminFormParent;

  /// Form field label for biography field
  ///
  /// In en, this message translates to:
  /// **'Biography'**
  String get adminFormBio;

  /// Form field label for image upload field
  ///
  /// In en, this message translates to:
  /// **'Portrait Upload'**
  String get adminFormImageUpload;

  /// Button label for taking a photo with the camera
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get adminFormImageCamera;

  /// Label for current portrait in admin form
  ///
  /// In en, this message translates to:
  /// **'Current Portrait:'**
  String get adminFormImageCurrent;

  /// Label for new portrait in admin form
  ///
  /// In en, this message translates to:
  /// **'New Portrait:'**
  String get adminFormImageNew;

  /// Validation error for name field in admin form
  ///
  /// In en, this message translates to:
  /// **'Please enter a first name'**
  String get adminFormNameVal;

  /// Validation error for gender field in admin form
  ///
  /// In en, this message translates to:
  /// **'Please choose gender'**
  String get adminFormGenderVal;

  /// Validation error for year born field in admin form
  ///
  /// In en, this message translates to:
  /// **'Please enter year born'**
  String get adminFormYearBornVal;

  /// Validation error for parent field in admin form
  ///
  /// In en, this message translates to:
  /// **'Please choose parent or Family Head if none'**
  String get adminFormParentVal;

  /// Validation error for year died field in admin form
  ///
  /// In en, this message translates to:
  /// **'Year died must be after year born'**
  String get adminFormYearDiedVal;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
