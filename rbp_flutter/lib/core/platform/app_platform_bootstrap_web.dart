import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> initializePlatformServices() async {
  // The shared-worker mode is more capable, but it has been unreliable in
  // local browser testing for this project. The no-worker factory keeps web
  // startup stable while we continue the multiplatform migration.
  databaseFactory = databaseFactoryFfiWebNoWebWorker;
}
