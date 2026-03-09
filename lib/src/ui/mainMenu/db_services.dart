import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:typed_data';
import 'package:flutter/services.dart';

// final String tabFamily = 'العبدالجليل';
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
    var map = <String, Object?> {
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
    // familyName = tabFamily;
  }
  Family copy({int? id, String? name, int? parent, int? yearBorn, int? yearDied,
  String? imgUrl,
  String? bio,
  int? gender,
  String? familyName}) {
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
  String toString() {
    // TODO: implement toString
    return 'Family<$name, $gender>';
  }
}

class DbServices {
  static Database? _database;
  static List<Family>? _storedFamily;

  DbServices._privateConstructor();
  static final DbServices _instance = DbServices._privateConstructor();

  static DbServices get instance {
    return _instance;
  } 

  Future<Database> get database async =>
    _database ??= await _initDB();

  List<Family>? get storedFamily => _storedFamily;

  Future<Database> _initDB() async {
    // Directory directory = await getApplicationDocumentsDirectory();
    
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, 'assets/ancestry_app.db');
    var exists = await databaseExists(path);

    // TODO restore entire if-else block
    // if (!exists) {
      // Should happen only the first time you launch your application
      print("Creating new copy from asset");

      // Make sure the parent directory exists
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Copy from asset
      ByteData data = await rootBundle.load(url.join("assets", "ancestry_app.db"));
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      // Write and flush the bytes written
      await File(path).writeAsBytes(bytes, flush: true);
    // } else {
    //   print("Opening existing database");
    // }

// open the database
    return openDatabase(path);




    // return openDatabase(
    //   join(directory.path, 'assets/ancestry_app.db')
    // );
  }

  // Future<List<Family>> get storedFamily async => 
  //   _storedFamily ??= await getFamily();

  // Future<void> ps() async {
  //   final Database db = await instance.database;
  //   print(db);
  //   (await db.query('sqlite_master', columns: ['type', 'name'])).forEach((row) {
  //     print(row.values);
  //   });
  // }

  Future<List<Family>> getFamily(String tabFamily, {bool maleOnly = false}) async {
    final Database db = await instance.database;
    final List<Map<String, dynamic>> maps;
    if (maleOnly) {
      maps = await db.query(tabFamily, where: 'gender == 1');
    }
    else {
      maps = await db.query(tabFamily);
    }

    _storedFamily = List.generate(maps.length, (i) {
      return Family(
        id: maps[i][colId],
        name: maps[i][colName],
        parent: maps[i][colParent],
        yearBorn: maps[i][colBorn],
        yearDied: maps[i][colDied],
        imgUrl: maps[i][colImgUrl],
        bio: maps[i][colBio],
        gender: maps[i][colGender],
        familyName: tabFamily
      );
    });

    return _storedFamily!;
  }

  Future<int> insert(String tabFamily, Family family) async {
    final Database db = await instance.database;

    int id = await db.insert(tabFamily, family.toMap());
    return id;
  }

  Future<int> update(String tabFamily, Family family) async {
    final Database db = await instance.database;

    int changes = await db.update(tabFamily, family.toMap(), where: '$colId = ?', whereArgs: [family.id]); 

    if (changes > 1) {
      throw Error();
    }
    return changes;
  }

  Future<int> maxId(String tabFamily) async {
    final Database db = await instance.database;
    final List<Map<String, dynamic>> maps;

    maps = await db.rawQuery('SELECT MAX(id) from $tabFamily');
    log('$maps');

    return maps[0]['MAX(id)'];
  }
  // Future<int> insertFamily(Family family) async {
  //   final Database db = await instance.database;
  //   return await db.insert(tabFamily, family.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  // }

  // Future<int> updateFamily(Family family) async {
  //   final Database db = await instance.database;
  //   return await db.update(tabFamily, family.toMap(), 
  //     where: '$colId = ?', whereArgs: [family.id]);
  // }

}