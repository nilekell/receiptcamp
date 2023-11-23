part of 'folder_view_cubit.dart';

sealed class FolderViewState extends Equatable {
  const FolderViewState();

  @override
  List<Object> get props => [];
}

final class FolderViewActionState extends FolderViewState {
  final String folderId;

  const FolderViewActionState({required this.folderId});
  
}

final class FolderViewInitial extends FolderViewState {}

final class FolderViewLoading extends FolderViewState {}

final class FolderViewLoadedSuccess extends FolderViewState {
  final List<dynamic> files;
  final Folder folder;
  final String orderedBy;
  final String order;
  const FolderViewLoadedSuccess({required this.files, required this.folder, required this.orderedBy, required this.order});

  @override
  List<Object> get props => [files, folder, orderedBy, order];
}

final class FolderViewError extends FolderViewState {}

// Renaming States

final class FolderViewRenameSuccess extends FolderViewActionState {
  const FolderViewRenameSuccess({required this.oldName, required this.newName, required super.folderId});
  final String oldName;
  final String newName;

  @override
  List<Object> get props => [oldName, newName];
}

final class FolderViewRenameFailure extends FolderViewActionState {
  final String oldName;
  final String newName;

  const FolderViewRenameFailure({required this.oldName, required this.newName, required super.folderId});

  @override
  List<Object> get props => [oldName, newName];
}

// Moving states

final class FolderViewMoveSuccess extends FolderViewActionState {
  const FolderViewMoveSuccess({required this.oldName, required this.newName, required super.folderId});

  final String oldName;
  final String newName;

  @override
  List<Object> get props => [oldName, newName];
}

final class FolderViewMoveFailure extends FolderViewActionState {
  const FolderViewMoveFailure({required this.oldName, required this.newName, required super.folderId});

  final String oldName;
  final String newName;

  @override
  List<Object> get props => [oldName, newName];
}

final class FolderViewUpdateDateSuccess extends FolderViewActionState {
  const FolderViewUpdateDateSuccess({required super.folderId, required this.oldTimestamp, required this.newTimestamp, required this.receiptName});

  final String receiptName;
  final int oldTimestamp;
  final int newTimestamp;

  @override
  List<Object> get props => [folderId, oldTimestamp, newTimestamp, receiptName];
}

final class FolderViewUpdateDateFailure extends FolderViewActionState {
  const FolderViewUpdateDateFailure({required super.folderId});

  @override
  List<Object> get props => [folderId];
}

// Deleting states

final class FolderViewDeleteSuccess extends FolderViewActionState {
  const FolderViewDeleteSuccess({required this.deletedName, required super.folderId});

  final String deletedName;

  @override
  List<Object> get props => [deletedName];
}

final class FolderViewDeleteFailure extends FolderViewActionState {
  const FolderViewDeleteFailure({required this.deletedName, required super.folderId});

  final String deletedName;

  @override
  List<Object> get props => [deletedName];
}

// Sharing states

final class FolderViewFileState extends FolderViewLoadedSuccess {
  const FolderViewFileState({required super.files, required super.folder, required super.orderedBy, required super.order});
  
  @override
  List<Object> get props => [files, folder, orderedBy, order];
}

final class FolderViewFileLoading extends FolderViewFileState {
  const FolderViewFileLoading({required super.files, required super.folder, required super.orderedBy, required super.order});
  
  @override
  List<Object> get props => [files, folder, orderedBy, order];
}

final class FolderViewFileLoaded extends FolderViewFileState {
  const FolderViewFileLoaded({required this.zipFile, required super.files, required super.folder, required super.orderedBy, required super.order});

  final File zipFile;

  @override
  List<Object> get props => [files, folder, orderedBy, order, zipFile];
}

final class FolderViewFileError extends FolderViewFileState {
  const FolderViewFileError({required super.files, required super.folder, required super.orderedBy, required super.order});

  @override
  List<Object> get props => [files, folder, orderedBy, order];
}

final class FolderViewFileEmpty extends FolderViewFileState {
  const FolderViewFileEmpty({required super.files, required super.folder, required super.orderedBy, required super.order});

  @override
  List<Object> get props => [files, folder, orderedBy, order];
}

// currently FolderViewShareSuccess is not used
final class FolderViewShareSuccess extends FolderViewActionState {
  const FolderViewShareSuccess({required this.receiptName, required super.folderId});

  final String receiptName;

  @override
  List<Object> get props => [receiptName];
}

final class FolderViewShareFailure extends FolderViewActionState {
  final String errorMessage;
  final String folderName;

  const FolderViewShareFailure({required super.folderId, required this.errorMessage, required this.folderName});

  @override
  List<Object> get props => [errorMessage];
}

final class FolderViewUploadSuccess extends FolderViewActionState {
  final String uploadedName;

  const FolderViewUploadSuccess({required this.uploadedName, required super.folderId});

  @override
  List<Object> get props => [uploadedName];
}

final class FolderViewUploadFailure extends FolderViewActionState {
  final ValidationError validationType;

  const FolderViewUploadFailure({required super.folderId, required this.validationType});
}

final class FolderViewPermissionsFailure extends FolderViewActionState {
  final PermissionFailedResult permissionResult;

  const FolderViewPermissionsFailure({required super.folderId, required this.permissionResult});
}

final class FolderViewMultiMoveSuccess extends FolderViewActionState {
  const FolderViewMultiMoveSuccess({required super.folderId, required this.numItemsMoved, required this.destinationFolderName});

  final int numItemsMoved;
  final String destinationFolderName;

  @override
  List<Object> get props => [numItemsMoved, destinationFolderName];
   
}

final class FolderViewMultiMoveFailure extends FolderViewActionState {
  const FolderViewMultiMoveFailure({required super.folderId});

  @override
  List<Object> get props => [folderId];
}

final class FolderViewMultiDeleteSuccess extends FolderViewActionState {
  const FolderViewMultiDeleteSuccess({required super.folderId, required this.numItemsDeleted});

  final int numItemsDeleted;

  @override
  List<Object> get props => [numItemsDeleted];

}

final class FolderViewMultiDeleteFailure extends FolderViewActionState {
  const FolderViewMultiDeleteFailure({required super.folderId});

  @override
  List<Object> get props => [folderId];
}