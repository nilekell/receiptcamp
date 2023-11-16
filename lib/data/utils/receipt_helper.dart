import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:receiptcamp/data/utils/file_helper.dart';
import 'package:receiptcamp/data/utils/text_recognition.dart';
import 'package:receiptcamp/data/utils/utilities.dart';
import 'package:receiptcamp/models/receipt.dart';
import 'package:receiptcamp/models/tag.dart';

// enum used to describe possible error types when checking image size & text presence before scanning
enum ValidationError {size, text, both, none}

class ReceiptService {
  @visibleForTesting
  static List<Tag> generateTags(List<String> keywords, String receiptId) {
    List<Tag> tags = [];
    try {
      for (var keyword in keywords) {
        String tagId = Utility.generateUid();
        Tag tag = Tag(id: tagId, receiptId: receiptId, tag: keyword);
        tags.add(tag);
      }
    } on Exception catch (e) {
      print('Error in generateTags: $e');
    }
    return tags;
  }

  // create and return receipt object
  static Future<Receipt> createReceiptFromFile(
      File receiptFile, String fileName, String folderId, String receiptUid) async {
    // Generating receipt object properties

    final path = receiptFile.path;
    // Getting current time for image creation
    final currentTime = Utility.getCurrentTime();

    // getting compressed file sizes
    final compressedfileSize = await FileService.getFileSize(path, 2);

    // Creating receipt object to be stored in local db
    Receipt thisReceipt = Receipt(
        id: receiptUid,
        name: fileName.split('.').first,
        fileName: fileName,
        dateCreated: currentTime,
        lastModified: currentTime,
        storageSize: compressedfileSize,
        // id of default folder
        parentId: folderId);

    return thisReceipt;
  }
  
  static Future<List<Tag>> extractKeywordsAndGenerateTags(String imagePath, String receiptId) async {
  List<Tag> tags = [];

  try {
    final receiptKeyWords = await TextRecognitionService.extractKeywordsFromPath(imagePath);
    print(receiptKeyWords);
    tags = generateTags(receiptKeyWords, receiptId);
  } on Exception catch (e) {
    print('Error in extractKeywordsAndGenerateTags: $e');
  }

  return tags;
}

  static Future<List<dynamic>> processingReceiptAndTags(XFile receiptImage, String folderId) async {
    // creating receipt primary key
    final receiptUid = Utility.generateUid();

    // tag processing
    final tagsList = await ReceiptService.extractKeywordsAndGenerateTags(
        receiptImage.path, receiptUid);

    // receipt processing

    // getting file extension with '.' from image path
    String fileExtension = extension(receiptImage.path);

    // identifying file type of receipt image
    final imageFileType = identifyImageFileTypeFromString(fileExtension);
    
    // getting new image path + file name (based on file type) to save receipt to
    final localReceiptImagePath = await FileService.getLocalImagePath(imageFileType);
    // compressing and saving image
    final receiptImageFile = await FileService.compressFile(
        File(receiptImage.path), localReceiptImagePath);

    // deleting temporary image files
    await FileService.deleteFileFromPath(receiptImage.path);

    // creating receipt object
    final receipt = await ReceiptService.createReceiptFromFile(
        receiptImageFile!, basename(receiptImageFile.path), folderId, receiptUid);

    return [receipt, tagsList];
}

  static ImageFileType identifyImageFileTypeFromString(String fileExtension) {
    ImageFileType imageFileType;

    if (fileExtension == '.png') {
      imageFileType = ImageFileType.png;
    } else if (fileExtension == '.heic') {
      imageFileType = ImageFileType.heic;
    }  else if (fileExtension == '.jpg' || fileExtension == '.jpeg') {
      imageFileType = ImageFileType.jpg;
    } else {
      throw Exception('Utilities.generateFileName(): unexpected file type');
    }
    return imageFileType;
  }

  static Future<(bool, ValidationError)> isValidImage(String imagePath) async {
    ValidationError validationError = ValidationError.none;

    try {
      final validSize = await FileService.isValidImageSize(imagePath);
      final hasText = await TextRecognitionService.imageHasText(imagePath);

      if (validSize == false) validationError = ValidationError.size;
      if (hasText == false) validationError = ValidationError.text;
      if (validSize == false && hasText == false) validationError = ValidationError.both;

      // only returns true when both booleans are true
      return (validSize && hasText, validationError);
    } on Exception catch (e) {
      print('Error in ReceiptService.imageHasText: $e');
      return (false, validationError);
    }
  }

  // method to check file name is valid
  static bool validReceiptFileName(String name) {
    // this regex pattern assumes that the file name should consist of only alphabetic characters
    // (lowercase or uppercase), digits, underscores, hyphens, and a file extension consisting of alphabetic
    // characters and digits
    try {
      final RegExp regex = RegExp(r'^[a-zA-Z0-9_\-]+\.[a-zA-Z0-9]+$');
      return name.isNotEmpty && regex.hasMatch(name);
    } on Exception catch (e) {
      print('Error in validReceiptFileName: $e');
      return false;
    }
  }

  static Future<dynamic> createTypedReceiptFromColumn(
      Receipt receipt, String lastColumn, String lastOrder) async {
    dynamic typedReceipt;

    switch (lastColumn) {
      case 'price':
        final priceString = await TextRecognitionService.extractPriceFromImage(
            receipt.localPath);
        final priceDouble =
            await TextRecognitionService.extractCostFromPriceString(
                priceString);
        typedReceipt = ReceiptWithPrice(
            receipt: receipt,
            priceDouble: priceDouble,
            priceString: priceString);
        break;
      case 'storageSize':
        typedReceipt = ReceiptWithSize(withSize: true, receipt: receipt);
        break;
      case 'lastModified':
      case 'name':
        typedReceipt = receipt;
        break;
    }

    return typedReceipt;
  }


  static List<ReceiptWithPrice> sortReceiptsByTotalCost(
      List<Receipt> receipts, String order) {
    print(receipts.length);
    List<ReceiptWithPrice> receiptsWithCost = receipts
        .whereType<ReceiptWithPrice>()
        .map((receipt) => receipt)
        .toList();

    receiptsWithCost.sort((a, b) {
      double aPrice = a.priceDouble;
      double bPrice = b.priceDouble;

      if (order == 'ASC') {
        return aPrice.compareTo(bPrice);
      } else if (order == 'DESC') {
        return bPrice.compareTo(aPrice);
      } else {
        return 0;
      }
    });

    return receiptsWithCost;
  }

  static List<ReceiptWithSize> sortReceiptsBySize(
      List<Receipt> receipts, String order) {
    List<ReceiptWithSize> receiptsWithSize = receipts
        .whereType<ReceiptWithSize>()
        .map((receipt) => receipt)
        .toList();

    receiptsWithSize.sort((a, b) {
      int aSize = a.storageSize;
      int bSize = b.storageSize;

      if (order == 'ASC') {
        return aSize.compareTo(bSize);
      } else if (order == 'DESC') {
        return bSize.compareTo(aSize);
      } else {
        return 0;
      }
    });

    return receiptsWithSize;
  }

  static List<Receipt> sortReceiptsByName(
      List<Receipt> receipts, String order) {
    receipts.sort((a, b) {
      int comparisonResult =
          a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (order == 'ASC') {
        return comparisonResult;
      } else if (order == 'DESC') {
        return -comparisonResult;
      } else {
        return 0;
      }
    });

    return receipts;
  }

  static List<Receipt> sortReceiptsByLastModified(
      List<Receipt> receipts, String order) {
    receipts.sort((a, b) {
      if (order == 'ASC') {
        return a.lastModified.compareTo(b.lastModified);
      } else if (order == 'DESC') {
        return b.lastModified.compareTo(a.lastModified);
      } else {
        return 0;
      }
    });

    return receipts;
  }
}
