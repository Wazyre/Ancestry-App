# Ancestry App — Developer Documentation

## Table of Contents
1. [Project Overview](#1-project-overview)
2. [Architecture](#2-architecture)
3. [Project Structure](#3-project-structure)
4. [Database & Backend](#4-database--backend)
5. [State Management](#5-state-management)
6. [Localization](#6-localization)
7. [Navigation](#7-navigation)
8. [Feature Reference](#8-feature-reference)
   - [Intro / Splash Screen](#81-intro--splash-screen)
   - [Family Main Screen](#82-family-main-screen)
   - [Family Tree Visualization](#83-family-tree-visualization)
   - [Relationship Finder](#84-relationship-finder)
   - [Profile Screen](#85-profile-screen)
   - [Global Search](#86-global-search)
   - [Admin Panel](#87-admin-panel)
   - [Options Screen](#88-options-screen)
9. [Reusable Base Widgets](#9-reusable-base-widgets)
10. [Offline Caching](#10-offline-caching)
11. [Arabic Text Normalization](#11-arabic-text-normalization)
12. [Data Model](#12-data-model)
13. [Theming](#13-theming)
14. [Adding a Localization Key](#14-adding-a-localization-key)
15. [Dependencies](#15-dependencies)
16. [Known Issues & TODOs](#16-known-issues--todos)
17. [Changelog](#17-changelog)

---

## 1. Project Overview

**Ancestry App** is a Flutter mobile application for displaying, browsing, and managing family trees. It targets Android (primary) and iOS.

Key capabilities:
- Browse family trees with interactive GraphView visualization
- View individual member profiles with lineage (grandparent → parent → children)
- Find the relationship path between any two family members
- Admin panel for adding/editing members (with authentication)
- Global fuzzy search across all family tables
- Full Arabic / English localization with gender-aware labels
- Offline support via SharedPreferences caching

**Backend:** Supabase (PostgreSQL + Storage)
**Min SDK:** Flutter default (`flutter.minSdkVersion`)
**Package ID:** `com.example.ancestry_app`

---

## 2. Architecture

```
┌─────────────────────────────────────────────────────────┐
│                        UI Layer                         │
│  main.dart → SplashScreen → IntroScreen                │
│  FamilyMainScreen  ProfileScreen  FindRelationScreen    │
│  TreeViewScreen    AdminScreen    OptionsScreen         │
└─────────────────────┬───────────────────────────────────┘
                      │ Provider
┌─────────────────────▼───────────────────────────────────┐
│                  State / Service Layer                  │
│  ThemeProvider (amber color scheme, text styles)        │
│  SettingsProvider (SharedPreferences settings)          │
│  DbServices (singleton, Supabase + cache)               │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│                    Data Layer                           │
│  Supabase (PostgreSQL tables + Storage bucket)          │
│  SharedPreferences (offline JSON cache)                 │
└─────────────────────────────────────────────────────────┘
```

**State management:** Provider via `MultiProvider` at root. Two providers:
- `ThemeProvider` — color scheme + text styles
- `SettingsProvider` — user preferences (name length, locale, text scale, maleOnly, theme mode)

**Navigation:** `Navigator.push` (no named routes). All screens are pushed imperatively.

---

## 3. Project Structure

```
lib/
├── main.dart                        # Entry point, SplashScreen, IntroScreen, _PersonSearchDelegate
├── l10n/
│   ├── app_en.arb                   # English string resources
│   ├── app_ar.arb                   # Arabic string resources
│   ├── app_localizations.dart       # Generated: abstract base + delegate
│   ├── app_localizations_en.dart    # Generated: English implementation
│   ├── app_localizations_ar.dart    # Generated: Arabic implementation
│   └── l10n.dart                    # BuildContext extension (unused/commented)
└── src/ui/
    ├── base/                        # Reusable widgets and providers
    │   ├── dropdown_avatar_family.dart    # Family member dropdown with avatar
    │   ├── dropdown_search_widget.dart    # Generic dropdown wrapper
    │   ├── image_form_field.dart          # File/camera image picker
    │   ├── image_popup.dart               # Zoomable image dialog
    │   ├── photo_based_avatar.dart        # Avatar with image + name label
    │   ├── radio_list_form_field.dart     # Radio FormField (unused)
    │   ├── settings_provider.dart         # ChangeNotifier: user settings
    │   └── theme_provider.dart            # ChangeNotifier: theme + text styles
    └── mainMenu/
        ├── db_services.dart               # DbServices singleton + Family model
        ├── family_main_screen.dart        # Hub after family selection
        ├── family_tree_screen.dart        # GraphView tree + relation path tabs
        ├── family_paint_screen.dart       # Custom-painted alternative tree
        ├── find_relation_screen.dart      # Relationship finder
        ├── profile_screen.dart            # Individual person profile
        ├── admin_screen.dart              # Add/edit family members
        ├── login_admin_screen.dart        # Admin authentication
        └── options_screen.dart            # User preferences
```

**Asset directories:**
```
assets/
├── fonts/          # ArefRuqaa-Regular.ttf, ArefRuqaa-Bold.ttf, Monadi.ttf
├── profile.png     # Default avatar
├── logo.png        # App icon source
└── *.svg           # tree.svg, relation.svg, phone.svg (used in FamilyMainScreen cards)
images/             # Additional image assets
```

---

## 4. Database & Backend

### Supabase Setup

The app uses Supabase for all persistent storage. Credentials are passed to `Supabase.initialize()` in `main()`.

### Table Schemas

**`families`** — metadata table listing all registered family names
```sql
CREATE TABLE families (
  name      TEXT PRIMARY KEY,  -- also used as the family's own table name
  biography JSONB              -- Quill Delta ops array, displayed in "Family History" screen
);
```

**`<family_name>`** — one table per family (e.g. `العبدالجليل`)
```sql
CREATE TABLE <family_name> (
  id        SERIAL PRIMARY KEY,
  name      TEXT,              -- first name only
  parent    INTEGER REFERENCES <family_name>(id),
  year_born INTEGER,
  year_died INTEGER,
  imgUrl    TEXT,              -- Supabase Storage public URL or asset path
  bio       TEXT,
  gender    INTEGER            -- 1 = male, 0 = female
);
```

**`admin_users`** — admin credentials and contact info
```sql
CREATE TABLE admin_users (
  username    TEXT,
  password    TEXT,
  family_name TEXT,            -- matches a row in families.name
  phone_number TEXT            -- WhatsApp number (digits only, e.g. 9665XXXXXXXX)
);
```

**Supabase Storage buckets** (both must be set to **Public** with an INSERT policy allowing `anon`/`authenticated`):

| Bucket | Used for | Upload path |
|--------|----------|-------------|
| `portraits` | Member profile photos (admin form) | `portraits/<timestamp>_<filename>` |
| `historyImgs` | Images embedded in the family biography editor | `historyImgs/<timestamp>_<filename>` |

Public URLs are obtained via `getPublicUrl()` and stored/embedded directly in the data.

### DbServices

`lib/src/ui/mainMenu/db_services.dart`

Singleton accessed via `DbServices.instance`. Key methods:

| Method | Description |
|--------|-------------|
| `getFamily(tabFamily, {maleOnly})` | Fetches all members of a family table; caches result; falls back to cache if offline |
| `insert(tabFamily, family)` | Inserts a new Family record (Supabase auto-assigns id) |
| `update(tabFamily, family)` | Updates an existing record by id |
| `searchAllFamilies(query)` | Searches all family tables; builds tritary display name; normalizes Arabic |
| `getFamilyTableNames()` | Reads family names from `families` table; caches in SharedPreferences |
| `validateAdminCredentials(u, p)` | Queries `admin_users` by username+password; stores result in `_adminLoggedIn` |
| `getFamilyBio(familyName)` | Fetches `biography` JSONB column and re-encodes it to a Quill Delta JSON string for callers |
| `updateFamilyBio(familyName, deltaJson)` | Decodes Delta JSON string to a Dart object and writes it to the `biography` JSONB column |
| `getAdminPhone(familyName)` | Fetches `phone_number` from `admin_users` for a given family |
| `uploadImage(File, {bucket})` | Uploads to a Storage bucket (default `portraits`); returns public URL string. Pass `bucket: 'historyImgs'` for family history images. |
| `normalizeArabic(String)` | Static utility: normalizes alef variants and taa-marbuta for fuzzy matching |

**In-memory store:** `DbServices.instance.storedFamily` holds the last-fetched family list and is used by screens that don't re-fetch (e.g. `ProfileScreen`).

---

## 5. State Management

### ThemeProvider
`lib/src/ui/base/theme_provider.dart`

- Provides `lightScheme` and `darkScheme` (both seeded from `Colors.amber`)
- Text styles: `bodyNormal` (14pt), `bodyBold` (14pt bold), `treeNode(Color)` (18pt bold)
- `getCurrentScheme(context)` — returns the active ThemeData
- `getCurrentThemeMode()` — returns `'light'` or `'dark'`

### SettingsProvider
`lib/src/ui/base/settings_provider.dart`

Persists all user settings to SharedPreferences. Exposed via `savedSettings` (`SavedSettings`):

| Field | Type | Default | SharedPrefs key |
|-------|------|---------|-----------------|
| `maleOnly` | bool | false | `'maleOnly'` |
| `nameLength` | int | 3 | `'nameLength'` |
| `locale` | String | `'ar'` | `'locale'` |
| `tabFamily` | String | `''` | `'tabFamily'` |
| `themeMode` | String | `''` | `'themeMode'` |
| `textScale` | double | 1.0 | `'textScale'` |

Setters: `setMaleOnly()`, `setNameLength()`, `setLocale()`, `setTabFamily()`, `setThemeMode()`, `setTextScale()`, `flipThemeMode()`

---

## 6. Localization

The app supports **Arabic (`ar`)** and **English (`en`)**.

ARB files are in `lib/l10n/`. Dart classes are auto-generated via `flutter gen-l10n` (configured in `pubspec.yaml` with `generate: true`).

### Accessing strings
```dart
AppLocalizations.of(context)!.someKey
```

### Adding a new key
1. Add the key + English value to `lib/l10n/app_en.arb`
2. Add the same key + Arabic value to `lib/l10n/app_ar.arb`
3. Add an abstract getter to `lib/l10n/app_localizations.dart`
4. Implement the getter in `lib/l10n/app_localizations_en.dart`
5. Implement the getter in `lib/l10n/app_localizations_ar.dart`
6. Run `flutter gen-l10n` (or hot restart — generation is automatic)

### Key inventory

| Key | EN | AR |
|-----|----|----|
| `selectFamily` | Choose Family | اختر العائلة |
| `enterFamily` | Enter family's page | دخول صفحة العائلة |
| `showTree` | Family Tree | شجرة العائلة |
| `familyChooseMember` | Choose a family member | اختر فرداً من العائلة |
| `familyEnterProfile` | Enter person's profile | دخول الملف الشخصي |
| `familyCompareMembers` | Find relationship | اكتشاف القرابة |
| `familyContactAdmin` | Contact family admin | التواصل مع مسؤول العائلة |
| `familyBio` | Family History | تاريخ العائلة |
| `familyBioEmpty` | No biography … | لم يُضف تاريخ … |
| `familyBioEditorHint` | Write the family history here… | اكتب تاريخ العائلة هنا… |
| `familyBioEditorSave` | Save | حفظ |
| `familyBioEditorInsertImage` | Insert Image | إدراج صورة |
| `noAdminPhone` | No contact number | لا يوجد رقم تواصل |
| `noAdminPhoneBody` | No phone number … | لم يُسجَّل رقم … |
| `dismiss` | Dismiss | تجاهل |
| `profileTitle` | Profile | الملف الشخصي |
| `profileSonM` | Children | الأبناء |
| `profileParentM` | Father | الأب |
| `profileGrandparentM` | Grandfather | الجد |
| `profileParentF` | Father | الأب |
| `profileGrandparentF` | Grandfather | الجد |
| `globalSearchHint` | Search across all families | البحث في كل العائلات |
| `searchNoResults` | No results found | لا توجد نتائج |
| `searchViewTree` | View in family tree | عرض في الشجرة |
| `treeTabTree` | Tree | الشجرة |
| `treeTabPath` | Path | المسار |
| `treeTabList` | List | القائمة |
| `relationIsParentOf` | is parent of | والد |
| `relationIsChildOf` | is child of | ابن |
| `relationCommonAncestor` | Common Ancestor | الجد المشترك |
| `extraSettings` | Extra Settings | إعدادات إضافية |
| `optionsButton` | Options | الخيارات |
| `optNameLengthLabel` | Number of Names | عدد الأسماء |
| `nameLengthThree` | Three | ثلاثة |
| `nameLengthFour` | Four | أربعة |
| `nameLengthFive` | Five | خمسة |
| `optDarkModeLabel` | Theme Mode | وضع السمة |
| `optMalesOnlyLabel` | Show males only in tree | إظهار الذكور فقط في الشجرة |
| `optTextSizeLabel` | Text Size | حجم الخط |
| `textSizeSystem` | System Default | افتراضي |
| `textSizeLarge` | Large | كبير |
| `textSizeXLarge` | Extra Large | كبير جداً |
| `adminButton` | Family Admin | مسؤول العائلة |
| `adminAddPerson` | Add Person | إضافة شخص |
| `adminEditPerson` | Edit Person | تعديل شخص |
| `adminQuickAdd` | Quick Add | إضافة سريعة |
| `adminFormName` | First Name | الاسم الأول |
| `adminFormGender` | Gender | الجنس |
| `adminFormMale` | Male | ذكر |
| `adminFormFemale` | Female | أنثى |
| `adminFormYearBorn` | Year Born | سنة الميلاد |
| `adminFormYearDied` | Year Died | سنة الوفاة |
| `adminFormParent` | Parent | الأب |
| `adminFormBio` | Biography | السيرة الذاتية |
| `adminFormImageUpload` | Portrait Upload | تحميل الصورة |
| `adminFormImageCamera` | Take Photo | التقاط صورة |
| `adminFormNameVal` | Please enter a first name | أدخل الاسم الأول |
| `loginUsernameLabel` | Username | اسم المستخدم |
| `loginPasswordLabel` | Password | كلمة المرور |
| `loginButton` | Login | تسجيل الدخول |

---

## 7. Navigation

All navigation is imperative (`Navigator.push` / `Navigator.pop`). No named routes.

```
SplashScreen
    └── IntroScreen
            ├── FamilyMainScreen(tabFamily)
            │       ├── TreeViewScreen(graphFamily, isRelationPath: false)
            │       │       └── ProfileScreen(person)
            │       ├── FindRelationScreen(familyList, tabFamily)
            │       │       └── TreeViewScreen(graphFamily, isRelationPath: true)
            │       │               └── ProfileScreen(person)
            │       ├── ProfileScreen(person)
            │       └── _FamilyBioScreen(familyName)
            ├── OptionsScreen   (Hero animation from settings icon)
            ├── LoginAdminScreen
            │       └── AdminScreen(tabFamily)
            └── showSearch(_PersonSearchDelegate)
                    ├── TreeViewScreen(graphFamily)
                    └── ProfileScreen(person)
```

---

## 8. Feature Reference

### 8.1 Intro / Splash Screen
**File:** `lib/main.dart`

`SplashScreen` shows the app logo with a fade animation for ~1800ms while fetching `getFamilyTableNames()` in parallel. On completion, navigates to `IntroScreen`.

`IntroScreen` provides:
- Language toggle (Arabic / English) — calls `SettingsProvider.setLocale()`
- Theme toggle (light / dark)
- Settings icon with Hero animation → `OptionsScreen`
- `DropdownSearchWidget` for selecting a registered family
- "Enter Family's Page" → `FamilyMainScreen`
- "Search" button → opens `_PersonSearchDelegate` (see §8.6)
- "Admin" button → `LoginAdminScreen`

### 8.2 Family Main Screen
**File:** `lib/src/ui/mainMenu/family_main_screen.dart`

Central hub after a family is selected. Loads the family member list from `DbServices.getFamily()` (respecting the `maleOnly` setting).

**Layout:**
- `DropdownAvatarFamily` for selecting a specific member
- Animated chip shows selected person's name
- 2×2 grid of `_ActionCard` widgets:
  1. **Family Tree** → `TreeViewScreen(graphFamily: ..., isRelationPath: false)`
  2. **Find Relationship** → `FindRelationScreen`
  3. **Enter Profile** → `ProfileScreen(person: selectedPerson)`
  4. **Family History** → `_FamilyBioScreen` (fetches `families.biography`)
- **Contact Admin** `TextButton.icon` (centered below grid) — launches `https://wa.me/<phone>`; shows alert if no phone is registered

`_FamilyBioScreen` renders the biography as **Quill Delta** using a read-only `QuillEditor` (flutter_quill). The `biography` column in Supabase stores a Quill Delta JSON string. Images embedded in the content are public Supabase Storage URLs rendered by `FamilyHistoryImageEmbedBuilder`. Legacy plain-text content is handled gracefully by wrapping it in a `Document` on load.

> **Bug guard:** `grabFamily` uses `if (mounted) setState(...)` to prevent `setState after dispose`.

### 8.3 Family Tree Visualization
**File:** `lib/src/ui/mainMenu/family_tree_screen.dart`

`TreeViewScreen` accepts:
- `graphFamily` — `List<Family>` to display
- `focusedPerson` — optional `Family`; when set, `_centerOnRoot` zooms to that node at scale 1.5 (matched by `id`) instead of fitting the whole tree
- `isRelationPath` — `bool` (default `false`); when `true`, wraps the view in a `DefaultTabController` with three tabs

**Normal mode (isRelationPath: false):**
- `InteractiveViewer` wrapping a `GraphView` with `BuchheimWalkerAlgorithm` (top→bottom)
- On first layout, `_centerOnRoot()` computes bounding box of all nodes and applies a `Matrix4` scale+translate to fit the entire tree in the viewport
- Export button: captures `RepaintBoundary` as PNG → wraps in PDF page → `Printing.sharePdf()`

**Relation path mode (isRelationPath: true):**

| Tab | Widget | Description |
|-----|--------|-------------|
| Tree | `_buildTreeTab()` | Same GraphView, only shows nodes on the relation path |
| Path | `_buildPathTab()` | Vertical card chain with arrows; LCA gets a "Common Ancestor" chip |
| List | `_buildListTab()` | Compact `ListView.separated`; separators show relationship direction |

**Key helpers:**
- `_findLcaIndex(List<Family>)` — scans consecutive pairs for the transition from ascending (child→parent) to descending (parent→child) to locate the LCA
- `_relationLabel(context, a, b)` — returns localized "is parent of" or "is child of" by comparing `b.parent == a.id`

**Zoom-to-fit logic:**
```dart
// Iterates graph.nodes to find min/max coordinates,
// then builds Matrix4 to center + scale to fit the viewport.
// Guard: skips if any node has width == 0 (layout not yet complete).
```

**Alternative tree:** `family_paint_screen.dart` contains `FamilyPaintScreen` + `TreePainter` (CustomPainter) — a decorative trunk-and-branches rendering not used in main navigation.

### 8.4 Relationship Finder
**File:** `lib/src/ui/mainMenu/find_relation_screen.dart`

LCA algorithm in `findRelationship()`:
1. Build ancestor chain from person A to root: `[A, A.parent, A.parent.parent, …]`
2. Build ancestor chain from person B to root
3. Find first element common to both chains (lowest common ancestor)
4. Construct path: `A-chain up to LCA` + `B-chain up to LCA reversed`
5. Pass result to `TreeViewScreen(isRelationPath: true)`

Edge case: if one person is a direct ancestor of the other, the path is just the straight ancestor chain (no fork).

### 8.5 Profile Screen
**File:** `lib/src/ui/mainMenu/profile_screen.dart`

Displays a person's:
- Large `CircleAvatar` (Hero animation tagged `avatar-${person.id}`)
- Name + birth/death years pill (right-aligned, forced LTR)
- Horizontally scrollable lineage row (RTL): grandparent → parent → children
  Each node is a tappable `PhotoBasedAvatar` that pushes another `ProfileScreen`
- Bio card (hidden if empty)
- **Share button** (`Icons.share_outlined`) in AppBar → `Share.share(_buildShareText())`

`_buildShareText()` produces a plain-text summary: name, years, grandparent label, parent label, children list, bio.

`_withFullName()` traverses the parent chain up to `nameLength` parts and appends `familyName`.

### 8.6 Global Search
**File:** `lib/main.dart` — `_PersonSearchDelegate`

Triggered by the "Search" button on `IntroScreen`. Uses Flutter's `SearchDelegate<Family?>`.

- Minimum query length: 2 characters (shows empty state otherwise)
- `FutureBuilder` over `DbServices.searchAllFamilies(query)`
- Results display: `CircleAvatar` + tritary name + family name subtitle
- On result tap → bottom sheet with two actions:
  - **View in family tree** — loads the full family via `getFamily()`, navigates to `TreeViewScreen`
  - **Enter profile** — navigates directly to `ProfileScreen`

Search is Arabic-normalized (see §11).

### 8.7 Admin Panel
**Files:** `lib/src/ui/mainMenu/login_admin_screen.dart`, `lib/src/ui/mainMenu/admin_screen.dart`

`LoginAdminScreen` validates credentials against `admin_users` table. On success, stores `_adminLoggedIn = true` and `_adminFamilyName` in `DbServices`. Auto-redirects to `AdminScreen` if already logged in.

`AdminScreen` provides:
- **Add Person** form
- **Edit Person** form (with `DropdownAvatarFamily` to select who to edit)
- **Quick Add** mode — minimal form (name, gender, year born, parent) for rapid data entry

Both forms validate required fields and upload a portrait if selected. Image upload via `DbServices.uploadImage()` → Supabase Storage → public URL stored in `imgUrl` field.

Form validation:
- Name: required
- Gender: required
- Year Born: required, must be a valid integer
- Year Died: optional, but if provided must be > year born
- Parent: required

**Edit Family History** button opens `FamilyHistoryEditor`:
- `QuillSimpleToolbar` — bold, italic, underline, strike, headings (H1–H3), lists, alignment, RTL direction toggle
- Custom "Insert Image" toolbar button — picks from gallery via `file_picker`, uploads to Supabase Storage `portraits` bucket, embeds the public URL
- Save button serialises the document to Quill Delta JSON and calls `DbServices.updateFamilyBio()`
- File: `lib/src/ui/mainMenu/family_history_editor.dart`

`FamilyHistoryImageEmbedBuilder` (in `family_history_editor.dart`) is a public `EmbedBuilder` used in both the editor and the read-only display to render `BlockEmbed.image` nodes as `Image.network`.

### 8.8 Options Screen
**File:** `lib/src/ui/mainMenu/options_screen.dart`

| Setting | Widget | Values | Provider method |
|---------|--------|--------|-----------------|
| Name length | RadioGroup | 3 / 4 / 5 parts | `setNameLength()` |
| Text scale | RadioGroup | 1.0x / 1.2x / 1.4x | `setTextScale()` |
| Male-only filter | CheckboxListTile | true / false | `setMaleOnly()` |
| Theme mode | (in IntroScreen toggle) | light / dark | `flipThemeMode()` |

---

## 9. Reusable Base Widgets

### `DropdownAvatarFamily`
`lib/src/ui/base/dropdown_avatar_family.dart`

```dart
DropdownAvatarFamily(
  familyList: List<Family>,
  maleOnly: bool?,           // filters to males only
  initalFamily: int?,        // pre-selected person id
  onChangedFn: ValueChanged<(CircleAvatar, Family)?>,
)
```

Returns a tuple `(CircleAvatar, Family)`. The Family's `name` field is replaced with the full constructed name (person + parents up to `nameLength` + familyName).

Custom `filterFn` normalizes Arabic before matching, so searching `اسامه` finds `أسامة`.

### `DropdownSearchWidget<T>`
`lib/src/ui/base/dropdown_search_widget.dart`

Generic dropdown wrapper around the `dropdown_search` package. Accepts builder callbacks for item rendering.

### `ImageFormField`
`lib/src/ui/base/image_form_field.dart`

Two-button widget (gallery + camera) that returns a `File` via `onChanged`. Uses `file_picker` for gallery and `image_picker` for camera.

### `ImagePopup`
`lib/src/ui/base/image_popup.dart`

Dialog showing an `InteractiveViewer`-wrapped image (Network or Asset). Pinch zoom 1×–4×. Fixed 400×400 container.

### `PhotoBasedAvatar`
`lib/src/ui/base/photo_based_avatar.dart`

100×100 rectangular container showing the person's image (Network or Asset fallback to `assets/profile.png`) with a name label below.

---

## 10. Offline Caching

All Supabase reads in `DbServices` follow a **network-first, cache-fallback** pattern:

```
try {
  fetch from Supabase
  write to SharedPreferences cache
  return live data
} catch (_) {
  read SharedPreferences cache
  if cache exists → return cached data
  else → rethrow
}
```

**Cache key scheme:**

| Data | Key |
|------|-----|
| Family table names | `cache_family_names` |
| All members of a family | `cache_family_<name>_all` |
| Male-only members of a family | `cache_family_<name>_male` |

Serialization: `jsonEncode` / `jsonDecode`. Integers deserialized with `(num?)?.toInt()` to handle JSON's `num` type.

Static helpers: `_familyToJson()`, `_familyFromJson()`, `_readCache()`, `_writeCache()`.

---

## 11. Arabic Text Normalization

`DbServices.normalizeArabic(String text)` is a static utility that normalizes Arabic text before string comparison:

| Input character(s) | Normalized to |
|--------------------|--------------|
| `أ` `إ` `آ` (alef variants) | `ا` |
| `ة` (taa marbuta) | `ه` |

Applied in:
- `DbServices.searchAllFamilies()` — both query and tritary name are normalized before `.contains()`
- `DropdownAvatarFamily` `filterFn` — both item name and filter string are normalized

This means typing `اسامه` finds `أسامة`, and `ابراهيم` finds `إبراهيم`.

---

## 12. Data Model

### `Family`
```dart
class Family {
  int?    id;
  String? name;       // first name only (stored in DB)
  int?    parent;     // id of parent Family record, or null for root
  int?    yearBorn;
  int?    yearDied;
  String? imgUrl;     // Supabase public URL or 'assets/...' path
  String? bio;
  int?    gender;     // 1 = male, 0 = female
  String? familyName; // name of the Supabase table this person belongs to
}
```

`Family.copy({...})` creates a shallow copy with optional field overrides. Used extensively for building display names without mutating stored records.

**Full name construction** (in `_withFullName`, `buildDropdown`, `searchAllFamilies`):
1. Start with `person.name`
2. Traverse parent chain up to `nameLength - 2` additional parts
3. Append `familyName` (the family surname)

Example with `nameLength = 3`: `"أحمد محمد علي العبدالجليل"`

### `SavedSettings`
```dart
class SavedSettings {
  bool   maleOnly;
  int    nameLength;  // 3, 4, or 5
  String locale;      // 'ar' or 'en'
  String tabFamily;   // current family table name
  String themeMode;   // '' | 'light' | 'dark'
  double textScale;   // 1.0 | 1.2 | 1.4
}
```

---

## 13. Theming

The app uses a single `Colors.amber` seed for both light and dark color schemes (Material 3).

Custom fonts defined in `pubspec.yaml`:
- `ArefRuqaa` — body text (Regular + Bold)
- `Monadi` — used for AppBar titles

Text scaling is applied app-wide via `MediaQuery` override in `FamilyTreeApp`:
```dart
child: MediaQuery(
  data: mediaQuery.copyWith(
    textScaler: TextScaler.linear(settings.savedSettings.textScale),
  ),
  ...
)
```

---

## 14. Adding a Localization Key

Full step-by-step process:

1. **`lib/l10n/app_en.arb`** — add:
   ```json
   "myNewKey": "English text",
   "@myNewKey": { "description": "What this string is for" }
   ```

2. **`lib/l10n/app_ar.arb`** — add:
   ```json
   "myNewKey": "النص العربي",
   "@myNewKey": { "description": "What this string is for" }
   ```

3. **`lib/l10n/app_localizations.dart`** — add abstract getter:
   ```dart
   /// Description of the string.
   String get myNewKey;
   ```

4. **`lib/l10n/app_localizations_en.dart`** — implement:
   ```dart
   @override
   String get myNewKey => 'English text';
   ```

5. **`lib/l10n/app_localizations_ar.dart`** — implement:
   ```dart
   @override
   String get myNewKey => 'النص العربي';
   ```

6. Use in widgets: `AppLocalizations.of(context)!.myNewKey`

---

## 15. Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_localizations` | sdk | ARB-based i18n infrastructure |
| `intl` | any | Intl/Locale support |
| `supabase_flutter` | ^2.8.4 | Backend: PostgreSQL + Auth + Storage |
| `graphview` | ^1.2.0 | Tree graph visualization |
| `dropdown_search` | ^6.0.1 | Searchable/filterable dropdowns |
| `shared_preferences` | ^2.3.5 | Persistent local key-value store |
| `provider` | ^6.1.2 | InheritedWidget-based state management |
| `file_picker` | ^10.3.10 | Gallery file selection |
| `image_picker` | ^1.1.2 | Camera image capture |
| `flutter_svg` | ^2.0.17 | SVG asset rendering |
| `url_launcher` | ^6.3.1 | Launch WhatsApp / external URLs |
| `pdf` | ^3.10.8 | PDF generation from widget captures |
| `printing` | ^5.13.2 | Print / share PDF files |
| `share_plus` | ^10.1.4 | Native share sheet for text/files |
| `google_fonts` | ^6.2.1 | Remote font loading |
| `flutter_quill` | ^11.5.0 | Rich text editor and reader for family biography |
| `cupertino_icons` | ^1.0.2 | iOS-style icon set |

**Dev dependencies:**
- `flutter_lints` ^6.0.0
- `flutter_launcher_icons` ^0.14.3 (configured in `pubspec.yaml`)

> **Windows build note:** `share_plus` v10 uses Kotlin incremental compilation which can fail if the pub cache and the project are on different drive letters (e.g. `C:\` vs `D:\`). Run `flutter clean && flutter pub get && flutter run` to recover.

---

## 16. Known Issues & TODOs

| # | Issue | Location | Notes |
|---|-------|----------|-------|
| 1 | Family list on IntroScreen is read from `families` table (fixed) but could be stale on first offline launch | `main.dart` SplashScreen | Cache fallback exists |
| 2 | `profile_screen.dart` forces `TextDirection.ltr` on the name pill | `profile_screen.dart:83` | Intentional layout choice but may look odd in full-RTL context |
| 3 | `buildFamilyListView()` in ProfileScreen is called before `getFamily()` resolves | `profile_screen.dart:36` | Uses `storedFamily` in-memory; stale if navigated to before any family is loaded |
| 4 | `family_paint_screen.dart` is not wired to any navigation | — | Alternative tree renderer, not exposed to users |
| 5 | `radio_list_form_field.dart` is unused | — | Can be removed |
| 6 | Admin password stored as plain text in `admin_users` table | `db_services.dart:267` | Should use hashed credentials |
| 7 | `share_plus` v10 Kotlin incremental compile error on Windows with cross-drive paths | `pubspec.yaml` | Run `flutter clean` to fix |

---

## 17. Changelog

### [Current]
- **Family biography rich text editor:** `biography` column in Supabase stores Quill Delta JSON. Admin screen has an "Edit Family History" button that opens `FamilyHistoryEditor` — a WYSIWYG `QuillEditor` with toolbar (bold, italic, headings, lists, alignment, RTL direction). Images are picked from gallery, uploaded to Supabase Storage `portraits` bucket, and embedded by public URL. `_FamilyBioScreen` displays using a read-only `QuillEditor` with the same image embed builder. Legacy plain-text content in the database is handled gracefully.
- **Arabic normalization in search & dropdown:** `DbServices.normalizeArabic()` added; alef variants (`أ/إ/آ→ا`) and taa-marbuta (`ة→ه`) are normalized before comparison. Applied in `searchAllFamilies` and `DropdownAvatarFamily.filterFn`.
- **Global search matches full tritary name:** `searchAllFamilies` now builds the tritary name first, then filters — so multi-word queries (e.g. "أحمد محمد") work correctly.
- **Share profile:** `share_plus` added; `ProfileScreen` AppBar has a share icon that calls `_buildShareText()`.
- **Offline caching:** Network-first + SharedPreferences fallback for `getFamily`, `getFamilyTableNames`, and `searchAllFamilies`.
- **Global person search:** `_PersonSearchDelegate` in `main.dart`; full-width button on `IntroScreen`; tritary name display.
- **Extra Settings localization:** Options screen section header uses `extraSettings` key instead of `optDarkModeLabel`.
- **Family biography:** "Family History" card in `FamilyMainScreen` grid; `DbServices.getFamilyBio()` fetches from `families.biography`.
- **Contact Admin moved:** Centered `TextButton.icon` below the 2×2 grid.
- **Zoom-to-fit on tree open:** `_centerOnRoot()` computes bounding box and applies `Matrix4` to fit entire tree in viewport.
- **Relation path tabs:** `TreeViewScreen` with `isRelationPath: true` shows Tree / Path / List tabs. Path and List tabs display LCA, directional labels ("is parent of" / "is child of"), and endpoint highlighting.
- **Correct relation path direction:** B-side of path is reversed so the path reads A → LCA → B.
- **setState after dispose fix:** `grabFamily` in `FamilyMainScreen` guarded with `if (mounted)`.
