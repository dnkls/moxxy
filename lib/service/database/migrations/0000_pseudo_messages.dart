import 'package:moxxyv2/service/database/constants.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV23ToV24(Database db) async {
  await db.execute(
    'ALTER TABLE $messagesTable ADD COLUMN pseudoMessageType INTEGER;',
  );
  await db.execute(
    'ALTER TABLE $messagesTable ADD COLUMN pseudoMessageData TEXT;',
  );
}
