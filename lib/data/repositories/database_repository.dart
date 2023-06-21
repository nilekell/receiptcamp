import 'package:receiptcamp/models/folder.dart';
import 'package:receiptcamp/models/receipt.dart';
import 'package:receiptcamp/models/tag.dart';
import 'package:receiptcamp/data/services/database.dart';

class DatabaseRepository {
  // ensuring there is only one instance of DatabaseRepository ever (it is a singleton)
  static final DatabaseRepository _instance = DatabaseRepository._privateConstructor();
  static DatabaseRepository get instance => _instance;

  DatabaseRepository._privateConstructor();

  final DatabaseService _databaseService = DatabaseService.instance;

  // Method to initialize the database
  Future<void> init() async {
    // This will create and initialize the database if it does not exist, or just retrieve it if it does.
    await _databaseService.database;
  }

  // Folder methods

  Future<List<Object>> getFolderContents(String folderId) async {
    return await _databaseService.getFolderContents(folderId);
  }

  Future<void> insertFolder(Folder folder) async {
    return await _databaseService.insertFolder(folder);
  }

  Future<void> renameFolder(String folderId, String newName) async {
    return await _databaseService.renameFolder(folderId, newName);
  }

  Future<List<Folder>> getFolders() async {
    return await _databaseService.getFolders();
  }

  Future<void> deleteFolder(String folderId) async {
    return await _databaseService.deleteFolder(folderId);
  }

  Future<bool> folderExists(String id, String name) async {
    return await _databaseService.folderExists(id, name);
  }

  // Receipt methods

  Future<int> insertReceipt(Receipt receipt) async {
    return await _databaseService.insertReceipt(receipt);
  }

  Future<int> updateReceipt(Receipt receipt) async {
    return await _databaseService.updateReceipt(receipt);
  }

  Future<int> deleteReceipt(String id) async {
    return await _databaseService.deleteReceipt(id);
  }

  Future<List<Receipt>> getReceipts() async {
    return await _databaseService.getReceipts();
  }

  Future<List<Receipt>> getReceiptByName(String name) async {
    return await _databaseService.getReceiptByName(name);
  }

  Future<void> renameReceipt(String id, String newName) async {
    return await _databaseService.renameReceipt(id, newName);
  }

  Future<List<Receipt>> getRecentReceipts() async {
    return await _databaseService.getRecentReceipts();
  }

  Future<List<Receipt>> getSuggestedReceiptsByTags(String tag) async {
    return await _databaseService.getSuggestedReceiptsByTags(tag);
  }

  Future<List<Receipt>> getFinalReceiptsByTags(String tag) async {
    return await _databaseService.getFinalReceiptsByTags(tag);
  }

  // Tag methods

  Future<void> insertTags(List<Tag> tags) async {
    return await _databaseService.insertTags(tags);
  }
  

  Future<List<Tag>> getTagsByReceiptID(String receiptId) async {
    return await _databaseService.getTagsByReceiptID(receiptId);
  }
  // Delete all data

  Future<void> deleteAll() async {
    await _databaseService.deleteAll();
  }

  // Other methods

  Future<void> printAllReceipts() async {
    await _databaseService.printAllReceipts();
  }
}
