import 'package:receiptcamp/data/repositories/database_repository.dart';
import 'package:receiptcamp/models/folder.dart';

class FolderHelper {
  // using DatabaseRepository singleton instance
  final DatabaseRepository databaseRepository = DatabaseRepository.instance;

  // method to check folder name is valid
  // This regex pattern assumes that the folder name should consist of only alphabetic
  // characters (lowercase or uppercase), digits, underscores, and hyphens.
  static bool validFolderName(String name) {
    try {
      final RegExp regex = RegExp(r'^[a-zA-Z0-9 _-]+$');
      return name.isNotEmpty && regex.hasMatch(name);
    } on Exception catch (e) {
      print('Error in validFolderName: $e');
      return false;
    }
  }

  static List<FolderWithPrice> sortFoldersByTotalCost(
      List<Folder> folders, String order) {
    // Mapping Folder objects to FolderWithPrice objects
    List<FolderWithPrice> foldersWithCost = folders
        .whereType<FolderWithPrice>()
        .map((folder) => folder)
        .toList();

    // Define a pattern to remove non-numeric characters (assuming currency symbols and commas)
    final pattern = RegExp(r'[^\d.]');

    // Sort the filtered FolderWithPrice list
    foldersWithCost.sort((a, b) {
      String aPrice = a.price.replaceAll(pattern, '');
      String bPrice = b.price.replaceAll(pattern, '');

      double aPriceDouble =
          aPrice == '--' ? 0.0 : double.tryParse(aPrice) ?? 0.0;
      double bPriceDouble =
          bPrice == '--' ? 0.0 : double.tryParse(bPrice) ?? 0.0;

      if (order == 'ASC') {
        return aPriceDouble.compareTo(bPriceDouble);
      } else if (order == 'DESC') {
        return bPriceDouble.compareTo(aPriceDouble);
      } else {
        return 0; // Do not sort if the order parameter is invalid
      }
    });

    return foldersWithCost;
  }


  static List<FolderWithSize> sortFoldersBySize(List<Folder> folders, String order) {
     // Mapping Folder objects to FolderWithPrice objects
    List<FolderWithSize> foldersWithSize = folders
        .whereType<FolderWithSize>()
        .map((folder) => folder)
        .toList();

    folders.sort((a, b) {
      // Assuming both a and b are of type FolderWithSize or its subtype
      int aSize = 0;
      int bSize = 0;

      if (a is FolderWithSize) {
        aSize = a.storageSize;
      }

      if (b is FolderWithSize) {
        bSize = b.storageSize;
      }

      if (order == 'ASC') {
        return aSize.compareTo(bSize);
      } else if (order == 'DESC') {
        return bSize.compareTo(aSize);
      } else {
        return 0; // Do not sort if the order parameter is invalid
      }
    });

    return foldersWithSize;
  }

  static List<Folder> sortFoldersByLastModified(
      List<Folder> folders, String order) {
    folders.sort((a, b) {
      if (order == 'ASC') {
        return a.lastModified.compareTo(b.lastModified);
      } else if (order == 'DESC') {
        return b.lastModified.compareTo(a.lastModified);
      } else {
        return 0; // Do not sort if the order parameter is invalid
      }
    });

    return folders;
  }

  static List<Folder> sortFoldersByName(List<Folder> folders, String order) {
    folders.sort((a, b) {
      int comparisonResult =
          a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (order == 'ASC') {
        return comparisonResult;
      } else if (order == 'DESC') {
        return -comparisonResult; // Reverse the comparison for descending order
      } else {
        return 0; // Do not sort if the order parameter is invalid
      }
    });

    return folders;
  }


}
