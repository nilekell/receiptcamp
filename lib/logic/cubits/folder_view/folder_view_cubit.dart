// ignore_for_file: unused_local_variable

import 'dart:io';
import 'dart:isolate';
import 'package:bloc/bloc.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receiptcamp/data/data_constants.dart';
import 'package:receiptcamp/data/repositories/database_repository.dart';
import 'package:receiptcamp/data/services/isolate.dart';
import 'package:receiptcamp/data/services/permissons.dart';
import 'package:receiptcamp/data/services/preferences.dart';
import 'package:receiptcamp/data/utils/file_helper.dart';
import 'package:receiptcamp/data/utils/folder_helper.dart';
import 'package:receiptcamp/data/utils/receipt_helper.dart';
import 'package:receiptcamp/data/utils/utilities.dart';
import 'package:receiptcamp/logic/blocs/home/home_bloc.dart';
import 'package:receiptcamp/logic/cubits/file_explorer/file_explorer_cubit.dart';
import 'package:receiptcamp/models/folder.dart';
import 'package:receiptcamp/models/receipt.dart';
import 'package:receiptcamp/models/tag.dart';

part 'folder_view_state.dart';

// this cubit controls the initialisation, loading, displaying and any methods that can
// affect what is currently being displayed in the folder view e.g. move/delete/upload/rename
class FolderViewCubit extends Cubit<FolderViewState> {

  final HomeBloc homeBloc;
  final FileExplorerCubit fileExplorerCubit;
  final PreferencesService prefs; 
  List<dynamic> cachedCurrentlyDisplayedFiles = [];

  final DatabaseRepository _dbRepo = DatabaseRepository.instance;

  FolderViewCubit({required this.homeBloc, required this.prefs, required this.fileExplorerCubit}) : super(FolderViewInitial());

  // init folderview
  initFolderView() {
    emit(FolderViewInitial());
    print('RefreshableFolderView instantiated');
    fetchFilesInFolderSortedBy(rootFolderId, column: prefs.getLastColumn(), order: prefs.getLastOrder());
  }

  retrieveCachedItems() async {
    emit(FolderViewLoadedSuccess(files: cachedCurrentlyDisplayedFiles, folder: fileExplorerCubit.currentlyDisplayedFolder!, orderedBy: prefs.getLastColumn(), order: prefs.getLastOrder()));
  }

  // get folder files
  fetchFilesInFolderSortedBy(String folderId, {String? column, String? order, bool userSelectedSort = false, bool useCachedFiles = false}) async {
    emit(FolderViewLoading());

    // if column and order are left out of the method call (null), set them to the last value
    column ??= prefs.getLastColumn();
    order ??= prefs.getLastOrder();

    // setting last order & column values
    final String lastColumn = prefs.getLastColumn();
    final String lastOrder = prefs.getLastOrder();

    try {
      final folder = await _dbRepo.getFolderById(folderId);

      // userSelectedSort is only true when the user taps on a tile in order options bottom sheet
      // this distinguishes between the user navigating between folders, sorting in the options sheet, or refreshing the folder view
      if (userSelectedSort && _isSameSort(order, column)) {
        // toggles order when the user has submitted the same sort
        order = order == 'ASC' ? 'DESC' : 'ASC';
      }

      // If the last column is still the same, and the order is changing, just reverse the items in the list
      // this saves refetching the files
      if (lastColumn == column && lastOrder != order) {
        await prefs.setLastOrder(order);
        cachedCurrentlyDisplayedFiles = cachedCurrentlyDisplayedFiles.reversed.toList();
        emit(FolderViewLoadedSuccess(files: cachedCurrentlyDisplayedFiles, folder: folder, orderedBy: column, order: order));
        return;
      }

      if (column == 'price') {
        final List<FolderWithPrice> foldersWithPrice = await _dbRepo.getFoldersByPrice(folderId, order);
        final List<ReceiptWithPrice> receiptsWithPrices = await _dbRepo.getReceiptsByPrice(folderId, order);
        final List<Object> files = [...foldersWithPrice, ...receiptsWithPrices];
        cachedCurrentlyDisplayedFiles = files;
        emit(FolderViewLoadedSuccess(files: files, folder: folder, orderedBy: column, order: order));

        // updating last column and last order
        await prefs.setLastColumn(column);
        await prefs.setLastOrder(order);
        return;
      }

      if (column == 'storageSize') {
        final List<FolderWithSize> foldersWithSize = await _dbRepo.getFoldersByTotalReceiptSize(folderId, order);
        final List<ReceiptWithSize> receiptsWithSize =  await _dbRepo.getReceiptsBySize(folderId, order);
        final List<Object> files = [...foldersWithSize, ...receiptsWithSize];
        cachedCurrentlyDisplayedFiles = files;
        emit(FolderViewLoadedSuccess(files: files, folder: folder, orderedBy: column, order: order));

        // updating last column and last order
        await prefs.setLastColumn(column);
        await prefs.setLastOrder(order);
        return;
      }

      final List<Folder> folders = await _dbRepo.getFoldersInFolderSortedBy(folderId, column, order);
      final List<Receipt> receipts = await _dbRepo.getReceiptsInFolderSortedBy(folderId, column, order);
      final List<Object> files = [...folders, ...receipts];
      cachedCurrentlyDisplayedFiles = files;
      emit(FolderViewLoadedSuccess(files: files, folder: folder, orderedBy: column, order: order));

      // updating last column and last order
      await prefs.setLastColumn(column);
      await prefs.setLastOrder(order);

    } catch (error) {
      emit(FolderViewError());
    }
  }

  // determines if the last selected order and column is the same as the next selected order and column
  bool _isSameSort(String currentOrder, currentColumn) {
    return currentOrder == prefs.getLastOrder() && currentColumn == prefs.getLastColumn();
  }

  updateDisplayFiles() {
    // Separate folders and receipts
    List<Folder> folders = [];
    List<Receipt> receipts = [];

    for (var item in cachedCurrentlyDisplayedFiles) {
      if (item is Folder) {
        folders.add(item);
      } else if (item is Receipt) {
        receipts.add(item);
      }
    }

    final lastColumn = prefs.getLastColumn();
    final lastOrder = prefs.getLastOrder();

    // Sort the folders based on the lastColumn and lastOrder
    switch (lastColumn) {
      case 'price':
          folders = FolderHelper.sortFoldersByTotalCost(folders, lastOrder);
        break;
      case 'storageSize':
        folders = FolderHelper.sortFoldersBySize(folders, lastOrder);
        break;
      case 'lastModified':
        folders = FolderHelper.sortFoldersByLastModified(folders, lastOrder);
        break;
      case 'name':
        folders = FolderHelper.sortFoldersByName(folders, lastOrder);
        break;
    }

    // Reassemble cachedCurrentlyDisplayedFiles with sorted folders followed by receipts
    cachedCurrentlyDisplayedFiles
      ..clear()
      ..addAll(folders)
      ..addAll(receipts);
  }

  moveMultipleItems(List<Object> items, String destinationFolderId) async {
    try {
      final String targetFolderName =
          (await _dbRepo.getFolderById(destinationFolderId))
              .name;

      int numMoved = 0;

      for (final item in items) {
        if (item is Receipt) {
          await _dbRepo.moveReceipt(item, destinationFolderId);
          numMoved++;
        } else if (item is Folder) {
          await _dbRepo.moveFolder(item, destinationFolderId);
          numMoved++;
        }
      }

      emit(
        FolderViewMultiMoveSuccess(
            folderId: destinationFolderId,
            numItemsMoved: numMoved,
            destinationFolderName: targetFolderName),
      );
    } on Exception catch (e) {
      print(e.toString());
      emit(const FolderViewMultiMoveFailure(folderId: rootFolderId));
    }
  }

  deleteMultiItems(List<Object> objectList) async {
    int numDeleted = 0;
    String parentId = '';
    try {
      for (final item in objectList) {
        if (item is Receipt) {
          await _dbRepo.deleteReceipt(item.id);
          numDeleted++;
          parentId = item.id;
        } else if (item is Folder) {
          await _dbRepo.deleteFolder(item.id);
          numDeleted++;
          parentId = item.id;
        }
      }

      emit(
        FolderViewMultiDeleteSuccess(
            numItemsDeleted: numDeleted, folderId: parentId),
      );
    } on Exception catch (e) {
      print(e.toString());
      emit(FolderViewMultiDeleteFailure(folderId: parentId));
    }
  }

  // move folder
  moveFolder(Folder folder, String targetFolderId) async {
     final Folder targetFolder =
      await _dbRepo.getFolderById(targetFolderId);

    try {
      // Check if the folder is found in the cached list
      int index = cachedCurrentlyDisplayedFiles.indexWhere(
          (element) => element is Folder && element.id == folder.id);

      // updating cache
      cachedCurrentlyDisplayedFiles.removeWhere(
          (element) => element is Folder && element.id == folder.id);

      // Update the parentId of the folder in the cached list
      dynamic updatedFolder = Folder(
        id: folder.id,
        name: folder.name,
        lastModified: Utility.getCurrentTime(),
        parentId: targetFolderId,
      );

      if (index != -1) {
        // getting folder type
        switch (folder) {
          case FolderWithPrice():
            updatedFolder =
                FolderWithPrice(price: folder.price, folder: updatedFolder);
          case FolderWithSize():
            updatedFolder = FolderWithSize(
                storageSize: folder.storageSize, folder: updatedFolder);
          default:
            break;
        }

        // reload all files in folder when receipt is moved to a folder within the same folder
        if (targetFolder.parentId == folder.parentId) {
          await _dbRepo.updateFolder(updatedFolder);
          emit(FolderViewMoveSuccess(
            oldName: folder.name,
            newName: targetFolder.name,
            folderId: folder.parentId));
          fetchFilesInFolderSortedBy(folder.parentId);
          return;
        }

        emit(FolderViewMoveSuccess(
            oldName: folder.name,
            newName: targetFolder.name,
            folderId: folder.parentId));

        // emitting cache
        retrieveCachedItems();

        // updating db
        _dbRepo.updateFolder(updatedFolder);
      } else {
        throw Exception('Unexpected error: ${folder.name} not found in cache');
      }
      
    } on Exception catch (e) {
      print(e.toString());
      emit(FolderViewMoveFailure(
          oldName: folder.name,
          newName: targetFolder.name,
          folderId: folder.parentId));
      fetchFilesInFolderSortedBy(folder.parentId);
    }
  }

  // delete folder
  deleteFolder(String folderId) async {
    final Folder deletedFolder =
        await _dbRepo.getFolderById(folderId);
    try {
      cachedCurrentlyDisplayedFiles.removeWhere(
          (element) => element is Folder && element.id == folderId);

      emit(FolderViewDeleteSuccess(
          deletedName: deletedFolder.name, folderId: deletedFolder.parentId));

      retrieveCachedItems();

      _dbRepo.deleteFolder(folderId);

      // notifying home bloc to reload when a folder is deleted
      // as this could mean some nested receipts are deleted
      homeBloc.add(HomeLoadReceiptsEvent());
      
    } on Exception catch (e) {
      print(e.toString());
      emit(FolderViewDeleteFailure(
          deletedName: deletedFolder.name, folderId: deletedFolder.parentId));
      fetchFilesInFolderSortedBy(deletedFolder.parentId, useCachedFiles: false);
    }
  }

// upload folder
  uploadFolder(String folderName, String parentFolderId) async {
    try {
      // creating folder id
      final folderId = Utility.generateUid();
      final currentTime = Utility.getCurrentTime();

      // create folder object
      final folder = Folder(
          id: folderId,
          name: folderName,
          lastModified: currentTime,
          parentId: parentFolderId);

      final lastColumn = prefs.getLastColumn();
      final lastOrder = prefs.getLastOrder();

      dynamic customFolder;

      switch (lastColumn) {
        case 'price':
          customFolder = FolderWithPrice(price: '--', folder: folder);
          cachedCurrentlyDisplayedFiles.add(customFolder);
          switch (lastOrder) {
            case 'ASC':
            case 'DESC':
          }
        case 'storageSize':
          customFolder = FolderWithSize(storageSize: 0, folder: folder);
          cachedCurrentlyDisplayedFiles.add(customFolder);
          switch (lastOrder) {
            case 'ASC':
            case 'DESC':
          }
        case 'lastModified':
        case 'name':
          customFolder = folder;
          cachedCurrentlyDisplayedFiles.add(customFolder);
          switch (lastOrder) {
            case 'ASC':
            case 'DESC':
          }
      }

      updateDisplayFiles();

      emit(FolderViewUploadSuccess(
          uploadedName: folder.name, folderId: folder.parentId));

      retrieveCachedItems();

      // save folder
      _dbRepo.insertFolder(folder);

    } on Exception catch (e) {
      print('Error in uploadFolder: $e');
      emit(FolderViewError());
      fetchFilesInFolderSortedBy(parentFolderId, useCachedFiles: true);
    }
  }

  // rename folder
  renameFolder(Folder folder, String newName) async {
    try {
      int index = cachedCurrentlyDisplayedFiles.indexWhere((element) => element is Folder && element.id == folder.id);

      dynamic updatedFolder = Folder(
        id: folder.id,
        name: newName,
        lastModified: Utility.getCurrentTime(),
        parentId: folder.parentId,
      );

      // Check if the folder is found in the cached list
      if (index != -1) {
        // getting folder type
        switch (folder) {
          case FolderWithPrice():
            updatedFolder = FolderWithPrice(price: folder.price, folder: updatedFolder);
          case FolderWithSize():
            updatedFolder = FolderWithSize(
              storageSize: folder.storageSize, folder: updatedFolder);
          default:
          break;
        }
        
        // updating cache
        cachedCurrentlyDisplayedFiles[index] = updatedFolder;

        emit(FolderViewRenameSuccess(
        oldName: folder.name, newName: newName, folderId: folder.parentId));

        // emitting cache
        retrieveCachedItems();
        
        // updating db
        _dbRepo.updateFolder(updatedFolder);

      } else {
        throw Exception('Unexpected error: ${folder.name} not found in cache');
      }
    } on Exception catch (e) {
      print(e.toString());
      emit(FolderViewRenameFailure(
          oldName: folder.name, newName: newName, folderId: folder.parentId));
      fetchFilesInFolderSortedBy(folder.parentId);
    }
  }

  // move receipt
  moveReceipt(Receipt receipt, String targetFolderId) async {
    final Folder targetFolder =
      await _dbRepo.getFolderById(targetFolderId);

    try {
      // Check if the receipt is found in the cached list
      int index = cachedCurrentlyDisplayedFiles.indexWhere(
          (element) => element is Receipt && element.id == receipt.id);

      // updating cache
      cachedCurrentlyDisplayedFiles.removeWhere(
          (element) => element is Receipt && element.id == receipt.id);

      // Update the parentId of the receipt in the cached list
      dynamic updatedReceipt = Receipt(
        id: receipt.id,
        name: receipt.name,
        lastModified: Utility.getCurrentTime(),
        parentId: targetFolderId,
        fileName: receipt.fileName,
        dateCreated: receipt.dateCreated,
        storageSize: receipt.storageSize,
      );

      if (index != -1) {
        // getting folder type
        switch (receipt) {
          case ReceiptWithPrice():
            updatedReceipt =
                ReceiptWithPrice(receipt: updatedReceipt, priceString: receipt.priceString, priceDouble: receipt.priceDouble);
          case ReceiptWithSize():
            updatedReceipt = ReceiptWithSize(withSize: receipt.withSize, receipt: updatedReceipt);
          default:
            break;
        }
        
        // reload all files in folder when receipt is moved to a folder within the same folder
        if (targetFolder.parentId == receipt.parentId) {
          await _dbRepo.updateReceipt(updatedReceipt);
          emit(FolderViewMoveSuccess(
            oldName: receipt.name,
            newName: targetFolder.name,
            folderId: receipt.parentId));
          fetchFilesInFolderSortedBy(receipt.parentId);
          return;
        }

        emit(FolderViewMoveSuccess(
            oldName: receipt.name,
            newName: targetFolder.name,
            folderId: receipt.parentId));

        // emitting cache
        retrieveCachedItems();

        // updating db
        _dbRepo.updateReceipt(updatedReceipt);
      } else {
        throw Exception('Unexpected error: ${receipt.name} not found in cache');
      }
      
    } on Exception catch (e) {
      print(e.toString());
      emit(FolderViewMoveFailure(
          oldName: receipt.name,
          newName: targetFolder.name,
          folderId: receipt.parentId));
      fetchFilesInFolderSortedBy(receipt.parentId);
    }
  }

  // delete receipt
  deleteReceipt(String receiptId) async {
    final Receipt deletedReceipt =
        await _dbRepo.getReceiptById(receiptId);
    try {
      cachedCurrentlyDisplayedFiles.removeWhere((element) => element is Receipt && element.id == receiptId);

      emit(FolderViewDeleteSuccess(
          deletedName: deletedReceipt.name, folderId: deletedReceipt.parentId));

      retrieveCachedItems();

      await _dbRepo.deleteReceipt(receiptId);

      // notifying home bloc to reload when a receipt is deleted
      homeBloc.add(HomeLoadReceiptsEvent());

    } on Exception catch (e) {
      print(e.toString());
      emit(FolderViewDeleteFailure(
          deletedName: deletedReceipt.name, folderId: deletedReceipt.parentId));
      fetchFilesInFolderSortedBy(deletedReceipt.parentId);
    }
  }

// upload receipt
  uploadReceiptFromGallery(String currentFolderId) async {
    // Requesting photos permission if not granted
    if (!PermissionsService.instance.hasPhotosAccess) {
      await PermissionsService.instance.requestPhotosPermission();
      // if user denies camera permissions, show failure snackbar
      if (!PermissionsService.instance.hasPhotosAccess) {
        emit(FolderViewPermissionsFailure(
            folderId: currentFolderId,
            permissionResult: PermissionsService.instance.photosResult));
        fetchFilesInFolderSortedBy(currentFolderId, useCachedFiles: true);
        return;
      }
    }

    ValidationError invalidImageReason = ValidationError.none;

    try {
      final ImagePicker imagePicker = ImagePicker();

      final List<XFile> receiptImages = await imagePicker.pickMultiImage();

      if (receiptImages.isEmpty) return;


      bool someImagesFailed = false;
      ValidationError invalidImageReason = ValidationError.none;

      const int maxNumOfImagesBeforeDelay = 0;

      if (receiptImages.length > maxNumOfImagesBeforeDelay) {
        emit(FolderViewLoading());
      }

      List<void Function()> emitQueue = [];
      final imageCount = receiptImages.length;

      for (final image in receiptImages) {
        bool validImage;

        (validImage, invalidImageReason) =
            await ReceiptService.isValidImage(image.path);

        if (!validImage) {
          someImagesFailed = true;
          continue;
        }

        final List<dynamic> results =
            await ReceiptService.processingReceiptAndTags(
                image, currentFolderId);
        final Receipt receipt = results[0];
        final List<Tag> tags = results[1];

        _dbRepo.insertTags(tags);
        await _dbRepo.insertReceipt(receipt);
        print('Image ${receipt.name} saved at ${receipt.localPath}');

        if (imageCount <= maxNumOfImagesBeforeDelay) {
          emit(FolderViewUploadSuccess(uploadedName: receipt.name, folderId: receipt.parentId));
        } else {
          emitQueue.add(() {
            emit(FolderViewUploadSuccess(
                uploadedName: receipt.name, folderId: receipt.parentId));
          });
        }
      }

      if (imageCount > maxNumOfImagesBeforeDelay) {
        for (var emitAction in emitQueue) {
          emitAction();
        }
      }

      // notifying home bloc to reload when all receipts uploaded from gallery
      homeBloc.add(HomeLoadReceiptsEvent());

      if (someImagesFailed) {
        print(invalidImageReason.name);
        emit(FolderViewUploadFailure(folderId: currentFolderId, validationType: invalidImageReason));
      }

      fetchFilesInFolderSortedBy(currentFolderId);

    } on Exception catch (e) {
      print('Error in uploadReceipt: $e');
      emit(FolderViewError());
       fetchFilesInFolderSortedBy(currentFolderId, useCachedFiles: false);
    }
  }

  uploadReceiptFromCamera(String currentFolderId) async {
    // Requesting camera permission if not granted
    if (!PermissionsService.instance.hasCameraAccess) {
      await PermissionsService.instance.requestCameraPermission();
      if (!PermissionsService.instance.hasCameraAccess) {
        emit(FolderViewPermissionsFailure(
            folderId: currentFolderId,
            permissionResult: PermissionsService.instance.cameraResult));
        fetchFilesInFolderSortedBy(currentFolderId, useCachedFiles: true);
        return;
      }
    }

    ValidationError invalidImageReason = ValidationError.none;

    try {
      final ImagePicker imagePicker = ImagePicker();
      final XFile? receiptPhoto =
          await imagePicker.pickImage(source: ImageSource.camera);
      if (receiptPhoto == null) {
        return;
      }

      bool validImage;

      (validImage, invalidImageReason) =
          await ReceiptService.isValidImage(receiptPhoto.path);
      if (!validImage) {
        emit(FolderViewUploadFailure(
            folderId: currentFolderId, validationType: invalidImageReason));
        fetchFilesInFolderSortedBy(currentFolderId, useCachedFiles: true);
        return;
      }

      final List<dynamic> results =
          await ReceiptService.processingReceiptAndTags(
              receiptPhoto, currentFolderId);
      final Receipt receipt = results[0];
      final List<Tag> tags = results[1];

      _dbRepo.insertTags(tags);
      await _dbRepo.insertReceipt(receipt);
      print('Image ${receipt.name} saved at ${receipt.localPath}');

      emit(FolderViewUploadSuccess(
          uploadedName: receipt.name, folderId: receipt.parentId));

      // notifying home bloc to reload when a receipt is uploaded from camera
      homeBloc.add(HomeLoadReceiptsEvent());
      
      fetchFilesInFolderSortedBy(receipt.parentId);

    } on Exception catch (e) {
      print('Error in uploadReceipt: $e');
      emit(FolderViewError());
      fetchFilesInFolderSortedBy(currentFolderId, useCachedFiles: false);
    }
  }

  uploadReceiptFromDocumentScan(String currentFolderId) async {
    // Requesting camera permission if not granted
    if (!PermissionsService.instance.hasCameraAccess) {
      await PermissionsService.instance.requestCameraPermission();
      if (!PermissionsService.instance.hasCameraAccess) {
        emit(FolderViewPermissionsFailure(
            folderId: currentFolderId,
            permissionResult: PermissionsService.instance.cameraResult));
        fetchFilesInFolderSortedBy(currentFolderId, useCachedFiles: true);
        return;
      }
    }

    try {
      List<String> validatedImagePaths = [];

      final scannedImagePaths = await CunningDocumentScanner.getPictures();
      if (scannedImagePaths == null || scannedImagePaths.isEmpty) {
        return;
      }

      const int maxNumOfImagesBeforeDelay = 0;

      if (scannedImagePaths.length > maxNumOfImagesBeforeDelay) {
        emit(FolderViewLoading());
      }

      List<void Function()> emitQueue = [];
      final imageCount = scannedImagePaths.length;

      bool someImagesFailed = false;
      ValidationError invalidImageReason = ValidationError.none;

      // iterating over scanned images and checking image size and if they contain text
      for (final path in scannedImagePaths) {
        bool validImage;
        (validImage, invalidImageReason)  =
            await ReceiptService.isValidImage(path);
        if (!validImage) {
          someImagesFailed = true;
          // fetchFilesInFolderSortedBy(currentFolderId, useCachedFiles: true);
          continue;
        }
        // only adding images that pass validations to list
        validatedImagePaths.add(path);
      }
      // only iterating over validated images and uploading them consecutively
      for (final path in validatedImagePaths) {
        final XFile receiptDocument = XFile(path);
        final List<dynamic> results =
            await ReceiptService.processingReceiptAndTags(
                receiptDocument, currentFolderId);
        final Receipt receipt = results[0];
        final List<Tag> tags = results[1];

        _dbRepo.insertTags(tags);
        await _dbRepo.insertReceipt(receipt);
        print('Image ${receipt.name} saved at ${receipt.localPath}');

        if (imageCount <= maxNumOfImagesBeforeDelay) {
          emit(FolderViewUploadSuccess(
              uploadedName: receipt.name, folderId: receipt.parentId));
        } else {
          emitQueue.add(() {
            emit(FolderViewUploadSuccess(
                uploadedName: receipt.name, folderId: receipt.parentId));
          });
        }
      }

      if (imageCount > maxNumOfImagesBeforeDelay) {
          for (var emitAction in emitQueue) {
            emitAction();
          }
        }

      if (someImagesFailed) {
        print(invalidImageReason.name);
        // if a single image fails the validation, show the upload failed
        emit(FolderViewUploadFailure(folderId: currentFolderId, validationType: invalidImageReason));
      }
      
      // notifying home bloc to reload when a receipt is uploaded from document scan
      homeBloc.add(HomeLoadReceiptsEvent());
      
      fetchFilesInFolderSortedBy(currentFolderId);

    } on Exception catch (e) {
      print('Error in uploadReceipt: $e');
      emit(FolderViewError());
      fetchFilesInFolderSortedBy(currentFolderId, useCachedFiles: false);
    }
  }

  // rename receipt
  renameReceipt(Receipt receipt, String newName) async {
    try {
        int index = cachedCurrentlyDisplayedFiles.indexWhere((element) => element is Receipt && element.id == receipt.id);

        dynamic updatedReceipt = Receipt(
            id: receipt.id,
            name: newName,
            fileName: receipt.fileName,
            dateCreated: receipt.dateCreated,
            lastModified: Utility.getCurrentTime(),
            parentId: receipt.parentId,
            storageSize: receipt.storageSize
        );

        // Check if the receipt is found in the cached list
        if (index != -1) {
            // getting receipt type
            switch (receipt) {
                case ReceiptWithPrice():
                    updatedReceipt = ReceiptWithPrice(priceString: receipt.priceString, priceDouble: receipt.priceDouble, receipt: updatedReceipt);
                case ReceiptWithSize():
                    updatedReceipt = ReceiptWithSize(
                        withSize: receipt.withSize, receipt: updatedReceipt);
                default:
                    break;
            }

            // updating cache
            cachedCurrentlyDisplayedFiles[index] = updatedReceipt;

            emit(FolderViewRenameSuccess(
                oldName: receipt.name, newName: newName, folderId: receipt.parentId));

            // emitting cache
            retrieveCachedItems();

            // updating db
            await _dbRepo.updateReceipt(updatedReceipt);

            homeBloc.add(HomeLoadReceiptsEvent());

        } else {
            throw Exception('Unexpected error: ${receipt.name} not found in cache');
        }
    } on Exception catch (e) {
        print(e.toString());
        emit(FolderViewRenameFailure(
            oldName: receipt.name, newName: newName, folderId: receipt.parentId));
        fetchFilesInFolderSortedBy(receipt.parentId);
    }
}


  generateZipFile(Folder folder, bool withPdfs) async {

    final folderIsEmpty = await _dbRepo.folderIsEmpty(folder.id);
    
    if (folderIsEmpty) {
      emit(FolderViewFileEmpty(folder: folder, files: cachedCurrentlyDisplayedFiles, orderedBy: prefs.getLastColumn(), order: prefs.getLastOrder(),));
      fetchFilesInFolderSortedBy(folder.parentId, useCachedFiles: true);
      return;
    }

    emit(FolderViewFileLoading(files: cachedCurrentlyDisplayedFiles, folder: folder, orderedBy: prefs.getLastColumn(), order: prefs.getLastOrder()));

    try {
      Map<String, dynamic> serializedFolder = folder.toMap();

      Map<String, dynamic> computeParams = {
        'folder': serializedFolder,
        'withPdfs': withPdfs
      };

      // Prepare data to pass to isolate
      final isolateParams = IsolateParams(
        computeParams: computeParams,
        rootToken: RootIsolateToken.instance!,
      );

      final receivePort = ReceivePort();
      await Isolate.spawn(IsolateService.zipFileEntryFunction, {
        'isolateParams': isolateParams,
        'sendPort': receivePort.sendPort,
      });

      // Receive data back from the isolate
      final File zipFile = await receivePort.first;

      emit(FolderViewFileLoaded(zipFile: zipFile, files: cachedCurrentlyDisplayedFiles, folder: folder, orderedBy: prefs.getLastColumn(), order: prefs.getLastOrder()));
    } on Exception catch (e) {
      print(e.toString());
      emit(FolderViewFileError(files: cachedCurrentlyDisplayedFiles, folder: folder, orderedBy: prefs.getLastColumn(), order: prefs.getLastOrder()));
      fetchFilesInFolderSortedBy(folder.parentId, useCachedFiles: true);
    }
  }

  // share folder
  shareFolder(Folder folder, File zipFile) async {
    try {
      await FileService.shareFolderAsZip(folder, zipFile);
    } on Exception catch (e) {
      print(e.toString());
      emit(FolderViewShareFailure(errorMessage: e.toString(), folderId: folder.id, folderName: folder.name));
      fetchFilesInFolderSortedBy(folder.parentId, useCachedFiles: true);
    }
  }

  updateReceiptDate(Receipt receipt, int newTimestamp) async {
    try {
        int index = cachedCurrentlyDisplayedFiles.indexWhere((element) => element is Receipt && element.id == receipt.id);

        dynamic updatedReceipt = Receipt(
            id: receipt.id,
            name: receipt.name,
            fileName: receipt.fileName,
            dateCreated: newTimestamp,
            lastModified: newTimestamp,
            storageSize: receipt.storageSize,
            parentId: receipt.parentId
        );

        // Check if the receipt is found in the cached list
        if (index != -1) {
            // getting receipt type
            switch (receipt) {
                case ReceiptWithPrice():
                    updatedReceipt = ReceiptWithPrice(priceString: receipt.priceString, priceDouble: receipt.priceDouble, receipt: updatedReceipt);
                case ReceiptWithSize():
                    updatedReceipt = ReceiptWithSize(withSize: receipt.withSize, receipt: updatedReceipt);
                default:
                    break;
            }

            // updating cache
            cachedCurrentlyDisplayedFiles[index] = updatedReceipt;

            emit(FolderViewUpdateDateSuccess(receiptName: receipt.name, folderId: receipt.parentId, oldTimestamp: receipt.lastModified, newTimestamp: newTimestamp));

            // emitting cache
            retrieveCachedItems();

            // updating db
            await _dbRepo.updateReceipt(updatedReceipt);

            // notifying home bloc to reload
            homeBloc.add(HomeLoadReceiptsEvent());

        } else {
            throw Exception('Unexpected error: ${receipt.name} not found in cache');
        }
    } on Exception catch (e) {
        print(e.toString());
        emit(FolderViewUpdateDateFailure(folderId: receipt.parentId));
        fetchFilesInFolderSortedBy(receipt.parentId, useCachedFiles: false);
    }
}
}
