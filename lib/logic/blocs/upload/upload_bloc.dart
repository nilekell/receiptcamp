import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:receiptcamp/data/repositories/database_repository.dart';
import 'package:receiptcamp/data/utils/receipt_helper.dart';
import 'package:receiptcamp/data/utils/file_helper.dart';
import 'package:receiptcamp/data/utils/utilities.dart';
import 'package:receiptcamp/models/folder.dart';
import 'package:receiptcamp/models/receipt.dart';
import 'package:receiptcamp/models/tag.dart';

part 'upload_event.dart';
part 'upload_state.dart';

class UploadBloc extends Bloc<UploadEvent, UploadState> {
  UploadBloc() : super(UploadInitial()) {
    on<UploadInitialEvent>(uploadInitialEvent);
    on<UploadTapEvent>(uploadTapEvent);
    on<CameraTapEvent>(cameraTapEvent);
    on<FolderCreateEvent>(folderCreateEvent);
  }

  FutureOr<void> uploadInitialEvent(event, Emitter<UploadState> emit) {}

  FutureOr<void> uploadTapEvent(
      UploadTapEvent event, Emitter<UploadState> emit) async {
    try {
      final ImagePicker imagePicker = ImagePicker();
      final XFile? receiptImage =
          await imagePicker.pickImage(source: ImageSource.gallery);
      if (receiptImage == null) {
        return;
      }

      final results = await processingReceiptAndTags(receiptImage, event.folderId);
      final receipt = results[0];
      final tags = results[1];

      await DatabaseRepository.instance.insertTags(tags);
      await DatabaseRepository.instance.insertReceipt(receipt);
      print('Image ${receipt.name} saved at ${receipt.localPath}');

      emit(UploadReceiptSuccess(receipt: receipt));
    } on PlatformException catch (e) {
      print(e.toString());
    } on Exception catch (e) {
      print('Error in uploadTapEvent: $e');
      emit(UploadFailed());
      return;
    }
  }

  FutureOr<void> cameraTapEvent(
      CameraTapEvent event, Emitter<UploadState> emit) async {
    try {
      final ImagePicker imagePicker = ImagePicker();
      final XFile? receiptPicture =
          await imagePicker.pickImage(source: ImageSource.camera);
      if (receiptPicture == null) {
        return;
      }

      final results = await processingReceiptAndTags(receiptPicture, event.folderId);
      final Receipt receipt = results[0];
      final List<Tag> tags = results[1];

      await DatabaseRepository.instance.insertTags(tags);
      await DatabaseRepository.instance.insertReceipt(receipt);
      print('Image ${receipt.name} saved at ${receipt.localPath}');

      emit(UploadReceiptSuccess(receipt: receipt));
    } on PlatformException catch (e) {
      print(e.toString());
    } on Exception catch (e) {
      print('Error in ReceiptService.generateAndSaveReceipt: $e');
      emit(UploadFailed());
      return;
    }
  }

  FutureOr<void> folderCreateEvent(
      FolderCreateEvent event, Emitter<UploadState> emit) async {
    try {
      // creating folder id
      final folderId = Utility.generateUid();
      final currentTime = Utility.getCurrentTime();

      // create folder object
      final folder = Folder(id: folderId, name: event.name, lastModified: currentTime, parentId: event.parentId );

      // save folder
      DatabaseRepository.instance.insertFolder(folder);
      print('Folder ${folder.name} saved in ${folder.parentId}');
      emit(UploadFolderSuccess(folder: folder));
    } on Exception catch (e) {
      print('Error in folderCreateEvent: $e');
      emit(UploadFailed());
    }
  }
}

Future<List<dynamic>> processingReceiptAndTags(XFile receiptImage, String folderIdToSaveTo) async {
  // tag actions
  final receiptUid = Utility.generateUid();
  final tagsList = await ReceiptService.extractKeywordsAndGenerateTags(
      receiptImage.path, receiptUid);

  // compressing and saving image
  final localReceiptImagePath = await FileService.getLocalImagePath();
  final receiptImageFile = await FileService.compressFile(
      File(receiptImage.path), localReceiptImagePath);

  // deleting temporary image files
  await FileService.deleteImageFromPath(receiptImage.path);

  // creating receipt object
  final receipt = await ReceiptService.createReceiptFromFile(
      receiptImageFile!, basename(receiptImageFile.path), folderIdToSaveTo);

  return [receipt, tagsList];
}
