import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final String colName = 'name';
final String colParent = 'parent';
final String colBorn = 'year_born';
final String colDied = 'year_died';
final String colId = 'id';
final String colImgUrl = 'imgUrl';
final String colBio = 'bio';
final String colGender = 'gender';

class Family {
  int? id;
  String? name;
  int? parent;
  int? yearBorn;
  int? yearDied;
  String? imgUrl;
  String? bio;
  int? gender;
  String? familyName;

  Map<String, Object?> toMap() {
    var map = <String, Object?>{
      colName: name,
      colParent: parent,
      colBorn: yearBorn,
      colDied: yearDied,
      colImgUrl: imgUrl,
      colBio: bio,
      colGender: gender,
    };
    if (id != null) {
      map[colId] = id;
    }
    return map;
  }

  Family({this.id, this.name, this.parent, this.yearBorn, this.yearDied, this.imgUrl, this.bio, this.gender, this.familyName});

  Family.fromMap(Map<String, dynamic> map) {
    id = map[colId];
    name = map[colName];
    parent = map[colParent];
    yearBorn = map[colBorn];
    yearDied = map[colDied];
    imgUrl = map[colImgUrl];
    bio = map[colBio];
    gender = map[colGender];
  }

  Family copy({int? id, String? name, int? parent, int? yearBorn, int? yearDied,
      String? imgUrl, String? bio, int? gender, String? familyName}) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      parent: parent ?? this.parent,
      yearBorn: yearBorn ?? this.yearBorn,
      yearDied: yearDied ?? this.yearDied,
      imgUrl: imgUrl ?? this.imgUrl,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      familyName: familyName ?? this.familyName,
    );
  }

  @override
  String toString() => 'Family<$name, $gender>';
}

class DbServices {
  static List<Family>? _storedFamily;
  static bool _adminLoggedIn = false;
  static String? _adminFamilyName;

  DbServices._privateConstructor();
  static final DbServices _instance = DbServices._privateConstructor();
  static DbServices get instance => _instance;

  bool get adminLoggedIn => _adminLoggedIn;
  String? get adminFamilyName => _adminFamilyName;
  void logoutAdmin() {
    _adminLoggedIn = false;
    _adminFamilyName = null;
  }

  SupabaseClient get _client => Supabase.instance.client;
  List<Family>? get storedFamily => _storedFamily;

  // ─── Arabic text normalisation ──────────────────────────────────────────────

  /// Normalises Arabic text for fuzzy matching:
  /// • أ / إ / آ  →  ا
  /// • ة          →  ه
  static String normalizeArabic(String text) => text
      .replaceAll(RegExp(r'[أإآ]'), 'ا')
      .replaceAll('ة', 'ه');

  // ─── Cache helpers ──────────────────────────────────────────────────────────

  static const String _kCacheFamilyNames = 'cache_family_names';

  // Cache key for a family member list (keyed by name + maleOnly flag)
  static String _cacheKeyFamily(String name, {bool maleOnly = false}) =>
      'cache_family_${name}_${maleOnly ? 'male' : 'all'}';

  // Serialize a Family to a plain map safe for JSON encoding
  static Map<String, dynamic> _familyToJson(Family f) => {
    colId: f.id,
    colName: f.name,
    colParent: f.parent,
    colBorn: f.yearBorn,
    colDied: f.yearDied,
    colImgUrl: f.imgUrl,
    colBio: f.bio,
    colGender: f.gender,
    'familyName': f.familyName,
  };

  // Deserialize a Family from a cached JSON map.
  // Uses (num?)?.toInt() because JSON integers round-trip as num in Dart.
  static Family _familyFromJson(Map<String, dynamic> map, String fallback) => Family(
    id: (map[colId] as num?)?.toInt(),
    name: map[colName] as String?,
    parent: (map[colParent] as num?)?.toInt(),
    yearBorn: (map[colBorn] as num?)?.toInt(),
    yearDied: (map[colDied] as num?)?.toInt(),
    imgUrl: map[colImgUrl] as String?,
    bio: map[colBio] as String?,
    gender: (map[colGender] as num?)?.toInt(),
    familyName: map['familyName'] as String? ?? fallback,
  );

  // Read a cached family list; returns null if nothing is cached yet
  static List<Family>? _readCache(SharedPreferences prefs, String key, String familyName) {
    final raw = prefs.getString(key);
    if (raw == null) return null;
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => _familyFromJson(e as Map<String, dynamic>, familyName))
        .toList();
  }

  // Write a family list to the cache
  static Future<void> _writeCache(SharedPreferences prefs, String key, List<Family> list) =>
      prefs.setString(key, jsonEncode(list.map(_familyToJson).toList()));

  // ─── Data methods ───────────────────────────────────────────────────────────

  /// Fetches family members, updating the local cache on success.
  /// Falls back to the cache when the network is unavailable.
  Future<List<Family>> getFamily(String tabFamily, {bool maleOnly = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _cacheKeyFamily(tabFamily, maleOnly: maleOnly);

    try {
      // Try the database first
      final List<Map<String, dynamic>> data = maleOnly
          ? await _client.from(tabFamily).select().eq(colGender, 1)
          : await _client.from(tabFamily).select();

      _storedFamily = data.map((row) => Family(
        id: row[colId],
        name: row[colName],
        parent: row[colParent],
        yearBorn: row[colBorn],
        yearDied: row[colDied],
        imgUrl: row[colImgUrl],
        bio: row[colBio],
        gender: row[colGender],
        familyName: tabFamily,
      )).toList();

      await _writeCache(prefs, cacheKey, _storedFamily!);
      return _storedFamily!;
    } catch (_) {
      // Network unavailable — serve from cache if present
      final cached = _readCache(prefs, cacheKey, tabFamily);
      if (cached != null) {
        _storedFamily = cached;
        return cached;
      }
      rethrow;
    }
  }

  Future<void> insert(String tabFamily, Family family) async {
    final map = family.toMap();
    map.remove(colId); // Supabase auto-assigns id via SERIAL
    await _client.from(tabFamily).insert(map);
  }

  Future<void> update(String tabFamily, Family family) async {
    final map = family.toMap();
    map.remove(colId);
    await _client.from(tabFamily).update(map).eq(colId, family.id!);
  }

  /// Searches for members whose first name contains [query] across every family table.
  /// Fetches each family in full so the parent chain can be traversed to build a
  /// tritary display name (person + father + grandfather). Uses the same per-family
  /// cache as getFamily so results are available offline too.
  Future<List<Family>> searchAllFamilies(String query) async {
    final familyNames = await getFamilyTableNames();
    final prefs = await SharedPreferences.getInstance();
    final results = <Family>[];
    final lowerQuery = normalizeArabic(query.toLowerCase());

    for (final familyName in familyNames) {
      final cacheKey = _cacheKeyFamily(familyName); // uses the _all variant
      List<Family> allMembers;

      try {
        // Try the database first and refresh the cache on success
        final data = await _client.from(familyName).select();
        allMembers = (data as List<dynamic>).map((row) => Family(
          id: row[colId],
          name: row[colName],
          parent: row[colParent],
          yearBorn: row[colBorn],
          yearDied: row[colDied],
          imgUrl: row[colImgUrl],
          bio: row[colBio],
          gender: row[colGender],
          familyName: familyName,
        )).toList();
        await _writeCache(prefs, cacheKey, allMembers);
      } catch (_) {
        // Fall back to cache; skip this family entirely if nothing is cached yet
        final cached = _readCache(prefs, cacheKey, familyName);
        if (cached == null) continue;
        allMembers = cached;
      }

      // Build tritary name for every member, then filter against the full name
      for (final person in allMembers) {
        String tritaryName = person.name ?? '';
        final father = allMembers.where((m) => m.id == person.parent).firstOrNull;
        if (father?.name != null) {
          tritaryName += ' ${father!.name}';
          final grandfather = allMembers.where((m) => m.id == father.parent).firstOrNull;
          if (grandfather?.name != null) {
            tritaryName += ' ${grandfather!.name}';
          }
        }
        if (normalizeArabic(tritaryName.toLowerCase()).contains(lowerQuery)) {
          results.add(person.copy(name: tritaryName));
        }
      }
    }
    return results;
  }

  /// Reads family names from the `families` metadata table, caching the result.
  /// Falls back to the cache when the network is unavailable.
  /// Schema: CREATE TABLE families (name TEXT PRIMARY KEY);
  Future<List<String>> getFamilyTableNames() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final data = await _client.from('families').select('name');
      final names = (data as List<dynamic>).map((row) => row['name'] as String).toList();
      await prefs.setStringList(_kCacheFamilyNames, names);
      return names;
    } catch (_) {
      final cached = prefs.getStringList(_kCacheFamilyNames);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<bool> validateAdminCredentials(String username, String password) async {
    final result = await _client
        .from('admin_users')
        .select()
        .eq('username', username)
        .eq('password', password)
        .maybeSingle();
    _adminLoggedIn = result != null;
    _adminFamilyName = result?['family_name'] as String?;
    return _adminLoggedIn;
  }

  /// Overwrites the biography for [familyName] in the families metadata table.
  /// [deltaJson] is a Quill Delta serialised with jsonEncode(delta.toJson()).
  /// Overwrites the biography for [familyName] in the families metadata table.
  /// [deltaJson] is a Quill Delta serialised with jsonEncode(delta.toJson()).
  /// The value is decoded to a Dart object before writing so Supabase stores
  /// it correctly in the JSONB column.
  Future<void> updateFamilyBio(String familyName, String deltaJson) async {
    await _client
        .from('families')
        .update({'biography': jsonDecode(deltaJson)})
        .eq('name', familyName);
  }

  /// Returns the biography for [familyName] as a Quill Delta JSON string,
  /// or null if none exists.
  /// The JSONB column is returned by Supabase as a parsed Dart object and is
  /// re-encoded to a string here so callers always receive a consistent type.
  Future<String?> getFamilyBio(String familyName) async {
    final result = await _client
        .from('families')
        .select('biography')
        .eq('name', familyName)
        .maybeSingle();
    final bio = result?['biography'];
    if (bio == null) return null;
    // JSONB arrives as a parsed List; re-encode to string for Quill.
    return bio is String ? bio : jsonEncode(bio);
  }

  /// Returns the WhatsApp phone number for the admin of [familyName], or null.
  /// Schema: admin_users must have columns family_name TEXT and phone_number TEXT.
  Future<String?> getAdminPhone(String familyName) async {
    final result = await _client
        .from('admin_users')
        .select('phone_number')
        .eq('family_name', familyName)
        .maybeSingle();
    return result?['phone_number'] as String?;
  }

  /// Uploads [file] to a Supabase Storage [bucket] and returns its public URL.
  /// Defaults to the `portraits` bucket (used for member profile photos).
  Future<String?> uploadImage(File file, {String bucket = 'portraits'}) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last.split('\\').last}';
    final path = '$bucket/$fileName';
    await _client.storage.from(bucket).upload(path, file);
    return _client.storage.from(bucket).getPublicUrl(path);
  }
}