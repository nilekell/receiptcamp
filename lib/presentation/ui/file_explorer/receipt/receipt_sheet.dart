import 'package:flutter/material.dart';
import 'package:receiptcamp/data/utils/file_helper.dart';
import 'package:receiptcamp/logic/cubits/folder_view/folder_view_cubit.dart';
import 'package:receiptcamp/models/receipt.dart';
import 'package:receiptcamp/presentation/ui/file_explorer/receipt/delete_receipt_confirmation_dialog.dart';
import 'package:receiptcamp/presentation/ui/file_explorer/receipt/move_receipt_dialog.dart';
import 'package:receiptcamp/presentation/ui/file_explorer/receipt/rename_receipt_dialog.dart';

void showReceiptOptions(BuildContext context, FolderViewCubit folderViewCubit, Receipt receipt) {
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
            // opening rename receipt dialog
            showRenameReceiptDialog(bottomSheetContext, folderViewCubit, receipt);
          },
        ),
        ListTile(
          leading: const Icon(Icons.drive_file_move),
          title: const Text('Move'),
          onTap: () {
            Navigator.of(bottomSheetContext).pop();
            // show move receipt dialog
            showMoveReceiptDialog(context, folderViewCubit, receipt);
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete),
          title: const Text('Delete'),
          onTap: () {
            Navigator.of(bottomSheetContext).pop();
            // opening delete receipt dialog
            showDeleteReceiptDialog(bottomSheetContext, folderViewCubit, receipt);
          },
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Download'),
          onTap: () {
            Navigator.of(bottomSheetContext).pop();
            FileService.saveImageToCameraRoll(receipt);
          },
        ),
        ListTile(
          leading: const Icon(Icons.share),
          title: const Text('Share'),
          onTap: () {
            Navigator.of(bottomSheetContext).pop();
            FileService.shareReceipt(receipt);
          },
        ),
      ],
    ),
  );
}