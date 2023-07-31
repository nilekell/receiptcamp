import 'package:receiptcamp/data/data_constants.dart';
import 'package:receiptcamp/data/utils/file_helper.dart';
import 'package:receiptcamp/data/utils/utilities.dart';
import 'package:receiptcamp/models/folder.dart';
import 'package:receiptcamp/models/receipt.dart';
import 'package:receiptcamp/models/tag.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  // defining a static instance of the DBHelper class, allowing us to
  // access the same db instance from anywhere in the program
  static final DatabaseService instance = DatabaseService._getInstance();
  // Define a private static variable to hold our database instance.
  static Database? _database;
  // Define a private constructor to prevent the class from being instantiated
  // from outside of the class.
  DatabaseService._getInstance();

  // Define a getter that returns our database instance. If the database
  // instance doesn't exist yet, we create it.
  Future<Database> get database async {
    if (_database != null) {
      // print('acessing database...');
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  // Define a private method to initialize our database.
  Future<Database> _initDatabase() async {
    // Get the path to the directory where we can store our database.
    final dbPath = await getDatabasesPath();
    // Create the path in the available directory to store our database.
    final path = '$dbPath/receipts.db';

    return await openDatabase(
      // creating database found at new path
      path,
      version: 1,
      // Create receipt table
      onCreate: (db, version) async {
        // Add Folder table creation
        await db.execute('''
          CREATE TABLE folders (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            lastModified INTEGER NOT NULL,
            parentId TEXT NOT NULL,
            FOREIGN KEY (parentId) REFERENCES folders(id)
          )
        ''');

        final currentTime = Utility.getCurrentTime();
        // creating an initial folder for all receipts to first be added to when they are created
        await db.execute('''
          INSERT INTO folders (id, name, lastModified, parentId)
          VALUES(?, ?, ?, 'null')
        ''', [rootFolderId, rootFolderName,currentTime]);

        // create receipts table
        await db.execute('''
          CREATE TABLE receipts (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            localPath TEXT NOT NULL,
            dateCreated INTEGER NOT NULL,
            lastModified INTEGER NOT NULL,
            storageSize INTEGER NOT NULL,
            parentId TEXT NOT NULL,
            FOREIGN KEY (parentId) REFERENCES folders(id)       
          )
        ''');

        // create tags table
        await db.execute('''
          CREATE TABLE tags (
              id TEXT PRIMARY KEY,
              receiptId TEXT NOT NULL,
              tag TEXT NOT NULL, 
              FOREIGN KEY (receiptId) REFERENCES receipts(id)
          )
      ''');
      },
    );
  }

  // Add Folder operations

  // Method to get folder contents (this includes receipts and folders)
  Future<List<Object>> getFolderContents(String folderId) async {
    final db = await database;

    // Fetch all folders in the folder
    final List<Map<String, dynamic>> folders = await db.rawQuery('''
      SELECT *
      FROM folders
      WHERE parentId = ?
    ''', [folderId]);

    final foldersList = List<Folder>.generate(folders.length, (i) {
      return Folder(
        id: folders[i]['id'],
        name: folders[i]['name'],
        lastModified: folders[i]['lastModified'],
        parentId: folders[i]['parentId'],
      );
    });

    // Fetch all receipts in the folder
    final List<Map<String, dynamic>> receipts = await db.rawQuery('''
      SELECT *
      FROM receipts
      WHERE parentId = ?
    ''', [folderId]);

    final receiptsList = List<Receipt>.generate(receipts.length, (i) {
      return Receipt(
          id: receipts[i]['id'],
          name: receipts[i]['name'],
          localPath: receipts[i]['localPath'],
          dateCreated: receipts[i]['dateCreated'],
          lastModified: receipts[i]['lastModified'],
          storageSize: receipts[i]['storageSize'],
          parentId: receipts[i]['parentId']);
    });

    return [...foldersList, ...receiptsList]; // combining two lists and return
  }

  // Method to rename folder
  Future<void> renameFolder(String folderId, String newName) async {
    final db = await database;
    final currentTime = Utility.getCurrentTime();
    // folders can have the same name
    if (await folderExists(id: folderId) == false) {
      return;
    } else {
      await db.rawUpdate('''
        UPDATE folders
        SET name = ?, lastModified = ?
        WHERE id = ?
        ''', [newName, currentTime, folderId]);
    }
  }

  // Method to move a receipt to a different folder
  Future<void> moveReceipt(Receipt receipt, String targetFolderId) async {
    final db = await database;

    if (await folderExists(id: targetFolderId) == false) {
      return;
    } else {
      final currentTime = Utility.getCurrentTime();
      await db.rawUpdate('''
      UPDATE receipts
      SET parentId = ?, lastModified = ?
      WHERE id = ?
    ''', [targetFolderId, currentTime, receipt.id]);
    }
  }

  // Method to insert a Folder object into the database.
  Future<void> insertFolder(Folder folder) async {
    final db = await database;
    if (folder.name == rootFolderName) {
      throw Exception('folder cannot have same name as default folder');
      // function ends after throw statement
    }
    await db.insert('folders', folder.toMap());
  }

  // Method to get all Folder objects from the database.
  Future<List<Folder>> getFolders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('folders');
    return List.generate(maps.length, (i) {
      return Folder(
        id: maps[i]['id'],
        name: maps[i]['name'],
        lastModified: maps[i]['lastModified'],
        parentId: maps[i]['parentId'],
      );
    });
  }

  // Method to get list of folders that a folder can logically be moved to
  // This will not include:
  // - the folder itself
  // - the parent of the folder
  // - any folders that are under the folder in the hierarchy
  Future<List<Folder>> getFoldersThatCanBeMovedTo(String fileToBeMovedId, String fileToBeMovedParentId) async {
    final db = await database;

    // initialising list of folders to explicitly not retrieve, starting with the folder itself and its parent
    List<String> exceptionFolderIds = [fileToBeMovedId, fileToBeMovedParentId];

    // getting folderIds of any folders that are 'under' the current folder in the file system hierarchy
    final subFolderIds = await getRecursiveSubFolderIds(fileToBeMovedId);
    // adding these folders so they are excluded in the returned list of eligible folders that can be moved to
    exceptionFolderIds.addAll(subFolderIds);

    // Create a string of placeholders for sqlite query
    String placeholders = exceptionFolderIds.map((_) => '?').join(',');
    print('placeholders: $placeholders');

    // querying for all folders except for those in [exceptionFolderIds]
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT *
      FROM folders
      WHERE id NOT IN ($placeholders)
    ''', exceptionFolderIds);

    // returning list of folders
    return List.generate(maps.length, (i) {
      return Folder(
        id: maps[i]['id'],
        name: maps[i]['name'],
        lastModified: maps[i]['lastModified'],
        parentId: maps[i]['parentId'],
      );
    });
  }

  // method to retrieve ids for folders and their subfolders for a specific folder
  Future<List<String>> getRecursiveSubFolderIds(String folderId) async {
    final db = await database;

    // initialising list of ids that will be returned
    List<String> subfolderIds = [];

    // method to get subfolders for a specific id
    Future<void> getSubFolderIds(String id) async {
      final List<Map<String, dynamic>> mapOfFolderIds = await db.rawQuery('''
        SELECT id
        FROM folders
        WHERE parentId = ?
        ''', [id]);

      // mapping each item in [mapOfFolderIds] to an element in [idList]
      List<String> idList =
          mapOfFolderIds.map((item) => item['id'].toString()).toList();

      subfolderIds.addAll(idList);

      // recursively get subfolders for each subfolder
      for (final id in idList) {
        await getSubFolderIds(id);
      }
    }

    await getSubFolderIds(folderId);

    return subfolderIds;
  }

  // Method to delete a Folder object from the database based on its id.
  Future<void> deleteFolder(String id) async {
    final db = await database;

    // Check if folder contains any subfolders
    final List<Map<String, dynamic>> subfolders = await db.rawQuery('''
      SELECT *
      FROM folders
      WHERE parentId = ?
    ''', [id]);

    // Check if folder contains any receipts
    final List<Map<String, dynamic>> receipts = await db.rawQuery('''
      SELECT *
      FROM receipts
      WHERE parentId = ?
    ''', [id]);

    // If the folder is not empty, recursively delete its contents
    if (subfolders.isNotEmpty || receipts.isNotEmpty) {
      for (var folder in subfolders) {
        await deleteFolder(folder['id']);
      }

      for (var receipt in receipts) {
        // deleting receipt image in local storage
        await FileService.deleteImageFromPath(receipt['localPath']);

        // deleting receipt record in db
        await db
            .rawDelete('DELETE FROM receipts WHERE id = ?', [receipt['id']]);
      }
    }

    // Delete the folder itself
    await db.rawDelete('DELETE FROM folders WHERE id = ?', [id]);
  }

  // method to check if folder already exists
  Future<bool> folderExists({String? id, String? name}) async {
    final db = await database;
    List<Object?> arguments = [];
    String query = 'SELECT COUNT (*) FROM folders WHERE ';

    if (id != null) {
      query += 'id=?';
      arguments.add(id);
    }

    if (name != null) {
      if (id != null) query += ' OR ';
      query += 'name=?';
      arguments.add(name);
    }

    final countResult = await db.rawQuery(query, arguments);

    int? numSameFolders = Sqflite.firstIntValue(countResult);

    if (numSameFolders != 0) {
      return true;
    } else {
      return false;
    }
  }

  // Method to get folder by its id
  Future<Folder> getFolderById(String folderId) async {
    final db = await database;
    final result = await db.rawQuery('''
    SELECT *
    FROM folders
    WHERE id = ?
  ''', [folderId]);

    if (result.isNotEmpty) {
      final folderResult = result.first;
      return Folder.fromMap(folderResult);
    } else {
      throw Exception('Folder with id $folderId not found');
    }
  }

  // Add Receipt operations

  // Method to insert a Receipt object into the database.
  Future<int> insertReceipt(Receipt receipt) async {
    final db = await database;
    return await db.insert('receipts', receipt.toMap());
  }

  // Method to update a Receipt object in the database.
  Future<int> updateReceipt(Receipt receipt) async {
    final db = await database;
    return await db.update(
      'receipts',
      receipt.toMap(),
      where: 'id = ?',
      whereArgs: [receipt.id],
    );
  }

  // Method to return receipt by id
  Future<Receipt> getReceiptById(String receiptId) async {
    final db = await database;
    final result = await db.rawQuery('''
    SELECT *
    FROM receipts
    WHERE id = ?
  ''', [receiptId]);

    if (result.isNotEmpty) {
      final receiptResult = result.first;
      return Receipt.fromMap(receiptResult);
    } else {
      throw Exception('Receipt with id $receiptId not found');
    }
  }

  // Method to delete a Receipt object from the database based on its id.
  Future<int> deleteReceipt(String id) async {
    final db = await database;

    // retrieving path of deleted receipt
    final String deletedReceiptPath = (await getReceiptById(id)).localPath;

    // deleting all tags associated to a receipt
    await deleteTagsForAReceipt(id);

    // deleting receipt image in local storage
    await FileService.deleteImageFromPath(deletedReceiptPath);

    // deleting receipt record in receipts table
    return await db.delete(
      'receipts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Method to move a folder to another folder
  Future<void> moveFolder(Folder folder, String targetFolderId) async {
    final db = await database;

    if (await folderExists(id: targetFolderId) == false) {
      return;
    } else {
      final currentTime = Utility.getCurrentTime();
      await db.rawUpdate('''
      UPDATE folders
      SET parentId = ?, lastModified = ?
      WHERE id = ?
    ''', [targetFolderId, currentTime, folder.id]);
    }
  }

  // Method to get all Receipt objects from the database.
  Future<List<Receipt>> getReceipts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('receipts');
    return List.generate(maps.length, (i) {
      return Receipt(
          id: maps[i]['id'],
          name: maps[i]['name'],
          localPath: maps[i]['localPath'],
          dateCreated: maps[i]['dateCreated'],
          lastModified: maps[i]['lastModified'],
          storageSize: maps[i]['storageSize'],
          parentId: maps[i]['parentId']);
    });
  }

  // Method to print all receipts objects from database
  Future<void> printAllReceipts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('receipts');
    print('num of receipts: ${maps.length}');
    print('All receipts in database:');
    maps.forEach((receiptMap) {
      final receipt = Receipt(
          id: receiptMap['id'],
          name: receiptMap['name'],
          localPath: receiptMap['localPath'],
          dateCreated: receiptMap['dateCreated'],
          lastModified: receiptMap['lastModified'],
          storageSize: receiptMap['storageSize'],
          parentId: receiptMap['parentId']);

      print('id: ${receipt.id.toString()}');
      print('name: ${receipt.name.toString()}');
      print('localPath: ${receipt.localPath.toString()}');
      print('dateCreated: ${receipt.dateCreated.toString()}');
      print('dateCreated: ${receipt.dateCreated.toString()}');
      print('lastModified: ${receipt.lastModified.toString()}');
      print('storageSize: ${receipt.storageSize.toString()}');
      print('//--------------//');
    });
  }

  // Method to get Receipt objects by name from the database
  Future<List<Receipt>> getReceiptByName(String name) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('receipts',
        // retrieving the following columns from the database
        columns: ['id', 'userID', 'name', 'localPath', 'dateCreated'],
        // '?'s are replaced with the items in the [whereArgs] field
        where: 'name = ?',
        // [name] is the argument of the function
        whereArgs: [name]);
    return List.generate(maps.length, (i) {
      return Receipt(
          id: maps[i]['id'],
          name: maps[i]['name'],
          localPath: maps[i]['localPath'],
          dateCreated: maps[i]['dateCreated'],
          lastModified: maps[i]['lastModified'],
          storageSize: maps[i]['storageSize'],
          parentId: maps[i]['parentId']);
    });
  }

  // Method to rename receipt
  Future<void> renameReceipt(String id, String newName) async {
    final db = await database;
    final currentTime = Utility.getCurrentTime();
    await db.rawUpdate('''
      UPDATE receipts
      SET name = ?, lastModified = ?
      WHERE id = ?
    ''', [newName, currentTime, id]);
  }

  // Method to get recently created receipts from database
  Future<List<Receipt>> getRecentReceipts() async {
    final db = await database;
    // Query the database for the 8 most recently created receipts
    final List<Map<String, dynamic>> maps = await db
        .rawQuery('SELECT * FROM receipts ORDER BY lastModified DESC LIMIT 8');
    // Convert the List<Map<String, dynamic>> to a List<Receipt>
    List<Receipt> receipts = List.generate(maps.length, (i) {
      return Receipt(
          id: maps[i]['id'],
          name: maps[i]['name'],
          localPath: maps[i]['localPath'],
          dateCreated: maps[i]['dateCreated'],
          lastModified: maps[i]['lastModified'],
          storageSize: maps[i]['storageSize'],
          parentId: maps[i]['parentId']);
    });

    return receipts;
  }

  Future<void> deleteAll() async {
    final db = await database;
    // delete() returns number (int) of rows deleted
    // deleting all rows in the receipts table NOT SPECIFIC TO USER
    print('total receipts deleted: ${await db.delete('receipts')}');
    // deleting ALL tags in database NOT SPECIFIC TO USER
    print('total tags deleted: ${await db.delete('tags')}');
    // deleting all folders in database (except root folder) NOT SPECIFIC TO USER
    print('total folders deleted: ${await db.delete('folders', where: 'id != ?', whereArgs: [rootFolderId])}');
  }

  // Add Tag operations

  // method to insert a list of receipt tags into tags table
  Future<void> insertTags(List<Tag> tags) async {
    final db = await database;

    // perform multiple operations in a single transaction
    Batch batch = db.batch();

    for (Tag tag in tags) {
      batch.insert('tags', tag.toMap());
    }

    await batch.commit(noResult: true);
  }

  // method to get all tags associated with a receipt based on its id
  Future<List<Tag>> getTagsByReceiptID(String receiptId) async {
    final db = await database;
    // retrieving a list of maps where each map represents a Tag object
    final List<Map<String, dynamic>> tagMaps = await db.rawQuery('''
                  SELECT *
                  FROM tags 
                  WHERE receiptId=?
                  ''', [receiptId]);
    // returning a list of Tag objects
    return List.generate(tagMaps.length, (i) {
      return Tag(
          id: tagMaps[i]['id'],
          receiptId: tagMaps[i]['receiptId'],
          tag: tagMaps[i]['tag']);
    });
  }

  // method to delete all receipt tags associated with a single receipt
  Future<int> deleteTagsForAReceipt(String receiptId) async {
    final db = await database;
    return await db.delete(
      'tags',
      where: 'receiptId = ?',
      whereArgs: [receiptId],
    );
  }

  // method to get first 8 receipts from specific tags, ordering by most recent
  Future<List<Receipt>> getSuggestedReceiptsByTags(String tag) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db
        // query will return receipts that have tags that match any part of the user's search query
        .rawQuery('''
        SELECT receipts.id, receipts.name, receipts.localPath, receipts.dateCreated, receipts.lastModified, receipts.storageSize, receipts.parentId
        FROM receipts
        INNER JOIN tags ON receipts.id = tags.receiptId
        WHERE tags.tag LIKE '%' || ? || '%'
        GROUP BY receipts.id
        ORDER BY dateCreated DESC
        LIMIT 8
        ''', [tag]);

    final receiptList = List.generate(maps.length, (i) {
      return Receipt(
          id: maps[i]['id'],
          name: maps[i]['name'],
          localPath: maps[i]['localPath'],
          dateCreated: maps[i]['dateCreated'],
          lastModified: maps[i]['lastModified'],
          storageSize: maps[i]['storageSize'],
          parentId: maps[i]['parentId']);
    });

    return receiptList;
  }

  // method to get all receipts from specific tags, ordering by most recent
  Future<List<Receipt>> getFinalReceiptsByTags(String tag) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db
        // the LIKE operator is used to match any tag that contains the specific string
        // the '%' is a wildcard that matches any sequence of characters before or after the specifed string
        // the '||' is a operator used to concatenate the '%' and '?' to form the full search pattern
        .rawQuery('''
        SELECT receipts.id, receipts.name, receipts.localPath, receipts.dateCreated, receipts.lastModified, receipts.storageSize, receipts.parentId
        FROM receipts
        INNER JOIN tags ON receipts.id = tags.receiptId
        WHERE tags.tag LIKE '%' || ? || '%'
        GROUP BY receipts.id
        ORDER BY dateCreated DESC
        ''', [tag]);

    final receiptList = List.generate(maps.length, (i) {
      return Receipt(
          id: maps[i]['id'],
          name: maps[i]['name'],
          localPath: maps[i]['localPath'],
          dateCreated: maps[i]['dateCreated'],
          lastModified: maps[i]['lastModified'],
          storageSize: maps[i]['storageSize'],
          parentId: maps[i]['parentId']);
    });

    print('num of receipts: ${receiptList.length}');
    return receiptList;
  }

  void printAllTags() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tags');

    final tags = List.generate(maps.length, (i) {
      return Tag(
        id: maps[i]['id'],
        receiptId: maps[i]['receiptId'],
        tag: maps[i]['tag'],
      );
    });

    for (var tag in tags) {
      print('${tag.id}, ${tag.receiptId}, ${tag.tag}');
    }
  }
}
