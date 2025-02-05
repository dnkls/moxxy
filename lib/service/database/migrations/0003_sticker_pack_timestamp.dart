import 'package:moxxyv2/service/database/constants.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV41ToV42(Database db) async {
  /// Add the new column
  await db.execute(
    '''
    ALTER TABLE $stickerPacksTable ADD COLUMN addedTimestamp INTEGER NOT NULL DEFAULT 0;
    ''',
  );

  /// Ensure that the sticker packs are sorted (albeit randomly)
  final stickerPackIds = await db.query(
    stickerPacksTable,
    columns: ['id'],
  );

  var counter = 0;
  for (final id in stickerPackIds) {
    await db.update(
      stickerPacksTable,
      {
        'addedTimestamp': counter,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    counter++;
  }
}
