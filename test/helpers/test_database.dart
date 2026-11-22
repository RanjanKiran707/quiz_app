import 'package:drift/native.dart';
import 'package:quiz_app/data/database/app_database.dart';

AppDatabase openTestDatabase() => AppDatabase(NativeDatabase.memory());
