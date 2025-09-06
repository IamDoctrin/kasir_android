import 'package:floor/floor.dart';
import 'database.dart';

class DatabaseInstance {
  static AppDatabase? _database;

  static Future<AppDatabase> get database async {
    if (_database != null) return _database!;

    _database =
        await $FloorAppDatabase
            .databaseBuilder('gulai_kambiang_kakek.db')
            .addMigrations([MIGRATION_1_2, MIGRATION_2_3, MIGRATION_3_4])
            .addCallback(
              Callback(
                onCreate: (database, version) async {
                  await seedDatabase(database);
                },
              ),
            )
            .build();
    return _database!;
  }
}
