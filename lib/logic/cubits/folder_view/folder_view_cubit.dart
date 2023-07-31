import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receiptcamp/data/repositories/database_repository.dart';
import 'package:receiptcamp/data/utils/receipt_helper.dart';
import 'package:receiptcamp/data/utils/utilities.dart';
import 'package:receiptcamp/models/folder.dart';
import 'package:receiptcamp/models/receipt.dart';
import 'package:receiptcamp/models/tag.dart';

part 'folder_view_state.dart';

// this cubit controls the initialisation, loading, displaying and any methods that can 
// affect what is currently being displayed in the folder view e.g. move/delete/upload/rename
class FolderViewCubit extends HydratedCubit<FolderViewState> {
  FolderViewCubit() : super(FolderViewInitial());

  // init folderview
  initFolderView(String currentFolderId) {
    emit(FolderViewInitial());
    fetchFiles(currentFolderId);
  }

  // get folder files
  fetchFiles(String folderId) async {
    emit(FolderViewLoading());
    try {
      final folder = await DatabaseRepository.instance.getFolderById(folderId);
      final List<Object> files = await DatabaseRepository.instance.getFolderContents(folderId);
      emit(FolderViewLoadedSuccess(files: files, folder: folder));
    } catch (error) {
      emit(FolderViewError());
    }
  }

  // move folder
moveFolder(Folder folder, String targetFolderId) async {
  final String targetFolderName = (await DatabaseRepository.instance.getFolderById(targetFolderId)).name;
  try {
    await DatabaseRepository.instance.moveFolder(folder, targetFolderId);
    emit(FolderViewMoveSuccess(oldName: folder.name, newName: targetFolderName, folderId: folder.parentId));
    fetchFiles(folder.parentId);
  } on Exception catch (e) {
    print(e.toString());
    emit(FolderViewMoveFailure(oldName: folder.name, newName: targetFolderName, folderId: folder.parentId));
  }
}

// delete folder
deleteFolder(String folderId) async {
  final Folder deletedFolder = await DatabaseRepository.instance.getFolderById(folderId);
  try {
    await DatabaseRepository.instance.deleteFolder(folderId);
    emit(FolderViewDeleteSuccess(deletedName: deletedFolder.name, folderId: deletedFolder.parentId));
    fetchFiles(deletedFolder.parentId);
  } on Exception catch (e) {
    print(e.toString());
    emit(FolderViewDeleteFailure(deletedName: deletedFolder.name, folderId: deletedFolder.parentId));
  }
}

// upload folder
uploadFolder(String folderName, String parentFolderId) async {
  try {
    // creating folder id
    final folderId = Utility.generateUid();
    final currentTime = Utility.getCurrentTime();

    // create folder object
    final folder = Folder(id: folderId, name: folderName, lastModified: currentTime, parentId: parentFolderId );

    // save folder
    DatabaseRepository.instance.insertFolder(folder);

    emit(FolderViewUploadSuccess(uploadedName: folder.name, folderId: folder.parentId));
    fetchFiles(parentFolderId);
  } on Exception catch (e) {
    print('Error in uploadFolder: $e');
    emit(FolderViewError());
  }
}

// rename folder
renameFolder(Folder folder, String newName) async {
  try {
    await DatabaseRepository.instance.renameFolder(folder.id, newName);
    emit(FolderViewRenameSuccess(oldName: folder.name, newName: newName, folderId: folder.parentId));
    fetchFiles(folder.parentId);
  } on Exception catch (e) {
    print(e.toString());
    emit(FolderViewRenameFailure(oldName: folder.name, newName: newName, folderId: folder.parentId));
  }
}

// move receipt
moveReceipt(Receipt receipt, String targetFolderId) async {
  final String targetFolderName = (await DatabaseRepository.instance.getFolderById(targetFolderId)).name;
  try {
    await DatabaseRepository.instance.moveReceipt(receipt, targetFolderId);
    emit(FolderViewMoveSuccess(oldName: receipt.name, newName: targetFolderName, folderId: receipt.parentId));
    fetchFiles(receipt.parentId);
  } on Exception catch (e) {
    print(e.toString());
    emit(FolderViewMoveFailure(oldName: receipt.name, newName: targetFolderName, folderId: receipt.parentId));
  }
}

// delete receipt
deleteReceipt(String receiptId) async {
  final Receipt deletedReceipt = await DatabaseRepository.instance.getReceiptById(receiptId);
  try {
    await DatabaseRepository.instance.deleteReceipt(receiptId);
    emit(FolderViewDeleteSuccess(deletedName: deletedReceipt.name, folderId: deletedReceipt.parentId));
    fetchFiles(deletedReceipt.parentId);
  } on Exception catch (e) {
    print(e.toString());
    emit(FolderViewDeleteFailure(deletedName: deletedReceipt.name, folderId: deletedReceipt.parentId));
  }
}

// upload receipt
uploadReceipt(String currentFolderId) async {
  try {
    final ImagePicker imagePicker = ImagePicker();
    final XFile? receiptImage =
        await imagePicker.pickImage(source: ImageSource.gallery);
    if (receiptImage == null) {
      return;
    }

    final List<dynamic> results = await ReceiptService.processingReceiptAndTags(receiptImage, currentFolderId);
    final Receipt receipt = results[0];
    final List<Tag> tags = results[1];

    await DatabaseRepository.instance.insertTags(tags);
    await DatabaseRepository.instance.insertReceipt(receipt);
    print('Image ${receipt.name} saved at ${receipt.localPath}');

    emit(FolderViewUploadSuccess(uploadedName: receipt.name, folderId: receipt.parentId));
    fetchFiles(receipt.parentId);
  } on Exception catch (e) {
    print('Error in uploadReceipt: $e');
    emit(FolderViewError());
  }
}

uploadReceiptFromCamera(String currentFolderId) async {
  try {
    final ImagePicker imagePicker = ImagePicker();
    final XFile? receiptPhoto =
        await imagePicker.pickImage(source: ImageSource.camera);
    if (receiptPhoto == null) {
      return;
    }

    final List<dynamic> results = await ReceiptService.processingReceiptAndTags(receiptPhoto, currentFolderId);
    final Receipt receipt = results[0];
    final List<Tag> tags = results[1];

    await DatabaseRepository.instance.insertTags(tags);
    await DatabaseRepository.instance.insertReceipt(receipt);
    print('Image ${receipt.name} saved at ${receipt.localPath}');

    emit(FolderViewUploadSuccess(uploadedName: receipt.name, folderId: receipt.parentId));
    fetchFiles(receipt.parentId);
  } on Exception catch (e) {
    print('Error in uploadReceipt: $e');
    emit(FolderViewError());
  }

}

// rename receipt
renameReceipt(Receipt receipt, String newName) async {
  try {
    await DatabaseRepository.instance.renameReceipt(receipt.id, newName);
    emit(FolderViewRenameSuccess(oldName: receipt.name, newName: newName, folderId: receipt.parentId));
    fetchFiles(receipt.parentId);
  } on Exception catch (e) {
    print(e.toString());
    emit(FolderViewRenameFailure(oldName: receipt.name, newName: newName, folderId: receipt.parentId));
  }
}

  @override
  FolderViewState? fromJson(Map<String, dynamic> json) {
    // TODO: implement fromJson
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic>? toJson(FolderViewState state) {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
