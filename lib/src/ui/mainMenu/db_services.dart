import 'dart:io';
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

  Future<List<Family>> getFamily(String tabFamily, {bool maleOnly = false}) async {
    var query = _client.from(tabFamily).select();

    final List<Map<String, dynamic>> data = maleOnly
        ? await _client.from(tabFamily).select().eq(colGender, 1)
        : await query;

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

    return _storedFamily!;
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

  /// Reads family names from the `families` metadata table.
  /// Schema: CREATE TABLE families (name TEXT PRIMARY KEY);
  Future<List<String>> getFamilyTableNames() async {
    final data = await _client.from('families').select('name');
    return (data as List<dynamic>).map((row) => row['name'] as String).toList();
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

  /// Uploads [file] to the `portraits` Supabase Storage bucket
  /// and returns its public URL.
  Future<String?> uploadImage(File file) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last.split('\\').last}';
    final path = 'portraits/$fileName';
    await _client.storage.from('portraits').upload(path, file);
    return _client.storage.from('portraits').getPublicUrl(path);
  }
}