import "package:flutter/material.dart";
import "package:receiptcamp/data/services/permissons.dart";
import "package:receiptcamp/data/utils/receipt_helper.dart";
import "package:receiptcamp/data/utils/utilities.dart";
import "package:receiptcamp/logic/cubits/folder_view/folder_view_cubit.dart";
import "package:receiptcamp/presentation/ui/ui_constants.dart";

// utility class that creates and shows snackbars displayed on file explorer screen
abstract class SnackBarUtility {
  static void showSnackBar(BuildContext context, FolderViewActionState state) {
    String message = "";

    switch (state) {
      case FolderViewUploadSuccess():
        message = "'${state.uploadedName}' added successfully";
        break;
      case FolderViewUploadFailure():
        switch (state.validationType) {
          case ValidationError.size:
            message = 'Image(s) too large to upload';
            break;
          case ValidationError.text:
            message = "Image(s) not recognised as receipt(s)";
            break;
          case ValidationError.both:
            message = 'Image(s) too large and not recognised as receipt(s)';
            break;
          case ValidationError.none:
            break;
        }
        break;
      // for rename/move/delete/share failures, an unexpected error has occured so snackbar has shown
      // and a bug fix will be required in the future
      case FolderViewRenameSuccess():
        message = "'${state.oldName}' renamed to '${state.newName}'";
        break;
      case FolderViewRenameFailure():
        message = "Failed to rename '${state.oldName}'";
        break;
      case FolderViewMoveSuccess():
        message = "Moved '${state.oldName}' to '${state.newName}'";
        break;
      case FolderViewMoveFailure():
        message = "Failed to move '${state.oldName}' to '${state.newName}'";
        break;
      case FolderViewDeleteSuccess():
        message = "Deleted '${state.deletedName}'";
        break;
      case FolderViewDeleteFailure():
        message = "Failed to delete '${state.deletedName}'";
        break;
      case FolderViewShareFailure():
        message = "Failed to share '${state.folderName}' ";
        break;
      case FolderViewPermissionsFailure():
        if (state.permissionResult == PermissionFailedResult.invalidCamera) {
          message = 'Failed to open camera - please check app settings';
          break;
        } else if (state.permissionResult == PermissionFailedResult.invalidPhotos) {
          message = 'Failed to open photo library - please check app settings';
          break;
        }
      case FolderViewMultiDeleteSuccess():
        message = state.numItemsDeleted > 1 ? 'Successfully deleted ${state.numItemsDeleted} items' :  'Successfully deleted ${state.numItemsDeleted} item';
        break;
      case FolderViewMultiDeleteFailure():
        message = 'Uh oh, an unexpected error occured while deleting those items';
        break;
      case FolderViewMultiMoveSuccess():
        message = state.numItemsMoved > 1 ? 'Successfully moved ${state.numItemsMoved} items' :  'Successfully moved ${state.numItemsMoved} item';
        break;
      case FolderViewMultiMoveFailure():
        message = 'Uh oh, an unexpected error occured while moving those items';
        break;
      case FolderViewUpdateDateSuccess():
        message = "Updated '${state.receiptName}' date to ${Utility.formatDisplayDateFromDateTime(Utility.formatDateTimeFromUnixTimestamp(state.newTimestamp))}";
        break;
      case FolderViewUpdateDateFailure():
        message = 'Failed to update date';
        break;
      default:
        print('Unknown state in showSnackBar: ${state.runtimeType}');
        return;
    }

    final SnackBar appSnackBar = SnackBar(
      backgroundColor: const Color(primaryDeepBlue),
      behavior: SnackBarBehavior.floating,
      content: Text(message),
      duration: const Duration(milliseconds: 2000),
    );

    ScaffoldMessenger.of(context).showSnackBar(appSnackBar);
  }
}


