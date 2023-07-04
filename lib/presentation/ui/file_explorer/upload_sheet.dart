import 'package:flutter/material.dart';
import 'package:receiptcamp/logic/blocs/upload/upload_bloc.dart';
import 'package:receiptcamp/models/folder.dart';
import 'package:receiptcamp/presentation/ui/file_explorer/folder/create_folder_dialog.dart';

void showUploadOptions(BuildContext context, UploadBloc uploadBloc, Folder currentFolder) {
  showModalBottomSheet(
    context: context,
    builder: (bottomSheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.photo_library),
          title: const Text('Choose from gallery'),
          onTap: () {
            Navigator.of(bottomSheetContext).pop();
            uploadBloc.add(UploadTapEvent(folderId: currentFolder.id));
          },
        ),
        ListTile(
          leading: const Icon(Icons.camera),
          title: const Text('Take a photo'),
          onTap: () {
            Navigator.of(bottomSheetContext).pop();
            uploadBloc.add(CameraTapEvent(folderId: currentFolder.id));
          },
        ),
        ListTile(
          leading: const Icon(Icons.folder),
          title: const Text('New folder'),
          onTap: () {
            // closing bottom sheet
            Navigator.of(bottomSheetContext).pop();
            showCreateFolderDialog(bottomSheetContext, uploadBloc, currentFolder);
          },
        ),
      ],
    ),
  );
}
