import 'package:flutter/material.dart';
import 'package:receiptcamp/logic/cubits/file_edit/file_editing_cubit.dart';
import 'package:receiptcamp/models/folder.dart';
import 'package:receiptcamp/presentation/ui/file_explorer/folder/delete_folder_confirmation_dialog.dart';
import 'package:receiptcamp/presentation/ui/file_explorer/folder/move_folder_dialog.dart';
import 'package:receiptcamp/presentation/ui/file_explorer/folder/rename_folder_dialog.dart';
void showFolderOptions(BuildContext context, FileEditingCubit fileEditingCubit, Folder folder) {
  showModalBottomSheet(
    context: context,
    builder: (bottomSheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('Rename'),
          onTap: () {
            // closing bottom sheet
            Navigator.of(bottomSheetContext).pop();
            // opening rename folder dialog
            showRenameFolderDialog(bottomSheetContext, fileEditingCubit, folder);
          },
        ),
        ListTile(
          leading: const Icon(Icons.drive_file_move),
          title: const Text('Move'),
          onTap: () {
            // closing bottom sheet
            Navigator.of(bottomSheetContext).pop();
            // show move folder dialog
            showMoveFolderDialog(bottomSheetContext, fileEditingCubit, folder);
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete),
          title: const Text('Delete'),
          onTap: () {
            Navigator.of(bottomSheetContext).pop();
            // opening deleting folder dialog
            showDeleteFolderDialog(bottomSheetContext, fileEditingCubit, folder);
          },
        ),
      ],
    ),
  );
}