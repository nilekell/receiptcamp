import 'package:receiptcamp/data/data_constants.dart';
import 'package:receiptcamp/data/utils/file_helper.dart';
import 'package:receiptcamp/data/utils/folder_helper.dart';
import 'package:receiptcamp/data/utils/text_recognition.dart';
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
            fileName TEXT NOT NULL,
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

  // Method to get all Folder objects in a specific folder sorted by a specific column
  Future<List<Folder>> getFoldersInFolderSortedBy(
      String folderId, String column, String order) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT * FROM folders WHERE parentId = ? ORDER BY $column $order',
        [folderId]);
    return List.generate(maps.length, (i) {
      return Folder(
        id: maps[i]['id'],
        name: maps[i]['name'],
        lastModified: maps[i]['lastModified'],
        parentId: maps[i]['parentId'],
      );
    });
  }

  // Method to get all Receipt objects in a specific folder sorted by a specific column
  Future<List<Receipt>> getReceiptsInFolderSortedBy(
      String folderId, String column, String order) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT * FROM receipts WHERE parentId = ? ORDER BY $column $order',
        [folderId]);
    return List.generate(maps.length, (i) {
      return Receipt(
          id: maps[i]['id'],
          name: maps[i]['name'],
          fileName: maps[i]['fileName'],
          dateCreated: maps[i]['dateCreated'],
          lastModified: maps[i]['lastModified'],
          storageSize: maps[i]['storageSize'],
          parentId: maps[i]['parentId']);
    });
  }

  Future<List<ReceiptWithSize>> getReceiptsBySize(
      String folderId, String order) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM receipts WHERE parentId = ? ORDER BY storageSize $order',
      [folderId],
    );

    // Create a list to hold the ReceiptWithSize objects
    final List<ReceiptWithSize> receiptsWithSize = [];

    // Iterate through the maps, creating a Receipt and then a ReceiptWithSize for each one
    for (var map in maps) {
      final Receipt receipt = Receipt.fromMap(map);
      final ReceiptWithSize receiptWithSize = ReceiptWithSize(
        withSize: true,
        receipt: receipt,
      );
      receiptsWithSize.add(receiptWithSize);
    }

    return receiptsWithSize;
  }

  Future<List<ReceiptWithPrice>> getReceiptsByPrice(
      String folderId, String order) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM receipts WHERE parentId = ?',
      [folderId],
    );

    final List<ReceiptWithPrice> receiptsWithPrice = [];

    for (var map in maps) {
      final Receipt receipt = Receipt.fromMap(map);
      final String priceString =
          await TextRecognitionService.extractPriceFromImage(receipt.localPath);
      final double priceDouble =
          double.tryParse(priceString.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
      final ReceiptWithPrice receiptWithPrice = ReceiptWithPrice(
          priceString: priceString, priceDouble: priceDouble, receipt: receipt);
      receiptsWithPrice.add(receiptWithPrice);
    }

    // Sort the list based on price
    receiptsWithPrice.sort((a, b) {
      if (order == 'ASC') {
        return a.priceDouble.compareTo(b.priceDouble);
      } else if (order == 'DESC') {
        return b.priceDouble.compareTo(a.priceDouble);
      } else {
        return 0; // Do not sort if the order parameter is invalid
      }
    });

    return receiptsWithPrice;
  }

  // method to get folders by price
  Future<List<FolderWithPrice>> getFoldersByPrice(
      String folderId, String order) async {

    // Step 1: Check is this folder contains no folders and receipts
    if (await folderHasNoContents(folderId)) return <FolderWithPrice>[];

    // Step 2: Retrieve direct subfolders
    List<Folder> subFolders = await getDirectFoldersByParentId(folderId);

    // Step 3: Initialize folder cost data structure
    List<FolderWithPrice> foldersWithCost = [];

    // Step 4: Calculate cost for each folder
    for (Folder folder in subFolders) {
      double totalCost = 0.0;
      String? commonCurrency;
      bool inconsistentCurrencyFound = false;

      // if a direct subfolder contains receipts, return it with a 'null' price
      if (await folderIsEmpty(folder.id)) {
        foldersWithCost.add(FolderWithPrice(price: '--', folder: folder));
        continue; 
      }

      // Step 5: Getting receipts in a direct subfolder by price
      List<ReceiptWithPrice> receiptsWithPrice = await getReceiptsByPrice(folder.id, order);

      // Step 6: Gettng currency symbol from receipts
      if (receiptsWithPrice.isNotEmpty) {
        commonCurrency = await TextRecognitionService.getCurrencySymbol(receiptsWithPrice[0].priceString);
        for (final receiptWithPrice in receiptsWithPrice) {
          if (await TextRecognitionService.getCurrencySymbol(receiptWithPrice.priceString) != commonCurrency) {
            inconsistentCurrencyFound = true;
            break;
          }
        }
      }

      // Step 7: Checking if all receipts have the same currency.
      // If not, add a Folder to be returned with a 'null' price
      if (inconsistentCurrencyFound) {
        foldersWithCost.add(FolderWithPrice(price: '--', folder: folder));
        continue;
      }

      // Step 8: If all receipts have the same currency, add the total cost of the
      // receipts to the running total for the folder
      totalCost +=
          receiptsWithPrice.fold(0, (sum, item) => sum + item.priceDouble);

      // Step 9: Get the total cost of receipts in all nested subfolders 
      double subFoldersCost = await calculateSubFoldersCost(folder.id);

      // Step 10: Adding total from all subfolders to folder's running total
      totalCost += subFoldersCost;
      
      // Step 11: Getting price to be displayed for a folder without rounding but keeping 2 decimal places
      String displayPrice = "${commonCurrency ?? ''}${(totalCost * 100).truncateToDouble() / 100}";

      // Step 12: Adding folder to be returned with display price
      foldersWithCost.add(FolderWithPrice(price: displayPrice, folder: folder));
    }

    if (foldersWithCost.length == 1) {
      return foldersWithCost;
    }

    // Step 13: Sort the folders by total cost
    foldersWithCost = FolderHelper.sortFoldersByTotalCost(foldersWithCost, order);

  // Step 14: Return the immediate subfolders with their prices
  return foldersWithCost;
}

// method to get subfolders total price from subfolders
Future<double> calculateSubFoldersCost(String folderId) async {
    final db = await database;

    // Step 9.1: Get all immediate subfolder IDs of the current folder
    List<Map<String, dynamic>> subFolderMaps = await db.rawQuery(
      'SELECT id FROM folders WHERE parentId = ?',
      [folderId],
    );

    // Step 9.2: Extract folder IDs as Strings
    List<String> subFolderIds =
        subFolderMaps.map((map) => map['id'] as String).toList();

    double totalCost = 0.0;
    String? commonCurrency;
    Set<String> currencySymbols = {'\$', '€', '¥', '£', '₹'};

    // Step 9.3: Iterate over each subfolder to calculate their total cost
    for (String subFolderId in subFolderIds) {

      // skipping over empty nested folders
      if (await folderHasNoContents(subFolderId)) continue;

      // Step 9.4: Recursively calculate the cost of this subfolder
      double subFolderCost = await calculateSubFoldersCost(subFolderId);

      // Step 9.5: add single subfolder's cost to the cost of its immediate parent
      totalCost += subFolderCost;

      // Step 9.6: Calculate the cost of receipts directly within this subfolder
      List<Map<String, dynamic>> receiptMaps = await db.rawQuery(
        'SELECT * FROM receipts WHERE parentId = ?',
        [subFolderId],
      );

      for (var receiptMap in receiptMaps) {
        final Receipt receipt = Receipt.fromMap(receiptMap);
        String priceString = await TextRecognitionService.extractPriceFromImage(
            receipt.localPath);

        // Remove currency symbols from the price string
        for (String symbol in currencySymbols) {
          if (priceString.contains(symbol)) {
            priceString = priceString.replaceAll(symbol, '');
            break; // Stop checking after the first match
          }
        }

        final double priceDouble =
            double.tryParse(priceString.replaceAll(RegExp(r'[^\d.]'), '')) ??
                0.0;

        // Extract and check the currency symbol
        if (commonCurrency == null) {
          commonCurrency =
              await TextRecognitionService.getCurrencySymbol(priceString);
        } else if (await TextRecognitionService.getCurrencySymbol(
                priceString) !=
            commonCurrency) {
          return 0.0;
        }

        // Step 9.7: Adding price of each receipt found directly in this sub folder to the total cost
        totalCost += priceDouble;
      }
    }

    // Step 9.8: Returning the total cost of the subfolder
    return totalCost;
  }

  Future<List<FolderWithSize>> getFoldersByTotalReceiptSize(
      String parentId, String order) async {
    final db = await database;
    List<FolderWithSize> foldersWithSizes = [];

    Future<int> getFolderSize(String folderId) async {
      int folderSize = 0;
      final List<Map<String, dynamic>> receiptMaps = await db
          .rawQuery('SELECT * FROM receipts WHERE parentId = ?', [folderId]);
      for (var map in receiptMaps) {
        folderSize += (map['storageSize'] as num).toInt();
      }

      final List<Map<String, dynamic>> subFolderMaps = await db
          .rawQuery('SELECT * FROM folders WHERE parentId = ?', [folderId]);
      for (var map in subFolderMaps) {
        folderSize += await getFolderSize(map['id']);
      }

      return folderSize;
    }

    final List<Map<String, dynamic>> folderMaps = await db
        .rawQuery('SELECT * FROM folders WHERE parentId = ?', [parentId]);
    for (var map in folderMaps) {
      final folder = Folder(
        id: map['id'],
        name: map['name'],
        lastModified: map['lastModified'],
        parentId: map['parentId'],
      );
      final storageSize = await getFolderSize(folder.id);
      foldersWithSizes
          .add(FolderWithSize(storageSize: storageSize, folder: folder));
    }

    foldersWithSizes = FolderHelper.sortFoldersBySize(foldersWithSizes, order);

    return foldersWithSizes;
  }


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
          fileName: receipts[i]['fileName'],
          dateCreated: receipts[i]['dateCreated'],
          lastModified: receipts[i]['lastModified'],
          storageSize: receipts[i]['storageSize'],
          parentId: receipts[i]['parentId']);
    });

    return [...foldersList, ...receiptsList]; // combining two lists and return
  }

  // Method to get all Folder objects for a specific folderId from the database.
  Future<List<Folder>> getDirectFoldersByParentId(String folderId) async {
    final db = await database;
    final List<Map<String, dynamic>> foldersMap = await db.rawQuery('''
      SELECT *
      FROM folders
      WHERE parentId = ?
    ''', [folderId]);

    return List.generate(foldersMap.length, (i) {
      return Folder(
        id: foldersMap[i]['id'],
        name: foldersMap[i]['name'],
        lastModified: foldersMap[i]['lastModified'],
        parentId: foldersMap[i]['parentId'],
      );
    });
  }

  Future<List<String>> getImmediateSubfolderIds(String folderId) async {
    final db = await database;
    // Execute the query to get all immediate subfolder IDs
    List<Map<String, dynamic>> mapOfFolderIds = await db.rawQuery(
      'SELECT id FROM folders WHERE parentId = ?',
      [folderId],
    );

    // Map each item in the result to an element in the list
    return mapOfFolderIds.map((item) => item['id'].toString()).toList();
  }

  Future<List<Receipt>> getAllReceiptsInFolder(String folderId) async {
    final List<Receipt> allReceipts = [];

    Future<void> fetchReceipts(String currentFolderId) async {
      final db = await database;

      // Fetch all folders in the current folder
      final List<Map<String, dynamic>> folders = await db.rawQuery('''
      SELECT *
      FROM folders
      WHERE parentId = ?
    ''', [currentFolderId]);

      final foldersList = List<Folder>.generate(folders.length, (i) {
        return Folder(
          id: folders[i]['id'],
          name: folders[i]['name'],
          lastModified: folders[i]['lastModified'],
          parentId: folders[i]['parentId'],
        );
      });

      // Fetch all receipts in the current folder
      final List<Map<String, dynamic>> receipts = await db.rawQuery('''
      SELECT *
      FROM receipts
      WHERE parentId = ?
    ''', [currentFolderId]);

      final receiptsList = List<Receipt>.generate(receipts.length, (i) {
        return Receipt(
          id: receipts[i]['id'],
          name: receipts[i]['name'],
          fileName: receipts[i]['fileName'],
          dateCreated: receipts[i]['dateCreated'],
          lastModified: receipts[i]['lastModified'],
          storageSize: receipts[i]['storageSize'],
          parentId: receipts[i]['parentId'],
        );
      });

      allReceipts.addAll(receiptsList); // Add the receipts to the global list

      // If there are folders, then we do a recursive call
      for (final folder in foldersList) {
        await fetchReceipts(folder.id);
      }
    }

    await fetchReceipts(folderId);

    return allReceipts;
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
    // folders can have the same name
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

   Future<List<Folder>> getMultiFoldersThatCanBeMovedTo(List<Object> filesToBeMoved) async {
    final db = await database;
    List<String> exceptionFolderIds = [];

    print('filesToBeMoved.length: ${filesToBeMoved.length}');
    for (final item in filesToBeMoved) {
      if (item is Receipt) {
        exceptionFolderIds.add(item.parentId);
        print('exceptionFolderIds: added Receipt ${item.name}, ${item.id}');
      } else if (item is Folder) {
        exceptionFolderIds.add(item.parentId);
        print('exceptionFolderIds: added Folder ${item.name}, ${item.id}');
        final subFolderIds = await getRecursiveSubFolderIds(item.id);
        exceptionFolderIds.add(item.id);
        exceptionFolderIds.addAll(subFolderIds);
      }
    }

    // removing duplicates
    exceptionFolderIds = exceptionFolderIds.toSet().toList();
    print('exceptionFolderIds: $exceptionFolderIds');

    // Create a string of placeholders for sqlite query
    String placeholders = exceptionFolderIds.map((_) => '?').join(',');

    // querying for all folders except for those in [exceptionFolderIds]
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT *
      FROM folders
      WHERE id NOT IN ($placeholders)
    ''', exceptionFolderIds);

    // returning list of folders
    return List.generate(maps.length, (i) {
      print(maps[i]['name']);
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
        deleteReceipt(Receipt.fromMap(receipt).id);
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

  // checks if folders has no receipts only
  Future<bool> folderIsEmpty(String folderId) async {
    final db = await database;

    int totalSubReceipts = 0;

    // getting list of ids for all sub folders within selected folder
    final List<String> subFolderIds = await getRecursiveSubFolderIds(folderId);

    // getting number of receipts within selected folder (not-recursive)
    getReceiptCountInFolder(String folderId) async {
      final countReceiptsResult = await db.rawQuery('''
     SELECT COUNT (*)
     FROM receipts
     WHERE parentId = ?
     ''', [folderId]);

      //adding number of receipts found directly in a folder to [totalSubReceipts]
      int numReceipts = Sqflite.firstIntValue(countReceiptsResult) ?? 0;
      totalSubReceipts = totalSubReceipts + numReceipts;
    }

    // getting number of receipts in selected subfolder
    await getReceiptCountInFolder(folderId);

    for (final id in subFolderIds) {
      // getting number of receipts in each subfolder
      await getReceiptCountInFolder(id);
      }

    return totalSubReceipts < 1;
  }

  // checks if folders has no receipts and folders only
  Future<bool> folderHasNoContents(String folderId) async {
    int numFolders = 0;
    int numReceipts = 0;
    List<String> subFolderIds = [];

    // getting number of receipts in selected subfolder
    numReceipts = await getReceiptCountInFolder(folderId);

    // getting list of ids for all sub folders within selected folder
    subFolderIds = await getRecursiveSubFolderIds(folderId);
    numFolders = subFolderIds.length;

    if (numFolders < 1) {
       return numReceipts < 1;
    }

    for (final id in subFolderIds) {
      // getting number of receipts in each subfolder
      int subFolderReceiptCount = await getReceiptCountInFolder(id);
      numReceipts += subFolderReceiptCount;
    }

    return numReceipts + numFolders < 1;
  }

  // getting number of receipts within selected folder (not-recursive)
  Future<int> getReceiptCountInFolder(String folderId) async {
    final db = await database;
    final countReceiptsResult = await db.rawQuery('''
    SELECT COUNT (*)
    FROM receipts
    WHERE parentId = ?
    ''', [folderId]);

    //adding number of receipts found directly in a folder to [totalSubReceipts]
    int numReceipts = Sqflite.firstIntValue(countReceiptsResult) ?? 0;
    numReceipts;

    return numReceipts;
  }

  Future<void> deleteAllFoldersExceptRoot() async {
    final Database db = await database;
    
    // delete all folders except the root folder
    await db.delete('folders', where: 'id != ?', whereArgs: [rootFolderId]);
    
    // delete all receipts and tags because they reference folders that no longer exist
    await db.delete('receipts');
    await db.delete('tags');

    FileService.deleteAllReceiptImages();
  }

  Future<int> updateFolder(Folder folder) async {
    final db = await database;
    return await db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
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
    await FileService.deleteFileFromPath(deletedReceiptPath);

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

  Future<void> printAllFolders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('folders');
    print('num of folders: ${maps.length}');
    print('All folders in database:');
    for (var folderMap in maps) {
      final folder = Folder(
          id: folderMap['id'],
          name: folderMap['name'],
          lastModified: folderMap['lastModified'],
          parentId: folderMap['parentId'],);

      print('id: ${folder.id.toString()}');
      print('name: ${folder.name.toString()}');
      print('lastModified: ${folder.lastModified.toString()}');
      print('parentId: ${folder.parentId.toString()}');
      print('//--------------//');
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
          fileName: maps[i]['fileName'],
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
    for (var receiptMap in maps) {
      final receipt = Receipt(
          id: receiptMap['id'],
          name: receiptMap['name'],
          fileName: receiptMap['fileName'],
          dateCreated: receiptMap['dateCreated'],
          lastModified: receiptMap['lastModified'],
          storageSize: receiptMap['storageSize'],
          parentId: receiptMap['parentId']);

      print('id: ${receipt.id.toString()}');
      print('name: ${receipt.name.toString()}');
      print('fileName: ${receipt.fileName.toString()}');
      print('dateCreated: ${receipt.dateCreated.toString()}');
      print('lastModified: ${receipt.lastModified.toString()}');
      print('storageSize: ${receipt.storageSize.toString()}');
      print('parentId: ${receipt.parentId.toString()}');
      print('//--------------//');
    }
  }

  // Method to get Receipt objects by name from the database
  Future<List<Receipt>> getReceiptByName(String name) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('receipts',
        // retrieving the following columns from the database
        columns: ['id', 'name', 'fileName', 'dateCreated', 'lastModified', 'storageSize', 'parentId'],
        // '?'s are replaced with the items in the [whereArgs] field
        where: 'name = ?',
        // [name] is the argument of the function
        whereArgs: [name]);
    return List.generate(maps.length, (i) {
      return Receipt(
          id: maps[i]['id'],
          name: maps[i]['name'],
          fileName: maps[i]['fileName'],
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
          fileName: maps[i]['fileName'],
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
        SELECT receipts.id, receipts.name, receipts.fileName, receipts.dateCreated, receipts.lastModified, receipts.storageSize, receipts.parentId
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
          fileName: maps[i]['fileName'],
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
        SELECT receipts.id, receipts.name, receipts.fileName, receipts.dateCreated, receipts.lastModified, receipts.storageSize, receipts.parentId
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
          fileName: maps[i]['fileName'],
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
